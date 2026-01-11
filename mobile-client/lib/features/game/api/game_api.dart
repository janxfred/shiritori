/// ゲームAPIクライアント
import 'package:dio/dio.dart';
import '../models/game_models.dart';

class GameApi {
  final Dio _dio;
  
  // Androidエミュレータから localhost にアクセスする場合は 10.0.2.2 を使用
  static const String _baseUrl = 'http://10.0.2.2:3002';

  GameApi() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  /// 新しいゲームを開始
  Future<CreateGameResponse> startGame({AiLevel level = AiLevel.hard}) async {
    try {
      final response = await _dio.post(
        '/api/game/start',
        data: {'aiLevel': level.value},
      );
      return CreateGameResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// ゲーム状態を取得
  Future<GameSession> getGameState(String sessionId) async {
    try {
      final response = await _dio.get('/api/game/$sessionId');
      final data = response.data as Map<String, dynamic>;
      return GameSession.fromJson(data['session'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 単語を送信
  Future<SubmitWordResponse> submitWord(String sessionId, String word) async {
    try {
      final response = await _dio.post(
        '/api/game/$sessionId/submit',
        data: {'word': word},
      );
      return SubmitWordResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 制限時間をチェック
  Future<CheckTimeResponse> checkTime(String sessionId) async {
    try {
      final response = await _dio.get('/api/game/$sessionId/check-time');
      return CheckTimeResponse.fromJson(response.data as Map<String, dynamic>);
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

