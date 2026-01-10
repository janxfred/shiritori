// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TurnHistoryEntry _$TurnHistoryEntryFromJson(Map<String, dynamic> json) {
  return _TurnHistoryEntry.fromJson(json);
}

/// @nodoc
mixin _$TurnHistoryEntry {
  int get turn => throw _privateConstructorUsedError;
  TurnPlayer get player => throw _privateConstructorUsedError;
  String get word => throw _privateConstructorUsedError;
  bool get isValid => throw _privateConstructorUsedError;
  List<String> get capturedChars => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;

  /// Serializes this TurnHistoryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TurnHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TurnHistoryEntryCopyWith<TurnHistoryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TurnHistoryEntryCopyWith<$Res> {
  factory $TurnHistoryEntryCopyWith(
    TurnHistoryEntry value,
    $Res Function(TurnHistoryEntry) then,
  ) = _$TurnHistoryEntryCopyWithImpl<$Res, TurnHistoryEntry>;
  @useResult
  $Res call({
    int turn,
    TurnPlayer player,
    String word,
    bool isValid,
    List<String> capturedChars,
    String message,
  });
}

/// @nodoc
class _$TurnHistoryEntryCopyWithImpl<$Res, $Val extends TurnHistoryEntry>
    implements $TurnHistoryEntryCopyWith<$Res> {
  _$TurnHistoryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TurnHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? turn = null,
    Object? player = null,
    Object? word = null,
    Object? isValid = null,
    Object? capturedChars = null,
    Object? message = null,
  }) {
    return _then(
      _value.copyWith(
            turn: null == turn
                ? _value.turn
                : turn // ignore: cast_nullable_to_non_nullable
                      as int,
            player: null == player
                ? _value.player
                : player // ignore: cast_nullable_to_non_nullable
                      as TurnPlayer,
            word: null == word
                ? _value.word
                : word // ignore: cast_nullable_to_non_nullable
                      as String,
            isValid: null == isValid
                ? _value.isValid
                : isValid // ignore: cast_nullable_to_non_nullable
                      as bool,
            capturedChars: null == capturedChars
                ? _value.capturedChars
                : capturedChars // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TurnHistoryEntryImplCopyWith<$Res>
    implements $TurnHistoryEntryCopyWith<$Res> {
  factory _$$TurnHistoryEntryImplCopyWith(
    _$TurnHistoryEntryImpl value,
    $Res Function(_$TurnHistoryEntryImpl) then,
  ) = __$$TurnHistoryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int turn,
    TurnPlayer player,
    String word,
    bool isValid,
    List<String> capturedChars,
    String message,
  });
}

/// @nodoc
class __$$TurnHistoryEntryImplCopyWithImpl<$Res>
    extends _$TurnHistoryEntryCopyWithImpl<$Res, _$TurnHistoryEntryImpl>
    implements _$$TurnHistoryEntryImplCopyWith<$Res> {
  __$$TurnHistoryEntryImplCopyWithImpl(
    _$TurnHistoryEntryImpl _value,
    $Res Function(_$TurnHistoryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TurnHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? turn = null,
    Object? player = null,
    Object? word = null,
    Object? isValid = null,
    Object? capturedChars = null,
    Object? message = null,
  }) {
    return _then(
      _$TurnHistoryEntryImpl(
        turn: null == turn
            ? _value.turn
            : turn // ignore: cast_nullable_to_non_nullable
                  as int,
        player: null == player
            ? _value.player
            : player // ignore: cast_nullable_to_non_nullable
                  as TurnPlayer,
        word: null == word
            ? _value.word
            : word // ignore: cast_nullable_to_non_nullable
                  as String,
        isValid: null == isValid
            ? _value.isValid
            : isValid // ignore: cast_nullable_to_non_nullable
                  as bool,
        capturedChars: null == capturedChars
            ? _value._capturedChars
            : capturedChars // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TurnHistoryEntryImpl implements _TurnHistoryEntry {
  const _$TurnHistoryEntryImpl({
    required this.turn,
    required this.player,
    required this.word,
    required this.isValid,
    required final List<String> capturedChars,
    required this.message,
  }) : _capturedChars = capturedChars;

  factory _$TurnHistoryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TurnHistoryEntryImplFromJson(json);

  @override
  final int turn;
  @override
  final TurnPlayer player;
  @override
  final String word;
  @override
  final bool isValid;
  final List<String> _capturedChars;
  @override
  List<String> get capturedChars {
    if (_capturedChars is EqualUnmodifiableListView) return _capturedChars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_capturedChars);
  }

  @override
  final String message;

  @override
  String toString() {
    return 'TurnHistoryEntry(turn: $turn, player: $player, word: $word, isValid: $isValid, capturedChars: $capturedChars, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TurnHistoryEntryImpl &&
            (identical(other.turn, turn) || other.turn == turn) &&
            (identical(other.player, player) || other.player == player) &&
            (identical(other.word, word) || other.word == word) &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            const DeepCollectionEquality().equals(
              other._capturedChars,
              _capturedChars,
            ) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    turn,
    player,
    word,
    isValid,
    const DeepCollectionEquality().hash(_capturedChars),
    message,
  );

  /// Create a copy of TurnHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TurnHistoryEntryImplCopyWith<_$TurnHistoryEntryImpl> get copyWith =>
      __$$TurnHistoryEntryImplCopyWithImpl<_$TurnHistoryEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TurnHistoryEntryImplToJson(this);
  }
}

abstract class _TurnHistoryEntry implements TurnHistoryEntry {
  const factory _TurnHistoryEntry({
    required final int turn,
    required final TurnPlayer player,
    required final String word,
    required final bool isValid,
    required final List<String> capturedChars,
    required final String message,
  }) = _$TurnHistoryEntryImpl;

  factory _TurnHistoryEntry.fromJson(Map<String, dynamic> json) =
      _$TurnHistoryEntryImpl.fromJson;

  @override
  int get turn;
  @override
  TurnPlayer get player;
  @override
  String get word;
  @override
  bool get isValid;
  @override
  List<String> get capturedChars;
  @override
  String get message;

  /// Create a copy of TurnHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TurnHistoryEntryImplCopyWith<_$TurnHistoryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GameSession _$GameSessionFromJson(Map<String, dynamic> json) {
  return _GameSession.fromJson(json);
}

/// @nodoc
mixin _$GameSession {
  String get id => throw _privateConstructorUsedError;
  GameStatus get status => throw _privateConstructorUsedError;
  TurnPlayer get currentTurn => throw _privateConstructorUsedError;
  int get playerMistakeCount => throw _privateConstructorUsedError;
  int get aiMistakeCount => throw _privateConstructorUsedError;
  List<String> get playerCapturedChars => throw _privateConstructorUsedError;
  List<String> get aiCapturedChars => throw _privateConstructorUsedError;
  String? get lastWord => throw _privateConstructorUsedError;
  String? get expectedStartChar => throw _privateConstructorUsedError;
  int get turnCount => throw _privateConstructorUsedError;
  int get roundCount => throw _privateConstructorUsedError;
  int get maxRounds => throw _privateConstructorUsedError;
  List<TurnHistoryEntry> get history => throw _privateConstructorUsedError;
  int get aiLevel => throw _privateConstructorUsedError;
  String get turnStartedAt => throw _privateConstructorUsedError;
  int get remainingTimeMs => throw _privateConstructorUsedError;
  bool get isOvertime => throw _privateConstructorUsedError;

  /// Serializes this GameSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameSessionCopyWith<GameSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameSessionCopyWith<$Res> {
  factory $GameSessionCopyWith(
    GameSession value,
    $Res Function(GameSession) then,
  ) = _$GameSessionCopyWithImpl<$Res, GameSession>;
  @useResult
  $Res call({
    String id,
    GameStatus status,
    TurnPlayer currentTurn,
    int playerMistakeCount,
    int aiMistakeCount,
    List<String> playerCapturedChars,
    List<String> aiCapturedChars,
    String? lastWord,
    String? expectedStartChar,
    int turnCount,
    int roundCount,
    int maxRounds,
    List<TurnHistoryEntry> history,
    int aiLevel,
    String turnStartedAt,
    int remainingTimeMs,
    bool isOvertime,
  });
}

/// @nodoc
class _$GameSessionCopyWithImpl<$Res, $Val extends GameSession>
    implements $GameSessionCopyWith<$Res> {
  _$GameSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? currentTurn = null,
    Object? playerMistakeCount = null,
    Object? aiMistakeCount = null,
    Object? playerCapturedChars = null,
    Object? aiCapturedChars = null,
    Object? lastWord = freezed,
    Object? expectedStartChar = freezed,
    Object? turnCount = null,
    Object? roundCount = null,
    Object? maxRounds = null,
    Object? history = null,
    Object? aiLevel = null,
    Object? turnStartedAt = null,
    Object? remainingTimeMs = null,
    Object? isOvertime = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as GameStatus,
            currentTurn: null == currentTurn
                ? _value.currentTurn
                : currentTurn // ignore: cast_nullable_to_non_nullable
                      as TurnPlayer,
            playerMistakeCount: null == playerMistakeCount
                ? _value.playerMistakeCount
                : playerMistakeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            aiMistakeCount: null == aiMistakeCount
                ? _value.aiMistakeCount
                : aiMistakeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            playerCapturedChars: null == playerCapturedChars
                ? _value.playerCapturedChars
                : playerCapturedChars // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            aiCapturedChars: null == aiCapturedChars
                ? _value.aiCapturedChars
                : aiCapturedChars // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            lastWord: freezed == lastWord
                ? _value.lastWord
                : lastWord // ignore: cast_nullable_to_non_nullable
                      as String?,
            expectedStartChar: freezed == expectedStartChar
                ? _value.expectedStartChar
                : expectedStartChar // ignore: cast_nullable_to_non_nullable
                      as String?,
            turnCount: null == turnCount
                ? _value.turnCount
                : turnCount // ignore: cast_nullable_to_non_nullable
                      as int,
            roundCount: null == roundCount
                ? _value.roundCount
                : roundCount // ignore: cast_nullable_to_non_nullable
                      as int,
            maxRounds: null == maxRounds
                ? _value.maxRounds
                : maxRounds // ignore: cast_nullable_to_non_nullable
                      as int,
            history: null == history
                ? _value.history
                : history // ignore: cast_nullable_to_non_nullable
                      as List<TurnHistoryEntry>,
            aiLevel: null == aiLevel
                ? _value.aiLevel
                : aiLevel // ignore: cast_nullable_to_non_nullable
                      as int,
            turnStartedAt: null == turnStartedAt
                ? _value.turnStartedAt
                : turnStartedAt // ignore: cast_nullable_to_non_nullable
                      as String,
            remainingTimeMs: null == remainingTimeMs
                ? _value.remainingTimeMs
                : remainingTimeMs // ignore: cast_nullable_to_non_nullable
                      as int,
            isOvertime: null == isOvertime
                ? _value.isOvertime
                : isOvertime // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameSessionImplCopyWith<$Res>
    implements $GameSessionCopyWith<$Res> {
  factory _$$GameSessionImplCopyWith(
    _$GameSessionImpl value,
    $Res Function(_$GameSessionImpl) then,
  ) = __$$GameSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    GameStatus status,
    TurnPlayer currentTurn,
    int playerMistakeCount,
    int aiMistakeCount,
    List<String> playerCapturedChars,
    List<String> aiCapturedChars,
    String? lastWord,
    String? expectedStartChar,
    int turnCount,
    int roundCount,
    int maxRounds,
    List<TurnHistoryEntry> history,
    int aiLevel,
    String turnStartedAt,
    int remainingTimeMs,
    bool isOvertime,
  });
}

/// @nodoc
class __$$GameSessionImplCopyWithImpl<$Res>
    extends _$GameSessionCopyWithImpl<$Res, _$GameSessionImpl>
    implements _$$GameSessionImplCopyWith<$Res> {
  __$$GameSessionImplCopyWithImpl(
    _$GameSessionImpl _value,
    $Res Function(_$GameSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? currentTurn = null,
    Object? playerMistakeCount = null,
    Object? aiMistakeCount = null,
    Object? playerCapturedChars = null,
    Object? aiCapturedChars = null,
    Object? lastWord = freezed,
    Object? expectedStartChar = freezed,
    Object? turnCount = null,
    Object? roundCount = null,
    Object? maxRounds = null,
    Object? history = null,
    Object? aiLevel = null,
    Object? turnStartedAt = null,
    Object? remainingTimeMs = null,
    Object? isOvertime = null,
  }) {
    return _then(
      _$GameSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as GameStatus,
        currentTurn: null == currentTurn
            ? _value.currentTurn
            : currentTurn // ignore: cast_nullable_to_non_nullable
                  as TurnPlayer,
        playerMistakeCount: null == playerMistakeCount
            ? _value.playerMistakeCount
            : playerMistakeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        aiMistakeCount: null == aiMistakeCount
            ? _value.aiMistakeCount
            : aiMistakeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        playerCapturedChars: null == playerCapturedChars
            ? _value._playerCapturedChars
            : playerCapturedChars // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        aiCapturedChars: null == aiCapturedChars
            ? _value._aiCapturedChars
            : aiCapturedChars // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        lastWord: freezed == lastWord
            ? _value.lastWord
            : lastWord // ignore: cast_nullable_to_non_nullable
                  as String?,
        expectedStartChar: freezed == expectedStartChar
            ? _value.expectedStartChar
            : expectedStartChar // ignore: cast_nullable_to_non_nullable
                  as String?,
        turnCount: null == turnCount
            ? _value.turnCount
            : turnCount // ignore: cast_nullable_to_non_nullable
                  as int,
        roundCount: null == roundCount
            ? _value.roundCount
            : roundCount // ignore: cast_nullable_to_non_nullable
                  as int,
        maxRounds: null == maxRounds
            ? _value.maxRounds
            : maxRounds // ignore: cast_nullable_to_non_nullable
                  as int,
        history: null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<TurnHistoryEntry>,
        aiLevel: null == aiLevel
            ? _value.aiLevel
            : aiLevel // ignore: cast_nullable_to_non_nullable
                  as int,
        turnStartedAt: null == turnStartedAt
            ? _value.turnStartedAt
            : turnStartedAt // ignore: cast_nullable_to_non_nullable
                  as String,
        remainingTimeMs: null == remainingTimeMs
            ? _value.remainingTimeMs
            : remainingTimeMs // ignore: cast_nullable_to_non_nullable
                  as int,
        isOvertime: null == isOvertime
            ? _value.isOvertime
            : isOvertime // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameSessionImpl implements _GameSession {
  const _$GameSessionImpl({
    required this.id,
    required this.status,
    required this.currentTurn,
    required this.playerMistakeCount,
    required this.aiMistakeCount,
    required final List<String> playerCapturedChars,
    required final List<String> aiCapturedChars,
    this.lastWord,
    this.expectedStartChar,
    required this.turnCount,
    required this.roundCount,
    required this.maxRounds,
    required final List<TurnHistoryEntry> history,
    required this.aiLevel,
    required this.turnStartedAt,
    required this.remainingTimeMs,
    required this.isOvertime,
  }) : _playerCapturedChars = playerCapturedChars,
       _aiCapturedChars = aiCapturedChars,
       _history = history;

  factory _$GameSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameSessionImplFromJson(json);

  @override
  final String id;
  @override
  final GameStatus status;
  @override
  final TurnPlayer currentTurn;
  @override
  final int playerMistakeCount;
  @override
  final int aiMistakeCount;
  final List<String> _playerCapturedChars;
  @override
  List<String> get playerCapturedChars {
    if (_playerCapturedChars is EqualUnmodifiableListView)
      return _playerCapturedChars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playerCapturedChars);
  }

  final List<String> _aiCapturedChars;
  @override
  List<String> get aiCapturedChars {
    if (_aiCapturedChars is EqualUnmodifiableListView) return _aiCapturedChars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_aiCapturedChars);
  }

  @override
  final String? lastWord;
  @override
  final String? expectedStartChar;
  @override
  final int turnCount;
  @override
  final int roundCount;
  @override
  final int maxRounds;
  final List<TurnHistoryEntry> _history;
  @override
  List<TurnHistoryEntry> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @override
  final int aiLevel;
  @override
  final String turnStartedAt;
  @override
  final int remainingTimeMs;
  @override
  final bool isOvertime;

  @override
  String toString() {
    return 'GameSession(id: $id, status: $status, currentTurn: $currentTurn, playerMistakeCount: $playerMistakeCount, aiMistakeCount: $aiMistakeCount, playerCapturedChars: $playerCapturedChars, aiCapturedChars: $aiCapturedChars, lastWord: $lastWord, expectedStartChar: $expectedStartChar, turnCount: $turnCount, roundCount: $roundCount, maxRounds: $maxRounds, history: $history, aiLevel: $aiLevel, turnStartedAt: $turnStartedAt, remainingTimeMs: $remainingTimeMs, isOvertime: $isOvertime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.currentTurn, currentTurn) ||
                other.currentTurn == currentTurn) &&
            (identical(other.playerMistakeCount, playerMistakeCount) ||
                other.playerMistakeCount == playerMistakeCount) &&
            (identical(other.aiMistakeCount, aiMistakeCount) ||
                other.aiMistakeCount == aiMistakeCount) &&
            const DeepCollectionEquality().equals(
              other._playerCapturedChars,
              _playerCapturedChars,
            ) &&
            const DeepCollectionEquality().equals(
              other._aiCapturedChars,
              _aiCapturedChars,
            ) &&
            (identical(other.lastWord, lastWord) ||
                other.lastWord == lastWord) &&
            (identical(other.expectedStartChar, expectedStartChar) ||
                other.expectedStartChar == expectedStartChar) &&
            (identical(other.turnCount, turnCount) ||
                other.turnCount == turnCount) &&
            (identical(other.roundCount, roundCount) ||
                other.roundCount == roundCount) &&
            (identical(other.maxRounds, maxRounds) ||
                other.maxRounds == maxRounds) &&
            const DeepCollectionEquality().equals(other._history, _history) &&
            (identical(other.aiLevel, aiLevel) || other.aiLevel == aiLevel) &&
            (identical(other.turnStartedAt, turnStartedAt) ||
                other.turnStartedAt == turnStartedAt) &&
            (identical(other.remainingTimeMs, remainingTimeMs) ||
                other.remainingTimeMs == remainingTimeMs) &&
            (identical(other.isOvertime, isOvertime) ||
                other.isOvertime == isOvertime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    status,
    currentTurn,
    playerMistakeCount,
    aiMistakeCount,
    const DeepCollectionEquality().hash(_playerCapturedChars),
    const DeepCollectionEquality().hash(_aiCapturedChars),
    lastWord,
    expectedStartChar,
    turnCount,
    roundCount,
    maxRounds,
    const DeepCollectionEquality().hash(_history),
    aiLevel,
    turnStartedAt,
    remainingTimeMs,
    isOvertime,
  );

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameSessionImplCopyWith<_$GameSessionImpl> get copyWith =>
      __$$GameSessionImplCopyWithImpl<_$GameSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameSessionImplToJson(this);
  }
}

