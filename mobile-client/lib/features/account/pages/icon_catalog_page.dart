import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/banner_ad_widget.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_icons == null) {
      _load();
    }
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
      appBar: AppBar(title: const Text('アイコン一覧')),
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
                final child = icon.owned
                    ? ClipOval(
                        child: Image.network(
                          _resolveImageUrl(icon.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
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

                return Tooltip(
                  message: icon.owned ? icon.id : '未獲得',
                  child: child,
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
