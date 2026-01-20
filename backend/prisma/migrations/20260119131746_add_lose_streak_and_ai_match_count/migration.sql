-- AlterTable
ALTER TABLE "user_stats" ADD COLUMN     "ai_match_count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "consecutive_login_days" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "current_lose_streak" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "gacha_count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "last_login_date" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "last_login_bonus_at" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "present_boxes" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "target_id" TEXT,
    "amount" INTEGER NOT NULL DEFAULT 0,
    "description" TEXT NOT NULL,
    "claimed" BOOLEAN NOT NULL DEFAULT false,
    "claimed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(3),

    CONSTRAINT "present_boxes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "present_boxes_user_id_claimed_idx" ON "present_boxes"("user_id", "claimed");

-- AddForeignKey
ALTER TABLE "present_boxes" ADD CONSTRAINT "present_boxes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
