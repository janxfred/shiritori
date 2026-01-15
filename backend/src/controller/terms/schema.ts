import { z } from "zod";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const termsStatusResponseSchema = z.object({
  currentVersion: z.string(),
  agreed: z.boolean(),
  agreedAt: z.string().datetime().nullable(),
  agreedVersion: z.string().nullable(),
});

export const agreeTermsRequestSchema = z.object({
  // 将来バージョンを明示的に送らせたくなった場合のために受ける（現状は無視して currentVersion を採用）
  version: z.string().optional(),
});

export const agreeTermsResponseSchema = z.object({
  message: z.string(),
  currentVersion: z.string(),
  agreedAt: z.string().datetime(),
  agreedVersion: z.string(),
});
