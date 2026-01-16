import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../api/gacha_api.dart';
import '../models/gacha_models.dart';

final gachaApiProvider = Provider<GachaApi>((ref) => GachaApi());

class GachaPage extends ConsumerStatefulWidget {
  const GachaPage({super.key});

  @override
  ConsumerState<GachaPage> createState() => _GachaPageState();
}

class _GachaPageState extends ConsumerState<GachaPage> {
  bool _busy = false;
  GachaStatusResponse? _status;
  GachaDrawResponse? _last;

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

  String _friendlyApiErrorMessage(DioException e) {
    final data = e.response?.data;
    final serverMessage = (data is Map<String, dynamic>) ? data['message'] : null;
    final message = (serverMessage is String && serverMessage.trim().isNotEmpty)
        ? serverMessage.trim()
        : (e.message ?? '通信に失敗しました');
    return message;
  }

  Future<void> _refresh() async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(gachaApiProvider);
      final status = await api.getStatus(token: session.token);
      if (!mounted) return;
      setState(() {
        _status = status;
      });
      ref.read(authControllerProvider.notifier).updateUser(
            session.user.copyWith(coins: status.coins),
          );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyApiErrorMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('取得に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _draw() async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(gachaApiProvider);
      final draw = await api.draw(token: session.token);
      if (!mounted) return;
      setState(() {
        _last = draw;
        _status = _status == null
            ? GachaStatusResponse(cost: 0, coins: draw.coins)
            : GachaStatusResponse(cost: _status!.cost, coins: draw.coins);
      });
      ref.read(authControllerProvider.notifier).updateUser(
            session.user.copyWith(coins: draw.coins),
          );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyApiErrorMessage(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('召喚に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_status == null) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(authControllerProvider);
    final session = sessionAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('召喚（ガチャ）'),
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
                    const Text('召喚にはログインが必要です'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('ログインへ'),
                    ),
                  ],
                ),
              ),
            );
          }

          final status = _status;
          final coins = status?.coins ?? session.user.coins;
          final cost = status?.cost;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('所持コイン: $coins'),
                        const SizedBox(height: 8),
                        Text('必要コイン: ${cost ?? '-'}'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _draw,
                            child: Text(_busy ? '召喚中…' : '召喚する'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_last != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _RewardView(
                        reward: _last!.reward,
                        resolveImageUrl: _resolveImageUrl,
                      ),
                    ),
                  ),
                ] else ...[
                  const Text('ここに召喚結果が表示されます'),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }
}

class _RewardView extends StatelessWidget {
  const _RewardView({
    required this.reward,
    required this.resolveImageUrl,
  });

  final GachaReward reward;
  final String Function(String) resolveImageUrl;

  @override
  Widget build(BuildContext context) {
    if (reward is GachaIconReward) {
      final r = reward as GachaIconReward;
      final url = resolveImageUrl(r.imageUrl);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('報酬: アイコン (${r.rarity})'),
          const SizedBox(height: 12),
          if (url.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      debugPrint('アイコン画像の読み込みに失敗: $error');
                      debugPrint('$stackTrace');
                    }
                    return const Text('画像を読み込めませんでした');
                  },
                ),
              ),
            ),
        ],
      );
    }

    if (reward is GachaMessageReward) {
      final r = reward as GachaMessageReward;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('報酬: メッセージ (${r.rarity})'),
          const SizedBox(height: 8),
          Text(r.content),
        ],
      );
    }

    if (reward is GachaTitleReward) {
      final r = reward as GachaTitleReward;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('報酬: 称号'),
          const SizedBox(height: 8),
          Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (r.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.description),
          ],
        ],
      );
    }

    final r = reward as GachaItemReward;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('報酬: アイテム (${r.rarity})'),
        const SizedBox(height: 8),
        Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (r.description.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(r.description),
        ],
      ],
    );
  }
}
