import { getPrisma, isDatabaseConfigured } from "../../database";
import { type ServerInstance } from "../../lib/fastify";
import { normalizeIconImageUrl } from "../../lib/asset_url";
import { verifyAuthToken } from "../../lib/auth";
import { consumeSoul } from "../../domain/services/SoulRecoveryService";
import {
  errorResponseSchema,
  matchmakeRequestSchema,
  matchmakeResponseSchema,
} from "./schema";

import {
  createPvpSession,
  getPvpSession,
  sessionToJson,
} from "../../infrastructure/PvpSessionStore";

import {
  assignMatchToUser,
  consumeAssignedMatch,
  isMatchmakeRedisReady,
} from "../../infrastructure/MatchmakeAssignmentStore";

import {
  joinMatchmakeQueue,
  findMatchCandidatesInQueue,
  removeFromQueue,
} from "../../infrastructure/MatchmakeQueueStore";

import { ICON_CATALOG } from "../../lib/icon_catalog";
import { scheduleAiTurnIfNeeded } from "../pvp/controller";

/** AI偽装対戦用の定数 */
export const AI_USER_ID_PREFIX = "ai_pvp_";

/** AI偽装用の称号リスト */
const FAKE_TITLES = [
  "新米の契約者",
  "言霊の欠片",
  "沈黙の観測者",
  "深淵の語り部",
  "黄昏の賢者",
  "紅蓮の魔導師",
  "蒼穹の旅人",
  null, // 称号なし
];

/** AI偽装用のフォールバックメッセージリスト（DBにメッセージがない場合用） */
const FALLBACK_MESSAGES = [
  { id: "msg_default_01", content: "契約は既に結ばれた。さあ、言葉を捧げよ。" },
];

/** メッセージマスタのキャッシュ（起動時に1回取得） */
let cachedMessages: Array<{ id: string; content: string }> | null = null;

/** DBからメッセージマスタを取得（キャッシュ付き） */
async function getMessagesFromDb(): Promise<
  Array<{ id: string; content: string }>
> {
  if (cachedMessages !== null) {
    return cachedMessages;
  }

  try {
    const prisma = getPrisma();
    const messages = await prisma.messageMaster.findMany({
      select: { id: true, content: true },
    });

    if (messages.length === 0) {
      cachedMessages = FALLBACK_MESSAGES;
    } else {
      cachedMessages = messages;
    }
    return cachedMessages;
  } catch {
    // DB接続エラーの場合はフォールバック
    return FALLBACK_MESSAGES;
  }
}

/** AI偽装用の対戦相手情報を生成 */
async function generateFakeOpponent(userId: string): Promise<{
  icon: { id: string; imageUrl: string };
  title: { id: string; name: string } | null;
  message: { id: string; content: string };
  rating: number | null;
  totalWins: number | null;
  winRate: number | null;
  maxStreak: number | null;
}> {
  // ランダムにアイコンを選択
  const iconIndex = Math.floor(Math.random() * ICON_CATALOG.length);
  const icon = ICON_CATALOG[iconIndex];

  // ランダムに称号を選択
  const titleIndex = Math.floor(Math.random() * FAKE_TITLES.length);
  const titleName = FAKE_TITLES[titleIndex];
  const title = titleName
    ? { id: `fake_title_${titleIndex}`, name: titleName }
    : null;

  // DBからメッセージを取得してランダムに選択
  const messages = await getMessagesFromDb();
  const messageIndex = Math.floor(Math.random() * messages.length);
  const selectedMessage = messages[messageIndex];
  const message = {
    id: selectedMessage.id,
    content: selectedMessage.content,
  };

  // ランダムに統計を生成（非公開の場合もある）
  const showStats = Math.random() > 0.3; // 70%の確率で公開
  const rating = showStats ? 1400 + Math.floor(Math.random() * 200) : null;
  const totalWins = showStats ? 10 + Math.floor(Math.random() * 50) : null;
  const winRate = showStats ? 45 + Math.random() * 25 : null;
  const maxStreak = showStats ? 2 + Math.floor(Math.random() * 8) : null;

  return {
    icon: {
      id: icon.id,
      imageUrl: normalizeIconImageUrl(icon.imageUrl),
    },
    title,
    message,
    rating,
    totalWins,
    winRate,
    maxStreak,
  };
}

