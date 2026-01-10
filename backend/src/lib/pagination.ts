import { z } from "zod";

/**
 * ページネーションのクエリパラメータスキーマ
 */
export const paginationQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export type PaginationQuery = z.infer<typeof paginationQuerySchema>;

/**
 * ページネーション用のオフセット計算
 */
export function calculatePagination(params: { page: number; limit: number }): {
  skip: number;
  take: number;
} {
  const { page, limit } = params;
  return {
    skip: (page - 1) * limit,
    take: limit,
  };
}

/**
 * ページネーションレスポンスの構築
 */
export function buildPaginationResponse<T>(params: {
  data: T[];
  total: number;
  page: number;
  limit: number;
}): {
  data: T[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
} {
  const { data, total, page, limit } = params;
  const totalPages = Math.ceil(total / limit);

  return {
    data,
    pagination: {
      total,
      page,
      limit,
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1,
    },
  };
}

/**
 * ページネーションレスポンススキーマを生成
 */
export function createPaginatedResponseSchema<T extends z.ZodTypeAny>(
  itemSchema: T
) {
  return z.object({
    data: z.array(itemSchema),
    pagination: z.object({
      total: z.number(),
      page: z.number(),
      limit: z.number(),
      totalPages: z.number(),
      hasNext: z.boolean(),
      hasPrev: z.boolean(),
    }),
  });
}