abstract class _GameSession implements GameSession {
  const factory _GameSession({
    required final String id,
    required final GameStatus status,
    required final TurnPlayer currentTurn,
    required final int playerMistakeCount,
    required final int aiMistakeCount,
    required final List<String> playerCapturedChars,
    required final List<String> aiCapturedChars,
    final String? lastWord,
    final String? expectedStartChar,
    required final int turnCount,
    required final int roundCount,
    required final int maxRounds,
    required final List<TurnHistoryEntry> history,
    required final int aiLevel,
    required final String turnStartedAt,
    required final int remainingTimeMs,
    required final bool isOvertime,
  }) = _$GameSessionImpl;

  factory _GameSession.fromJson(Map<String, dynamic> json) =
      _$GameSessionImpl.fromJson;

  @override
  String get id;
  @override
  GameStatus get status;
  @override
  TurnPlayer get currentTurn;
  @override
  int get playerMistakeCount;
  @override
  int get aiMistakeCount;
  @override
  List<String> get playerCapturedChars;
  @override
  List<String> get aiCapturedChars;
  @override
  String? get lastWord;
  @override
  String? get expectedStartChar;
  @override
  int get turnCount;
  @override
  int get roundCount;
  @override
  int get maxRounds;
  @override
  List<TurnHistoryEntry> get history;
  @override
  int get aiLevel;
  @override
  String get turnStartedAt;
  @override
  int get remainingTimeMs;
  @override
  bool get isOvertime;

