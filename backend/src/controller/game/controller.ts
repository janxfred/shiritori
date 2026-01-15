/**
 * ゲームコントローラー
 * 悪魔的しりとりのAPI エンドポイント
 */

import {
  checkTimeLimit,
  processAiFirstTurn,
  processTurn,
} from "../../application/ProcessTurnUseCase";
import { getRandomMessage } from "../../domain/constants/DemonMessages";
import type { AiLevel } from "../../domain/services/AiBrainService";
import { getDictionarySize } from "../../infrastructure/DictionaryRepository";
import {
  createSession,
  getSession,
  sessionToJson,
  updateSession,
} from "../../infrastructure/GameSessionStore";
import { type ServerInstance } from "../../lib/fastify";
import {
  checkTimeResponseSchema,
  createGameRequestSchema,
  createGameResponseSchema,
  errorResponseSchema,
  gameStateResponseSchema,
  lifecycleRequestSchema,
  lifecycleResponseSchema,
  sessionIdParamsSchema,
  submitWordRequestSchema,
  submitWordResponseSchema,
} from "./schema";

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
    }
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
    }
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
        overtimeStarted: result.overtimeStarted,
      });
    }
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
    }
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
    }
  );
}
