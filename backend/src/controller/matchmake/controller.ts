import { getPrisma, isDatabaseConfigured } from "../../database";
import { type ServerInstance } from "../../lib/fastify";
import {
  errorResponseSchema,
  matchmakeRequestSchema,
  matchmakeResponseSchema,
} from "./schema";

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
          "レート±100の範囲で対戦相手を1人探し、公開設定を反映した相手情報を返します。",
        body: matchmakeRequestSchema,
        response: {
          200: matchmakeResponseSchema,
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

      const prisma = getPrisma();
      const { userId } = request.body;

      const me = await prisma.user.findUnique({
        where: { id: userId },
        select: { id: true, rating: true },
      });

      if (!me) {
        return reply.status(404).send({ message: "ユーザーが見つかりません" });
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

      const opponent = best[Math.floor(Math.random() * best.length)]!;

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
        opponent: {
          userId: opponent.id,
          name: opponent.name,
          icon: {
            id: opponent.equippedIcon.id,
            imageUrl: opponent.equippedIcon.imageUrl,
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
  );
}
