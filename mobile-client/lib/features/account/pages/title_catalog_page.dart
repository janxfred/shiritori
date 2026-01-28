import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/services/new_item_service.dart';
import '../api/me_api.dart';
import '../models/me_models.dart';

final _meApiProvider = Provider<MeApi>((ref) => MeApi());

class TitleCatalogPage extends ConsumerStatefulWidget {
  const TitleCatalogPage({super.key});

  @override
  ConsumerState<TitleCatalogPage> createState() => _TitleCatalogPageState();
}

class _TitleCatalogPageState extends ConsumerState<TitleCatalogPage> {
  bool _busy = false;
  List<TitleCatalogEntry>? _titles;
  String? _errorMessage;
  DateTime? _lastViewedAt;

  Future<void> _load() async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(_meApiProvider);
      final res = await api.getTitleCatalog(token: session.token);
      if (!mounted) return;
      // 五十音順にソート
      final sortedTitles = List<TitleCatalogEntry>.from(res.titles)
        ..sort((a, b) {
          // 所持している場合のみ名前でソート
          if (a.owned && b.owned) {
            return a.name.compareTo(b.name);
          }
          // 未所持は後ろに
          if (!a.owned && b.owned) return 1;
          if (a.owned && !b.owned) return -1;
          return 0;
        });
      setState(() {
        _titles = sortedTitles;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _titles = _titles ?? const <TitleCatalogEntry>[];
        _errorMessage = '取得に失敗しました: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLastViewedAt();
  }

  Future<void> _loadLastViewedAt() async {
    final lastViewed = await NewItemService.getTitlesLastViewed();
    if (mounted) {
      setState(() => _lastViewedAt = lastViewed);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_titles == null) {
      _load();
    }
  }

  @override
  void dispose() {
    // アカウント設定画面に戻る際に最終表示日時を記録
    NewItemService.markTitlesViewed();
    super.dispose();
  }

  double _calculateCompletionRate() {
    if (_titles == null || _titles!.isEmpty) return 0.0;
    final owned = _titles!.where((title) => title.owned).length;
    return (owned / _titles!.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      final session = next.valueOrNull;
      if (session != null && _titles == null && !_busy) {
        _load();
      }
    });

    final sessionAsync = ref.watch(authControllerProvider);
    final session = sessionAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('称号一覧'),
            if (_titles != null && _titles!.isNotEmpty) ...[
              Text(
                'コンプ率: ${_calculateCompletionRate().toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: sessionAsync.when(
        data: (_) {
          if (session == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('称号一覧の表示にはログインが必要です'),
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

          final titles = _titles ?? const <TitleCatalogEntry>[];

          if (_busy && _titles == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (titles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('表示できる称号がありません'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('再読み込み'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: titles.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final t = titles[i];
                final name = t.owned ? t.name : '???';
                final showNew = t.owned && _lastViewedAt == null;
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(name)),
                      if (showNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text('獲得条件: ${t.condition}'),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
            ),
          ),
          if (session != null)
            BannerAdWidget(isSubscriber: session.user.isSubscriber),
        ],
      ),
    );
  }
}
