import { getPrisma, isDatabaseConfigured } from "../../database";
import { type ServerInstance } from "../../lib/fastify";
import {
  errorResponseSchema,
  getRankingResponseSchema,
  rankingQuerySchema,
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
  fastify.get(
    "/",
    {
      schema: {
        tags: ["Ranking"],
        summary: "ランキング取得",
        description:
          "レーティング順のランキングを取得します（公開設定はサーバー側で反映）。",
        querystring: rankingQuerySchema,
        response: {
          200: getRankingResponseSchema,
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

      const { limit } = request.query;
      const prisma = getPrisma();

      const [users, total] = await Promise.all([
        prisma.user.findMany({
          take: limit,
          orderBy: [{ rating: "desc" }, { createdAt: "asc" }],
          include: {
            stats: true,
            equippedIcon: true,
            equippedMessage: true,
            equippedTitle1: true,
          },
        }),
        prisma.user.count(),
      ]);

      const items = users.map((user, idx) => {
        const stats =
          user.stats ??
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

        return {
          rank: idx + 1,
          userId: user.id,
          name: user.name,
          icon: {
            id: user.equippedIcon.id,
            imageUrl: user.equippedIcon.imageUrl,
          },
          title: user.equippedTitle1
            ? { id: user.equippedTitle1.id, name: user.equippedTitle1.name }
            : null,
          message: {
            id: user.equippedMessage.id,
            content: user.equippedMessage.content,
          },
          rating: user.isRatingPublic ? user.rating : null,
          totalWins: user.isWinCountPublic ? stats.totalWins : null,
          winRate: user.isWinRatePublic ? winRate : null,
          maxStreak: user.isStreakPublic ? stats.maxStreak : null,
        };
      });

      return reply.send({ total, items });
    }
  );
}
