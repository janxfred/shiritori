import { getPrisma, isDatabaseConfigured } from "../../database";
import { type ServerInstance } from "../../lib/fastify";
import {
  createMatchRequestSchema,
  createMatchResponseSchema,
  errorResponseSchema,
} from "./schema";

function ratingDeltaFromResult(result: "win" | "loss" | "draw"): number {
  if (result === "win") return 4;
  if (result === "loss") return -2;
  return 0;
}

export default async function (fastify: ServerInstance) {
  fastify.post(
    "/",
    {
      schema: {
        tags: ["Match"],
        summary: "対戦結果反映（レート/戦績/履歴）",
        description:
          "ランクマッチの結果を反映します（勝利+4 / 敗北-2 / 引分0）。UserStats と MatchHistory を更新します。",
        body: createMatchRequestSchema,
        response: {
          200: createMatchResponseSchema,
          400: errorResponseSchema,
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
      const { userId, opponentId, result } = request.body;

      if (userId === opponentId) {
        return reply
          .status(400)
          .send({ message: "userId と opponentId が同一です" });
      }

      const [user, opponent] = await Promise.all([
        prisma.user.findUnique({
          where: { id: userId },
          include: { stats: true },
        }),
        prisma.user.findUnique({ where: { id: opponentId } }),
      ]);

      if (!user)
        return reply.status(404).send({ message: "ユーザーが見つかりません" });
      if (!opponent)
        return reply.status(404).send({ message: "対戦相手が見つかりません" });

      const delta = ratingDeltaFromResult(result);

      const nextStats = {
        totalWins: (user.stats?.totalWins ?? 0) + (result === "win" ? 1 : 0),
        totalLosses:
          (user.stats?.totalLosses ?? 0) + (result === "loss" ? 1 : 0),
        totalDraws: (user.stats?.totalDraws ?? 0) + (result === "draw" ? 1 : 0),
        currentStreak:
          result === "win" ? (user.stats?.currentStreak ?? 0) + 1 : 0,
        maxStreak: 0,
      };

      nextStats.maxStreak = Math.max(
        user.stats?.maxStreak ?? 0,
        nextStats.currentStreak
      );

      const updated = await prisma.$transaction(async (tx) => {
        const updatedUser = await tx.user.update({
          where: { id: userId },
          data: {
            rating: user.rating + delta,
            stats: {
              upsert: {
                create: {
                  totalWins: nextStats.totalWins,
                  totalLosses: nextStats.totalLosses,
                  totalDraws: nextStats.totalDraws,
                  currentStreak: nextStats.currentStreak,
                  maxStreak: nextStats.maxStreak,
                },
                update: {
                  totalWins: nextStats.totalWins,
                  totalLosses: nextStats.totalLosses,
                  totalDraws: nextStats.totalDraws,
                  currentStreak: nextStats.currentStreak,
                  maxStreak: nextStats.maxStreak,
                },
              },
            },
          },
          include: { stats: true },
        });

        await tx.matchHistory.create({
          data: {
            userId,
            opponentId,
            result,
          },
        });

        return updatedUser;
      });

      return reply.send({
        message: "対戦結果を反映しました",
        ratingDelta: delta,
        user: {
          id: updated.id,
          rating: updated.rating,
          stats: {
            totalWins: updated.stats?.totalWins ?? 0,
            totalLosses: updated.stats?.totalLosses ?? 0,
            totalDraws: updated.stats?.totalDraws ?? 0,
            currentStreak: updated.stats?.currentStreak ?? 0,
            maxStreak: updated.stats?.maxStreak ?? 0,
          },
        },
      });
    }
  );
}
