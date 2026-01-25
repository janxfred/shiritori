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

  /// サブスクリプションを購入
  /// 
  /// [packageIdentifier] は通常 "premium_subscription" などのパッケージ識別子
  static Future<CustomerInfo> purchaseSubscription({
    required String packageIdentifier,
  }) async {
    // まずOfferingsを取得
    final offerings = await Purchases.getOfferings();
    if (offerings.current == null) {
      throw Exception('利用可能なサブスクリプションが見つかりませんでした');
    }

    // パッケージを探す
    Package? targetPackage;
    for (final pkg in offerings.current!.availablePackages) {
      if (pkg.identifier == packageIdentifier) {
        targetPackage = pkg;
        break;
      }
    }

    if (targetPackage == null) {
      throw Exception('指定されたサブスクリプションパッケージが見つかりませんでした: $packageIdentifier');
    }

    // 購入を実行
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
