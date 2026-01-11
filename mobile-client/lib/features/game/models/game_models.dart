/// ゲームモデル定義

/// AIレベル
enum AiLevel {
  easy(1),
  normal(2),
  hard(3);

  final int value;
  const AiLevel(this.value);
}

/// ゲームステータス
enum GameStatus {
  playing,
  playerWin,
  aiWin,
  draw;

  factory GameStatus.fromString(String s) {
    switch (s) {
      case 'player_win':
        return GameStatus.playerWin;
      case 'ai_win':
        return GameStatus.aiWin;
      case 'draw':
        return GameStatus.draw;
      default:
        return GameStatus.playing;
    }
  }
}

/// ターン履歴エントリ
class TurnHistoryEntry {
  final int turn;
  final String player; // 'player' or 'ai'
  final String word;
  final bool isValid;
  final List<String> capturedChars;
  final String message;

  TurnHistoryEntry({
    required this.turn,
    required this.player,
    required this.word,
    required this.isValid,
    required this.capturedChars,
    required this.message,
  });

  factory TurnHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TurnHistoryEntry(
      turn: json['turn'] as int,
      player: json['player'] as String,
      word: json['word'] as String,
      isValid: json['isValid'] as bool,
      capturedChars: List<String>.from(json['capturedChars'] as List),
      message: json['message'] as String,
    );
  }
}

/// ゲームセッション
class GameSession {
  final String id;
  final GameStatus status;
  final String currentTurn;
  final int playerMistakeCount;
  final int aiMistakeCount;
  final List<String> playerCapturedChars;
  final List<String> aiCapturedChars;
  final String? lastWord;
  final String? expectedStartChar;
  final int turnCount;
  final int roundCount;
  final int maxRounds;
  final List<TurnHistoryEntry> history;
  final int aiLevel;
  final DateTime turnStartedAt;
  final int remainingTimeMs;
  final bool isOvertime;

  GameSession({
    required this.id,
    required this.status,
    required this.currentTurn,
    required this.playerMistakeCount,
    required this.aiMistakeCount,
    required this.playerCapturedChars,
    required this.aiCapturedChars,
    this.lastWord,
    this.expectedStartChar,
    required this.turnCount,
    required this.roundCount,
    required this.maxRounds,
    required this.history,
    required this.aiLevel,
    required this.turnStartedAt,
    required this.remainingTimeMs,
    required this.isOvertime,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      status: GameStatus.fromString(json['status'] as String),
      currentTurn: json['currentTurn'] as String,
      playerMistakeCount: json['playerMistakeCount'] as int,
      aiMistakeCount: json['aiMistakeCount'] as int,
      playerCapturedChars: List<String>.from(json['playerCapturedChars'] as List),
      aiCapturedChars: List<String>.from(json['aiCapturedChars'] as List),
      lastWord: json['lastWord'] as String?,
      expectedStartChar: json['expectedStartChar'] as String?,
      turnCount: json['turnCount'] as int,
      roundCount: json['roundCount'] as int,
      maxRounds: json['maxRounds'] as int,
      history: (json['history'] as List)
          .map((e) => TurnHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      aiLevel: json['aiLevel'] as int,
      turnStartedAt: DateTime.parse(json['turnStartedAt'] as String),
      remainingTimeMs: json['remainingTimeMs'] as int,
      isOvertime: json['isOvertime'] as bool,
    );
  }
}

/// ターン結果
class TurnResult {
  final String word;
  final bool isValid;
  final String message;
  final List<String> capturedChars;
  final bool? timeExpired;

  TurnResult({
    required this.word,
    required this.isValid,
    required this.message,
    required this.capturedChars,
    this.timeExpired,
  });

  factory TurnResult.fromJson(Map<String, dynamic> json) {
    return TurnResult(
      word: json['word'] as String,
      isValid: json['isValid'] as bool,
      message: json['message'] as String,
      capturedChars: List<String>.from(json['capturedChars'] as List),
      timeExpired: json['timeExpired'] as bool?,
    );
  }
}

/// ゲーム開始レスポンス
class CreateGameResponse {
  final GameSession session;
  final String message;
  final int dictionarySize;
  final String? startChar;
  final String? firstTurn;
  final TurnResult? aiFirstWord;

  CreateGameResponse({
    required this.session,
    required this.message,
    required this.dictionarySize,
    this.startChar,
    this.firstTurn,
    this.aiFirstWord,
  });

  factory CreateGameResponse.fromJson(Map<String, dynamic> json) {
    return CreateGameResponse(
      session: GameSession.fromJson(json['session'] as Map<String, dynamic>),
      message: json['message'] as String,
      dictionarySize: json['dictionarySize'] as int,
      startChar: json['startChar'] as String?,
      firstTurn: json['firstTurn'] as String?,
      aiFirstWord: json['aiFirstWord'] != null
          ? TurnResult.fromJson(json['aiFirstWord'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 単語送信レスポンス
class SubmitWordResponse {
  final GameSession session;
  final TurnResult playerResult;
  final TurnResult? aiResult;
  final bool gameOver;
  final String? winner;
  final bool? overtimeStarted;

  SubmitWordResponse({
    required this.session,
    required this.playerResult,
    this.aiResult,
    required this.gameOver,
    this.winner,
    this.overtimeStarted,
  });

  factory SubmitWordResponse.fromJson(Map<String, dynamic> json) {
    return SubmitWordResponse(
      session: GameSession.fromJson(json['session'] as Map<String, dynamic>),
      playerResult: TurnResult.fromJson(json['playerResult'] as Map<String, dynamic>),
      aiResult: json['aiResult'] != null
          ? TurnResult.fromJson(json['aiResult'] as Map<String, dynamic>)
          : null,
      gameOver: json['gameOver'] as bool,
      winner: json['winner'] as String?,
      overtimeStarted: json['overtimeStarted'] as bool?,
    );
  }
}

/// 時間チェックレスポンス
class CheckTimeResponse {
  final bool expired;
  final GameSession? session;
  final String? message;

  CheckTimeResponse({
    required this.expired,
    this.session,
    this.message,
  });

  factory CheckTimeResponse.fromJson(Map<String, dynamic> json) {
    return CheckTimeResponse(
      expired: json['expired'] as bool,
      session: json['session'] != null
          ? GameSession.fromJson(json['session'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}

