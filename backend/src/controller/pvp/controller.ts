import { getPrisma, isDatabaseConfigured } from "../../database";
import { verifyAuthToken } from "../../lib/auth";
import { type ServerInstance } from "../../lib/fastify";
import {
  extractCharsToCapture,
  getNextStartChar,
  judgeWord,
} from "../../domain/services/ShiritoriJudgeService";
import { isInDictionary } from "../../infrastructure/DictionaryRepository";
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

  if (session.resultCommitted) return undefined;

  // DB未設定ならレート対戦として成立しないため、ここで何もしない。
  if (!isDatabaseConfigured()) return undefined;

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

  const [p1, p2] = await Promise.all([
    prisma.user.findUnique({
      where: { id: session.player1Id },
      include: { stats: true },
    }),
    prisma.user.findUnique({
      where: { id: session.player2Id },
      include: { stats: true },
    }),
  ]);

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

    return {
      totalWins,
      totalLosses,
      totalDraws,
      currentStreak,
      maxStreak,
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
      select: { id: true, rating: true },
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
      select: { id: true, rating: true },
    });

    await tx.matchHistory.createMany({
      data: [
        { userId: p1.id, opponentId: p2.id, result: p1Result },
        { userId: p2.id, opponentId: p1.id, result: p2Result },
      ],
    });

    return { updatedP1, updatedP2 };
  });

  session.resultCommitted = true;
  await updatePvpSession(session);

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
        summary: "レート対戦開始（PvPセッション作成）",
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
        select: { id: true, isCheater: true },
      });
      if (!me) return reply.status(401).send({ message: "認証が必要です" });
      if (me.isCheater)
        return reply
          .status(403)
          .send({ message: "このアカウントは利用できません" });

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
    }
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

      return reply.send({ session: sessionToJson(session) });
    }
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
      return reply.send({
        session: sessionToJson(session),
        playerResult: { word, isValid: true, message: "OK", capturedChars },
        gameOver: false,
      });
    }
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
    }
  );
}
