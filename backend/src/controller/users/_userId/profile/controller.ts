import { getPrisma, isDatabaseConfigured } from "../../../../database";
import { type ServerInstance } from "../../../../lib/fastify";
import {
  commandResponseSchema,
  errorResponseSchema,
  profileParamsSchema,
  updateProfileRequestSchema,
} from "./schema";

export default async function (fastify: ServerInstance) {
  fastify.put(
    "/",
    {
      schema: {
        tags: ["Profile"],
        summary: "プロフィール更新（装備/公開設定）",
        params: profileParamsSchema,
        body: updateProfileRequestSchema,
        response: {
          200: commandResponseSchema,
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
      const { userId } = request.params;

      const existingUser = await prisma.user.findUnique({
        where: { id: userId },
      });
      if (!existingUser) {
        return reply.status(404).send({ message: "ユーザーが見つかりません" });
      }

      const {
        iconId,
        messageId,
        title1Id,
        title2Id,
        title3Id,
        isRatingPublic,
        isWinCountPublic,
        isWinRatePublic,
        isStreakPublic,
      } = request.body;

      if (iconId) {
        const icon = await prisma.iconMaster.findUnique({
          where: { id: iconId },
        });
        if (!icon) {
          return reply.status(400).send({ message: "存在しない iconId です" });
        }
      }

      if (messageId) {
        const message = await prisma.messageMaster.findUnique({
          where: { id: messageId },
        });
        if (!message) {
          return reply
            .status(400)
            .send({ message: "存在しない messageId です" });
        }
      }

      for (const [slot, titleId] of [
        ["title1Id", title1Id],
        ["title2Id", title2Id],
        ["title3Id", title3Id],
      ] as const) {
        if (titleId === undefined || titleId === null) continue;
        const title = await prisma.title.findUnique({ where: { id: titleId } });
        if (!title) {
          return reply.status(400).send({ message: `存在しない ${slot} です` });
        }
      }

      await prisma.user.update({
        where: { id: userId },
        data: {
          ...(iconId !== undefined && { iconId }),
          ...(messageId !== undefined && { messageId }),
          ...(title1Id !== undefined && { title1Id }),
          ...(title2Id !== undefined && { title2Id }),
          ...(title3Id !== undefined && { title3Id }),
          ...(isRatingPublic !== undefined && { isRatingPublic }),
          ...(isWinCountPublic !== undefined && { isWinCountPublic }),
          ...(isWinRatePublic !== undefined && { isWinRatePublic }),
          ...(isStreakPublic !== undefined && { isStreakPublic }),
        },
      });

      return reply.send({ message: "プロフィールを更新しました" });
    }
  );
}
