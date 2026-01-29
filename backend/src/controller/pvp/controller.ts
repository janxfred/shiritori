import { getPrisma, isDatabaseConfigured } from "../../database";
import {
  checkCoinsTitles,
  checkLoseStreakTitles,
  checkLooseTranscenderTitle,
  checkRatingTitles,
  checkTotalWinsTitles,
  checkWinRateTitles,
  checkWinStreakTitles,
} from "../../domain/services/TitleAchievementService";
import { incrementWeeklyBattleAndCheckBonus } from "../../domain/services/WeeklyMissionService";
import { thinkNextWord } from "../../domain/services/AiBrainService";
import { verifyAuthToken } from "../../lib/auth";
import { type ServerInstance } from "../../lib/fastify";
import {
  extractCharsToCapture,
  getNextStartChar,
  judgeWord,
} from "../../domain/services/ShiritoriJudgeService";
import {
  findWordsByPrefix,
  isInDictionary,
} from "../../infrastructure/DictionaryRepository";
import { MAX_ROUNDS } from "../../infrastructure/GameSessionStore";
import {
  createPvpSession,
  getOpponentId,
  getPvpSession,
  isParticipant,
  isPvpTimeExpired,
  sessionToJson,
  updatePvpSession,
  type PvpSession,
} from "../../infrastructure/PvpSessionStore";
import { isRedisConfigured } from "../../infrastructure/RedisClient";
import { normalizeIconImageUrl } from "../../lib/asset_url";
import {
  errorResponseSchema,
  pvpCheckTimeResponseSchema,
  pvpSessionResponseSchema,
  pvpStartRequestSchema,
  pvpStartResponseSchema,
  pvpSubmitRequestSchema,
  pvpSubmitResponseSchema,
} from "./schema";
import { AI_USER_ID_PREFIX } from "../matchmake/controller";

/** 対戦相手がAI偽装ユーザーかどうかを判定 */
function isAiOpponent(userId: string): boolean {
  return userId.startsWith(AI_USER_ID_PREFIX);
}

function getBearerToken(request: {
  headers: Record<string, unknown>;
}): string | null {
  const auth = request.headers.authorization;
  if (typeof auth !== "string") return null;
  const [type, token] = auth.split(" ");
  if (type?.toLowerCase() !== "bearer" || !token) return null;
  return token;
}

function calcWinRate(params: {
  totalWins: number;
  totalLosses: number;
  totalDraws: number;
}): number {
  const { totalWins, totalLosses, totalDraws } = params;
  const total = totalWins + totalLosses + totalDraws;
  if (total <= 0) return 0;
  return (totalWins / total) * 100;
}

function getMistakeCount(params: {
  session: PvpSession;
  userId: string;
}): number {
  const { session, userId } = params;
  if (session.player1Id === userId) return session.player1MistakeCount;
  return session.player2MistakeCount;
}

function incrementMistakeCount(params: {
  session: PvpSession;
  userId: string;
}): void {
  const { session, userId } = params;
  if (session.player1Id === userId) {
    session.player1MistakeCount++;
  } else {
    session.player2MistakeCount++;
  }
}

function getCapturedSet(params: {
  session: PvpSession;
  userId: string;
}): Set<string> {
  const { session, userId } = params;
  if (session.player1Id === userId) return session.player1CapturedChars;
  return session.player2CapturedChars;
}

function getOpponentCapturedSet(params: {
  session: PvpSession;
  userId: string;
}): Set<string> {
  const { session, userId } = params;
  if (session.player1Id === userId) return session.player2CapturedChars;
  return session.player1CapturedChars;
}

function computeWinnerUserId(session: PvpSession): string | null {
  if (session.status === "p1_win") return session.player1Id;
  if (session.status === "p2_win") return session.player2Id;
  return null;
}

/**
 * AI偽装対戦: AIのターンを自動で処理する
 * プレイヤーが有効な手を打った後、次がAIのターンの場合に呼ばれる
 * 非同期で遅延処理するため、呼び出し元は待機しない
 */
