/**
 * ゲームAPIのスキーマ定義
 */

import { z } from 'zod';

/** AIレベル */
export const aiLevelSchema = z.union([z.literal(1), z.literal(2), z.literal(3)]);
export type AiLevel = z.infer<typeof aiLevelSchema>;

/** ターン履歴エントリ */
export const turnHistoryEntrySchema = z.object({
  turn: z.number(),
  player: z.enum(['player', 'ai']),
  word: z.string(),
  isValid: z.boolean(),
  capturedChars: z.array(z.string()),
  message: z.string(),
});

export type TurnHistoryEntry = z.infer<typeof turnHistoryEntrySchema>;

/** セッション情報 */
export const sessionSchema = z.object({
  id: z.string(),
  status: z.enum(['playing', 'player_win', 'ai_win', 'draw']),
  currentTurn: z.enum(['player', 'ai']),
  playerMistakeCount: z.number(),
  aiMistakeCount: z.number(),
  playerCapturedChars: z.array(z.string()),
  aiCapturedChars: z.array(z.string()),
  lastWord: z.string().nullable(),
  expectedStartChar: z.string().nullable(),
  turnCount: z.number(),
  roundCount: z.number(),
  maxRounds: z.number(),
  history: z.array(turnHistoryEntrySchema),
  aiLevel: aiLevelSchema,
  turnStartedAt: z.string(),
  remainingTimeMs: z.number(),
  isOvertime: z.boolean(),
});

export type GameSession = z.infer<typeof sessionSchema>;

/** ゲーム開始レスポンス */
export const createGameResponseSchema = z.object({
  session: sessionSchema,
  message: z.string(),
  dictionarySize: z.number(),
});

export type CreateGameResponse = z.infer<typeof createGameResponseSchema>;

/** ゲーム状態レスポンス */
export const gameStateResponseSchema = z.object({
  session: sessionSchema,
});

export type GameStateResponse = z.infer<typeof gameStateResponseSchema>;

/** ターン結果 */
export const turnResultSchema = z.object({
  word: z.string(),
  isValid: z.boolean(),
  message: z.string(),
  capturedChars: z.array(z.string()),
  timeExpired: z.boolean().optional(),
});

export type TurnResult = z.infer<typeof turnResultSchema>;

/** 単語送信レスポンス */
export const submitWordResponseSchema = z.object({
  session: sessionSchema,
  playerResult: turnResultSchema,
  aiResult: turnResultSchema.optional(),
  gameOver: z.boolean(),
  winner: z.enum(['player', 'ai']).optional(),
  overtimeStarted: z.boolean().optional(),
});

export type SubmitWordResponse = z.infer<typeof submitWordResponseSchema>;

/** 時間チェックレスポンス */
export const checkTimeResponseSchema = z.object({
  expired: z.boolean(),
  session: sessionSchema.nullable(),
  message: z.string().optional(),
});

export type CheckTimeResponse = z.infer<typeof checkTimeResponseSchema>;
