import bcrypt from "bcryptjs";
import { getPrisma, isDatabaseConfigured } from "../../database";
import { signAuthToken } from "../../lib/auth";
import { type ServerInstance } from "../../lib/fastify";
import {
  errorResponseSchema,
  loginRequestSchema,
  loginResponseSchema,
  signupRequestSchema,
  signupResponseSchema,
} from "./schema";

async function ensureDefaultMasters(prisma: ReturnType<typeof getPrisma>) {
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
}

function formatAuthUser(user: {
  id: string;
  name: string;
  email: string | null;
  iconId: string;
  messageId: string;
  title1Id: string | null;
  title2Id: string | null;
  title3Id: string | null;
  level: number;
  exp: number;
  rating: number;
  coins: number;
  soulCount: number;
  isSubscriber: boolean;
  isRatingPublic: boolean;
  isWinCountPublic: boolean;
  isWinRatePublic: boolean;
  isStreakPublic: boolean;
  createdAt: Date;
  updatedAt: Date;
}) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    iconId: user.iconId,
    messageId: user.messageId,
    title1Id: user.title1Id,
    title2Id: user.title2Id,
    title3Id: user.title3Id,
    level: user.level,
    exp: user.exp,
    rating: user.rating,
    coins: user.coins,
    soulCount: user.soulCount,
    isSubscriber: user.isSubscriber,
    isRatingPublic: user.isRatingPublic,
    isWinCountPublic: user.isWinCountPublic,
    isWinRatePublic: user.isWinRatePublic,
    isStreakPublic: user.isStreakPublic,
    createdAt: user.createdAt.toISOString(),
    updatedAt: user.updatedAt.toISOString(),
  };
}

export default async function (fastify: ServerInstance) {
  fastify.post(
    "/signup",
    {
      schema: {
        tags: ["Auth"],
        summary: "アカウント作成（名前+合言葉）",
        body: signupRequestSchema,
        response: {
          201: signupResponseSchema,
          400: errorResponseSchema,
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
      await ensureDefaultMasters(prisma);

      const { name, password } = request.body;
      const passwordHash = await bcrypt.hash(password, 10);

      const user = await prisma.user.create({
        data: {
          name,
          passwordHash,
          stats: { create: {} },
          ownedIcons: { create: { iconId: "default_demon" } },
          ownedMessages: { create: { messageId: "msg_default_01" } },
        },
      });

      return reply.status(201).send({
        message: "アカウントを作成しました",
        token: signAuthToken({ userId: user.id }),
        user: formatAuthUser(user),
      });
    }
  );

  fastify.post(
    "/login",
    {
      schema: {
        tags: ["Auth"],
        summary: "ログイン（ID+合言葉）",
        body: loginRequestSchema,
        response: {
          200: loginResponseSchema,
          400: errorResponseSchema,
          401: errorResponseSchema,
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
      const { userId, password } = request.body;

      const user = await prisma.user.findUnique({ where: { id: userId } });
      if (!user) {
        return reply.status(404).send({ message: "ユーザーが見つかりません" });
      }

      const ok = await bcrypt.compare(password, user.passwordHash);
      if (!ok) {
        return reply.status(401).send({ message: "合言葉が違います" });
      }

      const updated = await prisma.user.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
      });

      return reply.send({
        message: "ログインしました",
        token: signAuthToken({ userId: updated.id }),
        user: formatAuthUser(updated),
      });
    }
  );
}
