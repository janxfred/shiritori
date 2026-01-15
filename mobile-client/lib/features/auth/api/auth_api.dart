import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/auth_session.dart';

class AuthApi {
  AuthApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<({String token, AuthUser user})> signUp({
    required String name,
    required String password,
  }) async {
    final res = await _dio.post('/api/auth/signup', data: {
      'name': name,
      'password': password,
    });

    final data = res.data as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, AuthUser user})> login({
    required String userId,
    required String password,
  }) async {
    final res = await _dio.post('/api/auth/login', data: {
      'userId': userId,
      'password': password,
    });

    final data = res.data as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
