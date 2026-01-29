import type { PrismaClient } from "@prisma/client";

type TxClient = Omit<
  PrismaClient,
  "$connect" | "$disconnect" | "$on" | "$transaction" | "$use" | "$extends"
>;

const WEEKLY_BONUS_COINS = 5;

/**
 * JSTで月曜日0時を取得
 * @param date 基準日時
 * @returns その週の月曜日0時（JST）
 */
function getMondayMidnightJST(date: Date): Date {
  // JSTに変換（UTC+9）
  const jstOffset = 9 * 60 * 60 * 1000;
  const utcTime = date.getTime();
  const jstTime = new Date(utcTime + jstOffset);

  // JST日付を取得
  const year = jstTime.getUTCFullYear();
  const month = jstTime.getUTCMonth();
  const dayOfMonth = jstTime.getUTCDate();
  const dayOfWeek = jstTime.getUTCDay(); // 0=日曜, 1=月曜, ...

  // 月曜日を基準にする (日曜=0 → 6日前, 月曜=1 → 0日前, ...)
  const daysFromMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;

  // JST月曜0時を作成
  const mondayJST = new Date(
    Date.UTC(year, month, dayOfMonth - daysFromMonday, 0, 0, 0, 0),
  );

  // UTCに戻す
  return new Date(mondayJST.getTime() - jstOffset);
}

/**
 * 週のリセットが必要かチェックし、必要ならリセット
 * statsが存在しない場合は何もしない（incrementWeeklyBattleAndCheckBonusで作成される）
 */
export async function checkAndResetWeeklyMission(
  tx: TxClient,
  userId: string,
): Promise<void> {
  const now = new Date();
  const currentWeekMonday = getMondayMidnightJST(now);

  const stats = await tx.userStats.findUnique({
    where: { userId },
    select: { weeklyResetDate: true },
  });

  // statsがない場合は何もしない（後で作成される）
  if (!stats) return;

  const lastResetDate = stats.weeklyResetDate;

  // リセット日が未設定、または現在の週の月曜より前ならリセット
  if (!lastResetDate || lastResetDate < currentWeekMonday) {
    await tx.userStats.update({
      where: { userId },
      data: {
        weeklyBattleCount: 0,
        weeklyBattleReward2: false,
        weeklyBattleReward5: false,
        weeklyResetDate: currentWeekMonday,
      },
    });
  }
}

/**
 * 対戦カウントを増加し、ウィークリーボーナスをチェック・付与
 * @returns 付与されたコイン数
 */
export async function incrementWeeklyBattleAndCheckBonus(
  tx: TxClient,
  userId: string,
): Promise<number> {
  console.log(
    `[WeeklyMission] incrementWeeklyBattleAndCheckBonus called for userId: ${userId}`,
  );
  const now = new Date();
  const currentWeekMonday = getMondayMidnightJST(now);
  console.log(
    `[WeeklyMission] currentWeekMonday: ${currentWeekMonday.toISOString()}`,
  );

  // 現在の状態を取得（upsertで確実に存在させる）
  let stats = await tx.userStats.findUnique({
    where: { userId },
    select: {
      weeklyBattleCount: true,
      weeklyBattleReward2: true,
      weeklyBattleReward5: true,
      weeklyResetDate: true,
    },
  });

  if (!stats) {
    // statsがない場合は作成（初回対戦）
    console.log(`[WeeklyMission] Creating new UserStats for userId: ${userId}`);
    stats = await tx.userStats.create({
      data: {
        userId,
        weeklyBattleCount: 0,
        weeklyBattleReward2: false,
        weeklyBattleReward5: false,
        weeklyResetDate: currentWeekMonday,
      },
      select: {
        weeklyBattleCount: true,
        weeklyBattleReward2: true,
        weeklyBattleReward5: true,
        weeklyResetDate: true,
      },
    });
  } else {
    console.log(
      `[WeeklyMission] Found existing stats: count=${stats.weeklyBattleCount}, reward2=${stats.weeklyBattleReward2}, reward5=${stats.weeklyBattleReward5}`,
    );
  }

  // 週のリセットチェック
  const lastResetDate = stats.weeklyResetDate;
  if (!lastResetDate || lastResetDate < currentWeekMonday) {
    // リセットが必要
    stats = {
      weeklyBattleCount: 0,
      weeklyBattleReward2: false,
      weeklyBattleReward5: false,
      weeklyResetDate: currentWeekMonday,
    };
    await tx.userStats.update({
      where: { userId },
      data: {
        weeklyBattleCount: 0,
        weeklyBattleReward2: false,
        weeklyBattleReward5: false,
        weeklyResetDate: currentWeekMonday,
      },
    });
  }

  const newCount = stats.weeklyBattleCount + 1;
  let totalBonusCoins = 0;
  let grantReward2 = false;
  let grantReward5 = false;

  // 2回達成報酬チェック
  if (newCount >= 2 && !stats.weeklyBattleReward2) {
    grantReward2 = true;
    totalBonusCoins += WEEKLY_BONUS_COINS;
  }

  // 5回達成報酬チェック
  if (newCount >= 5 && !stats.weeklyBattleReward5) {
    grantReward5 = true;
    totalBonusCoins += WEEKLY_BONUS_COINS;
  }

  // カウント更新
  await tx.userStats.update({
    where: { userId },
    data: {
      weeklyBattleCount: newCount,
      ...(grantReward2 ? { weeklyBattleReward2: true } : {}),
      ...(grantReward5 ? { weeklyBattleReward5: true } : {}),
    },
  });

  // ボーナスをプレゼントボックスに追加
  console.log(
    `[WeeklyMission] newCount=${newCount}, grantReward2=${grantReward2}, grantReward5=${grantReward5}, totalBonusCoins=${totalBonusCoins}`,
  );
  if (grantReward2) {
    console.log(
      `[WeeklyMission] Granting 2-battle reward to userId: ${userId}`,
    );
    await tx.presentBox.create({
      data: {
        userId,
        type: "coin",
        amount: WEEKLY_BONUS_COINS,
        description: "ウィークリーミッション：対戦2回達成報酬",
      },
    });
  }

  if (grantReward5) {
    console.log(
      `[WeeklyMission] Granting 5-battle reward to userId: ${userId}`,
    );
    await tx.presentBox.create({
      data: {
        userId,
        type: "coin",
        amount: WEEKLY_BONUS_COINS,
        description: "ウィークリーミッション：対戦5回達成報酬",
      },
    });
  }

  console.log(
    `[WeeklyMission] Completed. Returning totalBonusCoins=${totalBonusCoins}`,
  );
  return totalBonusCoins;
}
