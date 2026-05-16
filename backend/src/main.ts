import "dotenv/config";
import { buildApp } from "./app";
import { getPrisma, isDatabaseConfigured } from "./database";

/**
 * サーバー起動
 */
async function start() {
  const port = Number(process.env.PORT) || 3002;
  const host = "0.0.0.0";

  try {
    const app = await buildApp();

    await app.listen({ port, host });

    // DB接続を事前確立（コールドスタート時の初回リクエスト遅延を削減）
    if (isDatabaseConfigured()) {
      getPrisma().$queryRaw`SELECT 1`.catch((err: unknown) =>
        console.error("DB warmup failed:", err),
      );
    }
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }
}

start();
