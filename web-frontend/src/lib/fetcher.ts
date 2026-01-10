import { z } from 'zod';
import { ApiError } from './api-error';
import { errorResponseSchema } from '@/schemas/error-response.schema';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

type FetchOptions = {
  method?: string;
  headers?: Record<string, string>;
  body?: object;
};

/**
 * Base fetcher for direct fetch calls (non-SWR)
 * Validates response with Zod schema
 */
export async function fetcher<T>(
  path: string,
  schema: z.Schema<T>,
  options?: FetchOptions
): Promise<T> {
  const url = new URL(path, API_BASE_URL);

  const fetchOptions: RequestInit = {
    method: options?.method,
    headers: options?.headers,
  };

  if (options?.body) {
    fetchOptions.headers = {
      'Content-Type': 'application/json',
      ...fetchOptions.headers,
    };
    fetchOptions.body = JSON.stringify(options.body);
  }

  const response = await fetch(url.toString(), fetchOptions);

  if (!response.ok) {
    const errorJson = await response.json().catch(() => ({}));
    const parsed = errorResponseSchema.safeParse(errorJson);

    if (parsed.success) {
      throw new ApiError(parsed.data.message, response.status);
    }

    throw new ApiError(`Request failed (HTTP ${response.status})`, response.status);
  }

  // 204 No Content の場合は空オブジェクトを返す
  if (response.status === 204) {
    return schema.parse({});
  }

  const json = await response.json();

  const result = schema.safeParse(json);
  if (!result.success) {
    console.error('Response validation failed:', result.error);
    throw new Error('Response does not match expected schema');
  }

  return result.data;
}

/**
 * SWR fetcher factory - creates a fetcher function for useSWR
 * Validates response with Zod schema
 */
export function createSwrFetcher<T>(schema: z.Schema<T>) {
  return async (path: string): Promise<T> => {
    return fetcher(path, schema);
  };
}
