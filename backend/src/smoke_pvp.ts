import "dotenv/config";

import fs from "node:fs/promises";
import path from "node:path";

import { buildApp } from "./app";
import { getPrisma, isDatabaseConfigured } from "./database";
import { closeRedisClient } from "./infrastructure/RedisClient";

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function getString(obj: Record<string, unknown>, key: string): string | null {
  const v = obj[key];
  return typeof v === "string" ? v : null;
}

async function expectOk(
  res: { statusCode: number; body: string },
  label: string
) {
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw new Error(`${label}: status=${res.statusCode} body=${res.body}`);
  }
}

async function loadDictionaryWords(): Promise<string[]> {
  // 実行時のcwdは通常 backend/ なので、repo直下のJSONを参照する
  const dictPath = path.resolve(process.cwd(), "../shiritori_list.json");
  const raw = await fs.readFile(dictPath, "utf-8");
  const parsed = JSON.parse(raw) as unknown;
  if (!Array.isArray(parsed) || !parsed.every((x) => typeof x === "string")) {
    throw new Error(`shiritori_list.json の形式が不正です: ${dictPath}`);
  }
  return parsed;
}

function pickWord(params: { words: string[]; startsWith: string }): string {
  const { words, startsWith } = params;
  for (const w of words) {
    if (!w.startsWith(startsWith)) continue;
    if (w.endsWith("ん")) continue;
    if (w.length < 2) continue;
    return w;
  }
  throw new Error(`辞書に開始文字 '${startsWith}' の単語が見つかりません`);
}

async function signupUser(params: {
  app: Awaited<ReturnType<typeof buildApp>>;
  name: string;
  password: string;
}): Promise<{ userId: string; token: string }> {
  const { app, name, password } = params;

  const res = await app.inject({
    method: "POST",
    url: "/api/auth/signup",
    payload: { name, password },
  });
  await expectOk(res, "/api/auth/signup");

  const json = res.json() as unknown;
  if (!isObject(json)) throw new Error("signup: invalid json");

  const token = getString(json, "token");
  if (!token) throw new Error("signup: missing token");

  const userObj = json["user"];
  if (!isObject(userObj)) throw new Error("signup: missing user");
  const userId = getString(userObj, "id");
  if (!userId) throw new Error("signup: missing user.id");

  return { userId, token };
}

async function findIsolatedBaseRating(params: {
  prisma: ReturnType<typeof getPrisma>;
  excludeUserIds: string[];
}): Promise<number> {
  const { prisma, excludeUserIds } = params;

  const max = await prisma.user.aggregate({
    _max: { rating: true },
  });

  const maxRating = max._max.rating ?? 0;
  const candidates = [
    2_000_000_000,
    1_500_000_000,
    1_000_000_000,
    500_000_000,
    maxRating + 1000,
  ];

  for (const base of candidates) {
    const count = await prisma.user.count({
      where: {
        id: { notIn: excludeUserIds },
        rating: { gte: base - 100, lte: base + 100 },
      },
    });

    if (count === 0) return base;
  }

  // 最後の手段: max+1000 を基準に少しずつずらして探索
  let base = maxRating + 10_000;
  for (let i = 0; i < 50; i++) {
    const count = await prisma.user.count({
      where: {
        id: { notIn: excludeUserIds },
        rating: { gte: base - 100, lte: base + 100 },
      },
    });
    if (count === 0) return base;
    base += 10_000;
  }

  throw new Error("smoke:pvp 用の隔離レート帯が見つかりませんでした");
}

