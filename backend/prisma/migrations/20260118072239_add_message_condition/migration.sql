-- AlterTable
ALTER TABLE "message_masters" ADD COLUMN     "condition" TEXT NOT NULL DEFAULT 'ガチャで獲得';

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "email_linked_at" TIMESTAMP(3),
ADD COLUMN     "terms_agreed_at" TIMESTAMP(3),
ADD COLUMN     "terms_version" TEXT;

-- CreateTable
CREATE TABLE "item_masters" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "rarity" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "item_masters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_items" (
    "user_id" TEXT NOT NULL,
    "item_id" TEXT NOT NULL,
    "obtained_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_items_pkey" PRIMARY KEY ("user_id","item_id")
);

-- AddForeignKey
ALTER TABLE "user_items" ADD CONSTRAINT "user_items_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_items" ADD CONSTRAINT "user_items_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "item_masters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
