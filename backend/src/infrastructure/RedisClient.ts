import { createClient } from "redis";

type RedisClient = ReturnType<typeof createClient>;

let client: RedisClient | null = null;
let connectPromise: Promise<RedisClient> | null = null;

export function isRedisConfigured(): boolean {
  const url = process.env.REDIS_URL;
  return typeof url === "string" && url.trim().length > 0;
}

export async function getRedisClient(): Promise<RedisClient> {
  if (!isRedisConfigured()) {
    throw new Error("REDIS_URL が未設定です");
  }

  if (client) return client;
  if (connectPromise) return connectPromise;

  const url = process.env.REDIS_URL!.trim();
  const c = createClient({ url });

  c.on("error", (err: unknown) => {
    // 接続断は上位でリトライ/ハンドリングする
    console.error("[redis] error", err);
  });

  connectPromise = (async () => {
    await c.connect();
    client = c;
    return c;
  })();

  return connectPromise;
}

export async function closeRedisClient(): Promise<void> {
  connectPromise = null;

  if (!client) return;

  const c = client;
  client = null;

  try {
    await c.quit();
  } catch {
    try {
      c.disconnect();
    } catch {
      // ignore
    }
  }
}
