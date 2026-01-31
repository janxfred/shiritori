import { getPrisma, isDatabaseConfigured } from "../../database";
import { checkPremiumSubscriberTitle } from "../../domain/services/TitleAchievementService";
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

/** 1日の同期上限（悪用防止） */
const DAILY_SYNC_LIMIT = 10;

/** ユーザーごとの同期回数を追跡（メモリ内、リスタートでリセット） */
const syncCountMap = new Map<string, { count: number; date: string }>();

function checkSyncLimit(userId: string): boolean {
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const record = syncCountMap.get(userId);

  if (!record || record.date !== today) {
    syncCountMap.set(userId, { count: 1, date: today });
    return true;
  }

  if (record.count >= DAILY_SYNC_LIMIT) {
    return false;
  }

  record.count++;
  return true;
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
          429: errorResponseSchema,
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

      // 1日の同期上限チェック（悪用防止）
      if (!checkSyncLimit(payload.userId)) {
        return reply.status(429).send({
          message: "本日の同期上限に達しました。明日再試行してください。",
        });
      }

      const prisma = getPrisma();
      const { isActive } = request.body;

      const user = await prisma.$transaction(async (tx) => {
        const updatedUser = await tx.user.update({
          where: { id: payload.userId },
          data: { isSubscriber: isActive },
        });

        // プレミアム加入時に称号付与
        if (isActive) {
          await checkPremiumSubscriberTitle(tx, payload.userId);
        }

        return updatedUser;
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