export function scheduleAiTurnIfNeeded(session: PvpSession): void {
  // 次のプレイヤーがAIでない場合は何もしない
  if (!isAiOpponent(session.currentTurnUserId)) {
    return;
  }

  // ゲームが終了している場合は何もしない
  if (session.status !== "playing") {
    return;
  }

  // セッションIDを保存（クロージャで参照）
  const sessionId = session.id;

  // 人間らしさを演出: 5〜20秒のランダム遅延後にAIが応答
  const delayMs = 5000 + Math.floor(Math.random() * 15000);

  setTimeout(async () => {
    try {
      // 遅延後にセッションを再取得（状態が変わっている可能性）
      const currentSession = await getPvpSession(sessionId);
      if (!currentSession) return;

      // 既にゲームが終了している場合は何もしない
      if (currentSession.status !== "playing") return;

      // AIのターンでない場合は何もしない（タイムアウト等で状態が変わった）
      if (!isAiOpponent(currentSession.currentTurnUserId)) return;

      await processAiTurn(currentSession);
    } catch (e) {
      console.error("[AI Turn] Error processing AI turn:", e);
    }
  }, delayMs);
}

/**
 * AIのターンを実際に処理する（遅延なし）
 */
async function processAiTurn(session: PvpSession): Promise<void> {
  const aiUserId = session.currentTurnUserId;
  const humanUserId = getOpponentId({ session, userId: aiUserId });

  // AIの思考（Lv.3 = 常に戦略的）
  const aiResult = thinkNextWord({
    level: 3,
    turnCount: session.turnCount,
    startChar: session.expectedStartChar,
    playerCapturedChars: getCapturedSet({ session, userId: humanUserId }),
    usedWords: session.usedWords,
    findWordsByPrefix,
  });

  session.turnCount++;

  if (aiResult.noValidWord || !aiResult.word) {
    // AIが有効な単語を見つけられない場合、AIの負け
    session.history.push({
      turn: session.turnCount,
      playerId: aiUserId,
      word: "(降参)",
      isValid: false,
      capturedChars: [],
      message: "有効な単語が見つからない…",
    });

    session.status = session.player1Id === humanUserId ? "p1_win" : "p2_win";
    await updatePvpSession(session);
    return;
  }

  const word = aiResult.word;

  // 有効な単語
  session.usedWords.add(word);
  const capturedChars = extractCharsToCapture(word);
  const aiCaptured = getCapturedSet({ session, userId: aiUserId });
  const humanCaptured = getOpponentCapturedSet({ session, userId: aiUserId });

  for (const ch of capturedChars) {
    if (!aiCaptured.has(ch) && !humanCaptured.has(ch)) {
      aiCaptured.add(ch);
    }
  }

  session.lastWord = word;
  session.expectedStartChar = getNextStartChar(word);

  session.history.push({
    turn: session.turnCount,
    playerId: aiUserId,
    word,
    isValid: true,
    capturedChars,
    message: "OK",
  });

  // 手番交代 & タイマーリセット
  session.currentTurnUserId = humanUserId;
  session.turnStartedAt = new Date();

  // ラウンド進行
  if (session.validTurnsInRound === 0) {
    session.validTurnsInRound = 1;
  } else {
    session.validTurnsInRound = 0;
    session.roundCount++;
  }

  // 10ラウンド終了判定
  if (session.roundCount >= MAX_ROUNDS) {
    const p1Chars = session.player1CapturedChars.size;
    const p2Chars = session.player2CapturedChars.size;

    if (p1Chars < p2Chars) {
      session.status = "p1_win";
    } else if (p1Chars > p2Chars) {
      session.status = "p2_win";
    } else {
      session.status = "draw";
    }
  }

  await updatePvpSession(session);
}

function ratingDeltaFromResult(result: "win" | "loss" | "draw"): number {
  if (result === "win") return 4;
  if (result === "loss") return -2;
  return 0;
}

function coinDeltaFromResult(result: "win" | "loss" | "draw"): number {
  if (result === "win") return 4;
  return 1;
}

async function commitRatedResultIfNeeded(params: {
  session: PvpSession;
  winnerUserId: string | null;
  viewerUserId: string;
}): Promise<
  | {
      userId: string;
      opponentId: string;
      userRating: number;
      opponentRating: number;
      userDelta: number;
      opponentDelta: number;
    }
  | undefined
