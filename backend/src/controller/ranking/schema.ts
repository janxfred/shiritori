import { z } from "zod";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const rankingQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

export const rankingItemSchema = z.object({
  rank: z.number().int().min(1),
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

  // Visibility flags are applied server-side.
  rating: z.number().int().nullable(),
  totalWins: z.number().int().nullable(),
  winRate: z.number().nullable(),
  maxStreak: z.number().int().nullable(),
});

export const getRankingResponseSchema = z.object({
  total: z.number().int().min(0),
  items: z.array(rankingItemSchema),
});

export type RankingQuery = z.infer<typeof rankingQuerySchema>;
