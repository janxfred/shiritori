import "dotenv/config";
import { PrismaClient } from "@prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";
import bcrypt from "bcryptjs";

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not set");
}

const adapter = new PrismaPg({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log("🌱 Seeding database...");

  // --- マスタデータ ---
  await prisma.iconMaster.upsert({
    where: { id: "default_demon" },
    update: {},
    create: {
      id: "default_demon",
      imageUrl: "https://example.com/default_demon.png",
      rarity: 1,
    },
  });

  await prisma.messageMaster.upsert({
    where: { id: "msg_default_01" },
    update: {},
    create: {
      id: "msg_default_01",
      content: "契約は既に結ばれた。さあ、言葉を捧げよ。",
      rarity: 1,
    },
  });

  const titleIds = ["title_main_01", "title_sub_01", "title_sub_02"] as const;

  await prisma.title.upsert({
    where: { id: titleIds[0] },
    update: {},
    create: {
      id: titleIds[0],
      name: "新米の契約者",
      description: "魔界へようこそ。",
      condition: "default",
    },
  });

  await prisma.title.upsert({
    where: { id: titleIds[1] },
    update: {},
    create: {
      id: titleIds[1],
      name: "言霊の欠片",
      description: "まだ小さな力。",
      condition: "default",
    },
  });

  await prisma.title.upsert({
    where: { id: titleIds[2] },
    update: {},
    create: {
      id: titleIds[2],
      name: "沈黙の観測者",
      description: "言葉の行方を見届ける者。",
      condition: "default",
    },
  });

  const itemIds = ["item_01", "item_02", "item_03"] as const;

  await prisma.itemMaster.upsert({
    where: { id: itemIds[0] },
    update: {},
    create: {
      id: itemIds[0],
      name: "黒曜の欠片",
      description: "魔界の力を宿す小片。",
      rarity: 1,
    },
  });

  await prisma.itemMaster.upsert({
    where: { id: itemIds[1] },
    update: {},
    create: {
      id: itemIds[1],
      name: "契約の印",
      description: "悪魔との契約を証明する印。",
      rarity: 2,
    },
  });

  await prisma.itemMaster.upsert({
    where: { id: itemIds[2] },
    update: {},
    create: {
      id: itemIds[2],
      name: "深紅の蝋",
      description: "血判に使われる赤い蝋。",
      rarity: 1,
    },
  });

  // --- サンプルユーザー ---
  const passwordHash = await bcrypt.hash("password123", 10);

  const sampleUsers = [
    { email: "user1@example.com", name: "User 1" },
    { email: "user2@example.com", name: "User 2" },
    { email: "user3@example.com", name: "User 3" },
  ] as const;

  for (const u of sampleUsers) {
    const user = await prisma.user.upsert({
      where: { email: u.email },
      update: {
        name: u.name,
      },
      create: {
        email: u.email,
        name: u.name,
        passwordHash,
        // デフォルト装備はスキーマの default に依存
      },
    });

    await prisma.userStats.upsert({
      where: { userId: user.id },
      update: {},
      create: { userId: user.id },
    });

    await prisma.userIcon.createMany({
      data: [{ userId: user.id, iconId: "default_demon" }],
      skipDuplicates: true,
    });

    await prisma.userMessage.createMany({
      data: [{ userId: user.id, messageId: "msg_default_01" }],
      skipDuplicates: true,
    });

    await prisma.userTitle.createMany({
      data: titleIds.map((titleId) => ({ userId: user.id, titleId })),
      skipDuplicates: true,
    });
  }

  console.log(`✅ Seeded ${sampleUsers.length} users + masters`);
  console.log("🎉 Seeding completed!");
}

main()
  .catch((e) => {
    console.error("❌ Seeding failed:", e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
