import { z } from 'zod';
import { userSchema } from './user.schema';
import {
  paginationQuerySchema,
  createPaginatedResponseSchema,
} from '../pagination.schema';

// Request query schema
export const listUsersQuerySchema = paginationQuerySchema.extend({
  search: z.string().optional(),
});

export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;

// Response schema
export const listUsersResponseSchema = createPaginatedResponseSchema(userSchema);

export type ListUsersResponse = z.infer<typeof listUsersResponseSchema>;
