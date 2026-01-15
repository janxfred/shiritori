import { z } from "zod";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const authUserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email().nullable(),
  iconId: z.string(),
  messageId: z.string(),
  title1Id: z.string().nullable(),
  title2Id: z.string().nullable(),
  title3Id: z.string().nullable(),
  level: z.number().int(),
  exp: z.number().int(),
  rating: z.number().int(),
  coins: z.number().int(),
  soulCount: z.number().int(),
  isSubscriber: z.boolean(),
  isRatingPublic: z.boolean(),
  isWinCountPublic: z.boolean(),
  isWinRatePublic: z.boolean(),
  isStreakPublic: z.boolean(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export const signupRequestSchema = z.object({
  name: z.string().min(1).max(100),
  password: z.string().min(6).max(128),
});

export const signupResponseSchema = z.object({
  message: z.string(),
  token: z.string(),
  user: authUserSchema,
});

export const loginRequestSchema = z.object({
  userId: z.string().min(1),
  password: z.string().min(1).max(128),
});

export const loginResponseSchema = z.object({
  message: z.string(),
  token: z.string(),
  user: authUserSchema,
});

export type SignupRequest = z.infer<typeof signupRequestSchema>;
export type LoginRequest = z.infer<typeof loginRequestSchema>;
