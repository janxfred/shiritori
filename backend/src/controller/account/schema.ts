import { z } from "zod";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const linkEmailRequestSchema = z.object({
  userId: z.string().min(1),
  password: z.string().min(1).max(128),
  email: z.string().email(),
});

export const linkEmailResponseSchema = z.object({
  message: z.string(),
  coins: z.number().int().optional(),
  rewarded: z.boolean().optional(),
});

export const getEmailStatusResponseSchema = z.object({
  email: z.string().email().nullable(),
  linkedAt: z.string().datetime().nullable(),
  rewardCoins: z.number().int(),
  rewarded: z.boolean(),
});

export const setEmailRequestSchema = z.object({
  email: z.string().email(),
});

export const setEmailResponseSchema = z.object({
  message: z.string(),
  email: z.string().email(),
  linkedAt: z.string().datetime(),
  coins: z.number().int(),
  rewarded: z.boolean(),
});

export const unlinkEmailResponseSchema = z.object({
  message: z.string(),
  email: z.null(),
  linkedAt: z.string().datetime().nullable(),
  rewardCoins: z.number().int(),
  rewarded: z.boolean(),
});
