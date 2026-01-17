import { z } from "zod";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const statsSchema = z.object({
  totalWins: z.number().int(),
  totalLosses: z.number().int(),
  totalDraws: z.number().int(),
  currentStreak: z.number().int(),
  maxStreak: z.number().int(),
});

export const meSchema = z.object({
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

  stats: statsSchema.nullable(),

  // 直近の対戦結果から算出（未対戦なら null）
  lastRatingDelta: z.number().int().nullable(),
  lastMatchAt: z.string().nullable(),
});

export const getMeResponseSchema = z.object({
  user: meSchema,
});

export const updateMeRequestSchema = z
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
  .refine((v) => Object.keys(v).length > 0, {
    message: "更新内容がありません",
  });

export const updateMeResponseSchema = z.object({
  message: z.string(),
  user: meSchema,
});

export const rewardedAdResponseSchema = z.object({
  message: z.string(),
  user: meSchema,
});

export const inventoryItemSchema = z.object({
  id: z.string(),
  rarity: z.number().int(),
});

export const inventoryIconSchema = inventoryItemSchema.extend({
  imageUrl: z.string(),
});

export const inventoryMessageSchema = inventoryItemSchema.extend({
  content: z.string(),
});

export const inventoryTitleSchema = inventoryItemSchema.extend({
  name: z.string(),
  description: z.string(),
  condition: z.string(),
});

export const inventoryOwnedItemSchema = inventoryItemSchema.extend({
  name: z.string(),
  description: z.string(),
});

export const getInventoryResponseSchema = z.object({
  equipped: z.object({
    iconId: z.string(),
    messageId: z.string(),
    title1Id: z.string().nullable(),
    title2Id: z.string().nullable(),
    title3Id: z.string().nullable(),
  }),
  icons: z.array(inventoryIconSchema),
  messages: z.array(inventoryMessageSchema),
  titles: z.array(inventoryTitleSchema),
  items: z.array(inventoryOwnedItemSchema),
});

export const iconCatalogEntrySchema = z.object({
  id: z.string(),
  imageUrl: z.string(),
  rarity: z.number().int(),
  owned: z.boolean(),
});

export const getIconCatalogResponseSchema = z.object({
  icons: z.array(iconCatalogEntrySchema),
});

export const titleCatalogEntrySchema = z.object({
  id: z.string(),
  name: z.string(),
  condition: z.string(),
  owned: z.boolean(),
});

export const getTitleCatalogResponseSchema = z.object({
  titles: z.array(titleCatalogEntrySchema),
});
