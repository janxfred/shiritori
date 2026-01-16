import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/gacha_models.dart';

class GachaApi {
  GachaApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<GachaStatusResponse> getStatus({required String token}) async {
    final res = await _dio.get(
      '/api/gacha',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return GachaStatusResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GachaDrawResponse> draw({required String token}) async {
    final res = await _dio.post(
      '/api/gacha/draw',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return GachaDrawResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
