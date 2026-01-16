import { v4 as uuidv4 } from "uuid";

import { MAX_ROUNDS, TURN_TIME_LIMIT_MS } from "./GameSessionStore";
import { getRedisClient, isRedisConfigured } from "./RedisClient";

export type PvpSessionStatus = "playing" | "p1_win" | "p2_win" | "draw";

export interface PvpTurnHistoryEntry {
  turn: number;
  playerId: string;
  word: string;
  isValid: boolean;
  capturedChars: string[];
  message: string;
}

export interface PvpSession {
  id: string;
  status: PvpSessionStatus;

  player1Id: string;
  player2Id: string;

  currentTurnUserId: string;

  player1MistakeCount: number;
  player2MistakeCount: number;

  player1CapturedChars: Set<string>;
  player2CapturedChars: Set<string>;

  usedWords: Set<string>;
  lastWord: string | null;
  expectedStartChar: string;

  turnCount: number;
  /** ラウンド数（両者が有効手を1回ずつ = 1ラウンド） */
  roundCount: number;
  /** 現在ラウンドでの有効手数（0 or 1） */
  validTurnsInRound: 0 | 1;

  history: PvpTurnHistoryEntry[];

  createdAt: Date;
  turnStartedAt: Date;

  /** DBへレート反映済みか（重複更新防止） */
  resultCommitted: boolean;
}

const sessions = new Map<string, PvpSession>();

/** セッション有効期限（1時間） */
const SESSION_TTL_MS = 60 * 60 * 1000;

/** しりとりで使用可能なひらがな（開始文字用） */
const HIRAGANA_START_CHARS = [
  "あ",
  "い",
  "う",
  "え",
  "お",
  "か",
  "き",
  "く",
  "け",
  "こ",
  "さ",
  "し",
  "す",
  "せ",
  "そ",
  "た",
  "ち",
  "つ",
  "て",
  "と",
  "な",
  "に",
  "ぬ",
  "ね",
  "の",
  "は",
  "ひ",
  "ふ",
  "へ",
  "ほ",
  "ま",
  "み",
  "む",
  "め",
  "も",
  "や",
  "ゆ",
  "よ",
  "ら",
  "り",
  "る",
  "れ",
  "ろ",
  "わ",
] as const;

function cleanupOldSessions(): void {
  const now = Date.now();
  for (const [id, session] of sessions) {
    if (now - session.createdAt.getTime() > SESSION_TTL_MS) {
      sessions.delete(id);
    }
  }
}

type StoredPvpSession = {
  id: string;
  status: PvpSessionStatus;
  player1Id: string;
  player2Id: string;
  currentTurnUserId: string;
  player1MistakeCount: number;
  player2MistakeCount: number;
  player1CapturedChars: string[];
  player2CapturedChars: string[];
  usedWords: string[];
  lastWord: string | null;
  expectedStartChar: string;
  turnCount: number;
  roundCount: number;
  validTurnsInRound: 0 | 1;
  history: PvpTurnHistoryEntry[];
  createdAt: string;
  turnStartedAt: string;
  resultCommitted: boolean;
};

function redisKey(sessionId: string): string {
  return `pvp:session:${sessionId}`;
}

function toStored(session: PvpSession): StoredPvpSession {
  return {
    id: session.id,
    status: session.status,
    player1Id: session.player1Id,
    player2Id: session.player2Id,
    currentTurnUserId: session.currentTurnUserId,
    player1MistakeCount: session.player1MistakeCount,
    player2MistakeCount: session.player2MistakeCount,
    player1CapturedChars: Array.from(session.player1CapturedChars),
    player2CapturedChars: Array.from(session.player2CapturedChars),
    usedWords: Array.from(session.usedWords),
    lastWord: session.lastWord,
    expectedStartChar: session.expectedStartChar,
    turnCount: session.turnCount,
    roundCount: session.roundCount,
    validTurnsInRound: session.validTurnsInRound,
    history: session.history,
    createdAt: session.createdAt.toISOString(),
    turnStartedAt: session.turnStartedAt.toISOString(),
    resultCommitted: session.resultCommitted,
  };
}

