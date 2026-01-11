/**
 * しりとり判定サービス
 * 禁忌判定ロジックを純粋関数として実装
 */

/** 小文字→大文字の変換マップ */
const SMALL_TO_LARGE: Record<string, string> = {
  ぁ: "あ",
  ぃ: "い",
  ぅ: "う",
  ぇ: "え",
  ぉ: "お",
  っ: "つ",
  ゃ: "や",
  ゅ: "ゆ",
  ょ: "よ",
  ゎ: "わ",
};

/** 判定結果の型 */
export type JudgeResult =
  | { valid: true }
  | {
      valid: false;
      reason:
        | "ends_with_n"
        | "captured_char"
        | "not_in_dictionary"
        | "already_used"
        | "wrong_start_char";
      details?: string;
    };

/**
 * 小文字を大文字に正規化
 */
export function normalizeSmallChar(char: string): string {
  return SMALL_TO_LARGE[char] ?? char;
}

/**
 * 単語の末尾から次の頭文字を取得
 * - 伸ばし棒「ー」の場合、一つ前の文字を使用
 * - 小文字の場合、大文字に変換
 */
export function getNextStartChar(word: string): string {
  let lastChar = word[word.length - 1];

  // 伸ばし棒の場合、一つ前の文字を使用
  if (lastChar === "ー" && word.length > 1) {
    lastChar = word[word.length - 2];
  }

  return normalizeSmallChar(lastChar);
}

/**
 * 【ルールA】「ん」で終わるかチェック
 */
export function endsWithN(word: string): boolean {
  return word.endsWith("ん");
}

/**
 * 【ルールB】確保文字の禁忌チェック
 * 2文字目以降に相手の確保文字が含まれていないかチェック
 */
export function containsCapturedChar(
  word: string,
  opponentCapturedChars: Set<string>
): { contains: boolean; char?: string } {
  // 2文字目以降をチェック
  for (let i = 1; i < word.length; i++) {
    const char = normalizeSmallChar(word[i]);
    if (opponentCapturedChars.has(char)) {
      return { contains: true, char };
    }
  }
  return { contains: false };
}

/**
 * 頭文字が正しいかチェック
 */
export function hasCorrectStartChar(
  word: string,
  expectedStartChar: string
): boolean {
  const actualStartChar = normalizeSmallChar(word[0]);
  return actualStartChar === expectedStartChar;
}

/**
 * 単語から確保する文字を抽出（2文字目以降の全構成文字）
 * 伸ばし棒（ー）も確保対象とする
 */
export function extractCharsToCapture(word: string): string[] {
  const chars: string[] = [];
  const seen = new Set<string>();

  for (let i = 1; i < word.length; i++) {
    const char = normalizeSmallChar(word[i]);
    if (!seen.has(char)) {
      chars.push(char);
      seen.add(char);
    }
  }

  return chars;
}

/**
 * 総合判定
 */
export function judgeWord(params: {
  word: string;
  expectedStartChar: string | null; // 最初のターンはnull
  opponentCapturedChars: Set<string>;
  usedWords: Set<string>;
  isInDictionary: (word: string) => boolean;
}): JudgeResult {
  const {
    word,
    expectedStartChar,
    opponentCapturedChars,
    usedWords,
    isInDictionary,
  } = params;

  // 頭文字チェック（最初のターン以外）
  if (expectedStartChar !== null && !hasCorrectStartChar(word, expectedStartChar)) {
    return { valid: false, reason: "wrong_start_char" };
  }

  // 既出チェック
  if (usedWords.has(word)) {
    return { valid: false, reason: "already_used" };
  }

  // 辞書チェック
  if (!isInDictionary(word)) {
    return { valid: false, reason: "not_in_dictionary" };
  }

  // 「ん」チェック
  if (endsWithN(word)) {
    return { valid: false, reason: "ends_with_n" };
  }

  // 確保文字チェック
  const capturedResult = containsCapturedChar(word, opponentCapturedChars);
  if (capturedResult.contains) {
    return {
      valid: false,
      reason: "captured_char",
      details: capturedResult.char,
    };
  }

  return { valid: true };
}

