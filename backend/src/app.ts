import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import fastifyAutoload from "@fastify/autoload";
import fastifyCors from "@fastify/cors";
import fastifySwagger from "@fastify/swagger";
import fastifySwaggerUi from "@fastify/swagger-ui";
import Fastify from "fastify";
import {
  jsonSchemaTransform,
  serializerCompiler,
  validatorCompiler,
} from "fastify-type-provider-zod";

import { STATIC_ICON_FILE_NAMES } from "./lib/icon_catalog";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Fastifyアプリケーションの構築
 */
export async function buildApp() {
  const app = Fastify({
    logger: {
      level: "info",
      transport:
        process.env.NODE_ENV !== "production"
          ? {
              target: "pino-pretty",
              options: {
                colorize: true,
                translateTime: "yyyy-mm-dd HH:MM:ss",
                ignore: "pid,hostname",
              },
            }
          : undefined,
    },
  });

  // Zodバリデーターの設定
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  // CORSの設定
  const corsAllowAll = process.env.CORS_ALLOW_ALL === "true";

  await app.register(fastifyCors, {
    origin: (origin, cb) => {
      // モバイルアプリはブラウザCORSの対象外で、Originヘッダが無いことが多い。
      // ここで弾くとモバイルからのアクセスを阻害するため、Originなしは許可する。
      if (!origin) return cb(null, true);

      if (process.env.NODE_ENV !== "production") return cb(null, true);

      // productionでも全オリジン許可（モバイル向け / 必要に応じて利用）
      if (corsAllowAll) return cb(null, true);

      const allowedOrigin = process.env.CORS_ORIGIN;
      if (!allowedOrigin) return cb(null, true);
      if (allowedOrigin === "*") return cb(null, true);

      return cb(null, origin === allowedOrigin);
    },
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    credentials: true,
  });

  // Swagger/OpenAPIの設定（本番以外）
  if (process.env.NODE_ENV !== "production") {
    await app.register(fastifySwagger, {
      openapi: {
        info: {
          title: "Backend API",
          description: "Development Camp Backend API Template",
          version: "1.0.0",
        },
        servers: [
          {
            url: `http://localhost:${process.env.PORT || 3002}`,
            description: "Development server",
          },
        ],
      },
      transform: jsonSchemaTransform,
    });

    await app.register(fastifySwaggerUi, {
      routePrefix: "/docs",
      uiConfig: {
        docExpansion: "list",
        deepLinking: true,
      },
    });
  }

  // コントローラーの自動ロード
  await app.register(fastifyAutoload, {
    dir: path.join(__dirname, "controller"),
    options: { prefix: "/api" },
    // _paramName ディレクトリをURLパラメータとして扱う
    dirNameRoutePrefix: (folderParent, folderName) => {
      if (folderName.startsWith("_")) {
        return `:${folderName.slice(1)}`;
      }
      return folderName;
    },
  });

  // 簡易静的ファイル配信（モバイルのアイコン用 / 許可リスト方式）
  const allowedStaticFiles = new Set(STATIC_ICON_FILE_NAMES);
  app.get("/static/:file", async (request, reply) => {
    const file = (request.params as { file?: string }).file;
    if (!file || !allowedStaticFiles.has(file)) {
      return reply.status(404).send({ message: "not found" });
    }

    const safeFileName = path.basename(file);
    const filePath = path.join(__dirname, "..", "static", safeFileName);
    if (!fs.existsSync(filePath)) {
      return reply.status(404).send({ message: "not found" });
    }

    const ext = path.extname(safeFileName).toLowerCase();
    if (ext === ".png") reply.type("image/png");
    else if (ext === ".jpg" || ext === ".jpeg") reply.type("image/jpeg");
    else return reply.status(404).send({ message: "not found" });

    reply.header("cache-control", "public, max-age=3600");
    return reply.send(fs.createReadStream(filePath));
  });

  // ヘルスチェックエンドポイント
  app.get("/health", async () => {
    return { status: "ok", timestamp: new Date().toISOString() };
  });

  // liveness / readiness（デプロイ・監視向け）
  app.get("/health/live", async () => {
    return { status: "ok" };
  });

  app.get("/health/ready", async () => {
    return { status: "ok" };
  });

  return app;
}
