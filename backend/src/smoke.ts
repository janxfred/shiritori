import "dotenv/config";
import { buildApp } from "./app";
import { getPrisma, isDatabaseConfigured } from "./database";

async function expectOk(
  res: { statusCode: number; body: string },
  label: string
) {
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw new Error(`${label}: status=${res.statusCode} body=${res.body}`);
  }
}

async function main() {
  const app = await buildApp();
  await app.ready();

  // health
  const health = await app.inject({ method: "GET", url: "/health" });
  await expectOk(health, "/health");

  // game start -> lifecycle (anti-cheat)
  const start = await app.inject({
    method: "POST",
    url: "/api/game/start",
    payload: { aiLevel: 3 },
  });
  await expectOk(start, "/api/game/start");
  const startJson = start.json() as any;
  const sessionId = startJson?.session?.id as string | undefined;
  if (!sessionId) throw new Error("/api/game/start: missing session.id");

  const lifecycle = await app.inject({
    method: "POST",
    url: `/api/game/${sessionId}/lifecycle`,
    payload: { inactiveMs: 10_000 },
  });
  await expectOk(lifecycle, "lifecycle");
  const lifecycleJson = lifecycle.json() as any;
  if (lifecycleJson?.gameOver !== true) {
    throw new Error(`lifecycle: expected gameOver=true body=${lifecycle.body}`);
  }

  // DB-backed endpoints (if configured)
  if (isDatabaseConfigured()) {
    const prisma = getPrisma();
    const users = await prisma.user.findMany({
      take: 2,
      orderBy: { createdAt: "asc" },
      select: { id: true },
    });

    if (users.length >= 2) {
      const [u1, u2] = users;

      // Login to get token
      const login = await app.inject({
        method: "POST",
        url: "/api/auth/login",
        payload: { userId: u1!.id, password: "password123" },
      });
      await expectOk(login, "/api/auth/login");
      const token = (login.json() as any)?.token as string | undefined;
      if (!token) throw new Error("/api/auth/login: missing token");

      // /api/me and inventory
      const me = await app.inject({
        method: "GET",
        url: "/api/me",
        headers: { authorization: `Bearer ${token}` },
      });
      await expectOk(me, "/api/me");

      const inv = await app.inject({
        method: "GET",
        url: "/api/me/inventory",
        headers: { authorization: `Bearer ${token}` },
      });
      await expectOk(inv, "/api/me/inventory");

      // Terms agreement
      const termsStatus1 = await app.inject({
        method: "GET",
        url: "/api/terms/status",
        headers: { authorization: `Bearer ${token}` },
      });
      await expectOk(termsStatus1, "/api/terms/status");

      const agree = await app.inject({
        method: "POST",
        url: "/api/terms/agree",
        headers: { authorization: `Bearer ${token}` },
        payload: {},
      });
      await expectOk(agree, "/api/terms/agree");

      const termsStatus2 = await app.inject({
        method: "GET",
        url: "/api/terms/status",
        headers: { authorization: `Bearer ${token}` },
      });
      await expectOk(termsStatus2, "/api/terms/status (after agree)");
      const termsJson2 = termsStatus2.json() as any;
      if (termsJson2?.agreed !== true || !termsJson2?.agreedAt) {
        throw new Error(
          `/api/terms/status: expected agreed=true body=${termsStatus2.body}`
        );
      }

      // Account email link (optional feature)
      const emailStatus1 = await app.inject({
        method: "GET",
        url: "/api/account/email",
        headers: { authorization: `Bearer ${token}` },
      });
      await expectOk(emailStatus1, "/api/account/email (GET)");

      const newEmail = `linked+${u1!.id}@example.com`;
      const emailLink = await app.inject({
        method: "POST",
        url: "/api/account/email",
        headers: { authorization: `Bearer ${token}` },
        payload: { email: newEmail },
      });
      await expectOk(emailLink, "/api/account/email (POST)");
      const emailLinkJson = emailLink.json() as any;
      if (emailLinkJson?.email !== newEmail || !emailLinkJson?.linkedAt) {
        throw new Error(
          `/api/account/email: unexpected body=${emailLink.body}`
        );
      }

      const emailUnlink = await app.inject({
        method: "DELETE",
        url: "/api/account/email",
        headers: { authorization: `Bearer ${token}` },
      });
      await expectOk(emailUnlink, "/api/account/email (DELETE)");
      const emailUnlinkJson = emailUnlink.json() as any;
      if (emailUnlinkJson?.email !== null) {
        throw new Error(
          `/api/account/email (DELETE): expected email=null body=${emailUnlink.body}`
        );
      }
      if (!emailUnlinkJson?.linkedAt || emailUnlinkJson?.rewarded !== true) {
        throw new Error(
          `/api/account/email (DELETE): expected linkedAt + rewarded=true body=${emailUnlink.body}`
        );
      }

      // Ensure enough coins then draw gacha once
      await prisma.user.update({ where: { id: u1!.id }, data: { coins: 10 } });

      // Ensure minimal masters exist so gacha always has candidates
      await prisma.iconMaster.upsert({
        where: { id: "default_demon" },
        update: {},
        create: {
          id: "default_demon",
          imageUrl: "https://example.com/default_demon.png",
          rarity: 1,
        },
      });
      await prisma.messageMaster.upsert({
        where: { id: "msg_default_01" },
        update: {},
        create: {
          id: "msg_default_01",
          content: "契約は既に結ばれた。さあ、言葉を捧げよ。",
          rarity: 1,
        },
      });
      await prisma.title.upsert({
        where: { id: "title_smoke_01" },
        update: {},
        create: {
          id: "title_smoke_01",
          name: "煙の称号",
          description: "スモークテスト用の称号",
          condition: "smoke",
        },
      });
      await prisma.itemMaster.upsert({
        where: { id: "item_smoke_01" },
        update: {},
        create: {
          id: "item_smoke_01",
          name: "煙の欠片",
          description: "スモークテスト用のアイテム",
          rarity: 1,
        },
      });

      const gachaStatus = await app.inject({
        method: "GET",
        url: "/api/gacha",
        headers: { authorization: `Bearer ${token}` },
      });
      await expectOk(gachaStatus, "/api/gacha");

      const gachaDraw = await app.inject({
        method: "POST",
        url: "/api/gacha/draw",
        headers: { authorization: `Bearer ${token}` },
      });
      await expectOk(gachaDraw, "/api/gacha/draw");

      const ranking = await app.inject({
        method: "GET",
        url: "/api/ranking?limit=10",
      });
      await expectOk(ranking, "/api/ranking");

      const matchmake = await app.inject({
        method: "POST",
        url: "/api/matchmake",
        payload: { userId: u1!.id },
      });
      // 404 is allowed if no candidate, but seed should make it 200.
      if (matchmake.statusCode !== 200 && matchmake.statusCode !== 404) {
        throw new Error(
          `/api/matchmake: status=${matchmake.statusCode} body=${matchmake.body}`
        );
      }

      const match = await app.inject({
        method: "POST",
        url: "/api/matches",
        payload: { userId: u1!.id, opponentId: u2!.id, result: "win" },
      });
      await expectOk(match, "/api/matches");
      const matchJson = match.json() as any;
      if (matchJson?.ratingDelta !== 4) {
        throw new Error(
          `/api/matches: expected ratingDelta=4 body=${match.body}`
        );
      }
    }
  }

  await app.close();
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
