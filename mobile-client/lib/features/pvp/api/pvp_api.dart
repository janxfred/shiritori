import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/pvp_models.dart';

class PvpApi {
  PvpApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<PvpStartResponse> start({
    required String token,
    required String opponentId,
  }) async {
    try {
      final res = await _dio.post(
        '/api/pvp/start',
        data: {'opponentId': opponentId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return PvpStartResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PvpSession> getSession({
    required String token,
    required String sessionId,
  }) async {
    try {
      final res = await _dio.get(
        '/api/pvp/$sessionId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data as Map<String, dynamic>;
      return PvpSession.fromJson(data['session'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PvpSubmitResponse> submitWord({
    required String token,
    required String sessionId,
    required String word,
  }) async {
    try {
      final res = await _dio.post(
        '/api/pvp/$sessionId/submit',
        data: {'word': word},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return PvpSubmitResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PvpCheckTimeResponse> checkTime({
    required String token,
    required String sessionId,
  }) async {
    try {
      final res = await _dio.get(
        '/api/pvp/$sessionId/check-time',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return PvpCheckTimeResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return Exception(data['message']);
      }
    }
    return Exception('通信エラーが発生しました: ${e.message}');
  }
}
