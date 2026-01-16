import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/ranked_models.dart';

class RankedApi {
  RankedApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<MatchmakeResponse> matchmake({required String token}) async {
    try {
      final res = await _dio.post(
        '/api/matchmake',
        data: {},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return MatchmakeResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CreateMatchResponse> submitMatch({
    required String userId,
    required String opponentId,
    required MatchResult result,
  }) async {
    try {
      final res = await _dio.post(
        '/api/matches',
        data: {
          'userId': userId,
          'opponentId': opponentId,
          'result': result,
        },
      );
      return CreateMatchResponse.fromJson(res.data as Map<String, dynamic>);
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
