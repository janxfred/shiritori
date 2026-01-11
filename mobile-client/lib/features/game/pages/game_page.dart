/// 悪魔的しりとり ゲーム画面
import 'dart:async';
import 'package:flutter/material.dart';
import '../api/game_api.dart';
import '../models/game_models.dart';

/// 制限時間（ミリ秒）: 2分
const int timeLimitMs = 2 * 60 * 1000;

/// AIの応答遅延（ミリ秒）
const int aiResponseDelayMs = 1500;

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  final GameApi _api = GameApi();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _historyScrollController = ScrollController();

  // ゲーム状態
  GamePhase _phase = GamePhase.title;
  GameSession? _session;
  String _demonMessage = '';
  bool _isSubmitting = false;
  bool _isAiThinking = false;
  TurnResult? _lastPlayerResult;
  TurnResult? _lastAiResult;
  String? _winner;
  AiLevel _selectedLevel = AiLevel.normal;
  int _remainingTime = timeLimitMs;
  Timer? _timer;
  // クライアント側でのターン開始時刻（サーバー時間のずれを防ぐため）
  DateTime? _localTurnStartedAt;
  // ゲームオーバーモーダル表示中か
  bool _showGameOverModal = false;

  // アニメーション
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputController.dispose();
    _historyScrollController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// タイマー開始（クライアント側で120秒から確実にカウントダウン）
  void _startTimer() {
    _timer?.cancel();
    // ローカルでターン開始時刻を記録
    _localTurnStartedAt = DateTime.now();
    _remainingTime = timeLimitMs; // 120000ms = 2分

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_session == null || _phase != GamePhase.playing || _isAiThinking || _localTurnStartedAt == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final turnStarted = _localTurnStartedAt!.millisecondsSinceEpoch;
      final elapsed = now - turnStarted;
      final remaining = timeLimitMs - elapsed;

      setState(() {
        _remainingTime = remaining > 0 ? remaining : 0;
      });

      // 時間切れチェック
      if (remaining <= 0) {
        try {
          final result = await _api.checkTime(_session!.id);
          if (result.expired && result.session != null) {
            setState(() {
              _session = result.session;
              _demonMessage = result.message ?? '時間切れだ。';
              _winner = 'ai';
              _showGameOverModal = true;
            });
            _timer?.cancel();
          }
        } catch (e) {
          debugPrint('時間チェックエラー: $e');
        }
      }
    });
  }

  /// ターンのタイマーをリセット（AIターン終了後）
  void _resetTurnTimer() {
    _localTurnStartedAt = DateTime.now();
    _remainingTime = timeLimitMs;
  }

  /// ゲーム開始
  Future<void> _startGame({AiLevel? level}) async {
    final aiLevel = level ?? _selectedLevel;
    try {
      final response = await _api.startGame(level: aiLevel);
      setState(() {
        _session = response.session;
        _demonMessage = response.message;
        _remainingTime = timeLimitMs;
        _phase = GamePhase.playing;
        _lastPlayerResult = null;
        _lastAiResult = null;
        _winner = null;
        _showGameOverModal = false;
        _selectedLevel = aiLevel;
      });
      _startTimer();
    } catch (e) {
      _showError('ゲーム開始エラー: $e');
    }
  }

  /// 単語送信
  Future<void> _submitWord() async {
    final word = _katakanaToHiragana(_inputController.text.trim());
    if (word.isEmpty || _isSubmitting || _session == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _api.submitWord(_session!.id, word);
      
      setState(() {
        _session = response.session;
        _lastPlayerResult = response.playerResult;
        _inputController.clear();
      });

      // お手つきの場合はシェイク
      if (!response.playerResult.isValid) {
        _shakeController.forward().then((_) => _shakeController.reverse());
      }

      // ゲーム終了チェック
      if (response.gameOver) {
        setState(() {
          _winner = response.winner;
          _demonMessage = response.playerResult.message;
          _showGameOverModal = true;
        });
        _timer?.cancel();
        return;
      }

      // 延長戦開始
      if (response.overtimeStarted == true) {
        setState(() {
          _phase = GamePhase.overtimeAnnounce;
          _demonMessage = '延長戦だ！';
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _phase = GamePhase.playing;
        });
      }

      // AI思考中
      setState(() {
        _isAiThinking = true;
      });

      await Future.delayed(const Duration(milliseconds: aiResponseDelayMs));

      // AIの結果
      if (response.aiResult != null) {
        setState(() {
          _lastAiResult = response.aiResult;
          _demonMessage = response.aiResult!.message;
          _isAiThinking = false;
        });
        // AIターン終了後にプレイヤーのタイマーをリセット
        _resetTurnTimer();

        // AI勝利チェック
        if (response.session.status == GameStatus.aiWin) {
          setState(() {
            _winner = 'ai';
            _showGameOverModal = true;
          });
          _timer?.cancel();
        }
      } else {
        setState(() {
          _isAiThinking = false;
        });
        // AIの応答がない場合もタイマーをリセット
        _resetTurnTimer();
      }

      _scrollToBottom();
    } catch (e) {
      _showError('送信エラー: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// カタカナをひらがなに変換
  String _katakanaToHiragana(String str) {
    return str.replaceAllMapped(
      RegExp(r'[\u30A1-\u30F6]'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0x60),
    );
  }

  /// 履歴を一番下にスクロール
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_historyScrollController.hasClients) {
        _historyScrollController.animateTo(
          _historyScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// エラー表示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[800]),
    );
  }

  /// 残り時間をフォーマット
  String _formatTime(int ms) {
    // 2分0秒から開始するためfloorを使用
    final seconds = (ms / 1000).floor();
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Stack(
          children: [
            switch (_phase) {
              GamePhase.title => _buildTitleScreen(),
              GamePhase.playing => _buildGameScreen(),
              GamePhase.overtimeAnnounce => _buildOvertimeAnnounce(),
              GamePhase.gameOver => _buildGameScreen(), // ゲームオーバー時も背景はゲーム画面
            },
            // ゲームオーバーモーダル
            if (_showGameOverModal) _buildGameOverModal(),
          ],
        ),
      ),
    );
  }

  /// タイトル画面
  Widget _buildTitleScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), Color(0xFF3D0000)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // タイトル
            const Text(
              '悪魔的',
              style: TextStyle(
                fontSize: 48,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'しりとり',
              style: TextStyle(
                fontSize: 48,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '〜 悪魔との言葉遊び 〜',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 60),
            
            // レベル選択
            Text(
              '難易度を選択',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: AiLevel.values.map((level) {
                final isSelected = level == _selectedLevel;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedLevel = level),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected 
                          ? const Color(0xFFD4AF37) 
                          : const Color(0xFF2D2D2D),
                      foregroundColor: isSelected 
                          ? Colors.black 
                          : Colors.grey[400],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected 
                              ? const Color(0xFFD4AF37) 
                              : Colors.grey[700]!,
                        ),
                      ),
                    ),
                    child: Text(_getLevelName(level)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            
            // 開始ボタン
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                foregroundColor: const Color(0xFFD4AF37),
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
              child: const Text(
                'ゲーム開始',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelName(AiLevel level) {
    switch (level) {
      case AiLevel.easy:
        return 'Lv. 1';
      case AiLevel.normal:
        return 'Lv. 2';
      case AiLevel.hard:
        return 'Lv. 3';
    }
  }

  /// ゲーム画面
  Widget _buildGameScreen() {
    return Column(
      children: [
        // 上部: 悪魔の顔と台詞 + 残り時間
        _buildDemonHeader(),
        
        // 中部: 確保文字エリア
        _buildCapturedCharsArea(),
        
        // 下部: LINE風チャット履歴
        Expanded(child: _buildHistory()),
        
        // 最下部: 入力エリア
        _buildInputArea(),
      ],
    );
  }

  /// 悪魔ヘッダー（顔 + 台詞 + 残り時間）
  Widget _buildDemonHeader() {
    final isLowTime = _remainingTime < 30000;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          // 悪魔の顔
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.asset(
              'assets/悪魔.jpg',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          
          // 台詞
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Text(
                _isAiThinking ? '考え中...' : _demonMessage,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 残り時間
          Column(
            children: [
              Text(
                _formatTime(_remainingTime),
                style: TextStyle(
                  color: isLowTime ? Colors.red : const Color(0xFFD4AF37),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'R${_session?.roundCount ?? 0}/${_session?.maxRounds ?? 10}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 確保文字エリア
  Widget _buildCapturedCharsArea() {
    final playerChars = _session?.playerCapturedChars ?? [];
    final aiChars = _session?.aiCapturedChars ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // プレイヤーの確保文字
          Row(
            children: [
              Text(
                'あなたの確保した文字（${playerChars.length}文字）',
                style: const TextStyle(
                  color: Color(0xFF026E14),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'お手付き${_session?.playerMistakeCount ?? 0}',
                style: TextStyle(color: Colors.red[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            playerChars.isEmpty ? '（なし）' : playerChars.join('、'),
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 12),
          
          // 悪魔の確保文字
          Row(
            children: [
              Text(
                '悪魔の確保した文字（${aiChars.length}文字）',
                style: const TextStyle(
                  color: Color(0xFFC70606),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'お手付き${_session?.aiMistakeCount ?? 0}',
                style: TextStyle(color: Colors.red[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            aiChars.isEmpty ? '（なし）' : aiChars.join('、'),
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 履歴
  Widget _buildHistory() {
    final history = _session?.history ?? [];
    
    if (history.isEmpty) {
      return Center(
        child: Text(
          'しりとりを始めましょう',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      controller: _historyScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final isPlayer = entry.player == 'player';
        
        return Align(
          alignment: isPlayer ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPlayer
                  ? const Color(0xFF1B5E20).withOpacity(0.8)
                  : const Color(0xFF8B0000).withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: entry.isValid
                    ? (isPlayer ? const Color(0xFF4CAF50) : const Color(0xFFD4AF37))
                    : Colors.red,
                width: entry.isValid ? 1 : 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: isPlayer
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  entry.word,
                  style: TextStyle(
                    color: entry.isValid ? Colors.white : Colors.red[300],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: entry.isValid ? null : TextDecoration.lineThrough,
                  ),
                ),
                if (entry.capturedChars.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${entry.capturedChars.join(', ')}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 入力エリア
  Widget _buildInputArea() {
    final expectedChar = _session?.expectedStartChar;
    
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          border: Border(
            top: BorderSide(color: Colors.grey[800]!),
          ),
        ),
        child: Column(
          children: [
            if (expectedChar != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '「$expectedChar」から始まる言葉を入力',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    enabled: !_isSubmitting && !_isAiThinking,
                    // ひらがな入力を有効化
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.send,
                    autocorrect: false,
                    enableSuggestions: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ひらがなで入力...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                    ),
                    onSubmitted: (_) => _submitWord(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting || _isAiThinking ? null : _submitWord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          '送信',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 延長戦告知
  Widget _buildOvertimeAnnounce() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF8B0000), Color(0xFF1E1E1E)],
          radius: 1.5,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '⚔️',
              style: TextStyle(fontSize: 64),
            ),
            SizedBox(height: 24),
            Text(
              '延長戦',
              style: TextStyle(
                fontSize: 48,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '勝敗が決まるまで続く...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ゲームオーバー画面
  Widget _buildGameOverScreen() {
    // 後方互換のため残すが、モーダルを使用
    return _buildGameScreen();
  }

  /// ゲームオーバーモーダル
  Widget _buildGameOverModal() {
    final isPlayerWin = _winner == 'player';
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isPlayerWin
                ? [const Color(0xFF1B5E20), const Color(0xFF2D2D2D)]
                : [const Color(0xFF8B0000), const Color(0xFF2D2D2D)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 悪魔の顔
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                'assets/悪魔.jpg',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPlayerWin ? 'あなたの勝利！' : '悪魔の勝利',
              style: const TextStyle(
                fontSize: 28,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _demonMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // 再戦ボタン（レベル選択）
            const Text(
              '再戦する',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRematchButton('Lv.1', AiLevel.easy),
                const SizedBox(width: 8),
                _buildRematchButton('Lv.2', AiLevel.normal),
                const SizedBox(width: 8),
                _buildRematchButton('Lv.3', AiLevel.hard),
              ],
            ),
            const SizedBox(height: 16),
            
            // タイトルに戻るボタン
            TextButton(
              onPressed: () {
                setState(() {
                  _showGameOverModal = false;
                  _phase = GamePhase.title;
                });
              },
              child: Text(
                'タイトルに戻る',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 再戦ボタン
  Widget _buildRematchButton(String label, AiLevel level) {
    final isSelected = _selectedLevel == level;
    return ElevatedButton(
      onPressed: () => _startGame(level: level),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? const Color(0xFFD4AF37) 
            : const Color(0xFF3D3D3D),
        foregroundColor: isSelected ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected 
                ? const Color(0xFFD4AF37) 
                : Colors.grey[600]!,
          ),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildScoreColumn(String label, int chars, int mistakes, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          '$chars',
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '文字',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '❌$mistakes',
          style: TextStyle(color: Colors.red[400], fontSize: 14),
        ),
      ],
    );
  }
}

/// ゲームフェーズ
enum GamePhase {
  title,
  playing,
  overtimeAnnounce,
  gameOver,
}

/// 悪魔の顔を描画するカスタムペインター（添付画像準拠）
class DemonFacePainter extends CustomPainter {
  final bool isWin;
  
  DemonFacePainter({this.isWin = true});
  
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 + 5;
    final radius = size.width * 0.38;

    final grayColor = const Color(0xFF6B6B6B);
    final pinkColor = const Color(0xFFD4A5A5);

    // 左の羽
    _drawWing(canvas, centerX - radius * 0.95, centerY - radius * 0.3, true, grayColor);
    // 右の羽
    _drawWing(canvas, centerX + radius * 0.95, centerY - radius * 0.3, false, grayColor);

    // 左の角
    _drawHorn(canvas, centerX - radius * 0.45, centerY - radius * 0.85, true, grayColor);
    // 右の角
    _drawHorn(canvas, centerX + radius * 0.45, centerY - radius * 0.85, false, grayColor);

    // 背景の円（顔）
    final facePaint = Paint()
      ..color = const Color(0xFFFAFAFA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius, facePaint);

    // 顔の輪郭線
    final outlinePaint = Paint()
      ..color = grayColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(centerX, centerY), radius, outlinePaint);

    // 左目（ニヤリ＋眉毛）
    _drawLeftEye(canvas, centerX - radius * 0.35, centerY - radius * 0.15, grayColor);
    // 右目（ウインク）
    _drawRightEye(canvas, centerX + radius * 0.35, centerY - radius * 0.15, grayColor);

    // 頬っぺた（左）
    final cheekPaint = Paint()
      ..color = pinkColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - radius * 0.55, centerY + radius * 0.25),
        width: radius * 0.4,
        height: radius * 0.3,
      ),
      cheekPaint,
    );
    // 頬っぺた（右）
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + radius * 0.55, centerY + radius * 0.25),
        width: radius * 0.4,
        height: radius * 0.3,
      ),
      cheekPaint,
    );

    // ニヤリ口（牙付き）
    _drawMouthWithFang(canvas, centerX, centerY + radius * 0.4, radius, grayColor);
  }

  void _drawHorn(Canvas canvas, double x, double y, bool isLeft, Color color) {
    final hornPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final direction = isLeft ? -1.0 : 1.0;
    final path = Path();
    
    // 三角形の角
    path.moveTo(x - 6 * direction, y + 15);
    path.lineTo(x + 2 * direction, y - 12);
    path.lineTo(x + 10 * direction, y + 15);
    path.close();

    canvas.drawPath(path, hornPaint);

    final hornOutline = Paint()
      ..color = const Color(0xFF5A5A5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, hornOutline);
  }

  void _drawWing(Canvas canvas, double x, double y, bool isLeft, Color color) {
    final wingPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final direction = isLeft ? -1.0 : 1.0;
    final path = Path();
    
    // コウモリ羽（3つの波）
    path.moveTo(x, y + 10);
    // 下の波
    path.quadraticBezierTo(x + direction * 12, y + 15, x + direction * 18, y + 8);
    // 中の波
    path.quadraticBezierTo(x + direction * 22, y + 2, x + direction * 26, y - 2);
    // 上の波
    path.quadraticBezierTo(x + direction * 28, y - 10, x + direction * 22, y - 15);
    // 戻り
    path.quadraticBezierTo(x + direction * 15, y - 8, x + direction * 10, y - 5);
    path.quadraticBezierTo(x + direction * 5, y, x, y + 5);
    path.close();

    canvas.drawPath(path, wingPaint);

    final wingOutline = Paint()
      ..color = const Color(0xFF5A5A5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, wingOutline);
  }

  void _drawLeftEye(Canvas canvas, double x, double y, Color color) {
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // 眉毛
    final browPath = Path();
    browPath.moveTo(x - 8, y - 8);
    browPath.lineTo(x + 6, y - 5);
    canvas.drawPath(browPath, eyePaint);

    // 目（斜めのアーチ）
    final eyePath = Path();
    eyePath.moveTo(x - 6, y + 2);
    eyePath.quadraticBezierTo(x, y - 4, x + 6, y);
    canvas.drawPath(eyePath, eyePaint);
  }

  void _drawRightEye(Canvas canvas, double x, double y, Color color) {
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // 眉毛
    final browPath = Path();
    browPath.moveTo(x - 6, y - 5);
    browPath.lineTo(x + 8, y - 8);
    canvas.drawPath(browPath, eyePaint);

    // ウインク（逆U字）
    final eyePath = Path();
    eyePath.moveTo(x - 6, y);
    eyePath.quadraticBezierTo(x, y + 5, x + 6, y);
    canvas.drawPath(eyePath, eyePaint);
  }

  void _drawMouthWithFang(Canvas canvas, double x, double y, double radius, Color color) {
    final mouthPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // ニヤリ口
    final mouthPath = Path();
    mouthPath.moveTo(x - radius * 0.2, y);
    mouthPath.quadraticBezierTo(x + radius * 0.05, y + radius * 0.12, x + radius * 0.25, y - radius * 0.05);
    canvas.drawPath(mouthPath, mouthPaint);

    // 牙（左側の三角形）
    final fangPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final fangPath = Path();
    fangPath.moveTo(x - radius * 0.12, y + radius * 0.02);
    fangPath.lineTo(x - radius * 0.08, y + radius * 0.15);
    fangPath.lineTo(x - radius * 0.04, y + radius * 0.02);
    fangPath.close();
    canvas.drawPath(fangPath, fangPaint);
  }

  @override
  bool shouldRepaint(covariant DemonFacePainter oldDelegate) => oldDelegate.isWin != isWin;
}
