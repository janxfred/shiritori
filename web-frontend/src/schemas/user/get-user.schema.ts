import { z } from 'zod';
import { userSchema } from './user.schema';

// Params schema
export const getUserParamsSchema = z.object({
  userId: z.string(),
});

export type GetUserParams = z.infer<typeof getUserParamsSchema>;

// Response schema
export const getUserResponseSchema = userSchema;

export type GetUserResponse = z.infer<typeof getUserResponseSchema>;
