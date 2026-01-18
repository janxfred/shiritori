/**
 * ターン処理ユースケース
 * ユーザー送信 → 判定 → 確保 → AI思考 → 台詞選択 を一連で実行
 */

import { getRandomMessage } from "../domain/constants/DemonMessages";
import { thinkNextWord } from "../domain/services/AiBrainService";
import {
  extractCharsToCapture,
  getNextStartChar,
  judgeWord,
  type JudgeResult,
} from "../domain/services/ShiritoriJudgeService";
import {
  findWordsByPrefix,
  isInDictionary,
} from "../infrastructure/DictionaryRepository";
import {
  getSession,
  isTimeExpired,
  MAX_ROUNDS,
  updateSession,
  type GameSession,
  type TurnHistoryEntry,
} from "../infrastructure/GameSessionStore";

export interface TurnResult {
  success: boolean;
  session: GameSession;
  playerResult: {
    word: string;
    isValid: boolean;
    message: string;
    capturedChars: string[];
    timeExpired?: boolean;
  };
  aiResult?: {
    word: string;
    isValid: boolean;
    message: string;
    capturedChars: string[];
  };
  gameOver: boolean;
  winner?: "player" | "ai";
}

/**
 * プレイヤーのターンを処理
 */
export function processTurn(
  sessionId: string,
  playerWord: string
): TurnResult | null {
  const session = getSession(sessionId);
  if (!session) return null;

  if (session.status !== "playing") {
    return {
      success: false,
      session,
      playerResult: {
        word: playerWord,
        isValid: false,
        message: "ゲームは既に終了している。",
        capturedChars: [],
      },
      gameOver: true,
      winner: session.status === "player_win" ? "player" : "ai",
    };
  }

  // 制限時間チェック
  if (isTimeExpired(session)) {
    session.status = "ai_win";
    const message = "時は金なり…汝は時を浪費した。敗北だ。";

    const entry: TurnHistoryEntry = {
      turn: session.turnCount + 1,
      player: "player",
      word: "(時間切れ)",
      isValid: false,
      capturedChars: [],
      message,
    };
    session.history.push(entry);

    updateSession(session);
    return {
      success: true,
      session,
      playerResult: {
        word: playerWord,
        isValid: false,
        message,
        capturedChars: [],
        timeExpired: true,
      },
      gameOver: true,
      winner: "ai",
    };
  }

  // プレイヤーの単語を判定
  const playerJudge = judgeWord({
    word: playerWord,
    expectedStartChar: session.expectedStartChar,
    opponentCapturedChars: session.aiCapturedChars,
    usedWords: session.usedWords,
    isInDictionary,
  });

  const playerResult = processPlayerResult(session, playerWord, playerJudge);

  // ゲーム終了チェック（プレイヤーの2回目のお手つき）
  if (session.playerMistakeCount >= 2) {
    session.status = "ai_win";
    updateSession(session);
    return {
      success: true,
      session,
      playerResult,
      gameOver: true,
      winner: "ai",
    };
  }

  // プレイヤーが有効な単語を出した場合、AIのターン
  if (playerJudge.valid) {
    const aiResult = processAiTurn(session);

    // ゲーム終了チェック（AIのお手つきまたは有効な単語がない）
    if (session.aiMistakeCount >= 2 || aiResult.word === "") {
      session.status = "player_win";
      updateSession(session);
      return {
        success: true,
        session,
        playerResult,
        aiResult,
        gameOver: true,
        winner: "player",
      };
    }

    // ラウンド完了（プレイヤーとAIが1回ずつ）
    session.roundCount++;

    // ラウンド終了チェック
    const roundEndResult = checkRoundEnd(session, playerResult, aiResult);
    if (roundEndResult) {
      return roundEndResult;
    }

    // プレイヤーのターン開始時刻を更新
    session.turnStartedAt = new Date();

    updateSession(session);
    return {
      success: true,
      session,
      playerResult,
      aiResult,
      gameOver: false,
    };
  }

  // お手つきでも時間はリセットしない（そのまま継続）
  updateSession(session);
  return {
    success: true,
    session,
    playerResult,
    gameOver: false,
  };
}

/**
 * ラウンド終了チェック
 */
function checkRoundEnd(
  session: GameSession,
  playerResult: TurnResult["playerResult"],
  aiResult: NonNullable<TurnResult["aiResult"]>
): TurnResult | null {
  // 通常ゲーム：10ラウンド終了チェック
  if (session.roundCount >= MAX_ROUNDS) {
    const playerChars = session.playerCapturedChars.size;
    const aiChars = session.aiCapturedChars.size;

    if (playerChars < aiChars) {
      // プレイヤーの方が少ない = プレイヤー勝利
      session.status = "player_win";
      const message = getRandomMessage("roundEndPlayerWin");
      updateSession(session);
      return {
        success: true,
        session,
        playerResult,
        aiResult: { ...aiResult, message },
        gameOver: true,
        winner: "player",
      };
    } else if (playerChars > aiChars) {
      // プレイヤーの方が多い = AI勝利
      session.status = "ai_win";
      const message = getRandomMessage("roundEndAiWin");
      updateSession(session);
      return {
        success: true,
        session,
        playerResult,
        aiResult: { ...aiResult, message },
        gameOver: true,
        winner: "ai",
      };
    } else {
      // 同点 → 引き分け
      session.status = "draw";
      const message = "引き分けだ…互角の戦いだったな。";
      updateSession(session);
      return {
        success: true,
        session,
        playerResult,
        aiResult: { ...aiResult, message },
        gameOver: true,
        winner: undefined,
      };
    }
  }

  return null;
}

