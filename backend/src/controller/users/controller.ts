import { prisma } from "../../database";
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
  email: string;
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
        },
      },
    },
    async (request, reply) => {
      const { page, limit, search } = request.query;

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
    }
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
        },
      },
    },
    async (request, reply) => {
      const { email, name } = request.body;

      const existingUser = await prisma.user.findUnique({
        where: { email },
      });

      if (existingUser) {
        return reply
          .status(409)
          .send({ message: "このメールアドレスは既に登録されています" });
      }

      await prisma.user.create({
        data: { email, name },
      });

      return reply.status(201).send({ message: "ユーザーを作成しました" });
    }
  );
}