> {
  const { session, winnerUserId, viewerUserId } = params;

  const debug = process.env.PVP_DEBUG === "true";

  const debugLog = (message: string, extra?: Record<string, unknown>) => {
    if (!debug) return;
    // eslint-disable-next-line no-console
    console.log("[pvp:commit]", message, {
      sessionId: session.id,
      status: session.status,
      resultCommitted: session.resultCommitted,
      p1: session.player1Id,
      p2: session.player2Id,
      winnerUserId,
      viewerUserId,
      ...(extra ?? {}),
    });
  };

  if (session.resultCommitted) {
    debugLog("skip: already committed");
    return undefined;
  }

  // DB未設定なら対人戦として成立しないため、ここで何もしない。
  if (!isDatabaseConfigured()) {
    debugLog("skip: database not configured");
    return undefined;
  }

  const prisma = getPrisma();

  const p1Result: "win" | "loss" | "draw" =
    session.status === "draw"
      ? "draw"
      : winnerUserId === session.player1Id
        ? "win"
        : "loss";
  const p2Result: "win" | "loss" | "draw" =
    session.status === "draw"
      ? "draw"
      : winnerUserId === session.player2Id
        ? "win"
        : "loss";

  const p1Delta = ratingDeltaFromResult(p1Result);
  const p2Delta = ratingDeltaFromResult(p2Result);

  const p1CoinDelta = coinDeltaFromResult(p1Result);
  const p2CoinDelta = coinDeltaFromResult(p2Result);

  debugLog("start", {
    p1Result,
    p2Result,
    p1Delta,
    p2Delta,
    p1CoinDelta,
    p2CoinDelta,
  });

  const [p1, p2] = await Promise.all([
    prisma.user.findUnique({
      where: { id: session.player1Id },
      include: { stats: true },
    }),
    // AI偽装対戦の場合、player2はAIなのでDBに存在しない
    isAiOpponent(session.player2Id)
      ? Promise.resolve(null)
      : prisma.user.findUnique({
          where: { id: session.player2Id },
          include: { stats: true },
        }),
  ]);

  // AI偽装対戦の場合: p1（人間）のみ更新、AIは無視
  if (isAiOpponent(session.player2Id)) {
    if (!p1) return undefined;

    const p1Result: "win" | "loss" | "draw" =
      session.status === "draw"
        ? "draw"
        : winnerUserId === session.player1Id
          ? "win"
          : "loss";

    const p1Delta = ratingDeltaFromResult(p1Result);
    const p1CoinDelta = coinDeltaFromResult(p1Result);

    const nextStats = (user: typeof p1, result: "win" | "loss" | "draw") => {
      const totalWins =
        (user.stats?.totalWins ?? 0) + (result === "win" ? 1 : 0);
      const totalLosses =
        (user.stats?.totalLosses ?? 0) + (result === "loss" ? 1 : 0);
      const totalDraws =
        (user.stats?.totalDraws ?? 0) + (result === "draw" ? 1 : 0);

      const currentStreak =
        result === "win" ? (user.stats?.currentStreak ?? 0) + 1 : 0;
      const maxStreak = Math.max(user.stats?.maxStreak ?? 0, currentStreak);

      const currentLoseStreak =
        result === "loss" ? (user.stats?.currentLoseStreak ?? 0) + 1 : 0;

      return {
        totalWins,
        totalLosses,
        totalDraws,
        currentStreak,
        maxStreak,
        currentLoseStreak,
      };
    };

    const p1Next = nextStats(p1, p1Result);

    const updatedP1 = await prisma.user.update({
      where: { id: p1.id },
      data: {
        rating: { increment: p1Delta },
        coins: { increment: p1CoinDelta },
        stats: {
          upsert: {
            create: p1Next,
            update: p1Next,
          },
        },
      },
      select: { id: true, rating: true, coins: true },
    });

    // AI対戦は対戦履歴に残さない（aiMatchCountで別途カウント）
    await prisma.userStats.update({
      where: { userId: p1.id },
      data: { aiMatchCount: { increment: 1 } },
    });

    // 称号チェック（プレイヤーのみ）
    await checkRatingTitles(prisma, p1.id, updatedP1.rating);
    await checkCoinsTitles(prisma, p1.id, updatedP1.coins);
    await checkWinStreakTitles(prisma, p1.id, p1Next.currentStreak);
    await checkLoseStreakTitles(prisma, p1.id, p1Next.currentLoseStreak);
    await checkTotalWinsTitles(prisma, p1.id, p1Next.totalWins);

    // ウィークリーミッション（対戦カウント）- AI戦も含む
    await incrementWeeklyBattleAndCheckBonus(prisma, p1.id);

    session.resultCommitted = true;
    await updatePvpSession(session);

    debugLog("committed AI match result", { p1Result, p1Delta, p1CoinDelta });

    return {
      userId: p1.id,
      opponentId: session.player2Id,
      userRating: updatedP1.rating,
      opponentRating: 1500, // AIの仮想レーティング
      userDelta: p1Delta,
      opponentDelta: 0,
    };
  }

  if (!p1 || !p2) return undefined;

  const nextStats = (user: typeof p1, result: "win" | "loss" | "draw") => {
    const totalWins = (user.stats?.totalWins ?? 0) + (result === "win" ? 1 : 0);
    const totalLosses =
      (user.stats?.totalLosses ?? 0) + (result === "loss" ? 1 : 0);
    const totalDraws =
      (user.stats?.totalDraws ?? 0) + (result === "draw" ? 1 : 0);

    const currentStreak =
      result === "win" ? (user.stats?.currentStreak ?? 0) + 1 : 0;
    const maxStreak = Math.max(user.stats?.maxStreak ?? 0, currentStreak);

    const currentLoseStreak =
      result === "loss" ? (user.stats?.currentLoseStreak ?? 0) + 1 : 0;

    return {
      totalWins,
      totalLosses,
      totalDraws,
      currentStreak,
      maxStreak,
      currentLoseStreak,
    };
  };

  const p1Next = nextStats(p1, p1Result);
  const p2Next = nextStats(p2, p2Result);

  const updated = await prisma.$transaction(async (tx) => {
    const updatedP1 = await tx.user.update({
      where: { id: p1.id },
      data: {
        rating: { increment: p1Delta },
        coins: { increment: p1CoinDelta },
        stats: {
          upsert: {
            create: p1Next,
            update: p1Next,
          },
        },
      },
      select: { id: true, rating: true, coins: true },
    });

    const updatedP2 = await tx.user.update({
      where: { id: p2.id },
      data: {
        rating: { increment: p2Delta },
        coins: { increment: p2CoinDelta },
        stats: {
          upsert: {
            create: p2Next,
            update: p2Next,
          },
        },
      },
      select: { id: true, rating: true, coins: true },
    });

    await tx.matchHistory.createMany({
      data: [
        { userId: p1.id, opponentId: p2.id, result: p1Result },
        { userId: p2.id, opponentId: p1.id, result: p2Result },
      ],
    });

    // 称号チェック（プレイヤー1）
    await checkRatingTitles(tx, p1.id, updatedP1.rating);
    await checkCoinsTitles(tx, p1.id, updatedP1.coins);
    await checkWinStreakTitles(tx, p1.id, p1Next.currentStreak);
    await checkLoseStreakTitles(tx, p1.id, p1Next.currentLoseStreak);
    await checkTotalWinsTitles(tx, p1.id, p1Next.totalWins);
    await checkWinRateTitles(tx, p1.id);

    // 称号チェック（プレイヤー2）
    await checkRatingTitles(tx, p2.id, updatedP2.rating);
    await checkCoinsTitles(tx, p2.id, updatedP2.coins);
    await checkWinStreakTitles(tx, p2.id, p2Next.currentStreak);
    await checkLoseStreakTitles(tx, p2.id, p2Next.currentLoseStreak);
    await checkTotalWinsTitles(tx, p2.id, p2Next.totalWins);
    await checkWinRateTitles(tx, p2.id);

    // るーず超越チェック（「ず」「る」「ー」全て取られて勝利）
    if (p1Result === "win") {
      const opponentCapturedChars = Array.from(session.player2CapturedChars);
      await checkLooseTranscenderTitle(tx, p1.id, true, opponentCapturedChars);
    }
    if (p2Result === "win") {
      const opponentCapturedChars = Array.from(session.player1CapturedChars);
      await checkLooseTranscenderTitle(tx, p2.id, true, opponentCapturedChars);
    }

    // ウィークリーミッション（対戦カウント）
    await incrementWeeklyBattleAndCheckBonus(tx, p1.id);
    await incrementWeeklyBattleAndCheckBonus(tx, p2.id);

    return { updatedP1, updatedP2 };
  });

  session.resultCommitted = true;
  await updatePvpSession(session);

  debugLog("committed", {
    updatedP1: updated.updatedP1,
    updatedP2: updated.updatedP2,
  });

  const viewerIsP1 = viewerUserId === session.player1Id;
  const user = viewerIsP1 ? updated.updatedP1 : updated.updatedP2;
  const opponent = viewerIsP1 ? updated.updatedP2 : updated.updatedP1;
  const userDelta = viewerIsP1 ? p1Delta : p2Delta;
  const opponentDelta = viewerIsP1 ? p2Delta : p1Delta;

  return {
    userId: user.id,
    opponentId: opponent.id,
    userRating: user.rating,
    opponentRating: opponent.rating,
    userDelta,
    opponentDelta,
  };
}

