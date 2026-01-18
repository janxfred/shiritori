import { getPrisma, isDatabaseConfigured } from "../../database";
import { verifyAuthToken } from "../../lib/auth";
import type { ServerInstance } from "../../lib/fastify";
import { ICON_CATALOG } from "../../lib/icon_catalog";
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
  const idx = Math.floor(Math.random() * arr.length);
  const v = arr[idx];
  if (v === undefined) throw new Error("EMPTY_ARRAY");
  return v;
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

      // マスタ自己修復（少なくともアイコンは必ず候補に入るようにする）
      await Promise.all(
        ICON_CATALOG.map((icon) =>
          prisma.iconMaster.upsert({
            where: { id: icon.id },
            update: { imageUrl: icon.imageUrl, rarity: icon.rarity },
            create: {
              id: icon.id,
              imageUrl: icon.imageUrl,
              rarity: icon.rarity,
            },
          })
        )
      );

      // 重複排出あり：所持状況に関わらず全マスタが対象、等確率
      const [icons, messages, titles, items] = await Promise.all([
        prisma.iconMaster.findMany({
          select: { id: true, imageUrl: true, rarity: true },
        }),
        prisma.messageMaster.findMany({
          select: { id: true, content: true, rarity: true },
        }),
        prisma.title.findMany({
          select: { id: true, name: true },
        }),
        prisma.itemMaster.findMany({
          select: { id: true, name: true, rarity: true },
        }),
      ]);

      const masterTotal =
        icons.length + messages.length + titles.length + items.length;
      if (masterTotal === 0) {
        return reply
          .status(503)
          .send({ message: "ガチャの排出対象が未登録です" });
      }

      const total =
        icons.length + messages.length + titles.length + items.length;
      const p = total > 0 ? 1 / total : 0;

      const rates = [
        ...icons.map((x) => ({
          type: "icon" as const,
          id: x.id,
          imageUrl: x.imageUrl,
          rarity: x.rarity,
          probability: p,
        })),
        ...messages.map((x) => ({
          type: "message" as const,
          id: x.id,
          content: x.content,
          rarity: x.rarity,
          probability: p,
        })),
        ...titles.map((x) => ({
          type: "title" as const,
          id: x.id,
          name: x.name,
          probability: p,
        })),
        ...items.map((x) => ({
          type: "item" as const,
          id: x.id,
          name: x.name,
          rarity: x.rarity,
          probability: p,
        })),
      ];

      return reply.send({ cost: GACHA_COST, coins: user.coins, rates });
    }
  );

  fastify.post(
    "/draw",
    {
      schema: {
        tags: ["Gacha"],
        summary: "召喚（ガチャ）",
        description: `コイン${GACHA_COST}枚を消費して召喚します（重複排出あり）。`,
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

        // マスタ自己修復（少なくともアイコンは必ず候補に入るようにする）
        await Promise.all(
          ICON_CATALOG.map((icon) =>
            tx.iconMaster.upsert({
              where: { id: icon.id },
              update: { imageUrl: icon.imageUrl, rarity: icon.rarity },
              create: {
                id: icon.id,
                imageUrl: icon.imageUrl,
                rarity: icon.rarity,
              },
            })
          )
        );

        const [icons, messages, titles, items] = await Promise.all([
          tx.iconMaster.findMany(),
          tx.messageMaster.findMany(),
          tx.title.findMany(),
          tx.itemMaster.findMany(),
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
          await tx.userIcon.createMany({
            data: [{ userId: me.id, iconId: icon.id }],
            skipDuplicates: true,
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
          await tx.userMessage.createMany({
            data: [{ userId: me.id, messageId: msg.id }],
            skipDuplicates: true,
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
          await tx.userTitle.createMany({
            data: [{ userId: me.id, titleId: title.id }],
            skipDuplicates: true,
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
        await tx.userItem.createMany({
          data: [{ userId: me.id, itemId: item.id }],
          skipDuplicates: true,
        });
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
