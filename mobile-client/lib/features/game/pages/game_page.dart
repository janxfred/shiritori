import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_models.dart';
import '../providers/game_provider.dart';

/// カタカナをひらがなに変換
String katakanaToHiragana(String str) {
  return str.replaceAllMapped(
    RegExp(r'[\u30A1-\u30F6]'),
    (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0x60),
  );
}

/// ゲームページ
class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitWord() {
    final word = katakanaToHiragana(_inputController.text.trim());
    if (word.isEmpty) return;
    
    ref.read(gameProvider.notifier).submitWord(word);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a0a0a),
              Color(0xFF2d1515),
              Color(0xFF1a0a0a),
            ],
          ),
        ),
        child: SafeArea(
          child: switch (state.phase) {
            GamePhase.title => _buildTitleScreen(state),
            GamePhase.playing => _buildPlayingScreen(state),
            GamePhase.overtimeAnnounce => _buildOvertimeAnnounceScreen(state),
            GamePhase.gameOver => _buildGameOverScreen(state),
          },
        ),
      ),
    );
  }

  /// タイトル画面
  Widget _buildTitleScreen(GameState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // タイトル
          const Text(
            '悪魔的',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFdc2626),
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'しりとり',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFFfef2f2),
              letterSpacing: 12,
            ),
          ),
          const SizedBox(height: 48),
          
          // レベル選択
          const Text(
            '難易度を選べ',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF9ca3af),
            ),
          ),
          const SizedBox(height: 16),
          
          for (final level in AiLevel.values) ...[
            _buildLevelButton(level, state.selectedLevel),
            const SizedBox(height: 12),
          ],
          
          const SizedBox(height: 32),
          
          // 開始ボタン
          ElevatedButton(
            onPressed: () => ref.read(gameProvider.notifier).startGame(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFdc2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '挑戦する',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// レベル選択ボタン
  Widget _buildLevelButton(AiLevel level, AiLevel selected) {
    final isSelected = level == selected;
    
    return GestureDetector(
      onTap: () => ref.read(gameProvider.notifier).selectLevel(level),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFdc2626).withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFFdc2626) : const Color(0xFF4b5563),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          level.displayName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFFfef2f2) : const Color(0xFF9ca3af),
          ),
        ),
      ),
    );
  }

  /// ゲーム画面
  Widget _buildPlayingScreen(GameState state) {
    final session = state.session;
    if (session == null) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // ヘッダー（ラウンド、確保文字数）
        _buildHeader(session, state),
        
        const SizedBox(height: 16),
        
        // タイマー
        _buildTimer(state),
        
        const SizedBox(height: 16),
        
        // 悪魔のメッセージ
        _buildDemonMessage(state),
        
        const SizedBox(height: 16),
        
        // 現在の状況
        _buildCurrentWord(session, state),
        
        // 履歴
        Expanded(child: _buildHistory(session)),
        
        // 入力欄
        _buildInputArea(session, state),
      ],
    );
  }

  /// ヘッダー
  Widget _buildHeader(GameSession session, GameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ラウンド
          Text(
            session.isOvertime
                ? '延長戦'
                : 'Round ${session.roundCount}/${session.maxRounds}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: session.isOvertime
                  ? const Color(0xFFfbbf24)
                  : const Color(0xFFfef2f2),
            ),
          ),
          // 確保文字数
          Row(
            children: [
              Text(
                '👤 ${session.playerCapturedChars.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF60a5fa),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '👿 ${session.aiCapturedChars.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFf87171),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// タイマー
  Widget _buildTimer(GameState state) {
    final seconds = (state.remainingTimeMs / 1000).ceil();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    
    final isWarning = seconds <= 30;
    final isCritical = seconds <= 10;
    
    return Text(
      timeStr,
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        color: isCritical
            ? const Color(0xFFdc2626)
            : isWarning
                ? const Color(0xFFfbbf24)
                : const Color(0xFFfef2f2),
      ),
    );
  }

  /// 悪魔のメッセージ
  Widget _buildDemonMessage(GameState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFdc2626).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Text('👿', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.isAiThinking ? '悪魔が思考中...' : state.demonMessage,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFFfef2f2),
                fontStyle: state.isAiThinking ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 現在の単語
  Widget _buildCurrentWord(GameSession session, GameState state) {
    final char = session.expectedStartChar;
    if (char == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          const Text(
            '次の文字',
            style: TextStyle(fontSize: 12, color: Color(0xFF9ca3af)),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFdc2626),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                char,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 履歴
  Widget _buildHistory(GameSession session) {
    if (session.history.isEmpty) {
      return const Center(
        child: Text(
          'しりとりを始めよう',
          style: TextStyle(color: Color(0xFF6b7280)),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: session.history.length,
      itemBuilder: (context, index) {
        final entry = session.history[session.history.length - 1 - index];
        final isPlayer = entry.player == TurnPlayer.player;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: isPlayer ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isPlayer) const Text('👿 ', style: TextStyle(fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isPlayer
                      ? const Color(0xFF1e40af).withOpacity(0.6)
                      : const Color(0xFF7f1d1d).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: entry.isValid
                        ? Colors.transparent
                        : const Color(0xFFfbbf24),
                    width: 2,
                  ),
                ),
                child: Text(
                  entry.word.isNotEmpty ? entry.word : '(無効)',
                  style: TextStyle(
                    fontSize: 16,
                    color: entry.isValid
                        ? const Color(0xFFfef2f2)
                        : const Color(0xFFfbbf24),
                  ),
                ),
              ),
              if (isPlayer) const Text(' 👤', style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  /// 入力欄
  Widget _buildInputArea(GameSession session, GameState state) {
    final canInput = session.currentTurn == TurnPlayer.player &&
        !state.isAiThinking &&
        !state.isSubmitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black38,
        border: Border(top: BorderSide(color: Color(0xFF374151))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              enabled: canInput,
              style: const TextStyle(color: Color(0xFFfef2f2), fontSize: 18),
              decoration: InputDecoration(
                hintText: canInput ? 'ひらがなで入力...' : '相手のターン...',
                hintStyle: const TextStyle(color: Color(0xFF6b7280)),
                filled: true,
                fillColor: const Color(0xFF1f2937),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _submitWord(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u30FC]')),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: canInput ? _submitWord : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFdc2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: const Color(0xFF4b5563),
            ),
            child: Text(
              state.isSubmitting ? '...' : '送信',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 延長戦告知画面
  Widget _buildOvertimeAnnounceScreen(GameState state) {
    final session = state.session;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '⚡',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            '延長戦',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFFfbbf24),
            ),
          ),
          const SizedBox(height: 24),
          if (session != null) ...[
            Text(
              '👤 ${session.playerCapturedChars.length} 文字',
              style: const TextStyle(fontSize: 18, color: Color(0xFF60a5fa)),
            ),
            const SizedBox(height: 8),
            Text(
              '👿 ${session.aiCapturedChars.length} 文字',
              style: const TextStyle(fontSize: 18, color: Color(0xFFf87171)),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            '互いに1回ずつ回答し\n確保文字数の少ない方が勝利',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
          ),
        ],
      ),
    );
  }

  /// ゲームオーバー画面
  Widget _buildGameOverScreen(GameState state) {
    final isPlayerWin = state.winner == TurnPlayer.player;
    final session = state.session;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 結果
          Text(
            isPlayerWin ? '🎉 勝利 🎉' : '💀 敗北 💀',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: isPlayerWin ? const Color(0xFF22c55e) : const Color(0xFFdc2626),
            ),
          ),
          const SizedBox(height: 24),
          
          // 最終スコア
          if (session != null) ...[
            Text(
              '👤 ${session.playerCapturedChars.length} 文字  vs  👿 ${session.aiCapturedChars.length} 文字',
              style: const TextStyle(fontSize: 18, color: Color(0xFFfef2f2)),
            ),
            const SizedBox(height: 32),
          ],
          
          // 悪魔のメッセージ
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFdc2626).withOpacity(0.5)),
            ),
            child: Text(
              state.demonMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFfef2f2),
              ),
            ),
          ),
          const SizedBox(height: 48),
          
          // リプレイ選択
          const Text(
            '再挑戦するか？',
            style: TextStyle(fontSize: 16, color: Color(0xFF9ca3af)),
          ),
          const SizedBox(height: 16),
          
          for (final level in AiLevel.values) ...[
            _buildRetryLevelButton(level),
            const SizedBox(height: 8),
          ],
          
          const SizedBox(height: 24),
          
          // タイトルへ戻る
          TextButton(
            onPressed: () => ref.read(gameProvider.notifier).returnToTitle(),
            child: const Text(
              'タイトルへ戻る',
              style: TextStyle(color: Color(0xFF6b7280)),
            ),
          ),
        ],
      ),
    );
  }

  /// リトライレベルボタン
  Widget _buildRetryLevelButton(AiLevel level) {
    return ElevatedButton(
      onPressed: () => ref.read(gameProvider.notifier).startGame(level),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7f1d1d),
        foregroundColor: Colors.white,
        minimumSize: const Size(200, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        level.displayName,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}


