import { z } from "zod";

export const syncSubscriptionRequestSchema = z.object({
  isActive: z.boolean(),
});

export const syncSubscriptionResponseSchema = z.object({
  message: z.string(),
  isSubscriber: z.boolean(),
});

export const errorResponseSchema = z.object({
  message: z.string(),
});
