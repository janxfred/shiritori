import crypto from "node:crypto";
import bcrypt from "bcryptjs";
import { getPrisma, isDatabaseConfigured } from "../../database";
import { DEFAULT_ICON_URL } from "../../lib/asset_url";
import { type ServerInstance } from "../../lib/fastify";
import {
  buildPaginationResponse,
  calculatePagination,
} from "../../lib/pagination";
import {
  commandResponseSchema,
  createUserRequestSchema,
  errorResponseSchema,
  listUsersQuerySchema,
  listUsersResponseSchema,
} from "./schema";

function formatUserResponse(user: {
  id: string;
  email: string | null;
  name: string;
  createdAt: Date;
  updatedAt: Date;
}) {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    createdAt: user.createdAt.toISOString(),
    updatedAt: user.updatedAt.toISOString(),
  };
}

async function ensureDefaultMasters(prisma: ReturnType<typeof getPrisma>) {
  await prisma.iconMaster.upsert({
    where: { id: "default_demon" },
    update: {},
    create: {
      id: "default_demon",
      imageUrl: DEFAULT_ICON_URL,
      rarity: 1,
      displayNumber: 1,
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

export default async function (fastify: ServerInstance) {
  fastify.get(
    "/",
    {
      schema: {
        tags: ["User"],
        summary: "ユーザー一覧取得",
        description:
          "ユーザーの一覧を取得します。ページネーションと検索に対応しています。",
        querystring: listUsersQuerySchema,
        response: {
          200: listUsersResponseSchema,
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

      const { page, limit, search } = request.query;
      const prisma = getPrisma();

      const { skip, take } = calculatePagination({ page, limit });

      const where = search
        ? {
            OR: [
              { name: { contains: search } },
              { email: { contains: search } },
            ],
          }
        : {};

      const [users, total] = await Promise.all([
        prisma.user.findMany({
          where,
          skip,
          take,
          orderBy: { createdAt: "desc" },
        }),
        prisma.user.count({ where }),
      ]);

      const response = buildPaginationResponse({
        data: users.map((user) => formatUserResponse(user)),
        total,
        page,
        limit,
      });

      return reply.send(response);
    },
  );

  fastify.post(
    "/",
    {
      schema: {
        tags: ["User"],
        summary: "ユーザー作成",
        description: "新しいユーザーを作成します。",
        body: createUserRequestSchema,
        response: {
          201: commandResponseSchema,
          400: errorResponseSchema,
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

      const { email, name } = request.body;
      const prisma = getPrisma();

      await ensureDefaultMasters(prisma);

      const existingUser = await prisma.user.findUnique({
        where: { email },
      });

      if (existingUser) {
        return reply
          .status(409)
          .send({ message: "このメールアドレスは既に登録されています" });
      }

      const randomPassword = crypto.randomBytes(16).toString("hex");
      const passwordHash = await bcrypt.hash(randomPassword, 10);

      await prisma.user.create({
        data: {
          email,
          name,
          passwordHash,
          stats: { create: {} },
          ownedIcons: { create: { iconId: "default_demon" } },
          ownedMessages: { create: { messageId: "msg_default_01" } },
        },
      });

      return reply.status(201).send({ message: "ユーザーを作成しました" });
    },
  );
}
