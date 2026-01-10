import { z } from "zod";

/**
 * ユーザーモデルスキーマ
 */
export const userSchema = z.object({
  id: z.string(),
  email: z.email(),
  name: z.string().min(1).max(100),
  createdAt: z.coerce.date(),
  updatedAt: z.coerce.date(),
});

export type User = z.infer<typeof userSchema>;
