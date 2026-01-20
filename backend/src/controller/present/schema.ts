import { z } from "zod";

export const presentItemSchema = z.object({
  id: z.string(),
  type: z.enum(["coin", "title", "message", "icon", "item"]),
  targetId: z.string().nullable(),
  amount: z.number(),
  description: z.string(),
  claimed: z.boolean(),
  createdAt: z.string(),
  expiresAt: z.string().nullable(),
});

export const presentListResponseSchema = z.object({
  presents: z.array(presentItemSchema),
  unclaimedCount: z.number(),
});

export const claimPresentRequestSchema = z.object({
  presentId: z.string(),
});

export const claimPresentResponseSchema = z.object({
  message: z.string(),
  reward: z.object({
    type: z.string(),
    targetId: z.string().nullable(),
    amount: z.number(),
    description: z.string(),
  }),
});

export const claimAllPresentsResponseSchema = z.object({
  message: z.string(),
  claimedCount: z.number(),
  rewards: z.array(
    z.object({
      type: z.string(),
      targetId: z.string().nullable(),
      amount: z.number(),
      description: z.string(),
    })
  ),
});

export const errorResponseSchema = z.object({
  message: z.string(),
});
