/**
 * ゲームAPIのスキーマ定義
 */

import { z } from "zod";

/** セッションIDパラメータ */
export const sessionIdParamsSchema = z.object({
  sessionId: z.string(),
});

/** AIレベル */
export const aiLevelSchema = z.union([
  z.literal(1),
  z.literal(2),
  z.literal(3),
]);

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
});

/** ライフサイクル（非アクティブ時間通知）リクエスト */
export const lifecycleRequestSchema = z
  .object({
    inactiveMs: z.coerce.number().int().min(0),
  })
  .strict();

/** ライフサイクル（非アクティブ時間通知）レスポンス */
export const lifecycleResponseSchema = z.object({
  session: sessionSchema,
  gameOver: z.boolean(),
  winner: z.enum(["player", "ai"]).optional(),
  message: z.string().optional(),
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

/** AI対戦結果記録リクエスト */
export const recordAiMatchRequestSchema = z.object({
  result: z.enum(["win", "loss", "draw"]),
  aiLevel: aiLevelSchema,
  aiCapturedChars: z.array(z.string()).optional(),
});

/** AI対戦結果記録レスポンス */
export const recordAiMatchResponseSchema = z.object({
  message: z.string(),
  newTitles: z.array(
    z.object({
      titleId: z.string(),
      titleName: z.string(),
      description: z.string(),
    })
  ),
});
