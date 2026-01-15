import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api/auth_api.dart';
import '../models/auth_session.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi());

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  final api = ref.read(authApiProvider);
  return AuthController(api);
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._api) : super(const AsyncValue.data(null));

  final AuthApi _api;

  String _friendlyApiErrorMessage(DioException e) {
    final data = e.response?.data;
    final serverMessage = (data is Map<String, dynamic>) ? data['message'] : null;
    final message = (serverMessage is String && serverMessage.trim().isNotEmpty)
        ? serverMessage.trim()
        : (e.message ?? '通信に失敗しました');

    // Back-end validation message -> Japanese hint (best-effort)
    if (message.contains('body/password') && message.contains('Too small')) {
      return '合言葉は6文字以上にしてください';
    }
    if (message.contains('body/name') && message.contains('Too small')) {
      return 'プレイヤー名を入力してください';
    }
    if (message.contains('body/name') && message.contains('Too big')) {
      return 'プレイヤー名が長すぎます';
    }

    return message;
  }

  Future<void> signUp({required String name, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final result = await _api.signUp(name: name, password: password);
        return AuthSession(token: result.token, user: result.user);
      } on DioException catch (e) {
        throw StateError(_friendlyApiErrorMessage(e));
      }
    });
  }

  Future<void> login({required String userId, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final result = await _api.login(userId: userId, password: password);
        return AuthSession(token: result.token, user: result.user);
      } on DioException catch (e) {
        throw StateError(_friendlyApiErrorMessage(e));
      }
    });
  }

  void logout() {
    state = const AsyncValue.data(null);
  }

  void updateUser(AuthUser user) {
    final session = state.value;
    if (session == null) return;
    state = AsyncValue.data(session.copyWith(user: user));
  }
}
