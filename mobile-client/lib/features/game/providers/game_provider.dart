import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/game_api.dart';
import '../models/game_models.dart';

/// ゲームAPIプロバイダー
final gameApiProvider = Provider((ref) => GameApi());

/// ゲームフェーズ
enum GamePhase {
  title,
  playing,
  overtimeAnnounce,
  gameOver,
}

/// ゲーム状態
class GameState {
  final GamePhase phase;
  final GameSession? session;
  final String demonMessage;
  final TurnResult? lastPlayerResult;
  final TurnResult? lastAiResult;
  final TurnPlayer? winner;
  final bool isAiThinking;
  final bool isSubmitting;
  final int remainingTimeMs;
  final AiLevel selectedLevel;
  final String? startChar;
  final TurnPlayer? firstTurn;

  const GameState({
    this.phase = GamePhase.title,
    this.session,
    this.demonMessage = '',
    this.lastPlayerResult,
    this.lastAiResult,
    this.winner,
    this.isAiThinking = false,
    this.isSubmitting = false,
    this.remainingTimeMs = 120000,
    this.selectedLevel = AiLevel.medium,
    this.startChar,
    this.firstTurn,
  });

  GameState copyWith({
    GamePhase? phase,
    GameSession? session,
    String? demonMessage,
    TurnResult? lastPlayerResult,
    TurnResult? lastAiResult,
    TurnPlayer? winner,
    bool? isAiThinking,
    bool? isSubmitting,
    int? remainingTimeMs,
    AiLevel? selectedLevel,
    String? startChar,
    TurnPlayer? firstTurn,
    bool clearSession = false,
    bool clearLastResults = false,
    bool clearWinner = false,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      session: clearSession ? null : (session ?? this.session),
      demonMessage: demonMessage ?? this.demonMessage,
      lastPlayerResult: clearLastResults ? null : (lastPlayerResult ?? this.lastPlayerResult),
      lastAiResult: clearLastResults ? null : (lastAiResult ?? this.lastAiResult),
      winner: clearWinner ? null : (winner ?? this.winner),
      isAiThinking: isAiThinking ?? this.isAiThinking,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      remainingTimeMs: remainingTimeMs ?? this.remainingTimeMs,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      startChar: startChar ?? this.startChar,
      firstTurn: firstTurn ?? this.firstTurn,
    );
  }
}

/// ゲーム状態管理Notifier
class GameNotifier extends StateNotifier<GameState> {
  final GameApi _api;
  Timer? _timer;

  GameNotifier(this._api) : super(const GameState());

  /// AIレベルを選択
  void selectLevel(AiLevel level) {
    state = state.copyWith(selectedLevel: level);
  }

  /// ゲームを開始
  Future<void> startGame([AiLevel? level]) async {
    final aiLevel = level ?? state.selectedLevel;
    
    try {
      final response = await _api.startGame(aiLevel);
      
      state = state.copyWith(
        phase: GamePhase.playing,
        session: response.session,
        startChar: response.startChar,
        firstTurn: response.firstTurn,
        remainingTimeMs: 120000,
        clearLastResults: true,
        clearWinner: true,
      );
      
      // AI先攻の場合
      if (response.firstTurn == TurnPlayer.ai && response.aiFirstMove != null) {
        state = state.copyWith(
          isAiThinking: true,
          demonMessage: '我が先攻だ。「${response.startChar}」から始めるぞ…',
        );
        
        // 2秒後にAIの結果を表示
        await Future.delayed(const Duration(seconds: 2));
        
        state = state.copyWith(
          session: response.session,
          demonMessage: response.message,
          lastAiResult: TurnResult(
            word: response.aiFirstMove!.word,
            isValid: true,
            message: response.message,
            capturedChars: response.aiFirstMove!.capturedChars,
          ),
          isAiThinking: false,
          remainingTimeMs: 120000,
        );
      } else {
        // プレイヤー先攻
        state = state.copyWith(
          demonMessage: response.message,
          isAiThinking: false,
        );
      }
      
      _startTimer();
    } catch (e) {
      state = state.copyWith(demonMessage: 'エラー: $e');
    }
  }

  /// 単語を送信
  Future<void> submitWord(String word) async {
    if (state.session == null || state.isSubmitting || state.isAiThinking) return;
    
    state = state.copyWith(isSubmitting: true, clearLastResults: true);
    
    try {
      final response = await _api.submitWord(state.session!.id, word);
      
      state = state.copyWith(
        lastPlayerResult: response.playerResult,
        isSubmitting: false,
      );
      
      if (!response.playerResult.isValid) {
        state = state.copyWith(
          demonMessage: response.playerResult.message,
          session: response.session,
        );
        
        if (response.gameOver) {
          _stopTimer();
          state = state.copyWith(
            phase: GamePhase.gameOver,
            winner: response.winner,
          );
        }
        return;
      }
      
      // 有効な単語の場合
      if (response.aiResult != null) {
        state = state.copyWith(
          isAiThinking: true,
          demonMessage: 'ふむ…考えさせてもらおう…',
        );
        
        // 2秒待ってからAIの結果を表示
        await Future.delayed(const Duration(seconds: 2));
        
        state = state.copyWith(
          lastAiResult: response.aiResult,
          demonMessage: response.aiResult!.message,
          session: response.session,
          isAiThinking: false,
        );
        
        // 延長戦開始
        if (response.overtimeStarted == true) {
          _stopTimer();
          state = state.copyWith(phase: GamePhase.overtimeAnnounce);
          
          await Future.delayed(const Duration(seconds: 3));
          
          state = state.copyWith(
            phase: GamePhase.playing,
            remainingTimeMs: 120000,
          );
          _startTimer();
          return;
        }
        
        // ゲームオーバー
        if (response.gameOver) {
          _stopTimer();
          state = state.copyWith(
            phase: GamePhase.gameOver,
            winner: response.winner,
          );
          return;
        }
        
        // タイマーリセット
        state = state.copyWith(remainingTimeMs: 120000);
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        demonMessage: 'エラー: $e',
      );
    }
  }

  /// タイマーを開始
  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (state.session == null || state.phase != GamePhase.playing) return;
      if (state.isAiThinking) return;
      
      final turnStarted = DateTime.parse(state.session!.turnStartedAt).millisecondsSinceEpoch;
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - turnStarted;
      final remaining = (120000 - elapsed).clamp(0, 120000);
      
      state = state.copyWith(remainingTimeMs: remaining);
      
      // 時間切れ
      if (remaining <= 0) {
        try {
          final result = await _api.checkTime(state.session!.id);
          if (result.expired && result.session != null) {
            _stopTimer();
            state = state.copyWith(
              session: result.session,
              demonMessage: result.message ?? '時間切れだ。',
              winner: TurnPlayer.ai,
              phase: GamePhase.gameOver,
            );
          }
        } catch (e) {
          // ignore
        }
      }
    });
  }

  /// タイマーを停止
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// タイトルに戻る
  void returnToTitle() {
    _stopTimer();
    state = const GameState();
  }

  /// 延長戦告知から進む
  void proceedFromOvertimeAnnounce() {
    state = state.copyWith(
      phase: GamePhase.playing,
      remainingTimeMs: 120000,
    );
    _startTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// ゲーム状態プロバイダー
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref.watch(gameApiProvider));
});

