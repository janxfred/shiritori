import { PrismaClient } from "@prisma/client";
import { withAccelerate } from "@prisma/extension-accelerate";
import { PrismaPg } from "@prisma/adapter-pg";
import pg from "pg";

let prisma: InstanceType<typeof PrismaClient> | null = null;

export function isDatabaseConfigured(): boolean {
  return Boolean(process.env.DATABASE_URL);
}

/**
 * Prisma は `DATABASE_URL` がないと初期化時に例外になり得るため、
 * DBを使うAPI（ユーザーAPI等）でのみ遅延生成する。
 */
export function getPrisma(): InstanceType<typeof PrismaClient> {
  if (!process.env.DATABASE_URL) {
    throw new Error("DATABASE_URL is not set");
  }

  if (!prisma) {
    const connectionString = process.env.DATABASE_URL;

    // Prisma Postgres (prisma+postgres://) はHTTPベースのAccelerate経由で接続
    if (connectionString.startsWith("prisma+postgres://")) {
      const client = new PrismaClient({
        accelerateUrl: connectionString,
      }).$extends(withAccelerate());
      prisma = client as unknown as InstanceType<typeof PrismaClient>;
    } else {
      // 従来のPostgreSQL接続（Supabase等）の場合はpg.Pool経由
      const isProduction = process.env.NODE_ENV === "production";

      // connectionString からsslmodeパラメータを除去（pg.Poolのsslオプションと競合するため）
      const cleanedConnectionString = connectionString
        .replace(/[?&]sslmode=[^&]*/g, (match, offset, str) =>
          offset === str.indexOf("?") ? "?" : "",
        )
        .replace(/\?$/, "");

      const pool = new pg.Pool({
        connectionString: cleanedConnectionString,
        ssl: isProduction
          ? {
              rejectUnauthorized: false,
            }
          : false,
      });

      const adapter = new PrismaPg(pool);
      prisma = new PrismaClient({
        adapter,
      });
    }
  }

  return prisma;
}

async function disconnectPrisma() {
  if (!prisma) return;
  await prisma.$disconnect();
  prisma = null;
}

// アプリケーション終了時のクリーンアップ
process.on("beforeExit", async () => {
  await disconnectPrisma();
});
