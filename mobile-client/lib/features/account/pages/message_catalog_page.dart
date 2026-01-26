import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/services/new_item_service.dart';
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
  DateTime? _lastViewedAt;

  Future<void> _load() async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(_meApiProvider);
      final res = await api.getMessageCatalog(token: session.token);
      if (!mounted) return;
      // 五十音順にソート
      final sortedMessages = List<MessageCatalogEntry>.from(res.messages)
        ..sort((a, b) {
          // 所持している場合のみ内容でソート
          if (a.owned && b.owned) {
            return a.content.compareTo(b.content);
          }
          // 未所持は後ろに
          if (!a.owned && b.owned) return 1;
          if (a.owned && !b.owned) return -1;
          return 0;
        });
      setState(() {
        _messages = sortedMessages;
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
  void initState() {
    super.initState();
    _loadLastViewedAt();
  }

  Future<void> _loadLastViewedAt() async {
    final lastViewed = await NewItemService.getMessagesLastViewed();
    if (mounted) {
      setState(() => _lastViewedAt = lastViewed);
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
  void dispose() {
    // アカウント設定画面に戻る際に最終表示日時を記録
    NewItemService.markMessagesViewed();
    super.dispose();
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
                final showNew = m.owned && _lastViewedAt == null;
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(content)),
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