  /// Create a copy of GameSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameSessionImplCopyWith<_$GameSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AiFirstMove _$AiFirstMoveFromJson(Map<String, dynamic> json) {
  return _AiFirstMove.fromJson(json);
}

/// @nodoc
mixin _$AiFirstMove {
  String get word => throw _privateConstructorUsedError;
  List<String> get capturedChars => throw _privateConstructorUsedError;

  /// Serializes this AiFirstMove to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AiFirstMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AiFirstMoveCopyWith<AiFirstMove> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AiFirstMoveCopyWith<$Res> {
  factory $AiFirstMoveCopyWith(
    AiFirstMove value,
    $Res Function(AiFirstMove) then,
  ) = _$AiFirstMoveCopyWithImpl<$Res, AiFirstMove>;
  @useResult
  $Res call({String word, List<String> capturedChars});
}

/// @nodoc
class _$AiFirstMoveCopyWithImpl<$Res, $Val extends AiFirstMove>
    implements $AiFirstMoveCopyWith<$Res> {
  _$AiFirstMoveCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AiFirstMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? word = null, Object? capturedChars = null}) {
    return _then(
      _value.copyWith(
            word: null == word
                ? _value.word
                : word // ignore: cast_nullable_to_non_nullable
                      as String,
            capturedChars: null == capturedChars
                ? _value.capturedChars
                : capturedChars // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AiFirstMoveImplCopyWith<$Res>
    implements $AiFirstMoveCopyWith<$Res> {
  factory _$$AiFirstMoveImplCopyWith(
    _$AiFirstMoveImpl value,
    $Res Function(_$AiFirstMoveImpl) then,
  ) = __$$AiFirstMoveImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String word, List<String> capturedChars});
}

/// @nodoc
class __$$AiFirstMoveImplCopyWithImpl<$Res>
    extends _$AiFirstMoveCopyWithImpl<$Res, _$AiFirstMoveImpl>
    implements _$$AiFirstMoveImplCopyWith<$Res> {
  __$$AiFirstMoveImplCopyWithImpl(
    _$AiFirstMoveImpl _value,
    $Res Function(_$AiFirstMoveImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AiFirstMove
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? word = null, Object? capturedChars = null}) {
    return _then(
      _$AiFirstMoveImpl(
        word: null == word
            ? _value.word
            : word // ignore: cast_nullable_to_non_nullable
                  as String,
        capturedChars: null == capturedChars
            ? _value._capturedChars
            : capturedChars // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AiFirstMoveImpl implements _AiFirstMove {
  const _$AiFirstMoveImpl({
    required this.word,
    required final List<String> capturedChars,
  }) : _capturedChars = capturedChars;

  factory _$AiFirstMoveImpl.fromJson(Map<String, dynamic> json) =>
      _$$AiFirstMoveImplFromJson(json);

  @override
  final String word;
  final List<String> _capturedChars;
  @override
  List<String> get capturedChars {
    if (_capturedChars is EqualUnmodifiableListView) return _capturedChars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_capturedChars);
  }

  @override
  String toString() {
    return 'AiFirstMove(word: $word, capturedChars: $capturedChars)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AiFirstMoveImpl &&
            (identical(other.word, word) || other.word == word) &&
            const DeepCollectionEquality().equals(
              other._capturedChars,
              _capturedChars,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    word,
    const DeepCollectionEquality().hash(_capturedChars),
  );

  /// Create a copy of AiFirstMove
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AiFirstMoveImplCopyWith<_$AiFirstMoveImpl> get copyWith =>
      __$$AiFirstMoveImplCopyWithImpl<_$AiFirstMoveImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AiFirstMoveImplToJson(this);
  }
}

abstract class _AiFirstMove implements AiFirstMove {
  const factory _AiFirstMove({
    required final String word,
    required final List<String> capturedChars,
  }) = _$AiFirstMoveImpl;

  factory _AiFirstMove.fromJson(Map<String, dynamic> json) =
      _$AiFirstMoveImpl.fromJson;

  @override
  String get word;
  @override
  List<String> get capturedChars;

  /// Create a copy of AiFirstMove
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AiFirstMoveImplCopyWith<_$AiFirstMoveImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StartGameResponse _$StartGameResponseFromJson(Map<String, dynamic> json) {
  return _StartGameResponse.fromJson(json);
}

/// @nodoc
mixin _$StartGameResponse {
  GameSession get session => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  int get dictionarySize => throw _privateConstructorUsedError;
  String get startChar => throw _privateConstructorUsedError;
  TurnPlayer get firstTurn => throw _privateConstructorUsedError;
  AiFirstMove? get aiFirstMove => throw _privateConstructorUsedError;

  /// Serializes this StartGameResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StartGameResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StartGameResponseCopyWith<StartGameResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StartGameResponseCopyWith<$Res> {
  factory $StartGameResponseCopyWith(
    StartGameResponse value,
    $Res Function(StartGameResponse) then,
  ) = _$StartGameResponseCopyWithImpl<$Res, StartGameResponse>;
  @useResult
  $Res call({
    GameSession session,
    String message,
    int dictionarySize,
    String startChar,
    TurnPlayer firstTurn,
    AiFirstMove? aiFirstMove,
  });

  $GameSessionCopyWith<$Res> get session;
  $AiFirstMoveCopyWith<$Res>? get aiFirstMove;
}

/// @nodoc
class _$StartGameResponseCopyWithImpl<$Res, $Val extends StartGameResponse>
    implements $StartGameResponseCopyWith<$Res> {
  _$StartGameResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StartGameResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? session = null,
    Object? message = null,
    Object? dictionarySize = null,
    Object? startChar = null,
    Object? firstTurn = null,
    Object? aiFirstMove = freezed,
  }) {
    return _then(
      _value.copyWith(
            session: null == session
                ? _value.session
                : session // ignore: cast_nullable_to_non_nullable
                      as GameSession,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            dictionarySize: null == dictionarySize
                ? _value.dictionarySize
                : dictionarySize // ignore: cast_nullable_to_non_nullable
                      as int,
            startChar: null == startChar
                ? _value.startChar
                : startChar // ignore: cast_nullable_to_non_nullable
                      as String,
            firstTurn: null == firstTurn
                ? _value.firstTurn
                : firstTurn // ignore: cast_nullable_to_non_nullable
                      as TurnPlayer,
            aiFirstMove: freezed == aiFirstMove
                ? _value.aiFirstMove
                : aiFirstMove // ignore: cast_nullable_to_non_nullable
                      as AiFirstMove?,
          )
          as $Val,
    );
  }

  /// Create a copy of StartGameResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameSessionCopyWith<$Res> get session {
    return $GameSessionCopyWith<$Res>(_value.session, (value) {
      return _then(_value.copyWith(session: value) as $Val);
    });
  }

  /// Create a copy of StartGameResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AiFirstMoveCopyWith<$Res>? get aiFirstMove {
    if (_value.aiFirstMove == null) {
      return null;
    }

    return $AiFirstMoveCopyWith<$Res>(_value.aiFirstMove!, (value) {
      return _then(_value.copyWith(aiFirstMove: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StartGameResponseImplCopyWith<$Res>
    implements $StartGameResponseCopyWith<$Res> {
  factory _$$StartGameResponseImplCopyWith(
    _$StartGameResponseImpl value,
    $Res Function(_$StartGameResponseImpl) then,
  ) = __$$StartGameResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    GameSession session,
    String message,
    int dictionarySize,
    String startChar,
    TurnPlayer firstTurn,
    AiFirstMove? aiFirstMove,
  });

  @override
  $GameSessionCopyWith<$Res> get session;
  @override
  $AiFirstMoveCopyWith<$Res>? get aiFirstMove;
}

/// @nodoc
class __$$StartGameResponseImplCopyWithImpl<$Res>
    extends _$StartGameResponseCopyWithImpl<$Res, _$StartGameResponseImpl>
    implements _$$StartGameResponseImplCopyWith<$Res> {
  __$$StartGameResponseImplCopyWithImpl(
    _$StartGameResponseImpl _value,
    $Res Function(_$StartGameResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StartGameResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? session = null,
    Object? message = null,
    Object? dictionarySize = null,
    Object? startChar = null,
    Object? firstTurn = null,
    Object? aiFirstMove = freezed,
  }) {
    return _then(
      _$StartGameResponseImpl(
        session: null == session
            ? _value.session
            : session // ignore: cast_nullable_to_non_nullable
                  as GameSession,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        dictionarySize: null == dictionarySize
            ? _value.dictionarySize
            : dictionarySize // ignore: cast_nullable_to_non_nullable
                  as int,
        startChar: null == startChar
            ? _value.startChar
            : startChar // ignore: cast_nullable_to_non_nullable
                  as String,
        firstTurn: null == firstTurn
            ? _value.firstTurn
            : firstTurn // ignore: cast_nullable_to_non_nullable
                  as TurnPlayer,
        aiFirstMove: freezed == aiFirstMove
            ? _value.aiFirstMove
            : aiFirstMove // ignore: cast_nullable_to_non_nullable
                  as AiFirstMove?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StartGameResponseImpl implements _StartGameResponse {
  const _$StartGameResponseImpl({
    required this.session,
    required this.message,
    required this.dictionarySize,
    required this.startChar,
    required this.firstTurn,
    this.aiFirstMove,
  });

  factory _$StartGameResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$StartGameResponseImplFromJson(json);

  @override
  final GameSession session;
  @override
  final String message;
  @override
  final int dictionarySize;
  @override
  final String startChar;
  @override
  final TurnPlayer firstTurn;
  @override
  final AiFirstMove? aiFirstMove;

  @override
  String toString() {
    return 'StartGameResponse(session: $session, message: $message, dictionarySize: $dictionarySize, startChar: $startChar, firstTurn: $firstTurn, aiFirstMove: $aiFirstMove)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StartGameResponseImpl &&
            (identical(other.session, session) || other.session == session) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.dictionarySize, dictionarySize) ||
                other.dictionarySize == dictionarySize) &&
            (identical(other.startChar, startChar) ||
                other.startChar == startChar) &&
            (identical(other.firstTurn, firstTurn) ||
                other.firstTurn == firstTurn) &&
            (identical(other.aiFirstMove, aiFirstMove) ||
                other.aiFirstMove == aiFirstMove));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    session,
    message,
    dictionarySize,
    startChar,
    firstTurn,
    aiFirstMove,
  );

  /// Create a copy of StartGameResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StartGameResponseImplCopyWith<_$StartGameResponseImpl> get copyWith =>
      __$$StartGameResponseImplCopyWithImpl<_$StartGameResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StartGameResponseImplToJson(this);
  }
}

abstract class _StartGameResponse implements StartGameResponse {
  const factory _StartGameResponse({
    required final GameSession session,
    required final String message,
    required final int dictionarySize,
    required final String startChar,
    required final TurnPlayer firstTurn,
    final AiFirstMove? aiFirstMove,
  }) = _$StartGameResponseImpl;

  factory _StartGameResponse.fromJson(Map<String, dynamic> json) =
      _$StartGameResponseImpl.fromJson;

  @override
  GameSession get session;
  @override
  String get message;
  @override
  int get dictionarySize;
  @override
  String get startChar;
  @override
  TurnPlayer get firstTurn;
  @override
  AiFirstMove? get aiFirstMove;

  /// Create a copy of StartGameResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StartGameResponseImplCopyWith<_$StartGameResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TurnResult _$TurnResultFromJson(Map<String, dynamic> json) {
  return _TurnResult.fromJson(json);
}

/// @nodoc
mixin _$TurnResult {
  String get word => throw _privateConstructorUsedError;
  bool get isValid => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  List<String> get capturedChars => throw _privateConstructorUsedError;
  bool get timeExpired => throw _privateConstructorUsedError;

  /// Serializes this TurnResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TurnResultCopyWith<TurnResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TurnResultCopyWith<$Res> {
  factory $TurnResultCopyWith(
    TurnResult value,
    $Res Function(TurnResult) then,
  ) = _$TurnResultCopyWithImpl<$Res, TurnResult>;
  @useResult
  $Res call({
    String word,
    bool isValid,
    String message,
    List<String> capturedChars,
    bool timeExpired,
  });
}

/// @nodoc
class _$TurnResultCopyWithImpl<$Res, $Val extends TurnResult>
    implements $TurnResultCopyWith<$Res> {
  _$TurnResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? isValid = null,
    Object? message = null,
    Object? capturedChars = null,
    Object? timeExpired = null,
  }) {
    return _then(
      _value.copyWith(
            word: null == word
                ? _value.word
                : word // ignore: cast_nullable_to_non_nullable
                      as String,
            isValid: null == isValid
                ? _value.isValid
                : isValid // ignore: cast_nullable_to_non_nullable
                      as bool,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            capturedChars: null == capturedChars
                ? _value.capturedChars
                : capturedChars // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            timeExpired: null == timeExpired
                ? _value.timeExpired
                : timeExpired // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TurnResultImplCopyWith<$Res>
    implements $TurnResultCopyWith<$Res> {
  factory _$$TurnResultImplCopyWith(
    _$TurnResultImpl value,
    $Res Function(_$TurnResultImpl) then,
  ) = __$$TurnResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String word,
    bool isValid,
    String message,
    List<String> capturedChars,
    bool timeExpired,
  });
}

/// @nodoc
class __$$TurnResultImplCopyWithImpl<$Res>
    extends _$TurnResultCopyWithImpl<$Res, _$TurnResultImpl>
    implements _$$TurnResultImplCopyWith<$Res> {
  __$$TurnResultImplCopyWithImpl(
    _$TurnResultImpl _value,
    $Res Function(_$TurnResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? isValid = null,
    Object? message = null,
    Object? capturedChars = null,
    Object? timeExpired = null,
  }) {
    return _then(
      _$TurnResultImpl(
        word: null == word
            ? _value.word
            : word // ignore: cast_nullable_to_non_nullable
                  as String,
        isValid: null == isValid
            ? _value.isValid
            : isValid // ignore: cast_nullable_to_non_nullable
                  as bool,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        capturedChars: null == capturedChars
            ? _value._capturedChars
            : capturedChars // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        timeExpired: null == timeExpired
            ? _value.timeExpired
            : timeExpired // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TurnResultImpl implements _TurnResult {
  const _$TurnResultImpl({
    required this.word,
    required this.isValid,
    required this.message,
    required final List<String> capturedChars,
    this.timeExpired = false,
  }) : _capturedChars = capturedChars;

  factory _$TurnResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$TurnResultImplFromJson(json);

  @override
  final String word;
  @override
  final bool isValid;
  @override
  final String message;
  final List<String> _capturedChars;
  @override
  List<String> get capturedChars {
    if (_capturedChars is EqualUnmodifiableListView) return _capturedChars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_capturedChars);
  }

  @override
  @JsonKey()
  final bool timeExpired;

  @override
  String toString() {
    return 'TurnResult(word: $word, isValid: $isValid, message: $message, capturedChars: $capturedChars, timeExpired: $timeExpired)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TurnResultImpl &&
            (identical(other.word, word) || other.word == word) &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            (identical(other.message, message) || other.message == message) &&
            const DeepCollectionEquality().equals(
              other._capturedChars,
              _capturedChars,
            ) &&
            (identical(other.timeExpired, timeExpired) ||
                other.timeExpired == timeExpired));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    word,
    isValid,
    message,
    const DeepCollectionEquality().hash(_capturedChars),
    timeExpired,
  );

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TurnResultImplCopyWith<_$TurnResultImpl> get copyWith =>
      __$$TurnResultImplCopyWithImpl<_$TurnResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TurnResultImplToJson(this);
  }
}

abstract class _TurnResult implements TurnResult {
  const factory _TurnResult({
    required final String word,
    required final bool isValid,
    required final String message,
    required final List<String> capturedChars,
    final bool timeExpired,
  }) = _$TurnResultImpl;

  factory _TurnResult.fromJson(Map<String, dynamic> json) =
      _$TurnResultImpl.fromJson;

  @override
  String get word;
  @override
  bool get isValid;
  @override
  String get message;
  @override
  List<String> get capturedChars;
  @override
  bool get timeExpired;

  /// Create a copy of TurnResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TurnResultImplCopyWith<_$TurnResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SubmitWordResponse _$SubmitWordResponseFromJson(Map<String, dynamic> json) {
  return _SubmitWordResponse.fromJson(json);
}

/// @nodoc
mixin _$SubmitWordResponse {
  GameSession get session => throw _privateConstructorUsedError;
  TurnResult get playerResult => throw _privateConstructorUsedError;
  TurnResult? get aiResult => throw _privateConstructorUsedError;
  bool get gameOver => throw _privateConstructorUsedError;
  TurnPlayer? get winner => throw _privateConstructorUsedError;
  bool get overtimeStarted => throw _privateConstructorUsedError;

  /// Serializes this SubmitWordResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubmitWordResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubmitWordResponseCopyWith<SubmitWordResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubmitWordResponseCopyWith<$Res> {
  factory $SubmitWordResponseCopyWith(
    SubmitWordResponse value,
    $Res Function(SubmitWordResponse) then,
  ) = _$SubmitWordResponseCopyWithImpl<$Res, SubmitWordResponse>;
  @useResult
  $Res call({
    GameSession session,
    TurnResult playerResult,
    TurnResult? aiResult,
    bool gameOver,
    TurnPlayer? winner,
    bool overtimeStarted,
  });

  $GameSessionCopyWith<$Res> get session;
  $TurnResultCopyWith<$Res> get playerResult;
  $TurnResultCopyWith<$Res>? get aiResult;
}

/// @nodoc
class _$SubmitWordResponseCopyWithImpl<$Res, $Val extends SubmitWordResponse>
    implements $SubmitWordResponseCopyWith<$Res> {
  _$SubmitWordResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubmitWordResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? session = null,
    Object? playerResult = null,
    Object? aiResult = freezed,
    Object? gameOver = null,
    Object? winner = freezed,
    Object? overtimeStarted = null,
  }) {
    return _then(
      _value.copyWith(
            session: null == session
                ? _value.session
                : session // ignore: cast_nullable_to_non_nullable
                      as GameSession,
            playerResult: null == playerResult
                ? _value.playerResult
                : playerResult // ignore: cast_nullable_to_non_nullable
                      as TurnResult,
            aiResult: freezed == aiResult
                ? _value.aiResult
                : aiResult // ignore: cast_nullable_to_non_nullable
                      as TurnResult?,
            gameOver: null == gameOver
                ? _value.gameOver
                : gameOver // ignore: cast_nullable_to_non_nullable
                      as bool,
            winner: freezed == winner
                ? _value.winner
                : winner // ignore: cast_nullable_to_non_nullable
                      as TurnPlayer?,
            overtimeStarted: null == overtimeStarted
                ? _value.overtimeStarted
                : overtimeStarted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of SubmitWordResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameSessionCopyWith<$Res> get session {
    return $GameSessionCopyWith<$Res>(_value.session, (value) {
      return _then(_value.copyWith(session: value) as $Val);
    });
  }

  /// Create a copy of SubmitWordResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TurnResultCopyWith<$Res> get playerResult {
    return $TurnResultCopyWith<$Res>(_value.playerResult, (value) {
      return _then(_value.copyWith(playerResult: value) as $Val);
    });
  }

  /// Create a copy of SubmitWordResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TurnResultCopyWith<$Res>? get aiResult {
    if (_value.aiResult == null) {
      return null;
    }

    return $TurnResultCopyWith<$Res>(_value.aiResult!, (value) {
      return _then(_value.copyWith(aiResult: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SubmitWordResponseImplCopyWith<$Res>
    implements $SubmitWordResponseCopyWith<$Res> {
  factory _$$SubmitWordResponseImplCopyWith(
    _$SubmitWordResponseImpl value,
    $Res Function(_$SubmitWordResponseImpl) then,
  ) = __$$SubmitWordResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    GameSession session,
    TurnResult playerResult,
    TurnResult? aiResult,
    bool gameOver,
    TurnPlayer? winner,
    bool overtimeStarted,
  });

  @override
  $GameSessionCopyWith<$Res> get session;
  @override
  $TurnResultCopyWith<$Res> get playerResult;
  @override
  $TurnResultCopyWith<$Res>? get aiResult;
}

/// @nodoc
class __$$SubmitWordResponseImplCopyWithImpl<$Res>
    extends _$SubmitWordResponseCopyWithImpl<$Res, _$SubmitWordResponseImpl>
    implements _$$SubmitWordResponseImplCopyWith<$Res> {
  __$$SubmitWordResponseImplCopyWithImpl(
    _$SubmitWordResponseImpl _value,
    $Res Function(_$SubmitWordResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SubmitWordResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? session = null,
    Object? playerResult = null,
    Object? aiResult = freezed,
    Object? gameOver = null,
    Object? winner = freezed,
    Object? overtimeStarted = null,
  }) {
    return _then(
      _$SubmitWordResponseImpl(
        session: null == session
            ? _value.session
            : session // ignore: cast_nullable_to_non_nullable
                  as GameSession,
        playerResult: null == playerResult
            ? _value.playerResult
            : playerResult // ignore: cast_nullable_to_non_nullable
                  as TurnResult,
        aiResult: freezed == aiResult
            ? _value.aiResult
            : aiResult // ignore: cast_nullable_to_non_nullable
                  as TurnResult?,
        gameOver: null == gameOver
            ? _value.gameOver
            : gameOver // ignore: cast_nullable_to_non_nullable
                  as bool,
        winner: freezed == winner
            ? _value.winner
            : winner // ignore: cast_nullable_to_non_nullable
                  as TurnPlayer?,
        overtimeStarted: null == overtimeStarted
            ? _value.overtimeStarted
            : overtimeStarted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SubmitWordResponseImpl implements _SubmitWordResponse {
  const _$SubmitWordResponseImpl({
    required this.session,
    required this.playerResult,
    this.aiResult,
    required this.gameOver,
    this.winner,
    this.overtimeStarted = false,
  });

  factory _$SubmitWordResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubmitWordResponseImplFromJson(json);

  @override
  final GameSession session;
  @override
  final TurnResult playerResult;
  @override
  final TurnResult? aiResult;
  @override
  final bool gameOver;
  @override
  final TurnPlayer? winner;
  @override
  @JsonKey()
  final bool overtimeStarted;

  @override
  String toString() {
    return 'SubmitWordResponse(session: $session, playerResult: $playerResult, aiResult: $aiResult, gameOver: $gameOver, winner: $winner, overtimeStarted: $overtimeStarted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubmitWordResponseImpl &&
            (identical(other.session, session) || other.session == session) &&
            (identical(other.playerResult, playerResult) ||
                other.playerResult == playerResult) &&
            (identical(other.aiResult, aiResult) ||
                other.aiResult == aiResult) &&
            (identical(other.gameOver, gameOver) ||
                other.gameOver == gameOver) &&
            (identical(other.winner, winner) || other.winner == winner) &&
            (identical(other.overtimeStarted, overtimeStarted) ||
                other.overtimeStarted == overtimeStarted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    session,
    playerResult,
    aiResult,
    gameOver,
    winner,
    overtimeStarted,
  );

  /// Create a copy of SubmitWordResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubmitWordResponseImplCopyWith<_$SubmitWordResponseImpl> get copyWith =>
      __$$SubmitWordResponseImplCopyWithImpl<_$SubmitWordResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SubmitWordResponseImplToJson(this);
  }
}

abstract class _SubmitWordResponse implements SubmitWordResponse {
  const factory _SubmitWordResponse({
    required final GameSession session,
    required final TurnResult playerResult,
    final TurnResult? aiResult,
    required final bool gameOver,
    final TurnPlayer? winner,
    final bool overtimeStarted,
  }) = _$SubmitWordResponseImpl;

  factory _SubmitWordResponse.fromJson(Map<String, dynamic> json) =
      _$SubmitWordResponseImpl.fromJson;

  @override
  GameSession get session;
  @override
  TurnResult get playerResult;
  @override
  TurnResult? get aiResult;
  @override
  bool get gameOver;
  @override
  TurnPlayer? get winner;
  @override
  bool get overtimeStarted;

  /// Create a copy of SubmitWordResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubmitWordResponseImplCopyWith<_$SubmitWordResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CheckTimeResponse _$CheckTimeResponseFromJson(Map<String, dynamic> json) {
  return _CheckTimeResponse.fromJson(json);
}

/// @nodoc
mixin _$CheckTimeResponse {
  bool get expired => throw _privateConstructorUsedError;
  GameSession? get session => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;

  /// Serializes this CheckTimeResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CheckTimeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckTimeResponseCopyWith<CheckTimeResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckTimeResponseCopyWith<$Res> {
  factory $CheckTimeResponseCopyWith(
    CheckTimeResponse value,
    $Res Function(CheckTimeResponse) then,
  ) = _$CheckTimeResponseCopyWithImpl<$Res, CheckTimeResponse>;
  @useResult
  $Res call({bool expired, GameSession? session, String? message});

  $GameSessionCopyWith<$Res>? get session;
}

/// @nodoc
class _$CheckTimeResponseCopyWithImpl<$Res, $Val extends CheckTimeResponse>
    implements $CheckTimeResponseCopyWith<$Res> {
  _$CheckTimeResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckTimeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? expired = null,
    Object? session = freezed,
    Object? message = freezed,
  }) {
    return _then(
      _value.copyWith(
            expired: null == expired
                ? _value.expired
                : expired // ignore: cast_nullable_to_non_nullable
                      as bool,
            session: freezed == session
                ? _value.session
                : session // ignore: cast_nullable_to_non_nullable
                      as GameSession?,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of CheckTimeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameSessionCopyWith<$Res>? get session {
    if (_value.session == null) {
      return null;
    }

    return $GameSessionCopyWith<$Res>(_value.session!, (value) {
      return _then(_value.copyWith(session: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CheckTimeResponseImplCopyWith<$Res>
    implements $CheckTimeResponseCopyWith<$Res> {
  factory _$$CheckTimeResponseImplCopyWith(
    _$CheckTimeResponseImpl value,
    $Res Function(_$CheckTimeResponseImpl) then,
  ) = __$$CheckTimeResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool expired, GameSession? session, String? message});

  @override
  $GameSessionCopyWith<$Res>? get session;
}

/// @nodoc
class __$$CheckTimeResponseImplCopyWithImpl<$Res>
    extends _$CheckTimeResponseCopyWithImpl<$Res, _$CheckTimeResponseImpl>
    implements _$$CheckTimeResponseImplCopyWith<$Res> {
  __$$CheckTimeResponseImplCopyWithImpl(
    _$CheckTimeResponseImpl _value,
    $Res Function(_$CheckTimeResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CheckTimeResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? expired = null,
    Object? session = freezed,
    Object? message = freezed,
  }) {
    return _then(
      _$CheckTimeResponseImpl(
        expired: null == expired
            ? _value.expired
            : expired // ignore: cast_nullable_to_non_nullable
                  as bool,
        session: freezed == session
            ? _value.session
            : session // ignore: cast_nullable_to_non_nullable
                  as GameSession?,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CheckTimeResponseImpl implements _CheckTimeResponse {
  const _$CheckTimeResponseImpl({
    required this.expired,
    this.session,
    this.message,
  });

  factory _$CheckTimeResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckTimeResponseImplFromJson(json);

  @override
  final bool expired;
  @override
  final GameSession? session;
  @override
  final String? message;

  @override
  String toString() {
    return 'CheckTimeResponse(expired: $expired, session: $session, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckTimeResponseImpl &&
            (identical(other.expired, expired) || other.expired == expired) &&
            (identical(other.session, session) || other.session == session) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, expired, session, message);

  /// Create a copy of CheckTimeResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckTimeResponseImplCopyWith<_$CheckTimeResponseImpl> get copyWith =>
      __$$CheckTimeResponseImplCopyWithImpl<_$CheckTimeResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CheckTimeResponseImplToJson(this);
  }
}

abstract class _CheckTimeResponse implements CheckTimeResponse {
  const factory _CheckTimeResponse({
    required final bool expired,
    final GameSession? session,
    final String? message,
  }) = _$CheckTimeResponseImpl;

  factory _CheckTimeResponse.fromJson(Map<String, dynamic> json) =
      _$CheckTimeResponseImpl.fromJson;

  @override
  bool get expired;
  @override
  GameSession? get session;
  @override
  String? get message;

  /// Create a copy of CheckTimeResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckTimeResponseImplCopyWith<_$CheckTimeResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
