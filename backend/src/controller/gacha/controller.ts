import { getPrisma, isDatabaseConfigured } from "../../database";
import { verifyAuthToken } from "../../lib/auth";
import { type ServerInstance } from "../../lib/fastify";
import {
  errorResponseSchema,
  gachaDrawResponseSchema,
  gachaStatusResponseSchema,
} from "./schema";

const GACHA_COST = 3;

function getBearerToken(request: {
  headers: Record<string, unknown>;
}): string | null {
  const auth = request.headers.authorization;
  if (typeof auth !== "string") return null;
  const [type, token] = auth.split(" ");
  if (type?.toLowerCase() !== "bearer" || !token) return null;
  return token;
}

function pickOne<T>(arr: readonly T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]!;
}

export default async function (fastify: ServerInstance) {
  fastify.get(
    "/",
    {
      schema: {
        tags: ["Gacha"],
        summary: "召喚（ガチャ）状態取得",
        response: {
          200: gachaStatusResponseSchema,
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

      return reply.send({ cost: GACHA_COST, coins: user.coins });
    }
  );

  fastify.post(
    "/draw",
    {
      schema: {
        tags: ["Gacha"],
        summary: "召喚（ガチャ）",
        description: `コイン${GACHA_COST}枚を消費して召喚します。重複は可能な限り回避します。`,
        response: {
          200: gachaDrawResponseSchema,
          400: errorResponseSchema,
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
        const me = await tx.user.findUnique({
          where: { id: payload.userId },
          select: { id: true, coins: true },
        });
        if (!me) throw new Error("UNAUTHORIZED");

        if (me.coins < GACHA_COST) {
          return { kind: "error" as const, message: "コインが足りません" };
        }

        const [ownedIcons, ownedMessages, ownedTitles, ownedItems] =
          await Promise.all([
            tx.userIcon.findMany({
              where: { userId: me.id },
              select: { iconId: true },
            }),
            tx.userMessage.findMany({
              where: { userId: me.id },
              select: { messageId: true },
            }),
            tx.userTitle.findMany({
              where: { userId: me.id },
              select: { titleId: true },
            }),
            tx.userItem.findMany({
              where: { userId: me.id },
              select: { itemId: true },
            }),
          ]);

        const ownedIconIds = ownedIcons.map((x) => x.iconId);
        const ownedMessageIds = ownedMessages.map((x) => x.messageId);
        const ownedTitleIds = ownedTitles.map((x) => x.titleId);
        const ownedItemIds = ownedItems.map((x) => x.itemId);

        const [icons, messages, titles, items] = await Promise.all([
          tx.iconMaster.findMany({
            where: ownedIconIds.length ? { id: { notIn: ownedIconIds } } : {},
          }),
          tx.messageMaster.findMany({
            where: ownedMessageIds.length
              ? { id: { notIn: ownedMessageIds } }
              : {},
          }),
          tx.title.findMany({
            where: ownedTitleIds.length ? { id: { notIn: ownedTitleIds } } : {},
          }),
          tx.itemMaster.findMany({
            where: ownedItemIds.length ? { id: { notIn: ownedItemIds } } : {},
          }),
        ]);

        const candidates: Array<
          | { type: "icon"; id: string }
          | { type: "message"; id: string }
          | { type: "title"; id: string }
          | { type: "item"; id: string }
        > = [];

        for (const i of icons) candidates.push({ type: "icon", id: i.id });
        for (const m of messages)
          candidates.push({ type: "message", id: m.id });
        for (const t of titles) candidates.push({ type: "title", id: t.id });
        for (const it of items) candidates.push({ type: "item", id: it.id });

        if (candidates.length === 0) {
          return {
            kind: "error" as const,
            message: "ガチャの排出対象が未登録です",
          };
        }

        const chosen = pickOne(candidates);

        // 先にコインを消費
        const updatedUser = await tx.user.update({
          where: { id: me.id },
          data: { coins: { decrement: GACHA_COST } },
          select: { coins: true },
        });

        if (chosen.type === "icon") {
          const icon = await tx.iconMaster.findUnique({
            where: { id: chosen.id },
          });
          if (!icon) throw new Error("NOT_FOUND");
          await tx.userIcon.create({
            data: { userId: me.id, iconId: icon.id },
          });
          return {
            kind: "ok" as const,
            coins: updatedUser.coins,
            reward: {
              type: "icon" as const,
              id: icon.id,
              imageUrl: icon.imageUrl,
              rarity: icon.rarity,
            },
          };
        }

        if (chosen.type === "message") {
          const msg = await tx.messageMaster.findUnique({
            where: { id: chosen.id },
          });
          if (!msg) throw new Error("NOT_FOUND");
          await tx.userMessage.create({
            data: { userId: me.id, messageId: msg.id },
          });
          return {
            kind: "ok" as const,
            coins: updatedUser.coins,
            reward: {
              type: "message" as const,
              id: msg.id,
              content: msg.content,
              rarity: msg.rarity,
            },
          };
        }

        if (chosen.type === "title") {
          const title = await tx.title.findUnique({ where: { id: chosen.id } });
          if (!title) throw new Error("NOT_FOUND");
          await tx.userTitle.create({
            data: { userId: me.id, titleId: title.id },
          });
          return {
            kind: "ok" as const,
            coins: updatedUser.coins,
            reward: {
              type: "title" as const,
              id: title.id,
              name: title.name,
              description: title.description,
              condition: title.condition,
            },
          };
        }

        const item = await tx.itemMaster.findUnique({
          where: { id: chosen.id },
        });
        if (!item) throw new Error("NOT_FOUND");
        await tx.userItem.create({ data: { userId: me.id, itemId: item.id } });
        return {
          kind: "ok" as const,
          coins: updatedUser.coins,
          reward: {
            type: "item" as const,
            id: item.id,
            name: item.name,
            description: item.description,
            rarity: item.rarity,
          },
        };
      });

      if (result.kind === "error") {
        return reply.status(400).send({ message: result.message });
      }

      return reply.send({
        message: "召喚しました",
        coins: result.coins,
        reward: result.reward,
      });
    }
  );
}