async function main() {
  if (!isDatabaseConfigured()) {
    throw new Error("DATABASE_URL が未設定のため、smoke:pvp を実行できません");
  }

  const words = await loadDictionaryWords();

  const app = await buildApp();
  await app.ready();

  const prisma = getPrisma();

  try {
    const password = "password123";
    const suffix = Date.now().toString(36);
    const u1 = await signupUser({
      app,
      name: `smoke_pvp_u1_${suffix}`,
      password,
    });
    const u2 = await signupUser({
      app,
      name: `smoke_pvp_u2_${suffix}`,
      password,
    });

    // 既存ユーザーとレート帯が被ると matchmake 相手がブレるため、他ユーザーがいないレート帯(±100)を探索して隔離する
    const baseRating = await findIsolatedBaseRating({
      prisma,
      excludeUserIds: [u1.userId, u2.userId],
    });
    await prisma.user.update({
      where: { id: u1.userId },
      data: { rating: baseRating },
    });
    await prisma.user.update({
      where: { id: u2.userId },
      data: { rating: baseRating + 50 },
    });

    const token1 = u1.token;
    const token2 = u2.token;

    const mm1 = await app.inject({
      method: "POST",
      url: "/api/matchmake",
      headers: { authorization: `Bearer ${token1}` },
      payload: {},
    });
    if (mm1.statusCode === 404) {
      throw new Error(
        `matchmake(u1) が 404 でした。レート帯の候補がいない可能性があります body=${mm1.body}`
      );
    }
    await expectOk(mm1, "/api/matchmake (u1)");

    const mm1Json = mm1.json() as unknown;
    if (!isObject(mm1Json)) throw new Error("matchmake(u1): invalid json");

    const sessionObj = mm1Json["session"];
    if (!isObject(sessionObj))
      throw new Error("matchmake(u1): missing session");
    const sessionId = getString(sessionObj, "id");
    if (!sessionId) throw new Error("matchmake(u1): missing session.id");

    const opponentObj = mm1Json["opponent"];
    if (!isObject(opponentObj))
      throw new Error("matchmake(u1): missing opponent");
    const opponentId = getString(opponentObj, "userId");
    if (!opponentId) throw new Error("matchmake(u1): missing opponent.userId");

    if (opponentId !== u2.userId) {
      throw new Error(
        `想定外の相手が選ばれました: expected=${u2.userId} actual=${opponentId}`
      );
    }

    const mm2 = await app.inject({
      method: "POST",
      url: "/api/matchmake",
      headers: { authorization: `Bearer ${token2}` },
      payload: {},
    });
    if (mm2.statusCode !== 200) {
      throw new Error(
        `matchmake(u2): status=${mm2.statusCode} body=${mm2.body}`
      );
    }

    const mm2Json = mm2.json() as unknown;
    if (!isObject(mm2Json)) throw new Error("matchmake(u2): invalid json");
    const sessionObj2 = mm2Json["session"];
    if (!isObject(sessionObj2))
      throw new Error("matchmake(u2): missing session");
    const sessionId2 = getString(sessionObj2, "id");
    if (!sessionId2) throw new Error("matchmake(u2): missing session.id");

    if (sessionId2 !== sessionId) {
      throw new Error(
        `matchmake で同じ session が配布されませんでした: u1=${sessionId} u2=${sessionId2}`
      );
    }

    const pvp = await app.inject({
      method: "GET",
      url: `/api/pvp/${sessionId}`,
      headers: { authorization: `Bearer ${token1}` },
    });
    await expectOk(pvp, "/api/pvp/:sessionId");

    const pvpJson = pvp.json() as unknown;
    if (!isObject(pvpJson)) throw new Error("pvp: invalid json");
    const pvpSessionObj = pvpJson["session"];
    if (!isObject(pvpSessionObj)) throw new Error("pvp: missing session");

    const expectedStartChar = getString(pvpSessionObj, "expectedStartChar");
    const currentTurnUserId = getString(pvpSessionObj, "currentTurnUserId");
    if (!expectedStartChar) throw new Error("pvp: missing expectedStartChar");
    if (!currentTurnUserId) throw new Error("pvp: missing currentTurnUserId");

    const word = pickWord({ words, startsWith: expectedStartChar });

    const submitToken = currentTurnUserId === u1.userId ? token1 : token2;

    const submit = await app.inject({
      method: "POST",
      url: `/api/pvp/${sessionId}/submit`,
      headers: { authorization: `Bearer ${submitToken}` },
      payload: { word },
    });
    await expectOk(submit, "/api/pvp/:sessionId/submit");

    const submitJson = submit.json() as unknown;
    if (!isObject(submitJson)) throw new Error("submit: invalid json");

    console.log("[smoke:pvp] ok", {
      sessionId,
      word,
      expectedStartChar,
      submittedBy: currentTurnUserId,
    });
  } finally {
    await app.close();
    await prisma.$disconnect();
    await closeRedisClient();
  }
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
