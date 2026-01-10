/**
 * AI（悪魔）の思考サービス
 * 辞書から有効な単語を選択する
 */

import {
  containsCapturedChar,
  endsWithN,
  getNextStartChar,
} from "./ShiritoriJudgeService";

export type AiLevel = 1 | 2 | 3;

export interface AiThinkResult {
  word: string | null;
  noValidWord: boolean;
}

interface ThinkParams {
  startChar: string;
  playerCapturedChars: Set<string>;
  usedWords: Set<string>;
  findWordsByPrefix: (prefix: string) => string[];
}

/**
 * 有効な候補をフィルタリング
 */
function getValidCandidates(params: ThinkParams): string[] {
  const { startChar, playerCapturedChars, usedWords, findWordsByPrefix } = params;
  const candidates = findWordsByPrefix(startChar);
  const validCandidates: string[] = [];

  for (const word of candidates) {
    if (usedWords.has(word)) continue;
    if (endsWithN(word)) continue;
    const capturedResult = containsCapturedChar(word, playerCapturedChars);
    if (capturedResult.contains) continue;
    validCandidates.push(word);
  }

  return validCandidates;
}

/**
 * Lv.1: ランダムに選択
 */
function thinkRandom(params: ThinkParams): AiThinkResult {
  const validCandidates = getValidCandidates(params);

  if (validCandidates.length === 0) {
    return { word: null, noValidWord: true };
  }

  // 完全にランダムに選択
  const randomIndex = Math.floor(Math.random() * validCandidates.length);
  return { word: validCandidates[randomIndex], noValidWord: false };
}

/**
 * Lv.3: 戦略的に選択（返しにくい文字で終わる単語を優先）
 */
function thinkStrategic(params: ThinkParams): AiThinkResult {
  const { findWordsByPrefix } = params;
  const validCandidates = getValidCandidates(params);

  if (validCandidates.length === 0) {
    return { word: null, noValidWord: true };
  }

  // 戦略的に単語を選択
  // 1. 返しにくい文字（候補が少ない文字）で終わる単語を優先
  // 2. 同率の場合はランダム
  const scoredCandidates = validCandidates.map((word) => {
    const nextChar = getNextStartChar(word);
    const nextCandidatesCount = findWordsByPrefix(nextChar).length;
    return { word, score: nextCandidatesCount };
  });

  // スコアが低い（返しにくい）順にソート
  scoredCandidates.sort((a, b) => a.score - b.score);

  // 上位候補からランダムに選択（少し変化をつける）
  const topCandidates = scoredCandidates.slice(
    0,
    Math.min(5, scoredCandidates.length)
  );
  const selected =
    topCandidates[Math.floor(Math.random() * topCandidates.length)];

  return { word: selected.word, noValidWord: false };
}

/**
 * AIが次の一手を計算（レベル別）
 */
export function thinkNextWord(
  params: ThinkParams & { level: AiLevel; turnCount: number }
): AiThinkResult {
  const { level, turnCount, ...thinkParams } = params;

  switch (level) {
    case 1:
      // Lv.1: 常にランダム
      return thinkRandom(thinkParams);

    case 2:
      // Lv.2: Lv.1とLv.3を交互に使用（偶数ターンはランダム、奇数ターンは戦略的）
      if (turnCount % 2 === 0) {
        return thinkRandom(thinkParams);
      }
      return thinkStrategic(thinkParams);

    case 3:
      // Lv.3: 常に戦略的
      return thinkStrategic(thinkParams);

    default:
      return thinkStrategic(thinkParams);
  }
}
