import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/services/new_item_service.dart';
import '../api/me_api.dart';
import '../models/me_models.dart';

final _meApiProvider = Provider<MeApi>((ref) => MeApi());

class IconCatalogPage extends ConsumerStatefulWidget {
  const IconCatalogPage({super.key});

  @override
  ConsumerState<IconCatalogPage> createState() => _IconCatalogPageState();
}

class _IconCatalogPageState extends ConsumerState<IconCatalogPage> {
  bool _busy = false;
  List<IconCatalogEntry>? _icons;
  String? _errorMessage;
  DateTime? _lastViewedAt;

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

  Future<void> _load() async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(_meApiProvider);
      final res = await api.getIconCatalog(token: session.token);
      if (!mounted) return;
      setState(() {
        _icons = res.icons;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _icons = _icons ?? const <IconCatalogEntry>[];
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
    final lastViewed = await NewItemService.getIconsLastViewed();
    if (mounted) {
      setState(() => _lastViewedAt = lastViewed);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_icons == null) {
      _load();
    }
  }

  @override
  void dispose() {
    // アカウント設定画面に戻る際に最終表示日時を記録
    NewItemService.markIconsViewed();
    super.dispose();
  }

  double _calculateCompletionRate() {
    if (_icons == null || _icons!.isEmpty) return 0.0;
    final owned = _icons!.where((icon) => icon.owned).length;
    return (owned / _icons!.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      final session = next.valueOrNull;
      if (session != null && _icons == null && !_busy) {
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
            const Text('アイコン一覧'),
            if (_icons != null && _icons!.isNotEmpty) ...[
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
                    const Text('アイコン一覧の表示にはログインが必要です'),
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

          final icons = _icons ?? const <IconCatalogEntry>[];

          if (_busy && _icons == null) {
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

          if (icons.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('表示できるアイコンがありません'),
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
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: icons.length,
              itemBuilder: (context, i) {
                final icon = icons[i];
                final showNew = icon.owned && _lastViewedAt == null;
                final child = icon.owned
                    ? SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: ClipOval(
                          child: Image.network(
                            _resolveImageUrl(icon.imageUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '?',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      );

                return Stack(
                  children: [
                    Tooltip(
                      message: icon.owned ? icon.id : '未獲得',
                      child: child,
                    ),
                    if (showNew)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
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
