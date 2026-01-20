import type { PrismaClient, Prisma } from "@prisma/client";
import { TITLE_CATALOG } from "../../lib/title_catalog";

type TxClient = Omit<
  PrismaClient,
  "$connect" | "$disconnect" | "$on" | "$transaction" | "$use" | "$extends"
>;

// 称号チェック結果
type TitleCheckResult = {
  titleId: string;
  titleName: string;
  description: string;
};

// 称号をプレゼントボックスに追加
async function addTitleToPresent(
  tx: TxClient,
  userId: string,
  titleId: string,
  description: string
): Promise<void> {
  // 既に所持しているか確認
  const existing = await tx.userTitle.findUnique({
    where: { userId_titleId: { userId, titleId } },
  });

  if (existing) return;

  // プレゼントボックスに既に同じ称号があるか確認
  const existingPresent = await tx.presentBox.findFirst({
    where: { userId, type: "title", targetId: titleId, claimed: false },
  });

  if (existingPresent) return;

  // プレゼントボックスに追加
  await tx.presentBox.create({
    data: {
      userId,
      type: "title",
      targetId: titleId,
      amount: 0,
      description,
    },
  });
}

// レート達成称号チェック
export async function checkRatingTitles(
  tx: TxClient,
  userId: string,
  rating: number
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  if (rating >= 1500) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_rating_1500");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "レート1500達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  if (rating >= 2000) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_rating_2000");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "レート2000達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  return results;
}

// 連勝称号チェック
export async function checkWinStreakTitles(
  tx: TxClient,
  userId: string,
  currentStreak: number
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  if (currentStreak >= 3) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_win_streak_3");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "3連勝達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  if (currentStreak >= 5) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_win_streak_5");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "5連勝達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  if (currentStreak >= 10) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_win_streak_10");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "10連勝達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  return results;
}

// 連敗称号チェック
export async function checkLoseStreakTitles(
  tx: TxClient,
  userId: string,
  currentLoseStreak: number
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  if (currentLoseStreak >= 3) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_lose_streak_3");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "3連敗達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  return results;
}

// 累計勝利称号チェック
export async function checkTotalWinsTitles(
  tx: TxClient,
  userId: string,
  totalWins: number
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  const milestones = [
    { wins: 10, titleId: "title_total_wins_10" },
    { wins: 20, titleId: "title_total_wins_20" },
    { wins: 30, titleId: "title_total_wins_30" },
    { wins: 50, titleId: "title_total_wins_50" },
  ];

  for (const milestone of milestones) {
    if (totalWins >= milestone.wins) {
      const title = TITLE_CATALOG.find((t) => t.id === milestone.titleId);
      if (title) {
        await addTitleToPresent(tx, userId, title.id, `累計勝利${milestone.wins}回達成報酬`);
        results.push({ titleId: title.id, titleName: title.name, description: title.description });
      }
    }
  }

  return results;
}

// AI対戦数称号チェック
export async function checkAiMatchTitles(
  tx: TxClient,
  userId: string,
  aiMatchCount: number
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  if (aiMatchCount >= 10) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_ai_match_10");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "累計AI対戦10回達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  return results;
}

// ガチャ回数称号チェック
export async function checkGachaCountTitles(
  tx: TxClient,
  userId: string,
  gachaCount: number
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  const milestones = [
    { count: 3, titleId: "title_gacha_3" },
    { count: 10, titleId: "title_gacha_10" },
    { count: 50, titleId: "title_gacha_50" },
  ];

  for (const milestone of milestones) {
    if (gachaCount >= milestone.count) {
      const title = TITLE_CATALOG.find((t) => t.id === milestone.titleId);
      if (title) {
        await addTitleToPresent(tx, userId, title.id, `ガチャ${milestone.count}回達成報酬`);
        results.push({ titleId: title.id, titleName: title.name, description: title.description });
      }
    }
  }

  return results;
}

// コイン保有称号チェック
export async function checkCoinsTitles(
  tx: TxClient,
  userId: string,
  coins: number
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  if (coins >= 20) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_coins_20");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "コイン20枚保有達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  if (coins >= 50) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_coins_50");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "コイン50枚保有達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  return results;
}

// 連続ログイン称号チェック
export async function checkLoginStreakTitles(
  tx: TxClient,
  userId: string,
  consecutiveLoginDays: number
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  if (consecutiveLoginDays >= 7) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_login_7days");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "連続7日間ログイン達成報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  return results;
}

// 魂0称号チェック
export async function checkSoulEaterTitle(
  tx: TxClient,
  userId: string,
  soulCount: number
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  if (soulCount === 0) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_soul_eater");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "魂を使い果たした報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  return results;
}

// るーず超越称号チェック（「ず」「る」「ー」全て取られて勝利）
export async function checkLooseTranscenderTitle(
  tx: TxClient,
  userId: string,
  playerWon: boolean,
  opponentCapturedChars: string[]
): Promise<TitleCheckResult[]> {
  const results: TitleCheckResult[] = [];

  if (!playerWon) return results;

  const requiredChars = ["ず", "る", "ー"];
  const hasAllChars = requiredChars.every((char) =>
    opponentCapturedChars.includes(char)
  );

  if (hasAllChars) {
    const title = TITLE_CATALOG.find((t) => t.id === "title_loose_transcender");
    if (title) {
      await addTitleToPresent(tx, userId, title.id, "るーずを超越した報酬");
      results.push({ titleId: title.id, titleName: title.name, description: title.description });
    }
  }

  return results;
}
