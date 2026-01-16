import { z } from "zod";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const pvpStartRequestSchema = z.object({
  opponentId: z.string().min(1),
});

export const pvpTurnHistoryEntrySchema = z.object({
  turn: z.number().int(),
  playerId: z.string(),
  word: z.string(),
  isValid: z.boolean(),
  capturedChars: z.array(z.string()),
  message: z.string(),
});

export const pvpSessionSchema = z.object({
  id: z.string(),
  status: z.enum(["playing", "p1_win", "p2_win", "draw"]),

  player1Id: z.string(),
  player2Id: z.string(),
  currentTurnUserId: z.string(),

  player1MistakeCount: z.number().int(),
  player2MistakeCount: z.number().int(),

  player1CapturedChars: z.array(z.string()),
  player2CapturedChars: z.array(z.string()),

  lastWord: z.string().nullable(),
  expectedStartChar: z.string(),

  turnCount: z.number().int(),
  roundCount: z.number().int(),
  maxRounds: z.number().int(),

  history: z.array(pvpTurnHistoryEntrySchema),

  turnStartedAt: z.string(),
  remainingTimeMs: z.number().int(),
});

export const pvpOpponentSchema = z.object({
  userId: z.string(),
  name: z.string(),
  icon: z.object({
    id: z.string(),
    imageUrl: z.string(),
  }),
  title: z
    .object({
      id: z.string(),
      name: z.string(),
    })
    .nullable(),
  message: z.object({
    id: z.string(),
    content: z.string(),
  }),
  rating: z.number().int().nullable(),
  totalWins: z.number().int().nullable(),
  winRate: z.number().nullable(),
  maxStreak: z.number().int().nullable(),
});

export const pvpStartResponseSchema = z.object({
  session: pvpSessionSchema,
  opponent: pvpOpponentSchema,
});

export const pvpSessionResponseSchema = z.object({
  session: pvpSessionSchema,
});

export const pvpSubmitRequestSchema = z.object({
  word: z.string().min(1),
});

export const pvpSubmitResponseSchema = z.object({
  session: pvpSessionSchema,
  playerResult: z.object({
    word: z.string(),
    isValid: z.boolean(),
    message: z.string(),
    capturedChars: z.array(z.string()),
    timeExpired: z.boolean().optional(),
  }),
  gameOver: z.boolean(),
  winnerUserId: z.string().nullable().optional(),
  rated: z
    .object({
      userId: z.string(),
      opponentId: z.string(),
      userRating: z.number().int(),
      opponentRating: z.number().int(),
      userDelta: z.number().int(),
      opponentDelta: z.number().int(),
    })
    .optional(),
});

export const pvpCheckTimeResponseSchema = z.object({
  expired: z.boolean(),
  session: pvpSessionSchema.nullable(),
  message: z.string().optional(),
});

export type PvpStartRequest = z.infer<typeof pvpStartRequestSchema>;
export type PvpSubmitRequest = z.infer<typeof pvpSubmitRequestSchema>;
