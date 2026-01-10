import { PrismaClient } from "@prisma/client";

// Prismaクライアントのシングルトンインスタンス
export const prisma = new PrismaClient({
  // log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
});

// アプリケーション終了時のクリーンアップ
process.on("beforeExit", async () => {
  await prisma.$disconnect();
});
