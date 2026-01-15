/*
  Warnings:

  - Added the required column `password_hash` to the `users` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "users" ADD COLUMN     "coins" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "exp" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "icon_id" TEXT NOT NULL DEFAULT 'default_demon',
ADD COLUMN     "is_cheater" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "is_rating_public" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "is_streak_public" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "is_subscriber" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "is_win_count_public" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "is_win_rate_public" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "last_login_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "level" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "message_id" TEXT NOT NULL DEFAULT 'msg_default_01',
ADD COLUMN     "password_hash" TEXT NOT NULL,
ADD COLUMN     "rating" INTEGER NOT NULL DEFAULT 1000,
ADD COLUMN     "soul_count" INTEGER NOT NULL DEFAULT 5,
ADD COLUMN     "title1_id" TEXT,
ADD COLUMN     "title2_id" TEXT,
ADD COLUMN     "title3_id" TEXT,
ALTER COLUMN "email" DROP NOT NULL;

-- CreateTable
CREATE TABLE "message_masters" (
    "id" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "rarity" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "message_masters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "icon_masters" (
    "id" TEXT NOT NULL,
    "image_url" TEXT NOT NULL,
    "rarity" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "icon_masters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "titles" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "condition" TEXT NOT NULL,

    CONSTRAINT "titles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_messages" (
    "user_id" TEXT NOT NULL,
    "message_id" TEXT NOT NULL,
    "obtained_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_messages_pkey" PRIMARY KEY ("user_id","message_id")
);

-- CreateTable
CREATE TABLE "user_icons" (
    "user_id" TEXT NOT NULL,
    "icon_id" TEXT NOT NULL,
    "obtained_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_icons_pkey" PRIMARY KEY ("user_id","icon_id")
);

-- CreateTable
CREATE TABLE "user_titles" (
    "user_id" TEXT NOT NULL,
    "title_id" TEXT NOT NULL,
    "obtained_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_titles_pkey" PRIMARY KEY ("user_id","title_id")
);

-- CreateTable
CREATE TABLE "user_stats" (
    "user_id" TEXT NOT NULL,
    "total_wins" INTEGER NOT NULL DEFAULT 0,
    "total_losses" INTEGER NOT NULL DEFAULT 0,
    "total_draws" INTEGER NOT NULL DEFAULT 0,
    "current_streak" INTEGER NOT NULL DEFAULT 0,
    "max_streak" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "user_stats_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "match_histories" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "opponent_id" TEXT NOT NULL,
    "result" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "match_histories_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "match_histories_user_id_created_at_idx" ON "match_histories"("user_id", "created_at");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_icon_id_fkey" FOREIGN KEY ("icon_id") REFERENCES "icon_masters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "message_masters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_title1_id_fkey" FOREIGN KEY ("title1_id") REFERENCES "titles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_title2_id_fkey" FOREIGN KEY ("title2_id") REFERENCES "titles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_title3_id_fkey" FOREIGN KEY ("title3_id") REFERENCES "titles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_messages" ADD CONSTRAINT "user_messages_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_messages" ADD CONSTRAINT "user_messages_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "message_masters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_icons" ADD CONSTRAINT "user_icons_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_icons" ADD CONSTRAINT "user_icons_icon_id_fkey" FOREIGN KEY ("icon_id") REFERENCES "icon_masters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_titles" ADD CONSTRAINT "user_titles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_titles" ADD CONSTRAINT "user_titles_title_id_fkey" FOREIGN KEY ("title_id") REFERENCES "titles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_stats" ADD CONSTRAINT "user_stats_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "match_histories" ADD CONSTRAINT "match_histories_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
