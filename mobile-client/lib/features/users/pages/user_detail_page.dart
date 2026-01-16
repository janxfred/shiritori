import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import '../providers/users_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../account/api/me_api.dart';
import '../../account/models/me_models.dart';
import '../../../core/api/api_client.dart';

final _meApiProvider = Provider<MeApi>((ref) => MeApi());

class UserDetailPage extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  MeUser? _me;
  InventoryResponse? _inventory;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.listen(authControllerProvider, (prev, next) {
      final session = next.valueOrNull;
      if (session == null) return;
      if (session.user.id != widget.userId) return;
      if (_me != null && _inventory != null) return;
      if (_busy) return;
      _refreshIfMe();
    });
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_me == null || _inventory == null) {
      _refreshIfMe();
    }
  }

  Future<void> _refreshIfMe() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;
    if (session.user.id != widget.userId) return;

    setState(() => _busy = true);
    try {
      final meApi = ref.read(_meApiProvider);
      final results = await Future.wait<Object?>([
        meApi.getMe(token: session.token),
        meApi.getInventory(token: session.token),
      ]);
      if (!mounted) return;
      setState(() {
        _me = results[0] as MeUser;
        _inventory = results[1] as InventoryResponse;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setIcon(String iconId) async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final meApi = ref.read(_meApiProvider);
      await meApi.updateMe(token: session.token, iconId: iconId);
      await _refreshIfMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アイコンを変更しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アイコン変更に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setTitle(String? titleId) async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final meApi = ref.read(_meApiProvider);
      if (titleId == null) {
        await meApi.updateMe(token: session.token, clearTitle1: true);
      } else {
        await meApi.updateMe(token: session.token, title1Id: titleId);
      }
      await _refreshIfMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('称号を変更しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('称号変更に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setMessage(String messageId) async {
    if (_busy) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final meApi = ref.read(_meApiProvider);
      await meApi.updateMe(token: session.token, messageId: messageId);
      await _refreshIfMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メッセージを変更しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メッセージ変更に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider(widget.userId));
    final session = ref.watch(authControllerProvider).valueOrNull;
    final isMe = session != null && session.user.id == widget.userId;
    final l10n = AppLocalizations.of(context)!;

    if (isMe) {
      final me = _me;
      final inventory = _inventory;

      String? iconUrl;
      if (me != null && inventory != null) {
        for (final icon in inventory.icons) {
          if (icon.id == me.iconId) {
            iconUrl = _resolveImageUrl(icon.imageUrl);
            break;
          }
        }
      }

      final messageContent = (me == null || inventory == null)
          ? null
          : inventory.messages
              .where((m) => m.id == me.messageId)
              .map((m) => m.content)
              .cast<String?>()
              .firstOrNull;

      final titleNameById = (inventory == null)
          ? <String, String>{}
          : {for (final t in inventory.titles) t.id: t.name};

      final equippedTitleName = me?.title1Id == null
          ? null
          : (titleNameById[me!.title1Id!] ?? me.title1Id);

      final lastDelta = me?.lastRatingDelta;
      final deltaText = lastDelta == null
          ? '未対戦'
          : (lastDelta > 0 ? '+$lastDelta' : '$lastDelta');

      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.userDetail),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: RefreshIndicator(
          onRefresh: _refreshIfMe,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: (iconUrl?.trim().isNotEmpty ==
                                    true)
                                ? NetworkImage(iconUrl!)
                                : null,
                            child: (iconUrl?.trim().isNotEmpty == true)
                                ? null
                                : Text(
                                    (me?.name.isNotEmpty == true)
                                        ? me!.name[0]
                                        : '?',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  me?.name ?? '読み込み中…',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'レート: ${me?.rating ?? '-'}（直近: $deltaText）',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'コイン: ${me?.coins ?? '-'}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('称号'),
                      const SizedBox(height: 6),
                      Text(equippedTitleName ?? '未装備'),
                      const SizedBox(height: 12),
                      const Text('メッセージ'),
                      const SizedBox(height: 6),
                      Text(messageContent ?? '未取得'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('アイコン変更'),
                      const SizedBox(height: 12),
                      if (me == null || inventory == null)
                        const Text('読み込み中…')
                      else
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final icon in inventory.icons)
                              InkWell(
                                onTap: _busy
                                    ? null
                                    : () => _setIcon(icon.id),
                                borderRadius: BorderRadius.circular(32),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: 2,
                                      color: icon.id == me.iconId
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundImage: NetworkImage(
                                      _resolveImageUrl(icon.imageUrl),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _busy ? '更新中…' : 'タップで装備できます',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('称号変更'),
                      const SizedBox(height: 12),
                      if (me == null || inventory == null)
                        const Text('読み込み中…')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('未装備'),
                              selected: me.title1Id == null,
                              onSelected: _busy
                                  ? null
                                  : (_) => _setTitle(null),
                            ),
                            for (final t in inventory.titles)
                              ChoiceChip(
                                label: Text(t.name),
                                selected: t.id == me.title1Id,
                                onSelected: _busy
                                    ? null
                                    : (_) => _setTitle(t.id),
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _busy ? '更新中…' : 'タップで装備できます',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('メッセージ変更'),
                      const SizedBox(height: 12),
                      if (me == null || inventory == null)
                        const Text('読み込み中…')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in inventory.messages)
                              ChoiceChip(
                                label: Text(
                                  m.content,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: m.id == me.messageId,
                                onSelected: _busy
                                    ? null
                                    : (_) => _setMessage(m.id),
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _busy ? '更新中…' : 'タップで装備できます',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.userDetail),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: userAsync.when(
        data: (user) {
          final dateFormat = DateFormat.yMMMd();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0] : '?',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(l10n.name, user.name),
                    const Divider(),
                    _buildInfoRow(l10n.email, user.email),
                    const Divider(),
                    _buildInfoRow(
                      l10n.createdAt,
                      dateFormat.format(user.createdAt),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.loading),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${l10n.error}: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userProvider(widget.userId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
