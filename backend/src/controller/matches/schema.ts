import { z } from "zod";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const matchResultSchema = z.enum(["win", "loss", "draw"]);

export const createMatchRequestSchema = z
  .object({
    userId: z.string().min(1),
    opponentId: z.string().min(1),
    result: matchResultSchema,
  })
  .strict();

export const createMatchResponseSchema = z.object({
  message: z.string(),
  ratingDelta: z.number().int(),
  user: z.object({
    id: z.string(),
    rating: z.number().int(),
    stats: z.object({
      totalWins: z.number().int(),
      totalLosses: z.number().int(),
      totalDraws: z.number().int(),
      currentStreak: z.number().int(),
      maxStreak: z.number().int(),
    }),
  }),
});

export type CreateMatchRequest = z.infer<typeof createMatchRequestSchema>;
