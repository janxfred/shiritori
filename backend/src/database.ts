import { PrismaClient } from "@prisma/client";
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
    // 本番環境（Supabase等）ではSSL接続が必要
    // 自己署名証明書を使用するDBでは rejectUnauthorized: false が必要
    // connectionString内のsslmodeパラメータだけでは不十分なため、
    // 明示的にpg.Poolを作成してSSL設定を確実に適用する
    const isProduction = process.env.NODE_ENV === "production";

    // connectionString からsslmodeパラメータを除去（pg.Poolのsslオプションと競合するため）
    const connectionString = process.env.DATABASE_URL.replace(
      /[?&]sslmode=[^&]*/g,
      (match, offset, str) => (offset === str.indexOf("?") ? "?" : ""),
    ).replace(/\?$/, "");

    const pool = new pg.Pool({
      connectionString,
      ssl: isProduction
        ? {
            rejectUnauthorized: false,
          }
        : false,
    });

    const adapter = new PrismaPg(pool);
    prisma = new PrismaClient({
      adapter,
      // log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
    });
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
