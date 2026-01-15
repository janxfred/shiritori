import { getPrisma, isDatabaseConfigured } from "../../database";
import { verifyAuthToken } from "../../lib/auth";
import { type ServerInstance } from "../../lib/fastify";
import {
  errorResponseSchema,
  getInventoryResponseSchema,
  getMeResponseSchema,
  updateMeRequestSchema,
  updateMeResponseSchema,
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

function formatMe(user: {
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
  stats: {
    totalWins: number;
    totalLosses: number;
    totalDraws: number;
    currentStreak: number;
    maxStreak: number;
  } | null;
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
    stats: user.stats,
  };
}

export default async function (fastify: ServerInstance) {
  fastify.get(
    "/",
    {
      schema: {
        tags: ["Me"],
        summary: "自分のプロフィール取得",
        response: {
          200: getMeResponseSchema,
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
        include: { stats: true },
      });

      if (!user) return reply.status(401).send({ message: "認証が必要です" });

      return reply.send({ user: formatMe(user) });
    }
  );

  fastify.patch(
    "/",
    {
      schema: {
        tags: ["Me"],
        summary: "自分のプロフィール更新（装備・公開設定）",
        body: updateMeRequestSchema,
        response: {
          200: updateMeResponseSchema,
          400: errorResponseSchema,
          401: errorResponseSchema,
          403: errorResponseSchema,
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
      const body = request.body;

      // 所持チェック（装備変更のみ）
      if (body.iconId) {
        const owned = await prisma.userIcon.findUnique({
          where: {
            userId_iconId: { userId: payload.userId, iconId: body.iconId },
          },
        });
        if (!owned)
          return reply
            .status(403)
            .send({ message: "そのアイコンは所持していません" });
      }

      if (body.messageId) {
        const owned = await prisma.userMessage.findUnique({
          where: {
            userId_messageId: {
              userId: payload.userId,
              messageId: body.messageId,
            },
          },
        });
        if (!owned)
          return reply
            .status(403)
            .send({ message: "そのメッセージは所持していません" });
      }

      for (const [slotKey, titleId] of [
        ["title1Id", body.title1Id] as const,
        ["title2Id", body.title2Id] as const,
        ["title3Id", body.title3Id] as const,
      ]) {
        if (titleId === undefined) continue;
        if (titleId === null) continue; // 解除

        const owned = await prisma.userTitle.findUnique({
          where: { userId_titleId: { userId: payload.userId, titleId } },
        });
        if (!owned)
          return reply
            .status(403)
            .send({ message: `その称号は所持していません (${slotKey})` });
      }

      const user = await prisma.user.update({
        where: { id: payload.userId },
        data: {
          ...(body.iconId ? { iconId: body.iconId } : {}),
          ...(body.messageId ? { messageId: body.messageId } : {}),
          ...(body.title1Id !== undefined ? { title1Id: body.title1Id } : {}),
          ...(body.title2Id !== undefined ? { title2Id: body.title2Id } : {}),
          ...(body.title3Id !== undefined ? { title3Id: body.title3Id } : {}),
          ...(body.isRatingPublic !== undefined
            ? { isRatingPublic: body.isRatingPublic }
            : {}),
          ...(body.isWinCountPublic !== undefined
            ? { isWinCountPublic: body.isWinCountPublic }
            : {}),
          ...(body.isWinRatePublic !== undefined
            ? { isWinRatePublic: body.isWinRatePublic }
            : {}),
          ...(body.isStreakPublic !== undefined
            ? { isStreakPublic: body.isStreakPublic }
            : {}),
        },
        include: { stats: true },
      });

      return reply.send({
        message: "プロフィールを更新しました",
        user: formatMe(user),
      });
    }
  );

  fastify.get(
    "/inventory",
    {
      schema: {
        tags: ["Me"],
        summary: "所持品一覧取得",
        response: {
          200: getInventoryResponseSchema,
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
      });
      if (!user) return reply.status(401).send({ message: "認証が必要です" });

      const [icons, messages, titles, items] = await Promise.all([
        prisma.userIcon.findMany({
          where: { userId: payload.userId },
          include: { icon: true },
          orderBy: { obtainedAt: "asc" },
        }),
        prisma.userMessage.findMany({
          where: { userId: payload.userId },
          include: { message: true },
          orderBy: { obtainedAt: "asc" },
        }),
        prisma.userTitle.findMany({
          where: { userId: payload.userId },
          include: { title: true },
          orderBy: { obtainedAt: "asc" },
        }),
        prisma.userItem.findMany({
          where: { userId: payload.userId },
          include: { item: true },
          orderBy: { obtainedAt: "asc" },
        }),
      ]);

      return reply.send({
        equipped: {
          iconId: user.iconId,
          messageId: user.messageId,
          title1Id: user.title1Id,
          title2Id: user.title2Id,
          title3Id: user.title3Id,
        },
        icons: icons.map((x) => ({
          id: x.icon.id,
          imageUrl: x.icon.imageUrl,
          rarity: x.icon.rarity,
        })),
        messages: messages.map((x) => ({
          id: x.message.id,
          content: x.message.content,
          rarity: x.message.rarity,
        })),
        titles: titles.map((x) => ({
          id: x.title.id,
          name: x.title.name,
          description: x.title.description,
          condition: x.title.condition,
          rarity: 1,
        })),
        items: items.map((x) => ({
          id: x.item.id,
          name: x.item.name,
          description: x.item.description,
          rarity: x.item.rarity,
        })),
      });
    }
  );
}
