/**
 * ゲームセッションストア
 * メモリ上でゲーム状態を管理（セッションベース）
 */

import { v4 as uuidv4 } from "uuid";
import type { AiLevel } from "../domain/services/AiBrainService";

/** 回答制限時間（ミリ秒）: 2分 */
export const TURN_TIME_LIMIT_MS = 2 * 60 * 1000;

/** 最大ラウンド数 */
export const MAX_ROUNDS = 10;

export interface GameSession {
  id: string;
  status: "playing" | "player_win" | "ai_win" | "draw";
  currentTurn: "player" | "ai";
  playerMistakeCount: number;
  aiMistakeCount: number;
  playerCapturedChars: Set<string>;
  aiCapturedChars: Set<string>;
  usedWords: Set<string>;
  lastWord: string | null;
  expectedStartChar: string | null;
  turnCount: number;
  /** ラウンド数（プレイヤーとAIが1回ずつ = 1ラウンド） */
  roundCount: number;
  history: TurnHistoryEntry[];
  createdAt: Date;
  /** AIのレベル (1-3) */
  aiLevel: AiLevel;
  /** 現在のターン開始時刻 */
  turnStartedAt: Date;
  /** 延長戦フラグ */
  isOvertime: boolean;
  /** 延長戦開始時のプレイヤー確保文字数 */
  overtimePlayerCharsAtStart: number;
  /** 延長戦開始時のAI確保文字数 */
  overtimeAiCharsAtStart: number;
}

export interface TurnHistoryEntry {
  turn: number;
  player: "player" | "ai";
  word: string;
  isValid: boolean;
  capturedChars: string[];
  message: string;
}

/** セッションストア */
const sessions = new Map<string, GameSession>();

/** セッション有効期限（1時間） */
const SESSION_TTL_MS = 60 * 60 * 1000;

/**
 * 新しいゲームセッションを作成
 * @param aiLevel AIのレベル
 * @param firstTurn 先攻（指定しない場合はランダム）
 * @param startChar 開始文字（指定しない場合はランダム）
 */
export function createSession(
  aiLevel: AiLevel = 3,
  firstTurn?: "player" | "ai",
  startChar?: string
): GameSession {
  const now = new Date();
  
  // 先攻をランダムに決定（指定がない場合）
  const currentTurn = firstTurn ?? (Math.random() < 0.5 ? "player" : "ai");
  
  const session: GameSession = {
    id: uuidv4(),
    status: "playing",
    currentTurn,
    playerMistakeCount: 0,
    aiMistakeCount: 0,
    playerCapturedChars: new Set(),
    aiCapturedChars: new Set(),
    usedWords: new Set(),
    lastWord: null,
    expectedStartChar: startChar ?? null, // 開始文字は後でセット
    turnCount: 0,
    roundCount: 0,
    history: [],
    createdAt: now,
    aiLevel,
    turnStartedAt: now,
    isOvertime: false,
    overtimePlayerCharsAtStart: 0,
    overtimeAiCharsAtStart: 0,
  };

  sessions.set(session.id, session);
  cleanupOldSessions();

  return session;
}

/**
 * セッションを取得
 */
export function getSession(sessionId: string): GameSession | null {
  return sessions.get(sessionId) ?? null;
}

/**
 * セッションを更新
 */
export function updateSession(session: GameSession): void {
  sessions.set(session.id, session);
}

/**
 * セッションを削除
 */
export function deleteSession(sessionId: string): void {
  sessions.delete(sessionId);
}

/**
 * 古いセッションをクリーンアップ
 */
function cleanupOldSessions(): void {
  const now = Date.now();
  for (const [id, session] of sessions) {
    if (now - session.createdAt.getTime() > SESSION_TTL_MS) {
      sessions.delete(id);
    }
  }
}

/**
 * 制限時間を超過しているかチェック
 */
export function isTimeExpired(session: GameSession): boolean {
  const now = Date.now();
  const elapsed = now - session.turnStartedAt.getTime();
  return elapsed > TURN_TIME_LIMIT_MS;
}

/**
 * 残り時間を取得（ミリ秒）
 */
export function getRemainingTime(session: GameSession): number {
  const now = Date.now();
  const elapsed = now - session.turnStartedAt.getTime();
  return Math.max(0, TURN_TIME_LIMIT_MS - elapsed);
}

/**
 * セッションをJSON形式に変換（レスポンス用）
 */
export function sessionToJson(session: GameSession) {
  return {
    id: session.id,
    status: session.status,
    currentTurn: session.currentTurn,
    playerMistakeCount: session.playerMistakeCount,
    aiMistakeCount: session.aiMistakeCount,
    playerCapturedChars: Array.from(session.playerCapturedChars),
    aiCapturedChars: Array.from(session.aiCapturedChars),
    lastWord: session.lastWord,
    expectedStartChar: session.expectedStartChar,
    turnCount: session.turnCount,
    roundCount: session.roundCount,
    maxRounds: MAX_ROUNDS,
    history: session.history,
    aiLevel: session.aiLevel,
    turnStartedAt: session.turnStartedAt.toISOString(),
    remainingTimeMs: getRemainingTime(session),
    isOvertime: session.isOvertime,
  };
}
