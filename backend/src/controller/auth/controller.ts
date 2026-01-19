import bcrypt from "bcryptjs";
import { getPrisma, isDatabaseConfigured } from "../../database";
import { checkCoinsTitles, checkLoginStreakTitles } from "../../domain/services/TitleAchievementService";
import { signAuthToken } from "../../lib/auth";
import type { ServerInstance } from "../../lib/fastify";
import { ICON_CATALOG } from "../../lib/icon_catalog";
import { MESSAGE_CATALOG } from "../../lib/message_catalog";
import { TITLE_CATALOG } from "../../lib/title_catalog";
import {
  errorResponseSchema,
  loginRequestSchema,
  loginResponseSchema,
  signupRequestSchema,
  signupResponseSchema,
} from "./schema";

const LOGIN_BONUS_COINS = 3;
const LOGIN_BONUS_INTERVAL_HOURS = 24;

async function ensureDefaultMasters(prisma: ReturnType<typeof getPrisma>) {
  // アイコンマスタ
  await Promise.all(
    ICON_CATALOG.map((icon) =>
      prisma.iconMaster.upsert({
        where: { id: icon.id },
        update: { imageUrl: icon.imageUrl, rarity: icon.rarity },
        create: { id: icon.id, imageUrl: icon.imageUrl, rarity: icon.rarity },
      })
    )
  );

  // メッセージマスタ
  await Promise.all(
    MESSAGE_CATALOG.map((msg) =>
      prisma.messageMaster.upsert({
        where: { id: msg.id },
        update: { content: msg.content, condition: msg.condition, rarity: msg.rarity },
        create: { id: msg.id, content: msg.content, condition: msg.condition, rarity: msg.rarity },
      })
    )
  );

  // 称号マスタ
  await Promise.all(
    TITLE_CATALOG.map((title) =>
      prisma.title.upsert({
        where: { id: title.id },
        update: { name: title.name, description: title.description, condition: title.condition },
        create: { id: title.id, name: title.name, description: title.description, condition: title.condition },
      })
    )
  );

  // デフォルト称号（新米の契約者）
  await prisma.title.upsert({
    where: { id: "title_main_01" },
    update: {},
    create: {
      id: "title_main_01",
      name: "新米の契約者",
      description: "魔界へようこそ。",
      condition: "default",
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

async function findLoginUser(
  prisma: ReturnType<typeof getPrisma>,
  identifier: string
) {
  // 1) internal id (uuid)
  const byId = await prisma.user.findUnique({ where: { id: identifier } });
  if (byId) return { user: byId } as const;

  // 2) email (unique)
  const byEmail = await prisma.user.findUnique({
    where: { email: identifier },
  });
  if (byEmail) return { user: byEmail } as const;

  // 3) name (non-unique) -> disambiguate
  const byName = await prisma.user.findMany({ where: { name: identifier } });
  if (byName.length === 1) {
    const user = byName[0];
    if (user) return { user } as const;
  }
  if (byName.length >= 2) {
    return {
      error: {
        status: 400,
        message:
          "同名ユーザーが複数います。アカウント設定で表示されるユーザーIDでログインしてください",
      },
    } as const;
  }

  return { user: null } as const;
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
          title1Id: "title_main_01",
          stats: { create: {} },
          ownedIcons: { create: { iconId: "default_demon" } },
          ownedMessages: { create: { messageId: "msg_default_01" } },
          ownedTitles: { create: { titleId: "title_main_01" } },
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
        summary: "ログイン（ユーザーID/メール/名前 + 合言葉）",
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

      const found = await findLoginUser(prisma, userId);
      if (found.error) {
        return reply
          .status(found.error.status)
          .send({ message: found.error.message });
      }

      const user = found.user;
      if (!user)
        return reply.status(404).send({ message: "ユーザーが見つかりません" });

      const ok = await bcrypt.compare(password, user.passwordHash);
      if (!ok) {
        return reply.status(401).send({ message: "合言葉が違います" });
      }

      const now = new Date();
      let loginBonusGranted = false;

      // トランザクションでログイン処理
      const updated = await prisma.$transaction(async (tx) => {
        // ログインボーナスチェック
        const lastBonusAt = user.lastLoginBonusAt;
        const hoursSinceLastBonus = lastBonusAt
          ? (now.getTime() - lastBonusAt.getTime()) / (1000 * 60 * 60)
          : LOGIN_BONUS_INTERVAL_HOURS + 1;

        if (hoursSinceLastBonus >= LOGIN_BONUS_INTERVAL_HOURS) {
          // ログインボーナスをプレゼントボックスに追加
          await tx.presentBox.create({
            data: {
              userId: user.id,
              type: "coin",
              amount: LOGIN_BONUS_COINS,
              description: "ログインボーナス",
            },
          });
          loginBonusGranted = true;
        }

        // 連続ログイン日数チェック
        const stats = await tx.userStats.upsert({
          where: { userId: user.id },
          update: {},
          create: { userId: user.id },
        });

        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const lastLoginDate = stats.lastLoginDate;
        let newConsecutiveLoginDays = stats.consecutiveLoginDays;

        if (lastLoginDate) {
          const lastDate = new Date(
            lastLoginDate.getFullYear(),
            lastLoginDate.getMonth(),
            lastLoginDate.getDate()
          );
          const daysDiff = Math.floor(
            (today.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24)
          );

          if (daysDiff === 1) {
            newConsecutiveLoginDays = stats.consecutiveLoginDays + 1;
          } else if (daysDiff > 1) {
            newConsecutiveLoginDays = 1;
          }
        } else {
          newConsecutiveLoginDays = 1;
        }

        // 統計を更新
        await tx.userStats.update({
          where: { userId: user.id },
          data: {
            consecutiveLoginDays: newConsecutiveLoginDays,
            lastLoginDate: today,
          },
        });

        // 連続ログイン称号チェック
        await checkLoginStreakTitles(tx, user.id, newConsecutiveLoginDays);

        // ユーザー情報を更新
        const updatedUser = await tx.user.update({
          where: { id: user.id },
          data: {
            lastLoginAt: now,
            lastLoginBonusAt: loginBonusGranted ? now : undefined,
          },
        });

        // コイン保有称号チェック
        await checkCoinsTitles(tx, user.id, updatedUser.coins);

        return updatedUser;
      });

      const message = loginBonusGranted
        ? `ログインしました（ログインボーナス${LOGIN_BONUS_COINS}コインをプレゼントボックスに追加しました）`
        : "ログインしました";

      return reply.send({
        message,
        token: signAuthToken({ userId: updated.id }),
        user: formatAuthUser(updated),
      });
    }
  );
}
