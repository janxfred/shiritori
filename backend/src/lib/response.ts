import { z } from "zod";

/**
 * エラーレスポンススキーマ
 */
export const errorResponseSchema = z.object({
  message: z.string(),
  code: z.string().optional(),
});

export type ErrorResponse = z.infer<typeof errorResponseSchema>;

/**
 * 成功レスポンススキーマを生成
 */
export function createSuccessResponseSchema<T extends z.ZodTypeAny>(
  dataSchema: T
) {
  return z.object({
    success: z.literal(true),
    data: dataSchema,
  });
}

/**
 * 成功レスポンスを構築
 */
export function buildSuccessResponse<T>(params: { data: T }): {
  success: true;
  data: T;
} {
  return {
    success: true,
    data: params.data,
  };
}

/**
 * エラーレスポンスを構築
 * RORO原則: オブジェクトで受け取り、オブジェクトで返す
 */
export function buildErrorResponse(params: {
  message: string;
  code?: string;
}): ErrorResponse {
  return {
    message: params.message,
    code: params.code,
  };
}