/**
 * 制限時間チェックのみ（ポーリング用）
 */
export function checkTimeLimit(sessionId: string): {
  expired: boolean;
  session: GameSession | null;
} {
  const session = getSession(sessionId);
  if (!session) return { expired: false, session: null };

  if (session.status !== "playing") {
    return { expired: false, session };
  }

  if (isTimeExpired(session)) {
    session.status = "ai_win";
    const message = "時は金なり…汝は時を浪費した。敗北だ。";

    const entry: TurnHistoryEntry = {
      turn: session.turnCount + 1,
      player: "player",
      word: "(時間切れ)",
      isValid: false,
      capturedChars: [],
      message,
    };
    session.history.push(entry);

    updateSession(session);
    return { expired: true, session };
  }

  return { expired: false, session };
}

/**
 * プレイヤーの結果を処理
 */
function processPlayerResult(
  session: GameSession,
  word: string,
  judge: JudgeResult
): TurnResult["playerResult"] {
  session.turnCount++;

  if (!judge.valid) {
    session.playerMistakeCount++;

    let message: string;
    switch (judge.reason) {
      case "ends_with_n":
        message = getRandomMessage("endsWithN");
        break;
      case "captured_char":
        message = getRandomMessage("capturedCharError");
        break;
      case "not_in_dictionary":
        message = getRandomMessage("playerInvalidWord");
        break;
      case "already_used":
        message = getRandomMessage("alreadyUsed");
        break;
      case "wrong_start_char":
        message = getRandomMessage("wrongStartChar");
        break;
      default:
        message = getRandomMessage("playerMistake");
    }

    const entry: TurnHistoryEntry = {
      turn: session.turnCount,
      player: "player",
      word,
      isValid: false,
      capturedChars: [],
      message,
    };
    session.history.push(entry);

    return { word, isValid: false, message, capturedChars: [] };
  }

  // 有効な単語
  session.usedWords.add(word);
  const capturedChars = extractCharsToCapture(word);
  for (const char of capturedChars) {
    if (
      !session.aiCapturedChars.has(char) &&
      !session.playerCapturedChars.has(char)
    ) {
      session.playerCapturedChars.add(char);
    }
  }

  session.lastWord = word;
  session.expectedStartChar = getNextStartChar(word);

  const message = getRandomMessage("playerSuccess");
  const entry: TurnHistoryEntry = {
    turn: session.turnCount,
    player: "player",
    word,
    isValid: true,
    capturedChars,
    message,
  };
  session.history.push(entry);

  return { word, isValid: true, message, capturedChars };
}

/**
 * AIのターンを処理
 */
function processAiTurn(
  session: GameSession
): NonNullable<TurnResult["aiResult"]> {
  session.turnCount++;

  const result = thinkNextWord({
    startChar: session.expectedStartChar!,
    playerCapturedChars: session.playerCapturedChars,
    usedWords: session.usedWords,
    findWordsByPrefix,
    level: session.aiLevel,
    turnCount: session.turnCount,
  });

  if (result.noValidWord || !result.word) {
    session.aiMistakeCount = 2;
    const message = getRandomMessage("aiDefeat");

    const entry: TurnHistoryEntry = {
      turn: session.turnCount,
      player: "ai",
      word: "",
      isValid: false,
      capturedChars: [],
      message,
    };
    session.history.push(entry);

    return { word: "", isValid: false, message, capturedChars: [] };
  }

  const word = result.word;
  session.usedWords.add(word);

  const capturedChars = extractCharsToCapture(word);
  for (const char of capturedChars) {
    if (
      !session.playerCapturedChars.has(char) &&
      !session.aiCapturedChars.has(char)
    ) {
      session.aiCapturedChars.add(char);
    }
  }

  session.lastWord = word;
  session.expectedStartChar = getNextStartChar(word);

  const message = getRandomMessage("aiTurn");
  const entry: TurnHistoryEntry = {
    turn: session.turnCount,
    player: "ai",
    word,
    isValid: true,
    capturedChars,
    message,
  };
  session.history.push(entry);

  return { word, isValid: true, message, capturedChars };
}

/**
 * AI先攻時の最初のターンを処理
 */
export function processAiFirstTurn(sessionId: string): {
  session: GameSession;
  aiResult: NonNullable<TurnResult["aiResult"]>;
} | null {
  const session = getSession(sessionId);
  if (!session) return null;

  // AIのターンを処理
  const aiResult = processAiTurn(session);

  // AIが有効な単語を出した場合、プレイヤーのターンに切り替え
  if (aiResult.isValid) {
    session.currentTurn = "player";
    session.turnStartedAt = new Date();
  }

  updateSession(session);
  return { session, aiResult };
}
