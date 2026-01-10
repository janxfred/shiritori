/**
 * ゲームコントローラー
 * 悪魔的しりとりのAPI エンドポイント
 */

import { checkTimeLimit, processTurn } from "../../application/ProcessTurnUseCase";
import { getRandomMessage } from "../../domain/constants/DemonMessages";
import type { AiLevel } from "../../domain/services/AiBrainService";
import { getDictionarySize } from "../../infrastructure/DictionaryRepository";
import {
  createSession,
  getSession,
  sessionToJson,
} from "../../infrastructure/GameSessionStore";
import { type ServerInstance } from "../../lib/fastify";
import {
  checkTimeResponseSchema,
  createGameRequestSchema,
  createGameResponseSchema,
  errorResponseSchema,
  gameStateResponseSchema,
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
        description: "新しい悪魔的しりとりゲームを開始します。AIレベルを指定できます（1: 初級, 2: 中級, 3: 上級）。",
        body: createGameRequestSchema,
        response: {
          201: createGameResponseSchema,
        },
      },
    },
    async (request, reply) => {
      const { aiLevel } = request.body;
      const session = createSession(aiLevel as AiLevel);
      const message = getRandomMessage("gameStart");

      return reply.status(201).send({
        session: sessionToJson(session),
        message,
        dictionarySize: getDictionarySize(),
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
        return reply.status(404).send({ message: "セッションが見つかりません" });
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
        return reply.status(404).send({ message: "セッションが見つかりません" });
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
        description: "プレイヤーの制限時間（2分）を超過しているかチェックします。",
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
        return reply.status(404).send({ message: "セッションが見つかりません" });
      }

      return reply.send({
        expired: result.expired,
        session: sessionToJson(result.session),
        message: result.expired ? "時は金なり…汝は時を浪費した。敗北だ。" : undefined,
      });
    }
  );
}
