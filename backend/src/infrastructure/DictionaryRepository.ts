/**
 * 辞書リポジトリ
 * JSONファイルから辞書をロードし、前方一致検索を提供
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

interface DictionaryEntry {
  word: string;
}

/** 辞書データ（メモリ上にキャッシュ） */
let dictionary: Set<string> | null = null;
/** 前方一致検索用のインデックス */
let prefixIndex: Map<string, string[]> | null = null;

/**
 * 辞書を初期化（遅延ロード）
 */
function ensureLoaded(): void {
  if (dictionary !== null && prefixIndex !== null) {
    return;
  }

  const dictPath = path.resolve(__dirname, "../../..", "dictionary.json");

  if (!fs.existsSync(dictPath)) {
    console.warn(`辞書ファイルが見つかりません: ${dictPath}`);
    dictionary = new Set();
    prefixIndex = new Map();
    return;
  }

  const raw = fs.readFileSync(dictPath, "utf-8");
  const entries: DictionaryEntry[] = JSON.parse(raw);

  dictionary = new Set(entries.map((e) => e.word));
  prefixIndex = new Map();

  // 前方一致インデックスを構築（1文字目でグループ化）
  for (const entry of entries) {
    const word = entry.word;
    if (word.length === 0) continue;

    // 1文字目を正規化（小文字→大文字）
    let firstChar = word[0];
    const smallToLarge: Record<string, string> = {
      ぁ: "あ", ぃ: "い", ぅ: "う", ぇ: "え", ぉ: "お",
      っ: "つ", ゃ: "や", ゅ: "ゆ", ょ: "よ", ゎ: "わ",
    };
    firstChar = smallToLarge[firstChar] ?? firstChar;

    if (!prefixIndex.has(firstChar)) {
      prefixIndex.set(firstChar, []);
    }
    prefixIndex.get(firstChar)!.push(word);
  }

  console.log(`辞書ロード完了: ${dictionary.size}件`);
}

/**
 * 単語が辞書に存在するかチェック
 */
export function isInDictionary(word: string): boolean {
  ensureLoaded();
  return dictionary!.has(word);
}

/**
 * 指定された文字から始まる単語を検索
 */
export function findWordsByPrefix(prefix: string): string[] {
  ensureLoaded();
  return prefixIndex!.get(prefix) ?? [];
}

/**
 * 辞書の単語数を取得
 */
export function getDictionarySize(): number {
  ensureLoaded();
  return dictionary!.size;
}

