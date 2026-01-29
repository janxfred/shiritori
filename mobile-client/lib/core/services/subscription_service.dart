import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

/// RevenueCatのサブスクリプション状態を管理するサービス
class SubscriptionService {
  /// 現在のサブスクリプション状態を取得
  static Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// ユーザーがプレミアムサブスクリプションを持っているか確認
  static bool isSubscriber(CustomerInfo customerInfo) {
    final entitlements = customerInfo.entitlements.active;
    return entitlements.isNotEmpty;
  }

  /// 利用可能なOfferingsを取得してデバッグ出力
  /// テストやデバッグ用に公開
  static Future<Offerings> getOfferings() async {
    final offerings = await Purchases.getOfferings();
    debugPrint('=== RevenueCat Offerings Debug ===');
    debugPrint('Current Offering: ${offerings.current?.identifier ?? "null"}');
    if (offerings.current != null) {
      debugPrint('Available Packages:');
      for (final pkg in offerings.current!.availablePackages) {
        debugPrint('  - Package Identifier: ${pkg.identifier}');
        debugPrint('    Store Product ID: ${pkg.storeProduct.identifier}');
        debugPrint('    Price: ${pkg.storeProduct.priceString}');
        debugPrint('    Package Type: ${pkg.packageType}');
      }
    }
    debugPrint('All Offerings: ${offerings.all.keys.toList()}');
    debugPrint('=================================');
    return offerings;
  }

  /// サブスクリプションを購入
  /// 
  /// [packageIdentifier] はRevenueCatのパッケージ識別子（$rc_monthlyなど）
  /// または [storeProductId] はGoogle Play/App Storeの商品ID
  /// 
  /// 優先順位:
  /// 1. RevenueCatパッケージ識別子で完全一致
  /// 2. ストア商品IDで完全一致
  /// 3. ストア商品IDの部分一致（コロン区切りのプレフィックス）
  /// 4. 利用可能なパッケージが1つだけなら、それを使用
  static Future<CustomerInfo> purchaseSubscription({
    required String packageIdentifier,
  }) async {
    // まずOfferingsを取得（デバッグ出力付き）
    final offerings = await getOfferings();
    if (offerings.current == null) {
      throw Exception('利用可能なサブスクリプションが見つかりませんでした。RevenueCatダッシュボードでOfferingが設定されているか確認してください。');
    }

    final availablePackages = offerings.current!.availablePackages;
    if (availablePackages.isEmpty) {
      throw Exception('利用可能なパッケージがありません。RevenueCatダッシュボードでProductsとPackagesが設定されているか確認してください。');
    }

    Package? targetPackage;

    // 1. RevenueCatパッケージ識別子で完全一致
    for (final pkg in availablePackages) {
      if (pkg.identifier == packageIdentifier) {
        targetPackage = pkg;
        debugPrint('✓ パッケージ識別子で一致: ${pkg.identifier}');
        break;
      }
    }

    // 2. ストア商品IDで完全一致
    if (targetPackage == null) {
      for (final pkg in availablePackages) {
        if (pkg.storeProduct.identifier == packageIdentifier) {
          targetPackage = pkg;
          debugPrint('✓ ストア商品IDで一致: ${pkg.storeProduct.identifier}');
          break;
        }
      }
    }

    // 3. ストア商品IDの部分一致（コロン区切りのプレフィックス）
    // 例: "premium_subscription:monthly-standard" で "premium_subscription" を検索
    if (targetPackage == null) {
      final prefix = packageIdentifier.split(':').first;
      for (final pkg in availablePackages) {
        final storeId = pkg.storeProduct.identifier;
        if (storeId.startsWith(prefix) || storeId.contains(prefix)) {
          targetPackage = pkg;
          debugPrint('✓ プレフィックス部分一致: $prefix -> ${pkg.storeProduct.identifier}');
          break;
        }
      }
    }

    // 4. 利用可能なパッケージが1つだけなら、それを使用
    if (targetPackage == null && availablePackages.length == 1) {
      targetPackage = availablePackages.first;
      debugPrint('✓ 唯一のパッケージを使用: ${targetPackage.identifier} (${targetPackage.storeProduct.identifier})');
    }

    if (targetPackage == null) {
      // 詳細なエラーメッセージを生成
      final availableList = availablePackages
          .map((p) => '${p.identifier} (StoreID: ${p.storeProduct.identifier})')
          .join(', ');
      throw Exception(
        '指定されたサブスクリプションパッケージが見つかりませんでした: $packageIdentifier\n'
        '利用可能なパッケージ: $availableList\n'
        'RevenueCatダッシュボードでの設定を確認してください。'
      );
    }

    // 購入を実行
    debugPrint('購入実行: ${targetPackage.identifier} (${targetPackage.storeProduct.identifier})');
    final purchaserInfo = await Purchases.purchasePackage(targetPackage);
    return purchaserInfo;
  }

  /// RevenueCatのサブスクリプション状態をバックエンドに同期
  /// 
  /// [token] はJWTトークン
  /// [isActive] はサブスクリプションがアクティブかどうか
  static Future<void> syncSubscriptionToBackend({
    required String token,
    required bool isActive,
  }) async {
    final client = ApiClient().dio;
    final response = await client.post(
      '/api/subscription/sync',
      data: {'isActive': isActive},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('サブスクリプション同期に失敗しました: ${response.statusCode}');
    }
  }

  /// サブスクリプションを復元（以前購入したものを復元）
  static Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }
}
