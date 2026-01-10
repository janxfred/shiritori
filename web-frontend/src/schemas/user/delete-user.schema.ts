import { z } from 'zod';
import { commandResponseSchema } from './command-response.schema';

// Params schema
export const deleteUserParamsSchema = z.object({
  userId: z.string(),
});

export type DeleteUserParams = z.infer<typeof deleteUserParamsSchema>;

// Response schema
export { commandResponseSchema };
