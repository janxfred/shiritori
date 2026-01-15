import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
    seed: "tsx prisma/seed/main.ts",
  },
  datasource: {
    // DATABASE_URL はAPI側では optional だが、migrate/db系コマンドでは必須。
    // ここでは CLI 読み込み時の例外を避けるため、未設定時は空文字にフォールバックする。
    url: process.env.DATABASE_URL ?? "",
  },
});
