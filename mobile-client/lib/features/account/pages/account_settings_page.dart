import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../api/account_api.dart';
import '../api/me_api.dart';
import '../models/me_models.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/subscription_service.dart';

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

  RewardedAd? _rewardedAd;
  bool _loadingRewardedAd = false;
  bool _claimingRewardedAd = false;

  // サブスクリプション関連
  CustomerInfo? _customerInfo;
  bool _loadingSubscription = false;
  bool _purchasingSubscription = false;

  static const _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const _inquiryUrl = 'https://forms.gle/LPXFy4RXbQdV3LCg7';
  static const _subscriptionPackageIdentifier = 'premium_subscription:monthly-standard'; // Google Play StoreのProduct ID

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
  void dispose() {
    _emailController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _loadSubscriptionInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 初回だけステータス取得
    if (_status == null) {
      _refresh();
    }
  }

  Future<void> _loadRewardedAd() async {
    if (_loadingRewardedAd) return;
    if (_rewardedAd != null) return;

    setState(() => _loadingRewardedAd = true);
    try {
      final completer = Completer<RewardedAd?>();
      RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => completer.complete(ad),
          onAdFailedToLoad: (_) => completer.complete(null),
        ),
      );

      final ad = await completer.future;
      if (!mounted) return;
      setState(() {
        _rewardedAd = ad;
      });
    } finally {
      if (mounted) setState(() => _loadingRewardedAd = false);
    }
  }

  Future<void> _showRewardedAdAndClaimSoul() async {
    if (_busy || _claimingRewardedAd) return;
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    if (_rewardedAd == null) {
      await _loadRewardedAd();
    }
    final ad = _rewardedAd;
    if (ad == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('広告の読み込みに失敗しました')),
      );
      return;
    }

    _rewardedAd = null;
    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, _) async {
        if (earned) return;
        earned = true;
        if (!mounted) return;
        setState(() => _claimingRewardedAd = true);
        try {
          final meApi = ref.read(meApiProvider);
          final updated = await meApi.claimRewardedAd(token: session.token);
          if (!mounted) return;

          setState(() => _me = updated);
          ref.read(authControllerProvider.notifier).updateUser(
                session.user.copyWith(
                  name: updated.name,
                  email: updated.email,
                  coins: updated.coins,
                  soulCount: updated.soulCount,
                ),
              );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('魂を1回復しました')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('報酬の受け取りに失敗しました: $e')),
          );
        } finally {
          if (mounted) setState(() => _claimingRewardedAd = false);
        }
      },
    );
  }

  Future<void> _openInquiryForm() async {
    final uri = Uri.parse(_inquiryUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けませんでした')),
      );
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URLを開けませんでした')),
      );
    }
  }

  /// サブスクリプション情報を取得
  Future<void> _loadSubscriptionInfo() async {
    if (_loadingSubscription) return;
    setState(() => _loadingSubscription = true);
    try {
      final customerInfo = await SubscriptionService.getCustomerInfo();
      if (!mounted) return;
      setState(() => _customerInfo = customerInfo);
    } catch (e) {
      if (!mounted) return;
      // エラーは無視（初回取得失敗時など）
    } finally {
      if (mounted) setState(() => _loadingSubscription = false);
    }
  }

  /// サブスクリプションを購入
  Future<void> _purchaseSubscription() async {
    if (_purchasingSubscription || _busy) return;

    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _purchasingSubscription = true);
    try {
      // RevenueCatで購入処理
      final customerInfo = await SubscriptionService.purchaseSubscription(
        packageIdentifier: _subscriptionPackageIdentifier,
      );

      // バックエンドに同期
      final isActive = SubscriptionService.isSubscriber(customerInfo);
      await SubscriptionService.syncSubscriptionToBackend(
        token: session.token,
        isActive: isActive,
      );

      if (!mounted) return;

      // ローカル状態を更新
      setState(() => _customerInfo = customerInfo);

      // ユーザー情報をリフレッシュ
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プレミアムプランに加入しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('購入に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _purchasingSubscription = false);
    }
  }

  /// サブスクリプションを復元
  Future<void> _restoreSubscription() async {
    if (_purchasingSubscription || _busy) return;

    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _purchasingSubscription = true);
    try {
      // RevenueCatで復元処理
      final customerInfo = await SubscriptionService.restorePurchases();

      // バックエンドに同期
      final isActive = SubscriptionService.isSubscriber(customerInfo);
      await SubscriptionService.syncSubscriptionToBackend(
        token: session.token,
        isActive: isActive,
      );

      if (!mounted) return;

      // ローカル状態を更新
      setState(() => _customerInfo = customerInfo);

      // ユーザー情報をリフレッシュ
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? '購入履歴を復元しました' : '復元可能な購入が見つかりませんでした',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('復元に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _purchasingSubscription = false);
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

  Future<void> _setIcon(String iconId) async {
    if (_busy) return;

    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final meApi = ref.read(meApiProvider);
      await meApi.updateMe(token: session.token, iconId: iconId);
      await _refresh();
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

  Future<void> _setTitle1(String? titleId) async {
    if (_busy) return;

    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return;

    setState(() => _busy = true);
    try {
      final meApi = ref.read(meApiProvider);
      if (titleId == null) {
        await meApi.updateMe(token: session.token, clearTitle1: true);
      } else {
        await meApi.updateMe(token: session.token, title1Id: titleId);
      }
      await _refresh();
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
      final meApi = ref.read(meApiProvider);
      await meApi.updateMe(token: session.token, messageId: messageId);
      await _refresh();
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
    final sessionAsync = ref.watch(authControllerProvider);
    final session = sessionAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント設定'),
        leading: IconButton(
          tooltip: '戻る',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
              return;
            }
            context.go('/');
          },
          icon: const Icon(Icons.arrow_back),
        ),
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
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ProfileSummaryCard(me: me, inventory: inventory),
                      const SizedBox(height: 12),
                      _SubscriptionCard(
                        customerInfo: _customerInfo,
                        loading: _loadingSubscription || _purchasingSubscription,
                        onPurchase: _purchaseSubscription,
                        onRestore: _restoreSubscription,
                      ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('広告を見て魂を回復'),
                    subtitle: const Text('リワード広告視聴で魂+1'),
                    trailing: _loadingRewardedAd || _claimingRewardedAd
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    onTap: (_busy || _claimingRewardedAd)
                        ? null
                        : _showRewardedAdAndClaimSoul,
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
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('アイコン一覧'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/icons'),
                        ),
                        const SizedBox(height: 12),
                        if (me == null || inventory == null) ...[
                          const Text('読み込み中…'),
                        ] else ...[
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final icon in inventory.icons)
                                InkWell(
                                  onTap: _busy ? null : () => _setIcon(icon.id),
                                  borderRadius: BorderRadius.circular(32),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 2,
                                        color: icon.id == me.iconId
                                            ? Theme.of(context).colorScheme.primary
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
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('称号一覧'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/titles'),
                        ),
                        const SizedBox(height: 12),
                        if (me == null || inventory == null) ...[
                          const Text('読み込み中…'),
                        ] else ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('未装備'),
                                selected: me.title1Id == null,
                                onSelected: _busy
                                    ? null
                                    : (_) => _setTitle1(null),
                              ),
                              for (final t in inventory.titles)
                                ChoiceChip(
                                  label: Text(t.name),
                                  selected: t.id == me.title1Id,
                                  onSelected: _busy
                                      ? null
                                      : (_) => _setTitle1(t.id),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _busy ? '更新中…' : 'タップで装備できます',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
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
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('メッセージ一覧'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/messages'),
                        ),
                        const SizedBox(height: 12),
                        if (me == null || inventory == null) ...[
                          const Text('読み込み中…'),
                        ] else ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final m in inventory.messages)
                                ChoiceChip(
                                  label: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 300),
                                    child: Text(
                                      m.content,
                                      softWrap: true,
                                    ),
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
                      ],
                    ),
                  ),
                ),
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
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('お問い合わせ'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: _openInquiryForm,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('サクッとゲーム'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openExternalUrl('https://play.google.com/store/apps/details?id=com.JanFred.Connect4'),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    title: const Text('物語への没入'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openExternalUrl('https://madamisujan.booth.pm/'),
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

/// サブスクリプション購入カード
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.customerInfo,
    required this.loading,
    required this.onPurchase,
    required this.onRestore,
  });

  final CustomerInfo? customerInfo;
  final bool loading;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final isActive = customerInfo != null && 
                     SubscriptionService.isSubscriber(customerInfo!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.workspace_premium : Icons.star_border,
                  color: isActive ? Colors.amber : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'プレミアムプラン',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (isActive)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '加入中',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('プレミアム特典:'),
                  const SizedBox(height: 8),
                  const Text('• 魂の最大値が15個に増加'),
                  const Text('• リワード広告で魂が全回復'),
                  const Text('• バナー広告が非表示'),
                  const Text('• ログインボーナスが20コインに増加'),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('プレミアムプランに加入すると:'),
                  const SizedBox(height: 8),
                  const Text('• 魂の最大値が15個に増加！'),
                  const Text('• リワード広告で魂が全回復！'),
                  const Text('• バナー広告が非表示に！'),
                  const Text('• ログインボーナスが20コインに増加！'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onPurchase,
                    child: const Text('プレミアムプランに加入'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRestore,
                    child: const Text('購入履歴を復元'),
                  ),
                ],
              ),
          ],
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
        iconUrl = _resolveImageUrl(icon.imageUrl);
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
    final lastDelta = me0.lastRatingDelta;
    final deltaText = lastDelta == null
        ? '未対戦'
        : (lastDelta > 0 ? '+$lastDelta' : '$lastDelta');

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
                      Text(
                        'レート: ${me0.rating}（前回: $deltaText）',
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
            const Text('対人戦歴'),
            const SizedBox(height: 12),
            if (stats == null)
              const Text('未取得')
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: '勝ち', value: stats.totalWins.toString()),
                      _StatItem(label: '負け', value: stats.totalLosses.toString()),
                      _StatItem(label: '引き分け', value: stats.totalDraws.toString()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: '現在連勝数', value: stats.currentStreak.toString()),
                      _StatItem(label: '最大連勝数', value: stats.maxStreak.toString()),
                      if (stats.past30WinRate != null)
                        _StatItem(
                          label: '過去30戦勝率',
                          value: '${stats.past30WinRate!.toStringAsFixed(1)}%',
                        ),
                    ],
                  ),
                ],
              ),
          ], // 外側のColumnの閉じ括弧
        ), // 外側のColumnの閉じ括弧
      ), // Paddingの閉じ括弧
    ); // Cardの閉じ括弧
  }
}

// 1項目を縦に並べる（ラベルが上で数値が下）ためのパーツ
class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            color: Colors.white, // 背景に合わせて色を指定
          ),
        ),
      ],
    );
  }
}