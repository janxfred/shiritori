import type { FastifyInstance } from "fastify";
import type { ZodTypeProvider } from "fastify-type-provider-zod";

/**
 * Zod型プロバイダーを適用したFastifyインスタンスの型定義
 * コントローラーでの型推論を有効にするために使用
 */
export type ServerInstance = FastifyInstance<
  import("http").Server,
  import("http").IncomingMessage,
  import("http").ServerResponse,
  import("fastify").FastifyBaseLogger,
  ZodTypeProvider
>;
