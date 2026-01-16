import { getPrisma, isDatabaseConfigured } from "../../database";
import { type ServerInstance } from "../../lib/fastify";
import { normalizeIconImageUrl } from "../../lib/asset_url";
import { verifyAuthToken } from "../../lib/auth";
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
        select: { id: true, rating: true, isCheater: true },
      });

      if (!me) {
        return reply.status(401).send({ message: "認証が必要です" });
      }

      if (me.isCheater) {
        return reply
          .status(403)
          .send({ message: "このアカウントは利用できません" });
      }

      // 先に相手から割り当てられているPvPセッションがあれば、それを返す
      const assigned = await consumeAssignedMatch({ userId: me.id });
      if (assigned) {
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

            return reply.send({
              session: sessionToJson(session),
              opponent: {
                userId: opponent.id,
                name: opponent.name,
                icon: {
                  id: opponent.equippedIcon.id,
                  imageUrl: normalizeIconImageUrl(
                    opponent.equippedIcon.imageUrl
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
      const minRating = me.rating - 100;
      const maxRating = me.rating + 100;

      const candidates = await prisma.user.findMany({
        where: {
          id: { not: me.id },
          isCheater: false,
          rating: { gte: minRating, lte: maxRating },
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
          break;
        }
      }

      if (!chosen || !session) {
        return reply
          .status(404)
          .send({ message: "条件に合う対戦相手が見つかりません" });
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
    }
  );
}