function fromStored(stored: StoredPvpSession): PvpSession {
  return {
    id: stored.id,
    status: stored.status,
    player1Id: stored.player1Id,
    player2Id: stored.player2Id,
    currentTurnUserId: stored.currentTurnUserId,
    player1MistakeCount: stored.player1MistakeCount,
    player2MistakeCount: stored.player2MistakeCount,
    player1CapturedChars: new Set(stored.player1CapturedChars),
    player2CapturedChars: new Set(stored.player2CapturedChars),
    usedWords: new Set(stored.usedWords),
    lastWord: stored.lastWord,
    expectedStartChar: stored.expectedStartChar,
    turnCount: stored.turnCount,
    roundCount: stored.roundCount,
    validTurnsInRound: stored.validTurnsInRound,
    history: stored.history,
    createdAt: new Date(stored.createdAt),
    turnStartedAt: new Date(stored.turnStartedAt),
    resultCommitted: stored.resultCommitted,
  };
}

async function saveToRedis(session: PvpSession): Promise<void> {
  if (!isRedisConfigured()) return;
  const redis = await getRedisClient();
  await redis.set(redisKey(session.id), JSON.stringify(toStored(session)), {
    PX: SESSION_TTL_MS,
  });
}

async function loadFromRedis(sessionId: string): Promise<PvpSession | null> {
  if (!isRedisConfigured()) return null;
  const redis = await getRedisClient();
  const raw = await redis.get(redisKey(sessionId));
  if (!raw) return null;
  const stored = JSON.parse(raw) as StoredPvpSession;
  return fromStored(stored);
}

export async function createPvpSession(params: {
  player1Id: string;
  player2Id: string;
}): Promise<PvpSession> {
  const { player1Id, player2Id } = params;

  const now = new Date();
  const startChar =
    HIRAGANA_START_CHARS[
      Math.floor(Math.random() * HIRAGANA_START_CHARS.length)
    ];

  const currentTurnUserId = Math.random() < 0.5 ? player1Id : player2Id;

  const session: PvpSession = {
    id: uuidv4(),
    status: "playing",
    player1Id,
    player2Id,
    currentTurnUserId,
    player1MistakeCount: 0,
    player2MistakeCount: 0,
    player1CapturedChars: new Set(),
    player2CapturedChars: new Set(),
    usedWords: new Set(),
    lastWord: null,
    expectedStartChar: startChar,
    turnCount: 0,
    roundCount: 0,
    validTurnsInRound: 0,
    history: [],
    createdAt: now,
    turnStartedAt: now,
    resultCommitted: false,
  };

  sessions.set(session.id, session);
  cleanupOldSessions();

  await saveToRedis(session);

  return session;
}

export async function getPvpSession(
  sessionId: string
): Promise<PvpSession | null> {
  const cached = sessions.get(sessionId) ?? null;
  if (cached) return cached;

  const loaded = await loadFromRedis(sessionId);
  if (loaded) {
    sessions.set(sessionId, loaded);
    cleanupOldSessions();
  }
  return loaded;
}

export async function updatePvpSession(session: PvpSession): Promise<void> {
  sessions.set(session.id, session);
  await saveToRedis(session);
}

export function isPvpTimeExpired(session: PvpSession): boolean {
  const now = Date.now();
  const elapsed = now - session.turnStartedAt.getTime();
  return elapsed > TURN_TIME_LIMIT_MS;
}

export function getPvpRemainingTime(session: PvpSession): number {
  const now = Date.now();
  const elapsed = now - session.turnStartedAt.getTime();
  return Math.max(0, TURN_TIME_LIMIT_MS - elapsed);
}

export function isParticipant(params: {
  session: PvpSession;
  userId: string;
}): boolean {
  const { session, userId } = params;
  return session.player1Id === userId || session.player2Id === userId;
}

export function getOpponentId(params: {
  session: PvpSession;
  userId: string;
}): string {
  const { session, userId } = params;
  return session.player1Id === userId ? session.player2Id : session.player1Id;
}

export function sessionToJson(session: PvpSession) {
  return {
    id: session.id,
    status: session.status,
    player1Id: session.player1Id,
    player2Id: session.player2Id,
    currentTurnUserId: session.currentTurnUserId,
    player1MistakeCount: session.player1MistakeCount,
    player2MistakeCount: session.player2MistakeCount,
    player1CapturedChars: Array.from(session.player1CapturedChars),
    player2CapturedChars: Array.from(session.player2CapturedChars),
    lastWord: session.lastWord,
    expectedStartChar: session.expectedStartChar,
    turnCount: session.turnCount,
    roundCount: session.roundCount,
    maxRounds: MAX_ROUNDS,
    history: session.history,
    turnStartedAt: session.turnStartedAt.toISOString(),
    remainingTimeMs: getPvpRemainingTime(session),
  };
}
