import path from "node:path";
import { fileURLToPath } from "node:url";
import fastifyAutoload from "@fastify/autoload";
import fastifyCors from "@fastify/cors";
import fastifySwagger from "@fastify/swagger";
import fastifySwaggerUi from "@fastify/swagger-ui";
import Fastify from "fastify";
import {
  serializerCompiler,
  validatorCompiler,
  jsonSchemaTransform,
} from "fastify-type-provider-zod";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Fastifyアプリケーションの構築
 */
async function buildApp() {
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

/**
 * サーバー起動
 */
async function start() {
  const port = Number(process.env.PORT) || 3002;
  const host = "0.0.0.0";

  try {
    const app = await buildApp();

    await app.listen({ port, host });
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }
}

start();
