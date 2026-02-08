import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/api/api_client.dart';
import '../api/present_api.dart';
import '../models/present_models.dart';

final presentApiProvider = Provider<PresentApi>((ref) => PresentApi());

class PresentPage extends ConsumerStatefulWidget {
  const PresentPage({super.key});

  @override
  ConsumerState<PresentPage> createState() => _PresentPageState();
}

class _PresentPageState extends ConsumerState<PresentPage> {
  bool _busy = false;
  PresentListResponse? _list;

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
      final api = ref.read(presentApiProvider);
      final list = await api.getList(token: session.token);
      if (!mounted) return;
      setState(() {
        _list = list;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      // SnackBar表示を削除
    } catch (e) {
      if (!mounted) return;
      // SnackBar表示を削除
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claimAll() async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(presentApiProvider);
      final result = await api.claimAll(token: session.token);
      if (!mounted) return;

      // コインの合計を計算して更新
      final coinReward = result.rewards
          .where((r) => r.type == 'coin')
          .fold(0, (sum, r) => sum + r.amount);
      if (coinReward > 0) {
        ref.read(authControllerProvider.notifier).updateUser(
              session.user.copyWith(coins: session.user.coins + coinReward),
            );
      }

      // モーダルを表示
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Material(
              color: Colors.transparent,
              child: Card(
                color: Color(0xFF2D2D2D),
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        size: 64,
                        color: Color(0xFFD4AF37),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'プレゼントを受け取りました！',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // 1秒後にモーダルを閉じてホーム画面へ遷移
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.pop(); // モーダルを閉じる
          // プレゼント一覧を更新してから遷移
          await _refresh();
          if (mounted) {
            context.pop(); // ホーム画面へ戻る
          }
        }
      }
    } on DioException catch (e) {
      if (!mounted) return;
      // SnackBar表示を削除
    } catch (e) {
      if (!mounted) return;
      // SnackBar表示を削除
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_list == null) {
      _refresh();
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'coin':
        return 'コイン';
      case 'title':
        return '称号';
      case 'message':
        return 'メッセージ';
      case 'icon':
        return 'アイコン';
      case 'item':
        return 'アイテム';
      default:
        return type;
    }
  }

  String _getTypeImagePath(String type) {
    switch (type) {
      case 'coin':
        return '/static/コイン.jpeg';
      case 'title':
        return '/static/盾.jpeg';
      case 'message':
        return '/static/吹き出し.jpeg';
      case 'icon':
        return '/static/アイコン.jpeg';
      default:
        return '';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'coin':
        return Icons.monetization_on;
      case 'title':
        return Icons.star;
      case 'message':
        return Icons.chat_bubble;
      case 'icon':
        return Icons.face;
      case 'item':
        return Icons.inventory;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'coin':
        return const Color(0xFFD4AF37);
      case 'title':
        return Colors.purple;
      case 'message':
        return Colors.blue;
      case 'icon':
        return Colors.green;
      case 'item':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      final session = next.valueOrNull;
      if (session != null && _list == null && !_busy) {
        _refresh();
      }
    });

    final sessionAsync = ref.watch(authControllerProvider);
    final session = sessionAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('プレゼントボックス'),
        backgroundColor: const Color(0xFF2D2D2D),
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      body: sessionAsync.when(
        data: (_) {
          if (session == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'プレゼントボックスにはログインが必要です',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('ログインへ'),
                    ),
                  ],
                ),
              ),
            );
          }

          final list = _list;
          final presents = list?.presents ?? [];

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: Column(
                    children: [
                      // 一括受け取りボタン
                      if (presents.isNotEmpty)
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
                              Expanded(
                                child: Text(
                                  '未受け取り: ${presents.length}件',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _busy ? null : _claimAll,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37),
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(_busy ? '受け取り中…' : 'すべて受け取る'),
                              ),
                            ],
                          ),
                        ),

                      // プレゼント一覧
                      Expanded(
                        child: _busy && list == null
                      ? const Center(child: CircularProgressIndicator())
                      : presents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.card_giftcard,
                                    size: 64,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'プレゼントはありません',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: presents.length,
                              itemBuilder: (context, index) {
                                final present = presents[index];
                                final imagePath = _getTypeImagePath(present.type);
                                
                                return Card(
                                  color: const Color(0xFF2D2D2D),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: imagePath.isNotEmpty
                                        ? CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            backgroundImage: NetworkImage(
                                              _resolveImageUrl(imagePath),
                                            ),
                                          )
                                        : CircleAvatar(
                                            backgroundColor: _getTypeColor(present.type).withValues(alpha: 51),
                                            child: Icon(
                                              _getTypeIcon(present.type),
                                              color: _getTypeColor(present.type),
                                            ),
                                          ),
                                    title: Text(
                                      present.description,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      '${_getTypeLabel(present.type)}${present.type == 'coin' ? ' ×${present.amount}' : ''}',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              BannerAdWidget(isSubscriber: session.user.isSubscriber),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'エラー: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
