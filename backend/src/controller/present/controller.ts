import { getPrisma, isDatabaseConfigured } from "../../database";
import { verifyAuthToken } from "../../lib/auth";
import type { ServerInstance } from "../../lib/fastify";
import {
  claimAllPresentsResponseSchema,
  claimPresentRequestSchema,
  claimPresentResponseSchema,
  errorResponseSchema,
  presentListResponseSchema,
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
  // プレゼントボックス一覧取得
  fastify.get(
    "/",
    {
      schema: {
        tags: ["Present"],
        summary: "プレゼントボックス一覧取得",
        response: {
          200: presentListResponseSchema,
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

      const presents = await prisma.presentBox.findMany({
        where: {
          userId: payload.userId,
          claimed: false,
          OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
        },
        orderBy: { createdAt: "desc" },
      });

      const unclaimedCount = presents.length;

      return reply.send({
        presents: presents.map((p) => ({
          id: p.id,
          type: p.type as "coin" | "title" | "message" | "icon" | "item",
          targetId: p.targetId,
          amount: p.amount,
          description: p.description,
          claimed: p.claimed,
          createdAt: p.createdAt.toISOString(),
          expiresAt: p.expiresAt?.toISOString() ?? null,
        })),
        unclaimedCount,
      });
    }
  );

  // プレゼント受け取り
  fastify.post(
    "/claim",
    {
      schema: {
        tags: ["Present"],
        summary: "プレゼント受け取り",
        body: claimPresentRequestSchema,
        response: {
          200: claimPresentResponseSchema,
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

      const token = getBearerToken(request);
      if (!token) return reply.status(401).send({ message: "認証が必要です" });

      const payload = verifyAuthToken({ token });
      if (!payload)
        return reply.status(401).send({ message: "認証が必要です" });

      const { presentId } = request.body as { presentId: string };
      const prisma = getPrisma();

      const result = await prisma.$transaction(async (tx) => {
        const present = await tx.presentBox.findFirst({
          where: {
            id: presentId,
            userId: payload.userId,
            claimed: false,
          },
        });

        if (!present) {
          return { kind: "not_found" as const };
        }

        if (present.expiresAt && present.expiresAt < new Date()) {
          return { kind: "expired" as const };
        }

        // プレゼントを受け取り済みにする
        await tx.presentBox.update({
          where: { id: present.id },
          data: { claimed: true, claimedAt: new Date() },
        });

        // 報酬を付与
        if (present.type === "coin") {
          await tx.user.update({
            where: { id: payload.userId },
            data: { coins: { increment: present.amount } },
          });
        } else if (present.type === "title" && present.targetId) {
          await tx.userTitle.createMany({
            data: [{ userId: payload.userId, titleId: present.targetId }],
            skipDuplicates: true,
          });
        } else if (present.type === "message" && present.targetId) {
          await tx.userMessage.createMany({
            data: [{ userId: payload.userId, messageId: present.targetId }],
            skipDuplicates: true,
          });
        } else if (present.type === "icon" && present.targetId) {
          await tx.userIcon.createMany({
            data: [{ userId: payload.userId, iconId: present.targetId }],
            skipDuplicates: true,
          });
        } else if (present.type === "item" && present.targetId) {
          await tx.userItem.createMany({
            data: [{ userId: payload.userId, itemId: present.targetId }],
            skipDuplicates: true,
          });
        }

        return {
          kind: "ok" as const,
          reward: {
            type: present.type,
            targetId: present.targetId,
            amount: present.amount,
            description: present.description,
          },
        };
      });

      if (result.kind === "not_found") {
        return reply.status(404).send({ message: "プレゼントが見つかりません" });
      }

      if (result.kind === "expired") {
        return reply.status(400).send({ message: "プレゼントの期限が切れています" });
      }

      return reply.send({
        message: "プレゼントを受け取りました",
        reward: result.reward,
      });
    }
  );

  // 全プレゼント一括受け取り
  fastify.post(
    "/claim-all",
    {
      schema: {
        tags: ["Present"],
        summary: "全プレゼント一括受け取り",
        response: {
          200: claimAllPresentsResponseSchema,
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

      const result = await prisma.$transaction(async (tx) => {
        const presents = await tx.presentBox.findMany({
          where: {
            userId: payload.userId,
            claimed: false,
            OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
          },
        });

        if (presents.length === 0) {
          return { kind: "ok" as const, claimedCount: 0, rewards: [] };
        }

        // 全プレゼントを受け取り済みにする
        await tx.presentBox.updateMany({
          where: {
            id: { in: presents.map((p) => p.id) },
          },
          data: { claimed: true, claimedAt: new Date() },
        });

        // コインの合計
        const totalCoins = presents
          .filter((p) => p.type === "coin")
          .reduce((sum, p) => sum + p.amount, 0);

        if (totalCoins > 0) {
          await tx.user.update({
            where: { id: payload.userId },
            data: { coins: { increment: totalCoins } },
          });
        }

        // タイトル付与
        const titleIds = presents
          .filter((p) => p.type === "title" && p.targetId)
          .map((p) => p.targetId as string);
        if (titleIds.length > 0) {
          await tx.userTitle.createMany({
            data: titleIds.map((titleId) => ({ userId: payload.userId, titleId })),
            skipDuplicates: true,
          });
        }

        // メッセージ付与
        const messageIds = presents
          .filter((p) => p.type === "message" && p.targetId)
          .map((p) => p.targetId as string);
        if (messageIds.length > 0) {
          await tx.userMessage.createMany({
            data: messageIds.map((messageId) => ({ userId: payload.userId, messageId })),
            skipDuplicates: true,
          });
        }

        // アイコン付与
        const iconIds = presents
          .filter((p) => p.type === "icon" && p.targetId)
          .map((p) => p.targetId as string);
        if (iconIds.length > 0) {
          await tx.userIcon.createMany({
            data: iconIds.map((iconId) => ({ userId: payload.userId, iconId })),
            skipDuplicates: true,
          });
        }

        // アイテム付与
        const itemIds = presents
          .filter((p) => p.type === "item" && p.targetId)
          .map((p) => p.targetId as string);
        if (itemIds.length > 0) {
          await tx.userItem.createMany({
            data: itemIds.map((itemId) => ({ userId: payload.userId, itemId })),
            skipDuplicates: true,
          });
        }

        return {
          kind: "ok" as const,
          claimedCount: presents.length,
          rewards: presents.map((p) => ({
            type: p.type,
            targetId: p.targetId,
            amount: p.amount,
            description: p.description,
          })),
        };
      });

      return reply.send({
        message:
          result.claimedCount > 0
            ? `${result.claimedCount}件のプレゼントを受け取りました`
            : "受け取るプレゼントがありません",
        claimedCount: result.claimedCount,
        rewards: result.rewards,
      });
    }
  );
}
