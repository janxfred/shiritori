import { z } from "zod";

import { pvpSessionSchema } from "../pvp/schema";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const matchmakeRequestSchema = z.object({
  // 認証トークンから userId を特定するため、bodyは空を許容する。
});

export const matchmakeOpponentSchema = z.object({
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

export const matchmakeResponseSchema = z.object({
  session: pvpSessionSchema,
  opponent: matchmakeOpponentSchema,
});

export type MatchmakeRequest = z.infer<typeof matchmakeRequestSchema>;
