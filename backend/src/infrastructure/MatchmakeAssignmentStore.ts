import { getRedisClient, isRedisConfigured } from "./RedisClient";

export type MatchmakeAssignment = {
  sessionId: string;
  opponentId: string;
  assignedAt: string; // ISO
};

function key(userId: string): string {
  return `matchmake:assigned:${userId}`;
}

export function isMatchmakeRedisReady(): boolean {
  return isRedisConfigured();
}

export async function assignMatchToUser(params: {
  userId: string;
  sessionId: string;
  opponentId: string;
  ttlMs: number;
}): Promise<boolean> {
  if (!isRedisConfigured()) return false;

  const { userId, sessionId, opponentId, ttlMs } = params;
  const redis = await getRedisClient();

  const value: MatchmakeAssignment = {
    sessionId,
    opponentId,
    assignedAt: new Date().toISOString(),
  };

  const res = await redis.set(key(userId), JSON.stringify(value), {
    PX: ttlMs,
    NX: true,
  });

  return res === "OK";
}

export async function consumeAssignedMatch(params: {
  userId: string;
}): Promise<MatchmakeAssignment | null> {
  if (!isRedisConfigured()) return null;

  const redis = await getRedisClient();
  const raw = await redis.getDel(key(params.userId));
  if (!raw) return null;

  try {
    return JSON.parse(raw) as MatchmakeAssignment;
  } catch {
    return null;
  }
}
