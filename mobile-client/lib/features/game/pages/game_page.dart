// 悪魔的しりとり ゲーム画面
import 'dart:async';
import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../api/game_api.dart';
import '../models/game_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../../present/api/present_api.dart';
import '../../account/api/me_api.dart';
import '../../account/models/me_models.dart';

/// 制限時間（ミリ秒）: 40秒
const int timeLimitMs = 40 * 1000;

/// AIの応答遅延（ミリ秒）
const int aiResponseDelayMs = 2000;

final presentApiProvider = Provider<PresentApi>((ref) => PresentApi());
final meApiProvider = Provider<MeApi>((ref) => MeApi());

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final GameApi _api = GameApi();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _historyScrollController = ScrollController();

  final ValueNotifier<int> _remainingTimeMs = ValueNotifier<int>(timeLimitMs);

  // ゲーム状態
  GamePhase _phase = GamePhase.home;
  GameSession? _session;
  String _demonMessage = '';
  bool _isSubmitting = false;
  bool _isAiThinking = false;
  String? _winner;
  AiLevel _selectedLevel = AiLevel.normal;
  Timer? _timer;
  // クライアント側でのターン開始時刻（サーバー時間のずれを防ぐため）
  DateTime? _localTurnStartedAt;
  // ゲームオーバーモーダル表示中か
  bool _showGameOverModal = false;

  // アンチチート（非アクティブ時間）
  int? _pausedAtMs;
  bool _lifecycleBusy = false;

  // アニメーション
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late AnimationController _rotationController;

  // バナー広告
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // プレゼント未受け取り数
  int _unclaimedPresentCount = 0;

  // 自分の装備情報
  String? _myIconUrl;
  String? _myMessage;
  String? _myTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    
    // タイトル点滅用アニメーション
    _blinkController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    
    // 魔法陣回転用アニメーション
    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    _loadBannerAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUnclaimedPresentCount();
      _loadMyEquipment();
    });
  }

  Future<void> _fetchUnclaimedPresentCount() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    try {
      final api = ref.read(presentApiProvider);
      final list = await api.getList(token: session.token);
      if (!mounted) return;
      setState(() {
        _unclaimedPresentCount = list.unclaimedCount;
      });
    } catch (_) {
      // エラー時は無視
    }
  }

  /// 自分の装備情報を取得
  Future<void> _loadMyEquipment() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    try {
      final meApi = ref.read(meApiProvider);
      final inventory = await meApi.getInventory(token: session.token);
      if (!mounted) return;

      // 装備中のアイコンURLを取得
      final equippedIcon = inventory.icons.firstWhere(
        (icon) => icon.id == inventory.equipped.iconId,
        orElse: () => inventory.icons.first,
      );

      // 装備中のメッセージを取得
      final equippedMessage = inventory.messages.firstWhere(
        (msg) => msg.id == inventory.equipped.messageId,
        orElse: () => inventory.messages.first,
      );

      // 装備中の称号を取得
      String? titleName;
      if (inventory.equipped.title1Id != null) {
        final title = inventory.titles.firstWhere(
          (t) => t.id == inventory.equipped.title1Id,
          orElse: () => inventory.titles.first,
        );
        titleName = title.name;
      }

      setState(() {
        _myIconUrl = _resolveImageUrl(equippedIcon.imageUrl);
        _myMessage = equippedMessage.content;
        _myTitle = titleName;
      });
    } catch (e) {
      debugPrint('装備情報の取得に失敗: $e');
    }
  }

  String _resolveImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      final base = ApiClient().dio.options.baseUrl;
      return Uri.parse(base).resolve(trimmed).toString();
    }
    return trimmed;
  }

  /// バナー広告をロード
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('バナー広告のロードに失敗: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _inputController.dispose();
    _historyScrollController.dispose();
    _remainingTimeMs.dispose();
    _shakeController.dispose();
    _blinkController.dispose();
    _rotationController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ホーム画面/未開始は通知しない
    if (_session == null) return;
    // 既に終了している場合も通知しない
    if ((_session?.status ?? GameStatus.playing) != GameStatus.playing) return;
    if (_showGameOverModal) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _pausedAtMs = DateTime.now().millisecondsSinceEpoch;
        break;
      case AppLifecycleState.resumed:
        final pausedAt = _pausedAtMs;
        _pausedAtMs = null;
        if (pausedAt == null) return;
        final inactiveMs = DateTime.now().millisecondsSinceEpoch - pausedAt;
        _notifyLifecycleIfNeeded(inactiveMs);
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _notifyLifecycleIfNeeded(int inactiveMs) async {
    if (_lifecycleBusy) return;
    if (_session == null) return;

    _lifecycleBusy = true;
    try {
      final res = await _api.notifyLifecycle(_session!.id, inactiveMs);
      if (!mounted) return;

      // セッション更新は常に反映
      setState(() {
        _session = res.session;
      });

      if (res.gameOver) {
        final winner = res.winner ??
            (res.session.status == GameStatus.playerWin
                ? 'player'
                : 'ai');
        setState(() {
          _winner = winner;
          _demonMessage = res.message ?? '戦意喪失…敗北だ。';
          _showGameOverModal = true;
        });
        _timer?.cancel();
      }
    } catch (_) {
      // 通信失敗時は握り潰す（ゲーム進行は継続）
    } finally {
      _lifecycleBusy = false;
    }
  }

  /// タイマー開始（クライアント側で120秒から確実にカウントダウン）
  void _startTimer() {
    _timer?.cancel();
    // ローカルでターン開始時刻を記録
    _localTurnStartedAt = DateTime.now();
    _remainingTimeMs.value = timeLimitMs;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_session == null || _phase != GamePhase.playing || _isAiThinking || _localTurnStartedAt == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final turnStarted = _localTurnStartedAt!.millisecondsSinceEpoch;
      final elapsed = now - turnStarted;
      final remaining = timeLimitMs - elapsed;

      _remainingTimeMs.value = remaining > 0 ? remaining : 0;

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
    _remainingTimeMs.value = timeLimitMs;
  }

  /// ゲーム開始
  Future<void> _startGame({AiLevel? level}) async {
    final aiLevel = level ?? _selectedLevel;
    try {
      final response = await _api.startGame(level: aiLevel);
      setState(() {
        _session = response.session;
        _demonMessage = response.message;
        _remainingTimeMs.value = timeLimitMs;
        _phase = GamePhase.playing;
        _winner = null;
        _showGameOverModal = false;
        _selectedLevel = aiLevel;
      });

      // AI先攻の場合、AIの返答を2秒後に表示
      if (response.aiFirstWord != null) {
        setState(() {
          _isAiThinking = true;
        });
        await Future.delayed(const Duration(milliseconds: aiResponseDelayMs));
        setState(() {
          _isAiThinking = false;
          _demonMessage = response.aiFirstWord!.message;
        });
      }

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

      // AI思考中
      setState(() {
        _isAiThinking = true;
      });

      await Future.delayed(const Duration(milliseconds: aiResponseDelayMs));

      // AIの結果
      if (response.aiResult != null) {
        setState(() {
          _demonMessage = response.aiResult!.message;
          _isAiThinking = false;
        });
        // AIターン終了後にプレイヤーのタイマーをリセット
        _resetTurnTimer();
        // 自動スクロール
        _scrollToBottom();

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
        // 自動スクロール
        _scrollToBottom();
      }

      // プレイヤーの入力後も自動スクロール
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
    // 認証状態が変わった時にプレゼント数を更新
    ref.listen(authControllerProvider, (_, next) {
      final session = next.valueOrNull;
      if (session != null && _phase == GamePhase.home) {
        _fetchUnclaimedPresentCount();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            // バナー広告（常に上部に表示）
            if (_isBannerAdLoaded && _bannerAd != null)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            // メインコンテンツ
            Expanded(
              child: Stack(
                children: [
                  switch (_phase) {
                    GamePhase.home => _buildHomeScreen(),
                    GamePhase.playing => _buildGameScreen(),
                    GamePhase.overtimeAnnounce => _buildOvertimeAnnounce(),
                    GamePhase.gameOver => _buildGameScreen(), // ゲームオーバー時も背景はゲーム画面
                  },
                  if (_phase == GamePhase.home) ...[
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ref.watch(authControllerProvider).maybeWhen(
                        data: (session) => session == null
                            ? ElevatedButton.icon(
                                onPressed: () => context.push('/account'),
                                label: const Text('ログイン'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'アカウント設定',
                                onPressed: () => context.push('/account'),
                                icon: const Icon(Icons.settings),
                                color: const Color(0xFFD4AF37),
                              ),
                        orElse: () => IconButton(
                          tooltip: 'アカウント設定',
                          onPressed: () => context.push('/account'),
                          icon: const Icon(Icons.settings),
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: IconButton(
                        tooltip: 'ヘルプ',
                        onPressed: _showHelpModal,
                        icon: const Icon(Icons.help_outline),
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 48,
                      child: Stack(
                        children: [
                          IconButton(
                            tooltip: 'プレゼントボックス',
                            onPressed: () async {
                              await context.push('/present');
                              _fetchUnclaimedPresentCount();
                            },
                            icon: const Icon(Icons.card_giftcard),
                            color: const Color(0xFFD4AF37),
                          ),
                          if (_unclaimedPresentCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  _unclaimedPresentCount > 99 ? '99+' : '$_unclaimedPresentCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  // ゲームオーバーモーダル
                  if (_showGameOverModal) _buildGameOverModal(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ホーム画面
  Widget _buildHomeScreen() {
    return Stack(
      children: [
        // 背景: グラデーション
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), Color(0xFF3D0000)],
              ),
            ),
          ),
        ),
        
        // 背景: 回転する魔法陣
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159,
                child: Opacity(
                  opacity: 0.15,
                  child: CustomPaint(
                    painter: MagicCirclePainter(),
                  ),
                ),
              );
            },
          ),
        ),
        
        // 前景: コンテンツ
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 点滅するタイトル
                        AnimatedBuilder(
                          animation: _blinkAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _blinkAnimation.value,
                              child: child,
                            );
                          },
                          child: Text(
                            '悪魔的',
                            style: GoogleFonts.notoSerifJp(
                              fontSize: 48,
                              color: const Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withValues(alpha: 128),
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _blinkAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _blinkAnimation.value,
                              child: child,
                            );
                          },
                          child: Text(
                            'しりとり',
                            style: GoogleFonts.notoSerifJp(
                              fontSize: 48,
                              color: const Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black.withValues(alpha: 128),
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
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
                        const SizedBox(height: 32),
                        Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D).withValues(alpha: 204),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                '【ルール】',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '''
〜主な契約事〜
• 初めて使った文字を「確保」する
• 相手の確保文字は使用不可
• 確保文字が少ない方が勝利

〜その他の契約事〜
• お手つき2回で即敗北
• 1ターン40秒で10ターン制
• 小さい文字は大きい文字と同一となる
• 悪魔辞書にある一般的単語のみ使用可
                              ''',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                        const SizedBox(height: 32),
                        Text(
                          'AIの難易度を選択',
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
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedLevel = level),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [Color(0xFFFFF8DC), Color(0xFFFFD700), Color(0xFFB8860B)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : LinearGradient(
                                          colors: [Colors.grey[700]!, Colors.grey[800]!, Colors.grey[900]!],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFFFD700) : Colors.grey[600]!,
                                    width: 2,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFFD700).withOpacity(0.6),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: Text(
                                  _getLevelName(level),
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                        const SizedBox(height: 40),
                        Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF8B0000), Color(0xFF5A0000)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 76),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: const Color(0xFFD4AF37),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                            ),
                          ),
                          child: const Text(
                            '対AI戦',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2D2D2D),
                              const Color(0xFF1E1E1E),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 51),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: OutlinedButton(
                          onPressed: () => context.push('/ranked'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFFD4AF37),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '対人戦',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2D2D2D),
                              const Color(0xFF1E1E1E),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withValues(alpha: 51),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: OutlinedButton(
                          onPressed: () => context.push('/gacha'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFFD4AF37),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'ガチャ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showHelpModal() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ヘルプ'),
          content: SingleChildScrollView(
            child: Text(
              '''
【辞書に無い単語は？】
専門用語、人名、商品名、動詞、略語、俗語、複合語、公共良俗に反する言葉、マニアックな地名等。
見つけたら、あなただけのラッキーなので、是非使ってみてください。

【魂とは？】
・対人戦（PvP）を1回行うごとに魂を1消費します。
・リワード広告の視聴で魂を1回復できます。

【コインとは？】
・召喚（ガチャ）で使用します。対人戦の勝利で+4コイン、敗北で+1コイン獲得できます。
''',
              style: const TextStyle(height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
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
    final session = ref.watch(authControllerProvider).valueOrNull;
    
    return Column(
      children: [
        // 上部: 悪魔の顔と台詞 + 残り時間
        _buildDemonHeader(),
        
        // 対戦者情報エリア（AI vs プレイヤー）
        if (session != null) _buildBattleInfo(session),
        
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
          ValueListenableBuilder<int>(
            valueListenable: _remainingTimeMs,
            builder: (context, remainingMs, _) {
              final isLowTime = remainingMs < (timeLimitMs ~/ 4);
              return Column(
                children: [
                  Text(
                    _formatTime(remainingMs),
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
              );
            },
          ),
        ],
      ),
    );
  }

  /// 対戦者情報表示エリア（AI vs プレイヤー）
  Widget _buildBattleInfo(dynamic session) {
    // AI（悪魔）の情報
    const aiIconPath = 'assets/悪魔.jpg';
    const aiMessage = 'よろしくお願いします';
    final aiTitle = '悪魔 ${_getLevelName(_selectedLevel)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          // プレイヤー（自分）の情報
          Expanded(
            child: _buildPlayerCard(
              iconWidget: _myIconUrl == null
                  ? Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 28),
                    )
                  : ClipOval(
                      child: Image.network(
                        _myIconUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey[700],
                          child: const Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
              message: _myMessage ?? '',
              title: _myTitle ?? '',
              isOpponent: false,
            ),
          ),
          const SizedBox(width: 16),
          // VS表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[700]!),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // AI（相手）の情報
          Expanded(
            child: _buildPlayerCard(
              iconWidget: ClipOval(
                child: Image.asset(
                  aiIconPath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              message: aiMessage,
              title: aiTitle,
              isOpponent: true,
            ),
          ),
        ],
      ),
    );
  }

  /// プレイヤーカード（アイコン、メッセージ、称号）
  Widget _buildPlayerCard({
    required Widget iconWidget,
    required String message,
    required String title,
    required bool isOpponent,
  }) {
    return Column(
      children: [
        // アイコン
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: iconWidget,
        ),
        const SizedBox(height: 8),
        // メッセージ
        Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // 称号
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// プレイヤー情報表示エリア（旧実装 - 削除予定）
  Widget _buildPlayerInfo(dynamic session) {
    // AuthUserから装備情報を取得（将来的にバックエンドで対応予定）
    final iconUrl = session.user.iconId ?? 'default_demon';
    final message = 'よろしくお願いします'; // session.user.equippedMessage
    final title = session.user.name; // session.user.equippedTitle1?.name

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
          // ユーザーのアイコン
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: iconUrl.startsWith('http') || iconUrl.startsWith('/')
                  ? Image.network(
                      _resolveImageUrl(
                        iconUrl.startsWith('/')
                            ? iconUrl
                            : '/static/$iconUrl.jpg',
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[700],
                        child: const Icon(Icons.person, color: Colors.white, size: 28),
                      ),
                    )
                  : Image.network(
                      _resolveImageUrl('/static/$iconUrl.jpg'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[700],
                        child: const Icon(Icons.person, color: Colors.white, size: 28),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // メッセージと称号を縦並び
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // メッセージ
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 称号とユーザー名
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
          'しりとりを始めようぞ！',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // AI思考中は最後のAI履歴を非表示にする
    final displayHistory = _isAiThinking && history.isNotEmpty && history.last.player == 'ai'
        ? history.sublist(0, history.length - 1)
        : history;

    return ListView.builder(
      controller: _historyScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: displayHistory.length,
      itemBuilder: (context, index) {
        final entry = displayHistory[index];
        final isPlayer = entry.player == 'player';
        
        return Align(
          alignment: isPlayer ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPlayer
                  ? const Color(0xFF1B5E20).withValues(alpha: 204)
                  : const Color(0xFF8B0000).withValues(alpha: 204),
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
            // ホームに戻るボタン
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _timer?.cancel();
                  setState(() {
                    _phase = GamePhase.home;
                    _session = null;
                    _showGameOverModal = false;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'ホームに戻る',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
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

  /// ゲームオーバーモーダル
  Widget _buildGameOverModal() {
    final isPlayerWin = _winner == 'player';
    final isDraw = _winner == null;
    
    // 結果に応じた色とメッセージ
    List<Color> gradientColors;
    String resultMessage;
    if (isDraw) {
      gradientColors = [const Color(0xFF4A4A4A), const Color(0xFF2D2D2D)];
      resultMessage = '引き分け';
    } else if (isPlayerWin) {
      gradientColors = [const Color(0xFF1B5E20), const Color(0xFF2D2D2D)];
      resultMessage = 'あなたの勝利！';
    } else {
      gradientColors = [const Color(0xFF8B0000), const Color(0xFF2D2D2D)];
      resultMessage = '悪魔の勝利';
    }
    
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4AF37),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resultMessage,
              style: const TextStyle(
                fontSize: 22,
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // AIレベル選択（選択のみ、再戦は別ボタン）
            const Text(
              'AIのレベル',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLevelSelectButton('Lv.1', AiLevel.easy),
                const SizedBox(width: 6),
                _buildLevelSelectButton('Lv.2', AiLevel.normal),
                const SizedBox(width: 6),
                _buildLevelSelectButton('Lv.3', AiLevel.hard),
              ],
            ),
            const SizedBox(height: 12),
            
            // 再戦するボタン
            ElevatedButton(
              onPressed: () => _startGame(level: _selectedLevel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '再戦する',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// レベル選択ボタン（選択のみ、再戦は開始しない）
  Widget _buildLevelSelectButton(String label, AiLevel level) {
    final isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevel = level;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFFF8DC), Color(0xFFFFD700), Color(0xFFB8860B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [Colors.grey[700]!, Colors.grey[800]!, Colors.grey[900]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.grey[600]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.6),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// ゲームフェーズ
enum GamePhase {
  home,
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
      ..color = pinkColor.withValues(alpha: 179)
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

  void _drawWing(Canvas canvas, double x, double y, bool isLeft, Color color) {
    final wingPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final dir = isLeft ? -1.0 : 1.0;
    final path = Path();
    path.moveTo(x, y);
    path.quadraticBezierTo(x + dir * 18, y - 8, x + dir * 28, y + 6);
    path.quadraticBezierTo(x + dir * 18, y + 2, x + dir * 10, y + 16);
    canvas.drawPath(path, wingPaint);
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

  void _drawHorn(Canvas canvas, double x, double y, bool isLeft, Color color) {
    final hornFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final hornStroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final dir = isLeft ? -1.0 : 1.0;
    final path = Path();
    path.moveTo(x, y);
    path.quadraticBezierTo(x + dir * 6, y - 18, x + dir * 16, y - 8);
    path.quadraticBezierTo(x + dir * 8, y - 2, x, y);
    path.close();

    canvas.drawPath(path, hornFill);
    canvas.drawPath(path, hornStroke);
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

/// 魔法陣を描画するカスタムペインター
class MagicCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.7;

    final paint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 外側の円
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.9, paint);
    canvas.drawCircle(center, radius * 0.8, paint);

    // 五芒星
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 144 - 90) * 3.14159 / 180;
      
      final point = Offset(
        center.dx + radius * 0.7 * cos(angle),
        center.dy + radius * 0.7 * sin(angle),
      );
      
      if (i == 0) {
        starPath.moveTo(point.dx, point.dy);
      } else {
        starPath.lineTo(point.dx, point.dy);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, paint);

    // 内側の複雑な模様
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * 3.14159 / 180;
      final start = Offset(
        center.dx + radius * 0.5 * cos(angle),
        center.dy + radius * 0.5 * sin(angle),
      );
      final end = Offset(
        center.dx + radius * 0.8 * cos(angle),
        center.dy + radius * 0.8 * sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
