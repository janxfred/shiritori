import { z } from "zod";
import {
  createPaginatedResponseSchema,
  paginationQuerySchema,
} from "../../lib/pagination";

export const errorResponseSchema = z.object({
  message: z.string(),
});

export const userResponseSchema = z.object({
  id: z.string(),
  email: z.email(),
  name: z.string(),
  createdAt: z.string(),
  updatedAt: z.string(),
});

export type UserResponse = z.infer<typeof userResponseSchema>;

// GET /api/users
export const listUsersQuerySchema = paginationQuerySchema.extend({
  search: z.string().optional(),
});

export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;

export const listUsersResponseSchema =
  createPaginatedResponseSchema(userResponseSchema);

export const commandResponseSchema = z.object({
  message: z.string(),
});

// POST /api/users
export const createUserRequestSchema = z.object({
  email: z.email(),
  name: z.string().min(1).max(100),
});

export type CreateUserRequest = z.infer<typeof createUserRequestSchema>;
