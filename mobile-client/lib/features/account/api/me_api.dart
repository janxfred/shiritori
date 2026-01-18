import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/me_models.dart';

class MeApi {
  MeApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<MeUser> getMe({required String token}) async {
    final res = await _dio.get(
      '/api/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = res.data as Map<String, dynamic>;
    return MeUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<InventoryResponse> getInventory({required String token}) async {
    final res = await _dio.get(
      '/api/me/inventory',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return InventoryResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MeUser> updateMe({
    required String token,
    String? iconId,
    String? messageId,
    String? title1Id,
    bool clearTitle1 = false,
  }) async {
    final data = <String, dynamic>{};
    if (iconId != null) data['iconId'] = iconId;
    if (messageId != null) data['messageId'] = messageId;
    if (clearTitle1) {
      data['title1Id'] = null;
    } else if (title1Id != null) {
      data['title1Id'] = title1Id;
    }

    final res = await _dio.patch(
      '/api/me',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final body = res.data as Map<String, dynamic>;
    return MeUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<MeUser> claimRewardedAd({required String token}) async {
    final res = await _dio.post(
      '/api/me/rewarded-ad',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final body = res.data as Map<String, dynamic>;
    return MeUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<IconCatalogResponse> getIconCatalog({required String token}) async {
    final res = await _dio.get(
      '/api/me/icons',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return IconCatalogResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TitleCatalogResponse> getTitleCatalog({required String token}) async {
    final res = await _dio.get(
      '/api/me/titles',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return TitleCatalogResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
