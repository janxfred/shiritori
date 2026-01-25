import { getPrisma, isDatabaseConfigured } from "../../database";
import { verifyAuthToken } from "../../lib/auth";
import type { ServerInstance } from "../../lib/fastify";
import {
  errorResponseSchema,
  syncSubscriptionRequestSchema,
  syncSubscriptionResponseSchema,
} from "./schema";

function getBearerToken(request: {
  headers: Record<string, unknown>;
}): string | null {
  const auth = request.headers.authorization;
  if (typeof auth !== "string") return null;
  const [type, token] = auth.split(" ");
  if (type?.toLowerCase() !== "bearer" || !token) return null;
  return token;
}

export default async function (fastify: ServerInstance) {
  fastify.post(
    "/sync",
    {
      schema: {
        tags: ["Subscription"],
        summary: "サブスクリプション状態を同期",
        body: syncSubscriptionRequestSchema,
        response: {
          200: syncSubscriptionResponseSchema,
          401: errorResponseSchema,
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

      const token = getBearerToken(request);
      if (!token) return reply.status(401).send({ message: "認証が必要です" });

      const payload = verifyAuthToken({ token });
      if (!payload)
        return reply.status(401).send({ message: "認証が必要です" });

      const prisma = getPrisma();
      const { isActive } = request.body;

      const user = await prisma.user.update({
        where: { id: payload.userId },
        data: { isSubscriber: isActive },
      });

      return reply.send({
        message: isActive
          ? "プレミアムプランが有効になりました"
          : "プレミアムプランが解除されました",
        isSubscriber: user.isSubscriber,
      });
    },
  );
}
