import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/present_models.dart';

class PresentApi {
  PresentApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<PresentListResponse> getList({required String token}) async {
    final res = await _dio.get(
      '/api/present',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return PresentListResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ClaimPresentResponse> claim({
    required String token,
    required String presentId,
  }) async {
    final res = await _dio.post(
      '/api/present/claim',
      data: {'presentId': presentId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ClaimPresentResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ClaimAllPresentsResponse> claimAll({required String token}) async {
    final res = await _dio.post(
      '/api/present/claim-all',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ClaimAllPresentsResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
