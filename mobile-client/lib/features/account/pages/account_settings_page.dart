import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../api/account_api.dart';
import '../api/me_api.dart';
import '../models/me_models.dart';

final accountApiProvider = Provider<AccountApi>((ref) => AccountApi());
final meApiProvider = Provider<MeApi>((ref) => MeApi());

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  final _emailController = TextEditingController();
  EmailStatus? _status;
  MeUser? _me;
  InventoryResponse? _inventory;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初回だけステータス取得
    if (_status == null) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final accountApi = ref.read(accountApiProvider);
      final meApi = ref.read(meApiProvider);

      final statusFuture = accountApi.getEmailStatus(token: session.token);
      final meFuture = meApi.getMe(token: session.token);
      final invFuture = meApi.getInventory(token: session.token);

      final results = await Future.wait<Object?>([
        statusFuture,
        meFuture,
        invFuture,
      ]);

      final status = results[0] as EmailStatus;
      final me = results[1] as MeUser;
      final inventory = results[2] as InventoryResponse;
      if (!mounted) return;
      setState(() {
        _status = status;
        _me = me;
        _inventory = inventory;
        _emailController.text = status.email ?? '';
      });

      // 最新値でAuthUserも更新（表示系のズレ防止）
      ref.read(authControllerProvider.notifier).updateUser(
            session.user.copyWith(
              name: me.name,
              email: me.email,
              coins: me.coins,
              soulCount: me.soulCount,
            ),
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

  Future<void> _setEmail() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(accountApiProvider);
      final result = await api.setEmail(token: session.token, email: email);
      // AuthUserの表示用email/coinsも更新
      ref
          .read(authControllerProvider.notifier)
          .updateUser(session.user.copyWith(email: result.email, coins: result.coins));

      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.rewarded ? 'メールアドレスを連携しました（報酬獲得）' : 'メールアドレスを変更しました'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlinkEmail() async {
    if (_busy) return;

    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(accountApiProvider);
      await api.unlinkEmail(token: session.token);
      ref.read(authControllerProvider.notifier).updateUser(session.user.copyWith(email: null));
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メール連携を解除しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('解除に失敗しました: $e')),
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
        title: const Text('アカウント設定'),
        actions: [
          if (session != null)
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      ref.read(authControllerProvider.notifier).logout();
                      context.pop();
                    },
              child: const Text('ログアウト'),
            ),
        ],
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
                    const Text('メール連携の変更/解除にはログインが必要です'),
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

          final status = _status;
          final me = _me;
          final inventory = _inventory;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileSummaryCard(me: me, inventory: inventory),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('現在のメール'),
                  subtitle: Text(status?.email ?? session.user.email ?? '未連携'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('連携報酬'),
                  subtitle: Text(
                    status == null
                        ? '読み込み中…'
                        : '${status.rewardCoins}コイン（${status.rewarded ? '受取済み' : '未受取'}）',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _busy ? null : _setEmail,
                  child: Text(_busy ? '処理中…' : '連携/変更'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: (_busy || (status?.email == null && session.user.email == null))
                      ? null
                      : _unlinkEmail,
                  child: const Text('解除'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('エラー: $error'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.refresh(authControllerProvider),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.me,
    required this.inventory,
  });

  final MeUser? me;
  final InventoryResponse? inventory;

  @override
  Widget build(BuildContext context) {
    final me0 = me;
    final inventory0 = inventory;

    if (me0 == null || inventory0 == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('プロフィール'),
              SizedBox(height: 8),
              Text('読み込み中…'),
            ],
          ),
        ),
      );
    }

    String? iconUrl;
    for (final icon in inventory0.icons) {
      if (icon.id == me0.iconId) {
        iconUrl = icon.imageUrl;
        break;
      }
    }

    final titleNameById = <String, String>{
      for (final t in inventory0.titles) t.id: t.name,
    };

    final equippedTitleNames = <String>[];
    for (final titleId in [me0.title1Id, me0.title2Id, me0.title3Id]) {
      if (titleId == null) continue;
      equippedTitleNames.add(titleNameById[titleId] ?? titleId);
    }

    final stats = me0.stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: (iconUrl?.trim().isNotEmpty == true)
                      ? NetworkImage(iconUrl!)
                      : null,
                  child: (iconUrl?.trim().isNotEmpty == true)
                      ? null
                      : Text(
                          me0.name.isNotEmpty ? me0.name[0] : '?',
                          style: const TextStyle(fontSize: 20),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        me0.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${me0.id}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text('コイン: ${me0.coins} / 魂: ${me0.soulCount}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('称号'),
            const SizedBox(height: 6),
            if (equippedTitleNames.isEmpty)
              const Text('未装備')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in equippedTitleNames) Chip(label: Text(name)),
                ],
              ),
            const SizedBox(height: 12),
            const Text('戦歴'),
            const SizedBox(height: 6),
            if (stats == null)
              const Text('未取得')
            else
              Column(
                children: [
                  _StatRow(label: '勝ち', value: stats.totalWins.toString()),
                  _StatRow(label: '負け', value: stats.totalLosses.toString()),
                  _StatRow(label: '引き分け', value: stats.totalDraws.toString()),
                  _StatRow(label: '現在連勝', value: stats.currentStreak.toString()),
                  _StatRow(label: '最大連勝', value: stats.maxStreak.toString()),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
