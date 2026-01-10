import { z } from 'zod';
import { commandResponseSchema } from './command-response.schema';

// Request body schema (for form validation)
export const createUserRequestSchema = z.object({
  email: z.string().min(1, 'メールアドレスは必須です').email('メールアドレスの形式が正しくありません'),
  name: z.string().min(1, '名前は必須です').max(100, '名前は100文字以内で入力してください'),
});

export type CreateUserRequest = z.infer<typeof createUserRequestSchema>;

// Response schema
export { commandResponseSchema };
