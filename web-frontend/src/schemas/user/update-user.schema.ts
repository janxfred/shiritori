import { z } from 'zod';
import { commandResponseSchema } from './command-response.schema';

// Params schema
export const updateUserParamsSchema = z.object({
  userId: z.string(),
});

export type UpdateUserParams = z.infer<typeof updateUserParamsSchema>;

// Request body schema
export const updateUserRequestSchema = z.object({
  email: z.string().email('メールアドレスの形式が正しくありません').optional(),
  name: z
    .string()
    .min(1, '名前は必須です')
    .max(100, '名前は100文字以内で入力してください')
    .optional(),
});

export type UpdateUserRequest = z.infer<typeof updateUserRequestSchema>;

// Response schema
export { commandResponseSchema };
