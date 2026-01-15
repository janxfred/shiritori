import { z } from "zod";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const gachaStatusResponseSchema = z.object({
  cost: z.number().int(),
  coins: z.number().int(),
});

export const gachaRewardSchema = z.discriminatedUnion("type", [
  z.object({
    type: z.literal("icon"),
    id: z.string(),
    imageUrl: z.string(),
    rarity: z.number().int(),
  }),
  z.object({
    type: z.literal("message"),
    id: z.string(),
    content: z.string(),
    rarity: z.number().int(),
  }),
  z.object({
    type: z.literal("title"),
    id: z.string(),
    name: z.string(),
    description: z.string(),
    condition: z.string(),
  }),
  z.object({
    type: z.literal("item"),
    id: z.string(),
    name: z.string(),
    description: z.string(),
    rarity: z.number().int(),
  }),
]);

export const gachaDrawResponseSchema = z.object({
  message: z.string(),
  coins: z.number().int(),
  reward: gachaRewardSchema,
});
