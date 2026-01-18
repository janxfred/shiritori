import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../../account/api/me_api.dart';
import '../api/pvp_api.dart';
import '../models/pvp_models.dart';

final pvpApiProvider = Provider<PvpApi>((ref) => PvpApi());

class PvpGamePage extends ConsumerStatefulWidget {
  const PvpGamePage({
    super.key,
    required this.sessionId,
    this.initial,
    this.opponent,
  });

  final String sessionId;
  final PvpStartResponse? initial;
  final PvpOpponent? opponent;

  @override
  ConsumerState<PvpGamePage> createState() => _PvpGamePageState();
}

class _PvpGamePageState extends ConsumerState<PvpGamePage> {
  Timer? _timer;
  Timer? _battleIntroTimer;
  bool _busy = false;
  bool _polling = false;
  bool _showGameOverModal = false;
  bool _syncedMeAfterGameOver = false;

  bool _showBattleIntro = false;
  bool _battleIntroShownOnce = false;

  // バナー広告
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final ValueNotifier<int> _remainingTimeMs = ValueNotifier<int>(0);

  PvpSession? _session;
  PvpOpponent? _opponent;
  PvpRated? _rated;

  final _wordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initial != null) {
      _session = widget.initial!.session;
      _opponent = widget.initial!.opponent;
    } else if (widget.opponent != null) {
      _opponent = widget.opponent;
    }

    final initialSession = _session;
    if (initialSession != null) {
      _remainingTimeMs.value = initialSession.remainingTimeMs;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBattleIntroIfNeeded();
      _refresh();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    });

    _loadBannerAd();
  }

  void _startBattleIntroIfNeeded() {
    if (_battleIntroShownOnce) return;
    if (_opponent == null) return;

    _battleIntroShownOnce = true;
    setState(() => _showBattleIntro = true);

    _battleIntroTimer?.cancel();
    _battleIntroTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showBattleIntro = false);
    });
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

  void _updateSession(PvpSession session, {required String myUserId}) {
    _remainingTimeMs.value = session.remainingTimeMs;

    final prev = _session;
    final shouldRebuild = prev == null
        ? true
        : _shouldRebuildForSessionChange(prev: prev, next: session);
    if (!shouldRebuild) {
      // 残り時間だけ変わるケースではsetStateしない（IME変換中の入力が壊れやすい）
      _session = session;
      return;
    }

    setState(() {
      _session = session;
      if (session.status != 'playing') {
        _showGameOverModal = true;
      }
    });

    if (session.status != 'playing') {
      _syncMeAfterGameOver();
    }
  }

  Future<void> _syncMeAfterGameOver() async {
    if (_syncedMeAfterGameOver) return;

    final auth = ref.read(authControllerProvider).valueOrNull;
    if (auth == null) return;

    _syncedMeAfterGameOver = true;
    try {
      final me = await MeApi().getMe(token: auth.token);
      if (!mounted) return;
      ref
          .read(authControllerProvider.notifier)
          .updateUser(auth.user.copyWith(coins: me.coins, soulCount: me.soulCount));
    } catch (_) {
      _syncedMeAfterGameOver = false;
    }
  }

  bool _shouldRebuildForSessionChange({
    required PvpSession prev,
    required PvpSession next,
  }) {
    if (prev.status != next.status) return true;
    if (prev.currentTurnUserId != next.currentTurnUserId) return true;
    if (prev.expectedStartChar != next.expectedStartChar) return true;
    if (prev.turnCount != next.turnCount) return true;
    if (prev.roundCount != next.roundCount) return true;
    if (prev.maxRounds != next.maxRounds) return true;
    if (prev.lastWord != next.lastWord) return true;
    if (prev.turnStartedAt != next.turnStartedAt) return true;
    if (prev.player1MistakeCount != next.player1MistakeCount) return true;
    if (prev.player2MistakeCount != next.player2MistakeCount) return true;
    if (!listEquals(prev.player1CapturedChars, next.player1CapturedChars)) return true;
    if (!listEquals(prev.player2CapturedChars, next.player2CapturedChars)) return true;
    if (prev.history.length != next.history.length) return true;
    return false;
  }

  String _timeExpiredMessageForViewer({required PvpSession session, required String myUserId}) {
    // check-timeは「時間切れが発生した側」の台詞を返すことがあるので、UI側では勝敗から文言を決める
    final result = _resultText(session: session, myUserId: myUserId);
    if (result == '勝利') return '相手が時間切れだ。勝利。';
    if (result == '敗北') return '時間切れだ。敗北。';
    return '時間切れだ。';
  }

  String _formatTime(int ms) {
    final seconds = (ms / 1000).floor();
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      final baseUrl = ApiClient().dio.options.baseUrl;
      return '$baseUrl$url';
    }
    return url;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _battleIntroTimer?.cancel();
    _wordController.dispose();
    _remainingTimeMs.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _tick() async {
    final session = _session;
    if (session == null) {
      await _refresh();
      return;
    }

    await _refresh();

    final refreshed = _session;
    if (refreshed == null) return;

    if (_remainingTimeMs.value <= 0 && refreshed.status == 'playing') {
      await _checkTime();
    }
  }

  Future<void> _refresh() async {
    if (_polling) return;

    final auth = ref.read(authControllerProvider).valueOrNull;
    if (auth == null) return;

    setState(() => _polling = true);
    try {
      final api = ref.read(pvpApiProvider);
      final s = await api.getSession(token: auth.token, sessionId: widget.sessionId);
      if (!mounted) return;
      _updateSession(s, myUserId: auth.user.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _polling = false);
    }
  }

  Future<void> _checkTime() async {
    if (_busy) return;

    final auth = ref.read(authControllerProvider).valueOrNull;
    if (auth == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(pvpApiProvider);
      final res = await api.checkTime(token: auth.token, sessionId: widget.sessionId);
      if (!mounted) return;
      if (res.session != null) {
        _updateSession(res.session!, myUserId: auth.user.id);
      }
      if (res.expired && res.message != null) {
        final session = _session;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              session == null
                  ? res.message!
                  : _timeExpiredMessageForViewer(session: session, myUserId: auth.user.id),
            ),
          ),
        );
      }
    } catch (_) {
      // チェックは補助的なので黙殺
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitWord() async {
    if (_busy) return;

    final auth = ref.read(authControllerProvider).valueOrNull;
    final session = _session;
    if (auth == null || session == null) return;

    final word = _wordController.text.trim();
    if (word.isEmpty) return;

    if (session.status != 'playing') return;
    if (session.currentTurnUserId != auth.user.id) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(pvpApiProvider);
      final res = await api.submitWord(
        token: auth.token,
        sessionId: widget.sessionId,
        word: word,
      );

      if (!mounted) return;

      setState(() {
        _rated = res.rated ?? _rated;
      });
      _updateSession(res.session, myUserId: auth.user.id);

      _wordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.playerResult.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('送信に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _resultText({required PvpSession session, required String myUserId}) {
    if (session.status == 'draw') return '引き分け';

    final isP1 = session.player1Id == myUserId;
    final winnerIsP1 = session.status == 'p1_win';
    final winnerIsP2 = session.status == 'p2_win';

    if (winnerIsP1 && isP1) return '勝利';
    if (winnerIsP2 && !isP1) return '勝利';

    if (winnerIsP1 && !isP1) return '敗北';
    if (winnerIsP2 && isP1) return '敗北';

    return '終了';
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(authControllerProvider);
    final auth = sessionAsync.valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: sessionAsync.when(
          data: (_) {
            if (auth == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('対人戦にはログインが必要です'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('ログインへ'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.push('/signup'),
                        child: const Text('新規登録へ'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final session = _session;
            if (session == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final isMyTurn = session.currentTurnUserId == auth.user.id;
            final isGameOver = session.status != 'playing';

            // 初期ロードで既に終了状態の場合もモーダルを出す
            if (isGameOver && !_showGameOverModal) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _showGameOverModal = true);
              });
            }

            final myCaptured = session.player1Id == auth.user.id
                ? session.player1CapturedChars
                : session.player2CapturedChars;
            final oppCaptured = session.player1Id == auth.user.id
                ? session.player2CapturedChars
                : session.player1CapturedChars;

            final myMistakes = session.player1Id == auth.user.id
                ? session.player1MistakeCount
                : session.player2MistakeCount;
            final oppMistakes = session.player1Id == auth.user.id
                ? session.player2MistakeCount
                : session.player1MistakeCount;

            final opponent = _opponent;
            final opponentIconUrl =
              (opponent == null) ? null : _resolveImageUrl(opponent.iconImageUrl);

            return Column(
              children: [
                // バナー広告（常に上部に表示）
                if (_isBannerAdLoaded && _bannerAd != null)
                  SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                    // 上部: 相手アイコン + 称号(メッセージ扱い) + 残り時間
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[800]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: opponent == null
                                ? Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[800],
                                  )
                                : Image.network(
                                    opponentIconUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[800],
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[700]!),
                              ),
                              child: Text(
                                opponent?.messageContent ?? '',
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
                          ValueListenableBuilder<int>(
                            valueListenable: _remainingTimeMs,
                            builder: (context, remainingMs, _) {
                              // ターン制限40秒想定: 残り10秒を警告
                              final isLowTime = remainingMs < 10000;
                              return Column(
                                children: [
                                  Text(
                                    _formatTime(remainingMs),
                                    style: TextStyle(
                                      color: isLowTime
                                          ? Colors.red
                                          : const Color(0xFFD4AF37),
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'R${session.roundCount}/${session.maxRounds}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // 中部: 確保文字
                    Container(
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
                          Row(
                            children: [
                              Text(
                                'あなたの確保した文字（${myCaptured.length}文字）',
                                style: const TextStyle(
                                  color: Color(0xFF026E14),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'お手付き$myMistakes',
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            myCaptured.isEmpty ? '（なし）' : myCaptured.join('、'),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '相手の確保した文字（${oppCaptured.length}文字）',
                                style: const TextStyle(
                                  color: Color(0xFFC70606),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'お手付き$oppMistakes',
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            oppCaptured.isEmpty ? '（なし）' : oppCaptured.join('、'),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isGameOver
                                ? '結果: ${_resultText(session: session, myUserId: auth.user.id)}'
                                : (isMyTurn ? 'あなたの手番' : '相手の手番'),
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '次の頭文字: ${session.expectedStartChar}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          if (session.lastWord != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '直前の単語: ${session.lastWord}',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 下部: LINE風チャット履歴
                    Expanded(
                      child: _buildChatHistory(
                        session: session,
                        myUserId: auth.user.id,
                      ),
                    ),

                    // 最下部: 入力エリア
                    _buildInputArea(
                      expectedChar: session.expectedStartChar,
                      isMyTurn: isMyTurn,
                      isGameOver: isGameOver,
                    ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          tooltip: '戻る',
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                      if (_rated != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D)
                                  .withValues(alpha: 230),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                            child: Text(
                              'レート ${_rated!.userRating}（${_rated!.userDelta >= 0 ? '+' : ''}${_rated!.userDelta}）',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (_showBattleIntro && opponent != null)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            alignment: Alignment.center,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[700]!),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(48),
                                    child: (opponentIconUrl == null)
                                        ? Container(
                                            width: 96,
                                            height: 96,
                                            color: Colors.grey[800],
                                          )
                                        : Image.network(
                                            opponentIconUrl,
                                            width: 96,
                                            height: 96,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 96,
                                                height: 96,
                                                color: Colors.grey[800],
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    opponent.titleName ?? '称号: なし',
                                    style: TextStyle(
                                      color: Colors.grey[200],
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    opponent.messageContent,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_showGameOverModal && isGameOver)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 180),
                            alignment: Alignment.center,
                            child: _buildGameOverModal(
                              session: session,
                              myUserId: auth.user.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('エラー: $error'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverModal({required PvpSession session, required String myUserId}) {
    final result = _resultText(session: session, myUserId: myUserId);
    final isDraw = result == '引き分け';
    final isWin = result == '勝利';

    final gradientColors = isDraw
        ? [const Color(0xFF4A4A4A), const Color(0xFF2D2D2D)]
        : isWin
            ? [const Color(0xFF1B5E20), const Color(0xFF2D2D2D)]
            : [const Color(0xFF8B0000), const Color(0xFF2D2D2D)];

    final titleText = isDraw ? '引き分け' : isWin ? 'あなたの勝利！' : 'あなたの敗北';

    return Container(
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
            titleText,
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() => _showGameOverModal = false);
                  context.go('/ranked');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '再プレイ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  setState(() => _showGameOverModal = false);
                  context.go('/');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4AF37),
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'タイトル',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatHistory({required PvpSession session, required String myUserId}) {
    final history = session.history;
    if (history.isEmpty) {
      return Center(
        child: Text(
          'まだありません',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final isMine = entry.playerId == myUserId;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMine
                  ? const Color(0xFF1B5E20).withValues(alpha: 204)
                  : const Color(0xFF8B0000).withValues(alpha: 204),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: entry.isValid
                    ? (isMine
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFD4AF37))
                    : Colors.red,
                width: entry.isValid ? 1 : 2,
              ),
            ),
            child: Text(
              entry.word,
              style: TextStyle(
                color: entry.isValid ? Colors.white : Colors.red[300],
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: entry.isValid ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea({
    required String expectedChar,
    required bool isMyTurn,
    required bool isGameOver,
  }) {
    if (isGameOver) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          border: Border(
            top: BorderSide(color: Colors.grey[800]!),
          ),
        ),
        child: const SizedBox.shrink(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        children: [
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
                  controller: _wordController,
                  enabled: !_busy && isMyTurn,
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
                    helperText: isMyTurn ? null : '相手の手番です',
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
                onPressed: (!_busy && isMyTurn) ? _submitWord : null,
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
                child: _busy
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
    );
  }
}
