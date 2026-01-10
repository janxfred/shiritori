// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TurnHistoryEntryImpl _$$TurnHistoryEntryImplFromJson(
  Map<String, dynamic> json,
) => _$TurnHistoryEntryImpl(
  turn: (json['turn'] as num).toInt(),
  player: $enumDecode(_$TurnPlayerEnumMap, json['player']),
  word: json['word'] as String,
  isValid: json['isValid'] as bool,
  capturedChars: (json['capturedChars'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  message: json['message'] as String,
);

Map<String, dynamic> _$$TurnHistoryEntryImplToJson(
  _$TurnHistoryEntryImpl instance,
) => <String, dynamic>{
  'turn': instance.turn,
  'player': _$TurnPlayerEnumMap[instance.player]!,
  'word': instance.word,
  'isValid': instance.isValid,
  'capturedChars': instance.capturedChars,
  'message': instance.message,
};

const _$TurnPlayerEnumMap = {TurnPlayer.player: 'player', TurnPlayer.ai: 'ai'};

_$GameSessionImpl _$$GameSessionImplFromJson(Map<String, dynamic> json) =>
    _$GameSessionImpl(
      id: json['id'] as String,
      status: $enumDecode(_$GameStatusEnumMap, json['status']),
      currentTurn: $enumDecode(_$TurnPlayerEnumMap, json['currentTurn']),
      playerMistakeCount: (json['playerMistakeCount'] as num).toInt(),
      aiMistakeCount: (json['aiMistakeCount'] as num).toInt(),
      playerCapturedChars: (json['playerCapturedChars'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      aiCapturedChars: (json['aiCapturedChars'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastWord: json['lastWord'] as String?,
      expectedStartChar: json['expectedStartChar'] as String?,
      turnCount: (json['turnCount'] as num).toInt(),
      roundCount: (json['roundCount'] as num).toInt(),
      maxRounds: (json['maxRounds'] as num).toInt(),
      history: (json['history'] as List<dynamic>)
          .map((e) => TurnHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      aiLevel: (json['aiLevel'] as num).toInt(),
      turnStartedAt: json['turnStartedAt'] as String,
      remainingTimeMs: (json['remainingTimeMs'] as num).toInt(),
      isOvertime: json['isOvertime'] as bool,
    );

Map<String, dynamic> _$$GameSessionImplToJson(_$GameSessionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$GameStatusEnumMap[instance.status]!,
      'currentTurn': _$TurnPlayerEnumMap[instance.currentTurn]!,
      'playerMistakeCount': instance.playerMistakeCount,
      'aiMistakeCount': instance.aiMistakeCount,
      'playerCapturedChars': instance.playerCapturedChars,
      'aiCapturedChars': instance.aiCapturedChars,
      'lastWord': instance.lastWord,
      'expectedStartChar': instance.expectedStartChar,
      'turnCount': instance.turnCount,
      'roundCount': instance.roundCount,
      'maxRounds': instance.maxRounds,
      'history': instance.history,
      'aiLevel': instance.aiLevel,
      'turnStartedAt': instance.turnStartedAt,
      'remainingTimeMs': instance.remainingTimeMs,
      'isOvertime': instance.isOvertime,
    };

const _$GameStatusEnumMap = {
  GameStatus.playing: 'playing',
  GameStatus.playerWin: 'player_win',
  GameStatus.aiWin: 'ai_win',
  GameStatus.draw: 'draw',
};

_$AiFirstMoveImpl _$$AiFirstMoveImplFromJson(Map<String, dynamic> json) =>
    _$AiFirstMoveImpl(
      word: json['word'] as String,
      capturedChars: (json['capturedChars'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$AiFirstMoveImplToJson(_$AiFirstMoveImpl instance) =>
    <String, dynamic>{
      'word': instance.word,
      'capturedChars': instance.capturedChars,
    };

_$StartGameResponseImpl _$$StartGameResponseImplFromJson(
  Map<String, dynamic> json,
) => _$StartGameResponseImpl(
  session: GameSession.fromJson(json['session'] as Map<String, dynamic>),
  message: json['message'] as String,
  dictionarySize: (json['dictionarySize'] as num).toInt(),
  startChar: json['startChar'] as String,
  firstTurn: $enumDecode(_$TurnPlayerEnumMap, json['firstTurn']),
  aiFirstMove: json['aiFirstMove'] == null
      ? null
      : AiFirstMove.fromJson(json['aiFirstMove'] as Map<String, dynamic>),
);

Map<String, dynamic> _$$StartGameResponseImplToJson(
  _$StartGameResponseImpl instance,
) => <String, dynamic>{
  'session': instance.session,
  'message': instance.message,
  'dictionarySize': instance.dictionarySize,
  'startChar': instance.startChar,
  'firstTurn': _$TurnPlayerEnumMap[instance.firstTurn]!,
  'aiFirstMove': instance.aiFirstMove,
};

_$TurnResultImpl _$$TurnResultImplFromJson(Map<String, dynamic> json) =>
    _$TurnResultImpl(
      word: json['word'] as String,
      isValid: json['isValid'] as bool,
      message: json['message'] as String,
      capturedChars: (json['capturedChars'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      timeExpired: json['timeExpired'] as bool? ?? false,
    );

Map<String, dynamic> _$$TurnResultImplToJson(_$TurnResultImpl instance) =>
    <String, dynamic>{
      'word': instance.word,
      'isValid': instance.isValid,
      'message': instance.message,
      'capturedChars': instance.capturedChars,
      'timeExpired': instance.timeExpired,
    };

_$SubmitWordResponseImpl _$$SubmitWordResponseImplFromJson(
  Map<String, dynamic> json,
) => _$SubmitWordResponseImpl(
  session: GameSession.fromJson(json['session'] as Map<String, dynamic>),
  playerResult: TurnResult.fromJson(
    json['playerResult'] as Map<String, dynamic>,
  ),
  aiResult: json['aiResult'] == null
      ? null
      : TurnResult.fromJson(json['aiResult'] as Map<String, dynamic>),
  gameOver: json['gameOver'] as bool,
  winner: $enumDecodeNullable(_$TurnPlayerEnumMap, json['winner']),
  overtimeStarted: json['overtimeStarted'] as bool? ?? false,
);

Map<String, dynamic> _$$SubmitWordResponseImplToJson(
  _$SubmitWordResponseImpl instance,
) => <String, dynamic>{
  'session': instance.session,
  'playerResult': instance.playerResult,
  'aiResult': instance.aiResult,
  'gameOver': instance.gameOver,
  'winner': _$TurnPlayerEnumMap[instance.winner],
  'overtimeStarted': instance.overtimeStarted,
};

_$CheckTimeResponseImpl _$$CheckTimeResponseImplFromJson(
  Map<String, dynamic> json,
) => _$CheckTimeResponseImpl(
  expired: json['expired'] as bool,
  session: json['session'] == null
      ? null
      : GameSession.fromJson(json['session'] as Map<String, dynamic>),
  message: json['message'] as String?,
);

Map<String, dynamic> _$$CheckTimeResponseImplToJson(
  _$CheckTimeResponseImpl instance,
) => <String, dynamic>{
  'expired': instance.expired,
  'session': instance.session,
  'message': instance.message,
};
