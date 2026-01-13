import { PrismaClient } from "@prisma/client";

let prisma: PrismaClient | null = null;

export function isDatabaseConfigured(): boolean {
  return Boolean(process.env.DATABASE_URL);
}

/**
 * Prisma は `DATABASE_URL` がないと初期化時に例外になり得るため、
 * DBを使うAPI（ユーザーAPI等）でのみ遅延生成する。
 */
export function getPrisma(): PrismaClient {
  if (!process.env.DATABASE_URL) {
    throw new Error("DATABASE_URL is not set");
  }

  if (!prisma) {
    prisma = new PrismaClient({
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
