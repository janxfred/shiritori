/**
 * ゲームコントローラー
 * 悪魔的しりとりのAPI エンドポイント
 */

import {
  checkTimeLimit,
  processAiFirstTurn,
  processTurn,
} from "../../application/ProcessTurnUseCase";
import { getPrisma, isDatabaseConfigured } from "../../database";
import { getRandomMessage } from "../../domain/constants/DemonMessages";
import type { AiLevel } from "../../domain/services/AiBrainService";
import {
  checkAiMatchTitles,
  checkLoseStreakTitles,
  checkLooseTranscenderTitle,
  checkSoulEaterTitle,
  checkTotalWinsTitles,
  checkWinStreakTitles,
} from "../../domain/services/TitleAchievementService";
import { incrementWeeklyBattleAndCheckBonus } from "../../domain/services/WeeklyMissionService";
import { getDictionarySize } from "../../infrastructure/DictionaryRepository";
import {
  createSession,
  getSession,
  sessionToJson,
  updateSession,
} from "../../infrastructure/GameSessionStore";
import { verifyAuthToken } from "../../lib/auth";
import { type ServerInstance } from "../../lib/fastify";
import {
  checkTimeResponseSchema,
  createGameRequestSchema,
  createGameResponseSchema,
  errorResponseSchema,
  gameStateResponseSchema,
  lifecycleRequestSchema,
  lifecycleResponseSchema,
  recordAiMatchRequestSchema,
  recordAiMatchResponseSchema,
  sessionIdParamsSchema,
  submitWordRequestSchema,
  submitWordResponseSchema,
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

export default async function (fastify: ServerInstance) {
  /**
   * 新しいゲームを開始
   */
  fastify.post(
    "/start",
    {
      schema: {
        tags: ["Game"],
        summary: "ゲーム開始",
        description:
          "新しい悪魔的しりとりゲームを開始します。AIレベルを指定できます（1: 初級, 2: 中級, 3: 上級）。",
        body: createGameRequestSchema,
        response: {
          201: createGameResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { aiLevel } = request.body;
      const session = createSession(aiLevel as AiLevel);
      const startChar = session.expectedStartChar ?? undefined;
      const startCharText = startChar ?? "？";
      const firstTurn = session.currentTurn;

      // AI先攻の場合は最初にAIが応答
      if (firstTurn === "ai") {
        const aiFirstResult = processAiFirstTurn(session.id);
        if (aiFirstResult) {
          const message = `『${startCharText}』から始まるぞ。我が先攻だ！`;
          return reply.status(201).send({
            session: sessionToJson(aiFirstResult.session),
            message,
            dictionarySize: getDictionarySize(),
            startChar,
            firstTurn,
            aiFirstWord: aiFirstResult.aiResult,
          });
        }
      }

      const message = `『${startCharText}』から始まるぞ。汝が先攻だ！`;

      return reply.status(201).send({
        session: sessionToJson(session),
        message,
        dictionarySize: getDictionarySize(),
        startChar,
        firstTurn,
      });
    },
  );

  /**
   * ゲーム状態を取得
   */
  fastify.get(
    "/:sessionId",
    {
      schema: {
        tags: ["Game"],
        summary: "ゲーム状態取得",
        description: "現在のゲーム状態を取得します。",
        params: sessionIdParamsSchema,
        response: {
          200: gameStateResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { sessionId } = request.params;
      const session = getSession(sessionId);

      if (!session) {
        return reply
          .status(404)
          .send({ message: "セッションが見つかりません" });
      }

      return reply.send({
        session: sessionToJson(session),
      });
    },
  );

  /**
   * 単語を送信
   */
  fastify.post(
    "/:sessionId/submit",
    {
      schema: {
        tags: ["Game"],
        summary: "単語送信",
        description: "しりとりの単語を送信します。",
        params: sessionIdParamsSchema,
        body: submitWordRequestSchema,
        response: {
          200: submitWordResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { sessionId } = request.params;
      const { word } = request.body;

      const result = processTurn(sessionId, word);

      if (!result) {
        return reply
          .status(404)
          .send({ message: "セッションが見つかりません" });
      }

      return reply.send({
        session: sessionToJson(result.session),
        playerResult: result.playerResult,
        aiResult: result.aiResult,
        gameOver: result.gameOver,
        winner: result.winner,
      });
    },
  );

  /**
   * 制限時間をチェック
   */
  fastify.get(
    "/:sessionId/check-time",
    {
      schema: {
        tags: ["Game"],
        summary: "制限時間チェック",
        description:
          "プレイヤーの制限時間（40秒）を超過しているかチェックします。",
        params: sessionIdParamsSchema,
        response: {
          200: checkTimeResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { sessionId } = request.params;
      const result = checkTimeLimit(sessionId);

      if (!result.session) {
        return reply
          .status(404)
          .send({ message: "セッションが見つかりません" });
      }

      return reply.send({
        expired: result.expired,
        session: sessionToJson(result.session),
        message: result.expired
          ? "時は金なり…汝は時を浪費した。敗北だ。"
          : undefined,
      });
    },
  );

  /**
   * ライフサイクル（アンチチート）: 非アクティブ時間を通知
   * READMEv2.md: paused→resumed の delta >= 10秒 なら即敗北
   */
  fastify.post(
    "/:sessionId/lifecycle",
    {
      schema: {
        tags: ["Game"],
        summary: "ライフサイクル通知（アンチチート）",
        description:
          "アプリが非アクティブだった時間(ms)を通知します。inactiveMs >= 10000 の場合、即敗北（AI勝利）になります。",
        params: sessionIdParamsSchema,
        body: lifecycleRequestSchema,
        response: {
          200: lifecycleResponseSchema,
          404: errorResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { sessionId } = request.params;
      const { inactiveMs } = request.body;

      const session = getSession(sessionId);
      if (!session) {
        return reply
          .status(404)
          .send({ message: "セッションが見つかりません" });
      }

      // 既に終了している場合はそのまま返す
      if (session.status !== "playing") {
        return reply.send({
          session: sessionToJson(session),
          gameOver: true,
          winner: session.status === "player_win" ? "player" : "ai",
        });
      }

      // 非アクティブが10秒以上なら即敗北
      if (inactiveMs >= 10_000) {
        session.status = "ai_win";

        // 状態更新（残り時間計算を止めないため turnStartedAt はそのまま）
        const message = "戦意喪失…汝は魔界から目を逸らした。敗北だ。";

        // ログに残す（turn/history 形式は既存と合わせる）
        session.history.push({
          turn: session.turnCount + 1,
          player: "player",
          word: "(非アクティブ)",
          isValid: false,
          capturedChars: [],
          message,
        });

        updateSession(session);

        return reply.send({
          session: sessionToJson(session),
          gameOver: true,
          winner: "ai",
          message,
        });
      }

      return reply.send({
        session: sessionToJson(session),
        gameOver: false,
      });
    },
  );

  /**
   * AI対戦結果記録（称号チェック用）
   */
  fastify.post(
    "/record-ai-match",
    {
      schema: {
        tags: ["Game"],
        summary: "AI対戦結果記録",
        description: "AI対戦の結果を記録し、称号条件をチェックします。",
        body: recordAiMatchRequestSchema,
        response: {
          200: recordAiMatchResponseSchema,
          401: errorResponseSchema,
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

      const token = getBearerToken(request);
      if (!token) return reply.status(401).send({ message: "認証が必要です" });

      const payload = verifyAuthToken({ token });
      if (!payload)
        return reply.status(401).send({ message: "認証が必要です" });

      const { result, aiCapturedChars } = request.body as {
        result: "win" | "loss" | "draw";
        aiCapturedChars?: string[];
      };

      const prisma = getPrisma();

      const newTitles = await prisma.$transaction(async (tx) => {
        const user = await tx.user.findUnique({
          where: { id: payload.userId },
          include: { stats: true },
        });

        if (!user) throw new Error("UNAUTHORIZED");

        // 統計更新
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

        const aiMatchCount = (user.stats?.aiMatchCount ?? 0) + 1;

        await tx.userStats.upsert({
          where: { userId: user.id },
          update: {
            totalWins,
            totalLosses,
            totalDraws,
            currentStreak,
            maxStreak,
            currentLoseStreak,
            aiMatchCount,
          },
          create: {
            userId: user.id,
            totalWins,
            totalLosses,
            totalDraws,
            currentStreak,
            maxStreak,
            currentLoseStreak,
            aiMatchCount,
          },
        });

        const titles: Array<{
          titleId: string;
          titleName: string;
          description: string;
        }> = [];

        // 各種称号チェック
        const winStreakTitles = await checkWinStreakTitles(
          tx,
          user.id,
          currentStreak,
        );
        titles.push(...winStreakTitles);

        const loseStreakTitles = await checkLoseStreakTitles(
          tx,
          user.id,
          currentLoseStreak,
        );
        titles.push(...loseStreakTitles);

        const totalWinsTitles = await checkTotalWinsTitles(
          tx,
          user.id,
          totalWins,
        );
        titles.push(...totalWinsTitles);

        const aiMatchTitles = await checkAiMatchTitles(
          tx,
          user.id,
          aiMatchCount,
        );
        titles.push(...aiMatchTitles);

        // 魂が0になった場合のチェック
        const soulEaterTitles = await checkSoulEaterTitle(
          tx,
          user.id,
          user.soulCount,
        );
        titles.push(...soulEaterTitles);

        // るーず超越チェック
        if (result === "win" && aiCapturedChars) {
          const transcenderTitles = await checkLooseTranscenderTitle(
            tx,
            user.id,
            true,
            aiCapturedChars,
          );
          titles.push(...transcenderTitles);
        }

        // ウィークリーミッション（対戦カウント）
        await incrementWeeklyBattleAndCheckBonus(tx, user.id);

        return titles;
      });

      return reply.send({
        message: "AI対戦結果を記録しました",
        newTitles,
      });
    },
  );
}
