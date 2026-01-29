-- AlterTable
ALTER TABLE "user_stats" ADD COLUMN     "weekly_battle_count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "weekly_battle_reward_2" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "weekly_battle_reward_5" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "weekly_reset_date" TIMESTAMP(3);
