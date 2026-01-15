import bcrypt from "bcryptjs";
import { getPrisma, isDatabaseConfigured } from "../../database";
import { verifyAuthToken } from "../../lib/auth";
import { type ServerInstance } from "../../lib/fastify";
import {
  errorResponseSchema,
  getEmailStatusResponseSchema,
  linkEmailRequestSchema,
  linkEmailResponseSchema,
  setEmailRequestSchema,
  setEmailResponseSchema,
  unlinkEmailResponseSchema,
} from "./schema";

const EMAIL_LINK_REWARD_COINS = 5;

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
  fastify.get(
    "/email",
    {
      schema: {
        tags: ["Account"],
        summary: "メールアドレス連携状況の取得（ログイン中）",
        response: {
          200: getEmailStatusResponseSchema,
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
      const user = await prisma.user.findUnique({
        where: { id: payload.userId },
        select: { email: true, emailLinkedAt: true },
      });
      if (!user) return reply.status(401).send({ message: "認証が必要です" });

      return reply.send({
        email: user.email,
        linkedAt: user.emailLinkedAt ? user.emailLinkedAt.toISOString() : null,
        rewardCoins: EMAIL_LINK_REWARD_COINS,
        rewarded: Boolean(user.emailLinkedAt),
      });
    }
  );

  fastify.post(
    "/email",
    {
      schema: {
        tags: ["Account"],
        summary: "メールアドレス連携（ログイン中 / 初回のみ報酬）",
        body: setEmailRequestSchema,
        response: {
          200: setEmailResponseSchema,
          400: errorResponseSchema,
          401: errorResponseSchema,
          409: errorResponseSchema,
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
      const { email } = request.body;

      const duplicate = await prisma.user.findFirst({
        where: { email, NOT: { id: payload.userId } },
        select: { id: true },
      });
      if (duplicate) {
        return reply
          .status(409)
          .send({ message: "このメールアドレスは既に使用されています" });
      }

      const existing = await prisma.user.findUnique({
        where: { id: payload.userId },
        select: { email: true, emailLinkedAt: true },
      });
      if (!existing)
        return reply.status(401).send({ message: "認証が必要です" });

      const firstLinkAt = existing.emailLinkedAt ?? new Date();
      const rewardedNow =
        existing.email === null && existing.emailLinkedAt === null;

      const updated = await prisma.user.update({
        where: { id: payload.userId },
        data: {
          email,
          emailLinkedAt: firstLinkAt,
          ...(rewardedNow
            ? { coins: { increment: EMAIL_LINK_REWARD_COINS } }
            : {}),
        },
        select: { email: true, emailLinkedAt: true, coins: true },
      });

      return reply.send({
        message: "メールアドレスを連携しました",
        email: updated.email!,
        linkedAt: updated.emailLinkedAt!.toISOString(),
        coins: updated.coins,
        rewarded: rewardedNow,
      });
    }
  );

  fastify.delete(
    "/email",
    {
      schema: {
        tags: ["Account"],
        summary: "メールアドレス連携の解除（ログイン中）",
        response: {
          200: unlinkEmailResponseSchema,
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

      const existing = await prisma.user.findUnique({
        where: { id: payload.userId },
        select: { email: true, emailLinkedAt: true },
      });
      if (!existing)
        return reply.status(401).send({ message: "認証が必要です" });

      if (existing.email !== null) {
        await prisma.user.update({
          where: { id: payload.userId },
          data: { email: null },
          select: { id: true },
        });
      }

      return reply.send({
        message: "メールアドレス連携を解除しました",
        email: null,
        linkedAt: existing.emailLinkedAt
          ? existing.emailLinkedAt.toISOString()
          : null,
        rewardCoins: EMAIL_LINK_REWARD_COINS,
        rewarded: Boolean(existing.emailLinkedAt),
      });
    }
  );

  fastify.post(
    "/link-email",
    {
      schema: {
        tags: ["Account"],
        summary: "メールアドレス連携（任意）",
        body: linkEmailRequestSchema,
        response: {
          200: linkEmailResponseSchema,
          400: errorResponseSchema,
          401: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
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
      const { userId, password, email } = request.body;

      const user = await prisma.user.findUnique({ where: { id: userId } });
      if (!user) {
        return reply.status(404).send({ message: "ユーザーが見つかりません" });
      }

      const ok = await bcrypt.compare(password, user.passwordHash);
      if (!ok) {
        return reply.status(401).send({ message: "合言葉が違います" });
      }

      const duplicate = await prisma.user.findFirst({
        where: { email, NOT: { id: userId } },
      });
      if (duplicate) {
        return reply
          .status(409)
          .send({ message: "このメールアドレスは既に使用されています" });
      }

      const firstLinkAt = user.emailLinkedAt ?? new Date();
      const rewardedNow = user.email === null && user.emailLinkedAt === null;

      const updated = await prisma.user.update({
        where: { id: userId },
        data: {
          email,
          emailLinkedAt: firstLinkAt,
          ...(rewardedNow
            ? { coins: { increment: EMAIL_LINK_REWARD_COINS } }
            : {}),
        },
        select: { coins: true },
      });

      return reply.send({
        message: "メールアドレスを連携しました",
        coins: updated.coins,
        rewarded: rewardedNow,
      });
    }
  );
}
