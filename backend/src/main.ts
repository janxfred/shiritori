import "dotenv/config";
import { buildApp } from "./app";

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
