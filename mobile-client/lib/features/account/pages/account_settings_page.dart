import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../api/account_api.dart';

final accountApiProvider = Provider<AccountApi>((ref) => AccountApi());

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  final _emailController = TextEditingController();
  EmailStatus? _status;
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
    final session = ref.read(authControllerProvider).value;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(accountApiProvider);
      final status = await api.getEmailStatus(token: session.token);
      if (!mounted) return;
      setState(() {
        _status = status;
        _emailController.text = status.email ?? '';
      });
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

    final session = ref.read(authControllerProvider).value;
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

    final session = ref.read(authControllerProvider).value;
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
    final session = sessionAsync.value;

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
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
