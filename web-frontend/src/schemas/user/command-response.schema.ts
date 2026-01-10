import { z } from 'zod';

export const commandResponseSchema = z.object({
  message: z.string(),
});

export type CommandResponse = z.infer<typeof commandResponseSchema>;
