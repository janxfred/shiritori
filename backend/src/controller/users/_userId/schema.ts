import { z } from "zod";

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

// GET /api/users/:userId
export const getUserParamsSchema = z.object({
  userId: z.string(),
});

export type GetUserParams = z.infer<typeof getUserParamsSchema>;

export const getUserResponseSchema = userResponseSchema;

// PUT /api/users/:userId
export const updateUserParamsSchema = z.object({
  userId: z.string(),
});

export type UpdateUserParams = z.infer<typeof updateUserParamsSchema>;

export const updateUserRequestSchema = z.object({
  email: z.email().optional(),
  name: z.string().min(1).max(100).optional(),
});

export type UpdateUserRequest = z.infer<typeof updateUserRequestSchema>;

// DELETE /api/users/:userId
export const deleteUserParamsSchema = z.object({
  userId: z.string(),
});

export type DeleteUserParams = z.infer<typeof deleteUserParamsSchema>;

export const commandResponseSchema = z.object({
  message: z.string(),
});
