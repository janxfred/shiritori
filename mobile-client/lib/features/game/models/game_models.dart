import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_models.freezed.dart';
part 'game_models.g.dart';

/// AIレベル
enum AiLevel {
  @JsonValue(1)
  easy,
  @JsonValue(2)
  medium,
  @JsonValue(3)
  hard;

  int get value {
    switch (this) {
      case AiLevel.easy:
        return 1;
      case AiLevel.medium:
        return 2;
      case AiLevel.hard:
        return 3;
    }
  }

  String get displayName {
    switch (this) {
      case AiLevel.easy:
        return 'Lv.1 初級';
      case AiLevel.medium:
        return 'Lv.2 中級';
      case AiLevel.hard:
        return 'Lv.3 上級';
    }
  }
}

/// ゲームステータス
enum GameStatus {
  @JsonValue('playing')
  playing,
  @JsonValue('player_win')
  playerWin,
  @JsonValue('ai_win')
  aiWin,
  @JsonValue('draw')
  draw;
}

/// ターンプレイヤー
enum TurnPlayer {
  @JsonValue('player')
  player,
  @JsonValue('ai')
  ai;
}

/// ターン履歴エントリ
@freezed
class TurnHistoryEntry with _$TurnHistoryEntry {
  const factory TurnHistoryEntry({
    required int turn,
    required TurnPlayer player,
    required String word,
    required bool isValid,
    required List<String> capturedChars,
    required String message,
  }) = _TurnHistoryEntry;

  factory TurnHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$TurnHistoryEntryFromJson(json);
}

/// ゲームセッション
@freezed
class GameSession with _$GameSession {
  const factory GameSession({
    required String id,
    required GameStatus status,
    required TurnPlayer currentTurn,
    required int playerMistakeCount,
    required int aiMistakeCount,
    required List<String> playerCapturedChars,
    required List<String> aiCapturedChars,
    String? lastWord,
    String? expectedStartChar,
    required int turnCount,
    required int roundCount,
    required int maxRounds,
    required List<TurnHistoryEntry> history,
    required int aiLevel,
    required String turnStartedAt,
    required int remainingTimeMs,
    required bool isOvertime,
  }) = _GameSession;

  factory GameSession.fromJson(Map<String, dynamic> json) =>
      _$GameSessionFromJson(json);
}

/// AI先攻時の最初の手
@freezed
class AiFirstMove with _$AiFirstMove {
  const factory AiFirstMove({
    required String word,
    required List<String> capturedChars,
  }) = _AiFirstMove;

  factory AiFirstMove.fromJson(Map<String, dynamic> json) =>
      _$AiFirstMoveFromJson(json);
}

/// ゲーム開始レスポンス
@freezed
class StartGameResponse with _$StartGameResponse {
  const factory StartGameResponse({
    required GameSession session,
    required String message,
    required int dictionarySize,
    required String startChar,
    required TurnPlayer firstTurn,
    AiFirstMove? aiFirstMove,
  }) = _StartGameResponse;

  factory StartGameResponse.fromJson(Map<String, dynamic> json) =>
      _$StartGameResponseFromJson(json);
}

/// ターン結果
@freezed
class TurnResult with _$TurnResult {
  const factory TurnResult({
    required String word,
    required bool isValid,
    required String message,
    required List<String> capturedChars,
    @Default(false) bool timeExpired,
  }) = _TurnResult;

  factory TurnResult.fromJson(Map<String, dynamic> json) =>
      _$TurnResultFromJson(json);
}

/// 単語送信レスポンス
@freezed
class SubmitWordResponse with _$SubmitWordResponse {
  const factory SubmitWordResponse({
    required GameSession session,
    required TurnResult playerResult,
    TurnResult? aiResult,
    required bool gameOver,
    TurnPlayer? winner,
    @Default(false) bool overtimeStarted,
  }) = _SubmitWordResponse;

  factory SubmitWordResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmitWordResponseFromJson(json);
}

/// 時間チェックレスポンス
@freezed
class CheckTimeResponse with _$CheckTimeResponse {
  const factory CheckTimeResponse({
    required bool expired,
    GameSession? session,
    String? message,
  }) = _CheckTimeResponse;

  factory CheckTimeResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckTimeResponseFromJson(json);
}


