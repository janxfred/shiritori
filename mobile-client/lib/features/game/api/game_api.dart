import 'package:mobile_client/core/api/api_client.dart';
import '../models/game_models.dart';

/// ゲームAPI クライアント
class GameApi {
  final ApiClient _apiClient = ApiClient();

  /// ゲームを開始
  Future<StartGameResponse> startGame(AiLevel level) async {
    final response = await _apiClient.dio.post(
      '/api/game/start',
      data: {'aiLevel': level.value},
    );
    return StartGameResponse.fromJson(response.data);
  }

  /// 単語を送信
  Future<SubmitWordResponse> submitWord(String sessionId, String word) async {
    final response = await _apiClient.dio.post(
      '/api/game/$sessionId/submit',
      data: {'word': word},
    );
    return SubmitWordResponse.fromJson(response.data);
  }

  /// ゲーム状態を取得
  Future<GameSession> getGameState(String sessionId) async {
    final response = await _apiClient.dio.get('/api/game/$sessionId');
    return GameSession.fromJson(response.data['session']);
  }

  /// 制限時間をチェック
  Future<CheckTimeResponse> checkTime(String sessionId) async {
    final response = await _apiClient.dio.get('/api/game/$sessionId/check-time');
    return CheckTimeResponse.fromJson(response.data);
  }
}


