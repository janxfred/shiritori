import { z } from "zod";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const commandResponseSchema = z.object({
  message: z.string(),
});

export const profileParamsSchema = z.object({
  userId: z.string(),
});

export const updateProfileRequestSchema = z
  .object({
    iconId: z.string().min(1).optional(),
    messageId: z.string().min(1).optional(),
    title1Id: z.string().min(1).nullable().optional(),
    title2Id: z.string().min(1).nullable().optional(),
    title3Id: z.string().min(1).nullable().optional(),

    isRatingPublic: z.boolean().optional(),
    isWinCountPublic: z.boolean().optional(),
    isWinRatePublic: z.boolean().optional(),
    isStreakPublic: z.boolean().optional(),
  })
  .strict();
