import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../api/me_api.dart';
import '../models/me_models.dart';

final _meApiProvider = Provider<MeApi>((ref) => MeApi());

class MessageCatalogPage extends ConsumerStatefulWidget {
  const MessageCatalogPage({super.key});

  @override
  ConsumerState<MessageCatalogPage> createState() => _MessageCatalogPageState();
}

class _MessageCatalogPageState extends ConsumerState<MessageCatalogPage> {
  bool _busy = false;
  List<MessageCatalogEntry>? _messages;
  String? _errorMessage;

  Future<void> _load() async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(_meApiProvider);
      final res = await api.getMessageCatalog(token: session.token);
      if (!mounted) return;
      setState(() {
        _messages = res.messages;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages = _messages ?? const <MessageCatalogEntry>[];
        _errorMessage = '取得に失敗しました: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages == null) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      final session = next.valueOrNull;
      if (session != null && _messages == null && !_busy) {
        _load();
      }
    });

    final sessionAsync = ref.watch(authControllerProvider);
    final session = sessionAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('メッセージ一覧')),
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
                    const Text('メッセージ一覧の表示にはログインが必要です'),
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

          final messages = _messages ?? const <MessageCatalogEntry>[];

          if (_busy && _messages == null) {
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

          if (messages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('表示できるメッセージがありません'),
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
              itemCount: messages.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final m = messages[i];
                final content = m.owned ? m.content : '???';
                return ListTile(
                  title: Text(content),
                  subtitle: Text('獲得条件: ${m.condition}'),
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
