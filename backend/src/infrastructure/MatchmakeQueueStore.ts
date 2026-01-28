import { getRedisClient, isRedisConfigured } from "./RedisClient";

/**
 * マッチング待機キュー管理
 * ユーザーがマッチング画面にいる間、キューに登録される
 * キューに登録されているユーザー同士のみがマッチング可能
 */

const QUEUE_KEY = "matchmake:queue";
const USER_KEY_PREFIX = "matchmake:queue:user:";
const DEFAULT_TTL_MS = 30000; // 30秒（フロントが1秒ごとにリクエストするため、十分な余裕を持たせる）

export interface QueueEntry {
  userId: string;
  rating: number;
  joinedAt: string; // ISO
}

/**
 * マッチング待機キューに参加
 * @returns 参加成功時はtrue
 */
export async function joinMatchmakeQueue(params: {
  userId: string;
  rating: number;
  ttlMs?: number;
}): Promise<boolean> {
  if (!isRedisConfigured()) return false;

  const { userId, rating, ttlMs = DEFAULT_TTL_MS } = params;
  const redis = await getRedisClient();

  const entry: QueueEntry = {
    userId,
    rating,
    joinedAt: new Date().toISOString(),
  };

  // 個別ユーザーキーに保存（TTL付き）
  await redis.set(USER_KEY_PREFIX + userId, JSON.stringify(entry), {
    PX: ttlMs,
  });

  // Sorted Setにも追加（スコア=rating、後でレート範囲検索に使用）
  await redis.zAdd(QUEUE_KEY, { score: rating, value: userId });

  return true;
}

/**
 * マッチング待機キューから離脱
 */
export async function leaveMatchmakeQueue(userId: string): Promise<void> {
  if (!isRedisConfigured()) return;

  const redis = await getRedisClient();

  await redis.del(USER_KEY_PREFIX + userId);
  await redis.zRem(QUEUE_KEY, userId);
}

/**
 * ユーザーがキューに参加しているかチェック
 */
export async function isInMatchmakeQueue(userId: string): Promise<boolean> {
  if (!isRedisConfigured()) return false;

  const redis = await getRedisClient();
  const raw = await redis.get(USER_KEY_PREFIX + userId);

  return raw !== null;
}

/**
 * キュー内でマッチング可能な相手を検索
 * @param userId 自分のユーザーID（除外対象）
 * @param rating 自分のレート
 * @param ratingRange レート許容範囲（±100など）
 * @returns マッチング可能なユーザーIDのリスト（自分を除く、TTL有効なもののみ）
 */
export async function findMatchCandidatesInQueue(params: {
  userId: string;
  rating: number;
  ratingRange?: number;
}): Promise<string[]> {
  if (!isRedisConfigured()) return [];

  const { userId, rating, ratingRange = 100 } = params;
  const redis = await getRedisClient();

  const minRating = rating - ratingRange;
  const maxRating = rating + ratingRange;

  // レート範囲内のユーザーをSorted Setから取得
  const candidates = await redis.zRangeByScore(QUEUE_KEY, minRating, maxRating);

  // 自分を除外し、TTLが有効なユーザーのみフィルタ
  const validCandidates: string[] = [];

  for (const candidateId of candidates) {
    if (candidateId === userId) continue;

    // 個別キーの存在確認（TTL切れチェック）
    const exists = await redis.exists(USER_KEY_PREFIX + candidateId);
    if (exists) {
      validCandidates.push(candidateId);
    } else {
      // TTL切れのエントリはSorted Setからも削除
      await redis.zRem(QUEUE_KEY, candidateId);
    }
  }

  return validCandidates;
}

/**
 * キューから特定のユーザーを削除（マッチング成立時に両者を削除）
 */
export async function removeFromQueue(userIds: string[]): Promise<void> {
  if (!isRedisConfigured()) return;
  if (userIds.length === 0) return;

  const redis = await getRedisClient();

  // 個別キーを削除
  await redis.del(userIds.map((id) => USER_KEY_PREFIX + id));

  // Sorted Setからも削除
  await redis.zRem(QUEUE_KEY, userIds);
}