function getBearerToken(request: {
  headers: Record<string, unknown>;
}): string | null {
  const auth = request.headers.authorization;
  if (typeof auth !== "string") return null;
  const [type, token] = auth.split(" ");
  if (type?.toLowerCase() !== "bearer" || !token) return null;
  return token;
}

function calcWinRate(params: {
  totalWins: number;
  totalLosses: number;
  totalDraws: number;
}): number {
  const { totalWins, totalLosses, totalDraws } = params;
  const total = totalWins + totalLosses + totalDraws;
  if (total <= 0) return 0;
  return (totalWins / total) * 100;
}

export default async function (fastify: ServerInstance) {
  fastify.post(
    "/",
    {
      schema: {
        tags: ["Matchmake"],
        summary: "マッチング",
        description:
          "レート±100の範囲で対戦相手を1人探し、PvPセッションを作成して返します（相手側が後からmatchmakeしても同じsessionを受け取れます）。",
        body: matchmakeRequestSchema,
        response: {
          200: matchmakeResponseSchema,
          401: errorResponseSchema,
          403: errorResponseSchema,
          404: errorResponseSchema,
          503: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      if (!isDatabaseConfigured()) {
        return reply.status(503).send({
          message: "DATABASE_URL が未設定のため、このAPIは利用できません",
        });
      }

      if (!isMatchmakeRedisReady()) {
        return reply.status(503).send({
          message: "REDIS_URL が未設定のため、このAPIは利用できません",
        });
      }

      const token = getBearerToken(request);
      if (!token) return reply.status(401).send({ message: "認証が必要です" });

      const payload = verifyAuthToken({ token });
      if (!payload)
        return reply.status(401).send({ message: "認証が必要です" });

      const prisma = getPrisma();
      const me = await prisma.user.findUnique({
        where: { id: payload.userId },
        select: { id: true, rating: true, isCheater: true, soulCount: true },
      });

      if (!me) {
        return reply.status(401).send({ message: "認証が必要です" });
      }

      if (me.isCheater) {
        return reply
          .status(403)
          .send({ message: "このアカウントは利用できません" });
      }

      if (me.soulCount < 1) {
        return reply.status(403).send({ message: "魂が足りません" });
      }

      // 先に相手から割り当てられているPvPセッションがあれば、それを返す
      const assigned = await consumeAssignedMatch({ userId: me.id });
      if (assigned) {
        // 割り当て済みマッチを消費: 両者をキューから削除
        await removeFromQueue([me.id, assigned.opponentId]);

        const session = await getPvpSession(assigned.sessionId);
        if (session) {
          const opponent = await prisma.user.findUnique({
            where: { id: assigned.opponentId },
            include: {
              stats: true,
              equippedIcon: true,
              equippedMessage: true,
              equippedTitle1: true,
            },
          });

          if (opponent) {
            const stats =
              opponent.stats ??
              ({
                totalWins: 0,
                totalLosses: 0,
                totalDraws: 0,
                maxStreak: 0,
              } as const);

            const winRate = calcWinRate({
              totalWins: stats.totalWins,
              totalLosses: stats.totalLosses,
              totalDraws: stats.totalDraws,
            });

            const consumed = await prisma.user.updateMany({
              where: { id: me.id, soulCount: { gte: 1 } },
              data: {
                soulCount: { decrement: 1 },
                lastSoulUsedAt: new Date(),
              },
            });
            if (consumed.count !== 1) {
              return reply.status(403).send({ message: "魂が足りません" });
            }

            return reply.send({
              session: sessionToJson(session),
              opponent: {
                userId: opponent.id,
                name: opponent.name,
                icon: {
                  id: opponent.equippedIcon.id,
                  imageUrl: normalizeIconImageUrl(
                    opponent.equippedIcon.imageUrl,
                  ),
                },
                title: opponent.equippedTitle1
                  ? {
                      id: opponent.equippedTitle1.id,
                      name: opponent.equippedTitle1.name,
                    }
                  : null,
                message: {
                  id: opponent.equippedMessage.id,
                  content: opponent.equippedMessage.content,
                },
                rating: opponent.isRatingPublic ? opponent.rating : null,
                totalWins: opponent.isWinCountPublic ? stats.totalWins : null,
                winRate: opponent.isWinRatePublic ? winRate : null,
                maxStreak: opponent.isStreakPublic ? stats.maxStreak : null,
              },
            });
          }
        }
        // セッションが見つからない等の場合は、通常マッチングにフォールバック
      }

      // マッチング待機キューに参加（TTL: 10秒）
      // これにより「現在マッチング中のユーザー」のみが候補になる
      const queueTtlMs = 10 * 1000;
      await joinMatchmakeQueue({
        userId: me.id,
        rating: me.rating,
        ttlMs: queueTtlMs,
      });

      const minRating = me.rating - 100;
      const maxRating = me.rating + 100;

      // キューに登録されている「マッチング待機中」のユーザーのみを候補にする
      const candidateIds = await findMatchCandidatesInQueue({
        userId: me.id,
        rating: me.rating,
        ratingRange: 100,
      });

      if (candidateIds.length === 0) {
        return reply
          .status(404)
          .send({ message: "条件に合う対戦相手が見つかりません" });
      }

      // キュー内の候補ユーザーの詳細情報を取得
      const candidates = await prisma.user.findMany({
        where: {
          id: { in: candidateIds },
          isCheater: false,
          soulCount: { gte: 1 },
        },
        take: 50,
        include: {
          stats: true,
          equippedIcon: true,
          equippedMessage: true,
          equippedTitle1: true,
        },
      });

      if (candidates.length === 0) {
        return reply
          .status(404)
          .send({ message: "条件に合う対戦相手が見つかりません" });
      }

      let bestDistance = Number.POSITIVE_INFINITY;
      let best: (typeof candidates)[number][] = [];

      for (const c of candidates) {
        const d = Math.abs(c.rating - me.rating);
        if (d < bestDistance) {
          bestDistance = d;
          best = [c];
        } else if (d === bestDistance) {
          best.push(c);
        }
      }

      // 相手側が後からmatchmakeしたときに同じsessionを返す（Redis TTL 2分）
      const assignmentTtlMs = 2 * 60 * 1000;

      // すでに割当済みの相手を避けるため、候補を軽くリトライする
      const shuffled = [...best].sort(() => Math.random() - 0.5);
      let chosen: (typeof candidates)[number] | null = null;
      let session = null as Awaited<ReturnType<typeof createPvpSession>> | null;

      for (const candidate of shuffled) {
        const s = await createPvpSession({
          player1Id: me.id,
          player2Id: candidate.id,
        });

        const ok = await assignMatchToUser({
          userId: candidate.id,
          sessionId: s.id,
          opponentId: me.id,
          ttlMs: assignmentTtlMs,
        });

        if (ok) {
          chosen = candidate;
          session = s;
          // マッチング成立: 両者をキューから削除
          await removeFromQueue([me.id, candidate.id]);
          break;
        }
      }

      if (!chosen || !session) {
        return reply
          .status(404)
          .send({ message: "条件に合う対戦相手が見つかりません" });
      }

      const consumed = await prisma.user.updateMany({
        where: { id: me.id, soulCount: { gte: 1 } },
        data: {
          soulCount: { decrement: 1 },
          lastSoulUsedAt: new Date(),
        },
      });
      if (consumed.count !== 1) {
        return reply.status(403).send({ message: "魂が足りません" });
      }

      const stats =
        chosen.stats ??
        ({
          totalWins: 0,
          totalLosses: 0,
          totalDraws: 0,
          maxStreak: 0,
        } as const);

      const winRate = calcWinRate({
        totalWins: stats.totalWins,
        totalLosses: stats.totalLosses,
        totalDraws: stats.totalDraws,
      });

      return reply.send({
        session: sessionToJson(session),
        opponent: {
          userId: chosen.id,
          name: chosen.name,
          icon: {
            id: chosen.equippedIcon.id,
            imageUrl: normalizeIconImageUrl(chosen.equippedIcon.imageUrl),
          },
          title: chosen.equippedTitle1
            ? {
                id: chosen.equippedTitle1.id,
                name: chosen.equippedTitle1.name,
              }
            : null,
          message: {
            id: chosen.equippedMessage.id,
            content: chosen.equippedMessage.content,
          },
          rating: chosen.isRatingPublic ? chosen.rating : null,
          totalWins: chosen.isWinCountPublic ? stats.totalWins : null,
          winRate: chosen.isWinRatePublic ? winRate : null,
          maxStreak: chosen.isStreakPublic ? stats.maxStreak : null,
        },
      });
    },
  );

  // AI偽装対戦エンドポイント
  // 対人マッチングに失敗した場合にフロントエンドから呼ばれる
  // AIレベル3の思考ロジックで対戦するが、UIは人間と対戦しているように見せる
  fastify.post(
    "/ai",
    {
      schema: {
        response: {
          200: matchmakeResponseSchema,
          401: errorResponseSchema,
          403: errorResponseSchema,
          500: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      if (!isDatabaseConfigured()) {
        return reply.status(500).send({ message: "DB未設定" });
      }
      if (!isMatchmakeRedisReady()) {
        return reply
          .status(500)
          .send({ message: "マッチメイクサービス準備中" });
      }

      const prisma = getPrisma();
      const token = getBearerToken(request);
      if (!token) {
        return reply.status(401).send({ message: "認証が必要です" });
      }

      const payload = verifyAuthToken({ token });
      if (!payload) {
        return reply.status(401).send({ message: "無効なトークンです" });
      }

      const me = await prisma.user.findUnique({
        where: { id: payload.userId },
      });

      if (!me) {
        return reply.status(401).send({ message: "認証が必要です" });
      }

      if (me.isCheater) {
        return reply
          .status(403)
          .send({ message: "このアカウントは利用できません" });
      }

      if (me.soulCount < 1) {
        return reply.status(403).send({ message: "魂が足りません" });
      }

      // 魂を消費
      const consumed = await prisma.user.updateMany({
        where: { id: me.id, soulCount: { gte: 1 } },
        data: {
          soulCount: { decrement: 1 },
          lastSoulUsedAt: new Date(),
        },
      });
      if (consumed.count !== 1) {
        return reply.status(403).send({ message: "魂が足りません" });
      }

      // AI用のユーザーIDを生成（セッションごとにユニーク）
      const aiUserId = `${AI_USER_ID_PREFIX}${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

      // PvPセッションを作成（AIが player2）
      const session = await createPvpSession({
        player1Id: me.id,
        player2Id: aiUserId,
      });

      // AIが先攻の場合、AIのターンをスケジュール
      scheduleAiTurnIfNeeded(session);

      // 偽の対戦相手情報を生成
      const fakeOpponent = await generateFakeOpponent(aiUserId);

      return reply.send({
        session: sessionToJson(session),
        opponent: {
          userId: aiUserId,
          name: "対戦相手", // 名前は表示されないので固定値
          ...fakeOpponent,
        },
      });
    },
  );
}
