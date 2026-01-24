import type { Prisma } from "@prisma/client";

const MAX_SOUL_COUNT = 7;
const FULL_RECOVERY_HOURS = 24;

/**
 * 魂の自動回復をチェックし、必要に応じて全回復させる
 * @param userId ユーザーID
 * @param currentSoulCount 現在の魂の数
 * @param lastSoulUsedAt 最後に魂を使用した日時（null可）
 * @param tx トランザクション
 * @returns 回復後の魂の数
 */
export async function checkAndRecoverSoul(
  userId: string,
  currentSoulCount: number,
  lastSoulUsedAt: Date | null,
  tx: Prisma.TransactionClient,
): Promise<number> {
  // すでに最大値なら何もしない
  if (currentSoulCount >= MAX_SOUL_COUNT) {
    return currentSoulCount;
  }

  // 魂を一度も使用していない場合は回復不要
  if (!lastSoulUsedAt) {
    return currentSoulCount;
  }

  const now = new Date();
  const hoursSinceLastUse =
    (now.getTime() - lastSoulUsedAt.getTime()) / (1000 * 60 * 60);

  // 24時間経過していたら全回復
  if (hoursSinceLastUse >= FULL_RECOVERY_HOURS) {
    await tx.user.update({
      where: { id: userId },
      data: { soulCount: MAX_SOUL_COUNT },
    });
    return MAX_SOUL_COUNT;
  }

  return currentSoulCount;
}

/**
 * 魂を消費し、lastSoulUsedAtを更新する
 * @param userId ユーザーID
 * @param tx トランザクション
 */
export async function consumeSoul(
  userId: string,
  tx: Prisma.TransactionClient,
): Promise<void> {
  await tx.user.update({
    where: { id: userId, soulCount: { gte: 1 } },
    data: {
      soulCount: { decrement: 1 },
      lastSoulUsedAt: new Date(),
    },
  });
}
