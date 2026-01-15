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
}
