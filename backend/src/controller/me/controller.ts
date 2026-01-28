import { getPrisma, isDatabaseConfigured } from "../../database";
import { normalizeIconImageUrl } from "../../lib/asset_url";
import { verifyAuthToken } from "../../lib/auth";
import type { ServerInstance } from "../../lib/fastify";
import { ICON_CATALOG } from "../../lib/icon_catalog";
import { checkAndRecoverSoul } from "../../domain/services/SoulRecoveryService";
import {
  errorResponseSchema,
  getIconCatalogResponseSchema,
  getInventoryResponseSchema,
  getMeResponseSchema,
  getMessageCatalogResponseSchema,
  getTitleCatalogResponseSchema,
  rewardedAdResponseSchema,
  updateMeRequestSchema,
  updateMeResponseSchema,
} from "./schema";

function ratingDeltaFromResult(result: "win" | "loss" | "draw"): number {
  if (result === "win") return 4;
  if (result === "loss") return -2;
  return 0;
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
    past30WinRate: number | null;
  } | null;
  lastRatingDelta: number | null;
  lastMatchAt: string | null;
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
    lastRatingDelta: user.lastRatingDelta,
    lastMatchAt: user.lastMatchAt,
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

      // 魂の自動回復をチェック
      const userBeforeRecovery = await prisma.user.findUnique({
        where: { id: payload.userId },
        select: { soulCount: true, lastSoulUsedAt: true, isSubscriber: true },
      });

      if (!userBeforeRecovery)
        return reply.status(401).send({ message: "認証が必要です" });

      const recoveredSoulCount = await checkAndRecoverSoul(
        payload.userId,
        userBeforeRecovery.soulCount,
        userBeforeRecovery.lastSoulUsedAt,
        userBeforeRecovery.isSubscriber,
        prisma,
      );

      const user = await prisma.user.findUnique({
        where: { id: payload.userId },
        include: { stats: true },
      });

      if (!user) return reply.status(401).send({ message: "認証が必要です" });

      const lastMatch = await prisma.matchHistory.findFirst({
        where: { userId: user.id },
        orderBy: { createdAt: "desc" },
        select: { result: true, createdAt: true },
      });

      // 過去30試合の勝率を計算
      const past30Matches = await prisma.matchHistory.findMany({
        where: { userId: user.id },
        orderBy: { createdAt: "desc" },
        take: 30,
        select: { result: true },
      });

      let past30WinRate: number | null = null;
      if (past30Matches.length > 0) {
        const wins = past30Matches.filter((m) => m.result === "win").length;
        past30WinRate = (wins / past30Matches.length) * 100;
      }

      return reply.send({
        user: formatMe({
          ...user,
          stats: user.stats
            ? {
                ...user.stats,
                past30WinRate,
              }
            : null,
          lastRatingDelta: lastMatch
            ? ratingDeltaFromResult(lastMatch.result as "win" | "loss" | "draw")
            : null,
          lastMatchAt: lastMatch ? lastMatch.createdAt.toISOString() : null,
        }),
      });
    },
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

      const lastMatch = await prisma.matchHistory.findFirst({
        where: { userId: user.id },
        orderBy: { createdAt: "desc" },
        select: { result: true, createdAt: true },
      });

      return reply.send({
        message: "プロフィールを更新しました",
        user: formatMe({
          ...user,
          lastRatingDelta: lastMatch
            ? ratingDeltaFromResult(lastMatch.result as "win" | "loss" | "draw")
            : null,
          lastMatchAt: lastMatch ? lastMatch.createdAt.toISOString() : null,
        }),
      });
    },
  );

  fastify.post(
    "/rewarded-ad",
    {
      schema: {
        tags: ["Me"],
        summary: "リワード広告報酬の受け取り（魂+1）",
        response: {
          200: rewardedAdResponseSchema,
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

      const currentUser = await prisma.user.findUnique({
        where: { id: payload.userId },
        select: { isSubscriber: true, soulCount: true },
      });

      if (!currentUser)
        return reply.status(401).send({ message: "認証が必要です" });

      // 課金者は全回復、無課金は+1
      const { getMaxSoulCount } =
        await import("../../domain/services/SoulRecoveryService");
      const maxSoulCount = getMaxSoulCount(currentUser.isSubscriber);
      const newSoulCount = currentUser.isSubscriber
        ? maxSoulCount
        : Math.min(currentUser.soulCount + 1, maxSoulCount);

      const user = await prisma.user.update({
        where: { id: payload.userId },
        data: { soulCount: newSoulCount },
        include: { stats: true },
      });

      const lastMatch = await prisma.matchHistory.findFirst({
        where: { userId: user.id },
        orderBy: { createdAt: "desc" },
        select: { result: true, createdAt: true },
      });

      const message = user.isSubscriber
        ? "魂を全回復しました（プレミアム特典）"
        : "魂を1回復しました";

      return reply.send({
        message,
        user: formatMe({
          ...user,
          lastRatingDelta: lastMatch
            ? ratingDeltaFromResult(lastMatch.result as "win" | "loss" | "draw")
            : null,
          lastMatchAt: lastMatch ? lastMatch.createdAt.toISOString() : null,
        }),
      });
    },
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

      // 任意選択要件: デフォルト配布アイコンはマスタも含めて自己修復する
      await Promise.all(
        ICON_CATALOG.map((icon) =>
          prisma.iconMaster.upsert({
            where: { id: icon.id },
            update: {
              imageUrl: icon.imageUrl,
              rarity: icon.rarity,
              displayNumber: icon.displayNumber,
            },
            create: {
              id: icon.id,
              imageUrl: icon.imageUrl,
              rarity: icon.rarity,
              displayNumber: icon.displayNumber,
            },
          }),
        ),
      );

      // デフォルトアイコンのみは必ず所持扱いにする（自己修復）
      await prisma.userIcon.createMany({
        data: [{ userId: payload.userId, iconId: "default_demon" }],
        skipDuplicates: true,
      });

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
          imageUrl: normalizeIconImageUrl(x.icon.imageUrl),
          rarity: x.icon.rarity,
          displayNumber: x.icon.displayNumber,
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
    },
  );

  fastify.get(
    "/icons",
    {
      schema: {
        tags: ["Me"],
        summary: "アイコン一覧取得（所持フラグ付き）",
        response: {
          200: getIconCatalogResponseSchema,
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

      // マスタ自己修復（icon_catalog.ts が配信対象のソース・オブ・トゥルース）
      await Promise.all(
        ICON_CATALOG.map((icon) =>
          prisma.iconMaster.upsert({
            where: { id: icon.id },
            update: {
              imageUrl: icon.imageUrl,
              rarity: icon.rarity,
              displayNumber: icon.displayNumber,
            },
            create: {
              id: icon.id,
              imageUrl: icon.imageUrl,
              rarity: icon.rarity,
              displayNumber: icon.displayNumber,
            },
          }),
        ),
      );

      const [all, owned] = await Promise.all([
        prisma.iconMaster.findMany({
          select: {
            id: true,
            imageUrl: true,
            rarity: true,
            displayNumber: true,
          },
          orderBy: { displayNumber: "asc" },
        }),
        prisma.userIcon.findMany({
          where: { userId: payload.userId },
          select: { iconId: true },
        }),
      ]);

      const ownedSet = new Set(owned.map((x) => x.iconId));

      return reply.send({
        icons: all.map((x) => ({
          id: x.id,
          imageUrl: normalizeIconImageUrl(x.imageUrl),
          rarity: x.rarity,
          displayNumber: x.displayNumber,
          owned: ownedSet.has(x.id),
        })),
      });
    },
  );

  fastify.get(
    "/titles",
    {
      schema: {
        tags: ["Me"],
        summary: "称号一覧取得（所持フラグ付き）",
        response: {
          200: getTitleCatalogResponseSchema,
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

      const [all, owned] = await Promise.all([
        prisma.title.findMany({
          select: { id: true, name: true, condition: true },
          orderBy: [{ id: "asc" }],
        }),
        prisma.userTitle.findMany({
          where: { userId: payload.userId },
          select: { titleId: true },
        }),
      ]);

      const ownedSet = new Set(owned.map((x) => x.titleId));

      return reply.send({
        titles: all.map((x) => ({
          id: x.id,
          name: x.name,
          condition: x.condition,
          owned: ownedSet.has(x.id),
        })),
      });
    },
  );

  fastify.get(
    "/messages",
    {
      schema: {
        tags: ["Me"],
        summary: "メッセージ一覧取得（所持フラグ付き）",
        response: {
          200: getMessageCatalogResponseSchema,
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

      const [all, owned] = await Promise.all([
        prisma.messageMaster.findMany({
          select: { id: true, content: true, condition: true, rarity: true },
          orderBy: [{ rarity: "asc" }, { id: "asc" }],
        }),
        prisma.userMessage.findMany({
          where: { userId: payload.userId },
          select: { messageId: true },
        }),
      ]);

      const ownedSet = new Set(owned.map((x) => x.messageId));

      return reply.send({
        messages: all.map((x) => ({
          id: x.id,
          content: x.content,
          condition: x.condition,
          rarity: x.rarity,
          owned: ownedSet.has(x.id),
        })),
      });
    },
  );
}