export default async function (fastify: ServerInstance) {
  fastify.post(
    "/start",
    {
      schema: {
        tags: ["PvP"],
        summary: "対人戦開始（PvPセッション作成）",
        body: pvpStartRequestSchema,
        response: {
          200: pvpStartResponseSchema,
          401: errorResponseSchema,
          403: errorResponseSchema,
          404: errorResponseSchema,
          503: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      if (!isDatabaseConfigured()) {
        return reply.status(503).send({
          message: "DATABASE_URL が未設定のため、このAPIは利用できません",
        });
      }

      if (!isRedisConfigured()) {
        return reply.status(503).send({
          message: "REDIS_URL が未設定のため、このAPIは利用できません",
        });
      }

      const token = getBearerToken(request);
      if (!token) return reply.status(401).send({ message: "認証が必要です" });

      const payload = verifyAuthToken({ token });
      if (!payload)
        return reply.status(401).send({ message: "認証が必要です" });

      const prisma = getPrisma();
      const me = await prisma.user.findUnique({
        where: { id: payload.userId },
        select: { id: true, isCheater: true, soulCount: true },
      });
      if (!me) return reply.status(401).send({ message: "認証が必要です" });
      if (me.isCheater)
        return reply
          .status(403)
          .send({ message: "このアカウントは利用できません" });

      if (me.soulCount < 1) {
        return reply.status(403).send({ message: "魂が足りません" });
      }

      const { opponentId } = request.body;
      if (opponentId === payload.userId) {
        return reply
          .status(403)
          .send({ message: "自分自身とは対戦できません" });
      }

      const opponent = await prisma.user.findUnique({
        where: { id: opponentId },
        include: {
          stats: true,
          equippedIcon: true,
          equippedMessage: true,
          equippedTitle1: true,
        },
      });

      if (!opponent)
        return reply.status(404).send({ message: "対戦相手が見つかりません" });
      if (opponent.isCheater)
        return reply
          .status(403)
          .send({ message: "そのユーザーとは対戦できません" });

      const stats =
        opponent.stats ??
        ({
          totalWins: 0,
          totalLosses: 0,
          totalDraws: 0,
          maxStreak: 0,
        } as const);

      const winRate = calcWinRate({
        totalWins: stats.totalWins,
        totalLosses: stats.totalLosses,
        totalDraws: stats.totalDraws,
      });

      const consumed = await prisma.user.updateMany({
        where: { id: me.id, soulCount: { gte: 1 } },
        data: {
          soulCount: { decrement: 1 },
          lastSoulUsedAt: new Date(),
        },
      });
      if (consumed.count !== 1) {
        return reply.status(403).send({ message: "魂が足りません" });
      }

      const session = await createPvpSession({
        player1Id: payload.userId,
        player2Id: opponent.id,
      });

      return reply.send({
        session: sessionToJson(session),
        opponent: {
          userId: opponent.id,
          name: opponent.name,
          icon: {
            id: opponent.equippedIcon.id,
            imageUrl: normalizeIconImageUrl(opponent.equippedIcon.imageUrl),
          },
          title: opponent.equippedTitle1
            ? {
                id: opponent.equippedTitle1.id,
                name: opponent.equippedTitle1.name,
              }
            : null,
          message: {
            id: opponent.equippedMessage.id,
            content: opponent.equippedMessage.content,
          },
          rating: opponent.isRatingPublic ? opponent.rating : null,
          totalWins: opponent.isWinCountPublic ? stats.totalWins : null,
          winRate: opponent.isWinRatePublic ? winRate : null,
          maxStreak: opponent.isStreakPublic ? stats.maxStreak : null,
        },
      });
    },
  );

  fastify.get(
    "/:sessionId",
    {
      schema: {
        tags: ["PvP"],
        summary: "PvPセッション状態取得",
        response: {
          200: pvpSessionResponseSchema,
          401: errorResponseSchema,
          403: errorResponseSchema,
          404: errorResponseSchema,
          503: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      if (!isDatabaseConfigured()) {
        return reply.status(503).send({
          message: "DATABASE_URL が未設定のため、このAPIは利用できません",
        });
      }

      if (!isRedisConfigured()) {
        return reply.status(503).send({
          message: "REDIS_URL が未設定のため、このAPIは利用できません",
        });
      }

      const token = getBearerToken(request);
      if (!token) return reply.status(401).send({ message: "認証が必要です" });

      const payload = verifyAuthToken({ token });
      if (!payload)
        return reply.status(401).send({ message: "認証が必要です" });

      const { sessionId } = request.params as { sessionId: string };
      const session = await getPvpSession(sessionId);
      if (!session)
        return reply
          .status(404)
          .send({ message: "セッションが見つかりません" });

      if (!isParticipant({ session, userId: payload.userId })) {
        return reply
          .status(403)
          .send({ message: "このセッションには参加していません" });
      }

      // クライアントがcheck-timeを叩けないまま離脱/復帰したケースでも、
      // セッション取得で時間切れ決着→レート/コイン反映が漏れないようにする。
      if (session.status === "playing" && isPvpTimeExpired(session)) {
        const loserId = session.currentTurnUserId;
        const winnerId = getOpponentId({ session, userId: loserId });

        session.turnCount++;
        session.history.push({
          turn: session.turnCount,
          playerId: loserId,
          word: "(時間切れ)",
          isValid: false,
          capturedChars: [],
          message: "時は金なり…汝は時を浪費した。敗北だ。",
        });

        session.status = session.player1Id === winnerId ? "p1_win" : "p2_win";
        await updatePvpSession(session);

        await commitRatedResultIfNeeded({
          session,
          winnerUserId: winnerId,
          viewerUserId: payload.userId,
        });
      }

      return reply.send({ session: sessionToJson(session) });
    },
  );

  fastify.post(
    "/:sessionId/submit",
    {
      schema: {
        tags: ["PvP"],
        summary: "PvP単語送信",
        body: pvpSubmitRequestSchema,
        response: {
          200: pvpSubmitResponseSchema,
          400: errorResponseSchema,
          401: errorResponseSchema,
          403: errorResponseSchema,
          404: errorResponseSchema,
          503: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      if (!isDatabaseConfigured()) {
        return reply.status(503).send({
          message: "DATABASE_URL が未設定のため、このAPIは利用できません",
        });
      }

      if (!isRedisConfigured()) {
        return reply.status(503).send({
          message: "REDIS_URL が未設定のため、このAPIは利用できません",
        });
      }

      const token = getBearerToken(request);
      if (!token) return reply.status(401).send({ message: "認証が必要です" });

      const payload = verifyAuthToken({ token });
      if (!payload)
        return reply.status(401).send({ message: "認証が必要です" });

      const { sessionId } = request.params as { sessionId: string };
      const session = await getPvpSession(sessionId);
      if (!session)
        return reply
          .status(404)
          .send({ message: "セッションが見つかりません" });

      if (!isParticipant({ session, userId: payload.userId })) {
        return reply
          .status(403)
          .send({ message: "このセッションには参加していません" });
      }

      if (session.status !== "playing") {
        const winnerUserId = computeWinnerUserId(session);
        const rated = await commitRatedResultIfNeeded({
          session,
          winnerUserId,
          viewerUserId: payload.userId,
        });
        return reply.send({
          session: sessionToJson(session),
          playerResult: {
            word: request.body.word,
            isValid: false,
            message: "ゲームは既に終了しています",
            capturedChars: [],
          },
          gameOver: true,
          winnerUserId,
          ...(rated ? { rated } : {}),
        });
      }

      if (session.currentTurnUserId !== payload.userId) {
        return reply
          .status(403)
          .send({ message: "あなたのターンではありません" });
      }

      // 制限時間チェック
      if (isPvpTimeExpired(session)) {
        const opponentId = getOpponentId({ session, userId: payload.userId });
        const message = "時は金なり…汝は時を浪費した。敗北だ。";

        session.turnCount++;
        session.history.push({
          turn: session.turnCount,
          playerId: payload.userId,
          word: "(時間切れ)",
          isValid: false,
          capturedChars: [],
          message,
        });

        session.status = session.player1Id === opponentId ? "p1_win" : "p2_win";
        await updatePvpSession(session);

        const winnerUserId = opponentId;
        const rated = await commitRatedResultIfNeeded({
          session,
          winnerUserId,
          viewerUserId: payload.userId,
        });

        return reply.send({
          session: sessionToJson(session),
          playerResult: {
            word: request.body.word,
            isValid: false,
            message,
            capturedChars: [],
            timeExpired: true,
          },
          gameOver: true,
          winnerUserId,
          ...(rated ? { rated } : {}),
        });
      }

      const word = request.body.word;

      const judge = judgeWord({
        word,
        expectedStartChar: session.expectedStartChar,
        opponentCapturedChars: getOpponentCapturedSet({
          session,
          userId: payload.userId,
        }),
        usedWords: session.usedWords,
        isInDictionary,
      });

      session.turnCount++;

      if (!judge.valid) {
        incrementMistakeCount({ session, userId: payload.userId });

        const message =
          judge.reason === "ends_with_n"
            ? "『ん』で終わった。禁忌だ。"
            : judge.reason === "captured_char"
              ? "相手の確保文字を使った。禁忌だ。"
              : judge.reason === "not_in_dictionary"
                ? "その単語は悪魔辞書に存在しない。"
                : judge.reason === "already_used"
                  ? "既に使われた単語だ。"
                  : "頭文字が違う。";

        session.history.push({
          turn: session.turnCount,
          playerId: payload.userId,
          word,
          isValid: false,
          capturedChars: [],
          message,
        });

        const mistakeCount = getMistakeCount({
          session,
          userId: payload.userId,
        });
        if (mistakeCount >= 2) {
          const winnerUserId = getOpponentId({
            session,
            userId: payload.userId,
          });
          session.status =
            session.player1Id === winnerUserId ? "p1_win" : "p2_win";
          await updatePvpSession(session);

          const rated = await commitRatedResultIfNeeded({
            session,
            winnerUserId,
            viewerUserId: payload.userId,
          });

          return reply.send({
            session: sessionToJson(session),
            playerResult: { word, isValid: false, message, capturedChars: [] },
            gameOver: true,
            winnerUserId,
            ...(rated ? { rated } : {}),
          });
        }

        await updatePvpSession(session);
        return reply.send({
          session: sessionToJson(session),
          playerResult: { word, isValid: false, message, capturedChars: [] },
          gameOver: false,
        });
      }

      // 有効な単語
      session.usedWords.add(word);
      const capturedChars = extractCharsToCapture(word);
      const myCaptured = getCapturedSet({ session, userId: payload.userId });
      const oppCaptured = getOpponentCapturedSet({
        session,
        userId: payload.userId,
      });

      for (const ch of capturedChars) {
        if (!myCaptured.has(ch) && !oppCaptured.has(ch)) {
          myCaptured.add(ch);
        }
      }

      session.lastWord = word;
      session.expectedStartChar = getNextStartChar(word);

      session.history.push({
        turn: session.turnCount,
        playerId: payload.userId,
        word,
        isValid: true,
        capturedChars,
        message: "OK",
      });

      // 手番交代 & タイマーリセット
      session.currentTurnUserId = getOpponentId({
        session,
        userId: payload.userId,
      });
      session.turnStartedAt = new Date();

      // ラウンド進行
      if (session.validTurnsInRound === 0) {
        session.validTurnsInRound = 1;
      } else {
        session.validTurnsInRound = 0;
        session.roundCount++;
      }

      // 10ラウンド終了判定（捕獲文字が少ない方が勝利）
      if (session.roundCount >= MAX_ROUNDS) {
        const p1Chars = session.player1CapturedChars.size;
        const p2Chars = session.player2CapturedChars.size;

        if (p1Chars < p2Chars) {
          session.status = "p1_win";
        } else if (p1Chars > p2Chars) {
          session.status = "p2_win";
        } else {
          session.status = "draw";
        }

        await updatePvpSession(session);

        const winnerUserId = computeWinnerUserId(session);
        const rated = await commitRatedResultIfNeeded({
          session,
          winnerUserId,
          viewerUserId: payload.userId,
        });

        return reply.send({
          session: sessionToJson(session),
          playerResult: { word, isValid: true, message: "OK", capturedChars },
          gameOver: true,
          winnerUserId,
          ...(rated ? { rated } : {}),
        });
      }

      await updatePvpSession(session);

      // AI偽装対戦: 次がAIのターンなら非同期で遅延処理をスケジュール
      // クライアントへは即座にレスポンスを返し、AIの応答はポーリングで取得
      scheduleAiTurnIfNeeded(session);

      return reply.send({
        session: sessionToJson(session),
        playerResult: { word, isValid: true, message: "OK", capturedChars },
        gameOver: false,
      });
    },
  );

  fastify.get(
    "/:sessionId/check-time",
    {
      schema: {
        tags: ["PvP"],
        summary: "PvP制限時間チェック",
        response: {
          200: pvpCheckTimeResponseSchema,
          401: errorResponseSchema,
          403: errorResponseSchema,
          404: errorResponseSchema,
          503: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      if (!isDatabaseConfigured()) {
        return reply.status(503).send({
          message: "DATABASE_URL が未設定のため、このAPIは利用できません",
        });
      }

      if (!isRedisConfigured()) {
        return reply.status(503).send({
          message: "REDIS_URL が未設定のため、このAPIは利用できません",
        });
      }

      const token = getBearerToken(request);
      if (!token) return reply.status(401).send({ message: "認証が必要です" });

      const payload = verifyAuthToken({ token });
      if (!payload)
        return reply.status(401).send({ message: "認証が必要です" });

      const { sessionId } = request.params as { sessionId: string };
      const session = await getPvpSession(sessionId);
      if (!session)
        return reply
          .status(404)
          .send({ message: "セッションが見つかりません" });

      if (!isParticipant({ session, userId: payload.userId })) {
        return reply
          .status(403)
          .send({ message: "このセッションには参加していません" });
      }

      if (session.status !== "playing") {
        return reply.send({ expired: false, session: sessionToJson(session) });
      }

      if (!isPvpTimeExpired(session)) {
        return reply.send({ expired: false, session: sessionToJson(session) });
      }

      const loserId = session.currentTurnUserId;
      const winnerId = getOpponentId({ session, userId: loserId });
      const loserMessage = "時は金なり…汝は時を浪費した。敗北だ。";
      const winnerMessage = "時は金なり…相手は時を浪費した。勝利だ。";
      const messageForViewer =
        payload.userId === loserId ? loserMessage : winnerMessage;

      session.turnCount++;
      session.history.push({
        turn: session.turnCount,
        playerId: loserId,
        word: "(時間切れ)",
        isValid: false,
        capturedChars: [],
        message: loserMessage,
      });

      session.status = session.player1Id === winnerId ? "p1_win" : "p2_win";
      await updatePvpSession(session);

      await commitRatedResultIfNeeded({
        session,
        winnerUserId: winnerId,
        viewerUserId: payload.userId,
      });

      return reply.send({
        expired: true,
        session: sessionToJson(session),
        message: messageForViewer,
      });
    },
  );
}
