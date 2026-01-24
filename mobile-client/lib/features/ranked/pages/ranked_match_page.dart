import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../account/api/me_api.dart';
import '../api/ranked_api.dart';
import '../../pvp/models/pvp_models.dart';

final rankedApiProvider = Provider<RankedApi>((ref) => RankedApi());
final meApiProvider = Provider<MeApi>((ref) => MeApi());

class RankedMatchPage extends ConsumerStatefulWidget {
  const RankedMatchPage({super.key});

  @override
  ConsumerState<RankedMatchPage> createState() => _RankedMatchPageState();
}

class _RankedMatchPageState extends ConsumerState<RankedMatchPage> {
  bool _busy = false;
  int? _myRating;
  bool _matchmakeRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final session = ref.read(authControllerProvider).valueOrNull;
    if (session != null && _myRating == null) {
      _refreshMe();
    }

    // 「対人戦」ボタン押下でこの画面に遷移してきたら、即マッチング開始
    if (session != null && !_matchmakeRequested) {
      _matchmakeRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startMatchmake();
      });
    }
  }

  Future<void> _refreshMe() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    try {
      final meApi = ref.read(meApiProvider);
      final me = await meApi.getMe(token: session.token);
      if (!mounted) return;
      setState(() => _myRating = me.rating);
    } catch (_) {
      // 失敗しても画面は表示する
    }
  }

  Future<void> _startMatchmake() async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(rankedApiProvider);
      final res = await api.matchmake(token: session.token);
      if (!mounted) return;

      // PvP開始時に魂は必ず1消費される（失敗時は例外になるためここには来ない）
      ref.read(authControllerProvider.notifier).updateUser(
            session.user.copyWith(
              soulCount: (session.user.soulCount - 1).clamp(0, 1 << 30),
            ),
          );

      final pvpOpponent = PvpOpponent(
        userId: res.opponent.userId,
        name: res.opponent.name,
        iconImageUrl: res.opponent.iconImageUrl,
        messageContent: res.opponent.messageContent,
        titleName: res.opponent.titleName,
        rating: res.opponent.rating,
        totalWins: res.opponent.totalWins,
        winRate: res.opponent.winRate,
        maxStreak: res.opponent.maxStreak,
      );

      try {
        final meApi = ref.read(meApiProvider);
        final me = await meApi.getMe(token: session.token);
        if (mounted) {
          ref.read(authControllerProvider.notifier).updateUser(
                session.user.copyWith(
                  name: me.name,
                  email: me.email,
                  coins: me.coins,
                  soulCount: me.soulCount,
                ),
              );
        }
      } catch (_) {
        // 失敗しても対戦は開始できる
      }

      if (!mounted) return;

      // 相手が見つかったら即対戦開始（この画面に戻らない）
      context.go('/pvp/${res.sessionId}', extra: pvpOpponent);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('マッチングに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(authControllerProvider);
    final session = sessionAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('対人戦'),
        leading: IconButton(
          tooltip: 'ホームへ',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home),
        ),
      ),
      body: sessionAsync.when(
        data: (_) {
          if (session == null) {
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('自分: ${session.user.name}'),
                      const SizedBox(height: 4),
                      Text('レート: ${_myRating?.toString() ?? '取得中…'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (_busy) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('マッチング中…')),
                      ] else ...[
                        const Expanded(child: Text('マッチング待機中')),
                        TextButton(
                          onPressed: _startMatchmake,
                          child: const Text('再試行'),
                        ),
                      ],
                    ],
                  ),
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
    );
  }
}
