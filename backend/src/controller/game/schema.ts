/**
 * ゲームAPIのスキーマ定義
 */

import { z } from "zod";

/** セッションIDパラメータ */
export const sessionIdParamsSchema = z.object({
  sessionId: z.string(),
});

/** AIレベル */
export const aiLevelSchema = z.union([z.literal(1), z.literal(2), z.literal(3)]);

/** ターン履歴エントリ */
const turnHistoryEntrySchema = z.object({
  turn: z.number(),
  player: z.enum(["player", "ai"]),
  word: z.string(),
  isValid: z.boolean(),
  capturedChars: z.array(z.string()),
  message: z.string(),
});

/** セッション情報 */
const sessionSchema = z.object({
  id: z.string(),
  status: z.enum(["playing", "player_win", "ai_win", "draw"]),
  currentTurn: z.enum(["player", "ai"]),
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

/** ゲーム開始リクエスト */
export const createGameRequestSchema = z.object({
  aiLevel: aiLevelSchema.optional().default(3),
});

/** ターン結果 */
const turnResultSchema = z.object({
  word: z.string(),
  isValid: z.boolean(),
  message: z.string(),
  capturedChars: z.array(z.string()),
  timeExpired: z.boolean().optional(),
});

/** ゲーム開始レスポンス */
export const createGameResponseSchema = z.object({
  session: sessionSchema,
  message: z.string(),
  dictionarySize: z.number(),
  startChar: z.string().optional(),
  firstTurn: z.enum(["player", "ai"]).optional(),
  aiFirstWord: turnResultSchema.optional(),
});

/** ゲーム状態レスポンス */
export const gameStateResponseSchema = z.object({
  session: sessionSchema,
});

/** 単語送信リクエスト */
export const submitWordRequestSchema = z.object({
  word: z.string().min(1, "単語を入力してください"),
});

/** 単語送信レスポンス */
export const submitWordResponseSchema = z.object({
  session: sessionSchema,
  playerResult: turnResultSchema,
  aiResult: turnResultSchema.optional(),
  gameOver: z.boolean(),
  winner: z.enum(["player", "ai"]).optional(),
  overtimeStarted: z.boolean().optional(),
});

/** 時間チェックレスポンス */
export const checkTimeResponseSchema = z.object({
  expired: z.boolean(),
  session: sessionSchema.nullable(),
  message: z.string().optional(),
});

/** エラーレスポンス */
export const errorResponseSchema = z.object({
  message: z.string(),
});
