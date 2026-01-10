import { prisma } from "../../../database";
import { type ServerInstance } from "../../../lib/fastify";
import {
  commandResponseSchema,
  errorResponseSchema,
  getUserParamsSchema,
  getUserResponseSchema,
  updateUserParamsSchema,
  updateUserRequestSchema,
  deleteUserParamsSchema,
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
        summary: "ユーザー詳細取得",
        description: "指定したIDのユーザー情報を取得します。",
        params: getUserParamsSchema,
        response: {
          200: getUserResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { userId } = request.params;

      const user = await prisma.user.findUnique({
        where: { id: userId },
      });

      if (!user) {
        return reply.status(404).send({ message: "ユーザーが見つかりません" });
      }

      return reply.send(formatUserResponse(user));
    }
  );

  fastify.put(
    "/",
    {
      schema: {
        tags: ["User"],
        summary: "ユーザー更新",
        description: "指定したIDのユーザー情報を更新します。",
        params: updateUserParamsSchema,
        body: updateUserRequestSchema,
        response: {
          200: commandResponseSchema,
          400: errorResponseSchema,
          404: errorResponseSchema,
          409: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { userId } = request.params;
      const { email, name } = request.body;

      const existingUser = await prisma.user.findUnique({
        where: { id: userId },
      });

      if (!existingUser) {
        return reply.status(404).send({ message: "ユーザーが見つかりません" });
      }

      if (email) {
        const duplicateEmail = await prisma.user.findFirst({
          where: {
            email,
            NOT: { id: userId },
          },
        });

        if (duplicateEmail) {
          return reply
            .status(409)
            .send({ message: "このメールアドレスは既に使用されています" });
        }
      }

      await prisma.user.update({
        where: { id: userId },
        data: {
          ...(email && { email }),
          ...(name && { name }),
        },
      });

      return reply.send({ message: "ユーザーを更新しました" });
    }
  );

  fastify.delete(
    "/",
    {
      schema: {
        tags: ["User"],
        summary: "ユーザー削除",
        description: "指定したIDのユーザーを削除します。",
        params: deleteUserParamsSchema,
        response: {
          200: commandResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { userId } = request.params;

      const existingUser = await prisma.user.findUnique({
        where: { id: userId },
      });

      if (!existingUser) {
        return reply.status(404).send({ message: "ユーザーが見つかりません" });
      }

      await prisma.user.delete({
        where: { id: userId },
      });

      return reply.send({ message: "ユーザーを削除しました" });
    }
  );
}
