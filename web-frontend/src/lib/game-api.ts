/**
 * ゲームAPI クライアント
 */

import { fetcher } from './fetcher';
import {
  checkTimeResponseSchema,
  createGameResponseSchema,
  gameStateResponseSchema,
  submitWordResponseSchema,
  type AiLevel,
  type CheckTimeResponse,
  type CreateGameResponse,
  type GameStateResponse,
  type SubmitWordResponse,
} from '@/schemas/game.schema';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3002';

/**
 * 新しいゲームを開始
 */
export async function startGame(aiLevel: AiLevel = 3): Promise<CreateGameResponse> {
  return fetcher(`${API_BASE_URL}/api/game/start`, createGameResponseSchema, {
    method: 'POST',
    body: { aiLevel },
  });
}

/**
 * ゲーム状態を取得
 */
export async function getGameState(sessionId: string): Promise<GameStateResponse> {
  return fetcher(
    `${API_BASE_URL}/api/game/${sessionId}`,
    gameStateResponseSchema
  );
}

/**
 * 単語を送信
 */
export async function submitWord(
  sessionId: string,
  word: string
): Promise<SubmitWordResponse> {
  return fetcher(
    `${API_BASE_URL}/api/game/${sessionId}/submit`,
    submitWordResponseSchema,
    {
      method: 'POST',
      body: { word },
    }
  );
}

/**
 * 制限時間をチェック
 */
export async function checkTime(sessionId: string): Promise<CheckTimeResponse> {
  return fetcher(
    `${API_BASE_URL}/api/game/${sessionId}/check-time`,
    checkTimeResponseSchema
  );
}
