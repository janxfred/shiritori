import { getPrisma, isDatabaseConfigured } from "../../database";
import { verifyAuthToken } from "../../lib/auth";
import { type ServerInstance } from "../../lib/fastify";
import {
  agreeTermsRequestSchema,
  agreeTermsResponseSchema,
  errorResponseSchema,
  termsStatusResponseSchema,
} from "./schema";

const CURRENT_TERMS_VERSION = "2.3";

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
  fastify.get(
    "/status",
    {
      schema: {
        tags: ["Terms"],
        summary: "契約（Terms of Service）の同意状況取得",
        response: {
          200: termsStatusResponseSchema,
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
        select: { termsAgreedAt: true, termsVersion: true },
      });
      if (!user) return reply.status(401).send({ message: "認証が必要です" });

      return reply.send({
        currentVersion: CURRENT_TERMS_VERSION,
        agreed: Boolean(user.termsAgreedAt),
        agreedAt: user.termsAgreedAt ? user.termsAgreedAt.toISOString() : null,
        agreedVersion: user.termsVersion ?? null,
      });
    }
  );

  fastify.post(
    "/agree",
    {
      schema: {
        tags: ["Terms"],
        summary: "契約（Terms of Service）に同意する",
        body: agreeTermsRequestSchema,
        response: {
          200: agreeTermsResponseSchema,
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

      // idempotent: already agreed -> keep timestamp
      const existing = await prisma.user.findUnique({
        where: { id: payload.userId },
        select: { termsAgreedAt: true },
      });
      if (!existing)
        return reply.status(401).send({ message: "認証が必要です" });

      const agreedAt = existing.termsAgreedAt ?? new Date();
      const updated = await prisma.user.update({
        where: { id: payload.userId },
        data: {
          termsAgreedAt: agreedAt,
          termsVersion: CURRENT_TERMS_VERSION,
        },
        select: { termsAgreedAt: true, termsVersion: true },
      });

      return reply.send({
        message: "契約に同意しました",
        currentVersion: CURRENT_TERMS_VERSION,
        agreedAt: updated.termsAgreedAt!.toISOString(),
        agreedVersion: updated.termsVersion ?? CURRENT_TERMS_VERSION,
      });
    }
  );
}
