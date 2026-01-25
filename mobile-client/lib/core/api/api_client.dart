import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  static String get _baseUrl {
    String? fromEnv;
    try {
      fromEnv = dotenv.env['API_BASE_URL']?.trim();
    } catch (_) {
      // flutter_dotenv が未初期化（テスト等）でもフォールバックできるようにする
      fromEnv = null;
    }
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv;
    }

    // エミュレータからlocalhostへアクセスする場合:
    // Android: 10.0.2.2
    // iOS Simulator: localhost
    const port = '3002';
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$port';
    } else if (Platform.isIOS) {
      return 'http://localhost:$port';
    }
    return 'http://localhost:$port';
  }

  ApiClient._internal() {
    if (kDebugMode) {
      stderr.writeln('[API] baseUrl=$_baseUrl');
    }

    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // エラーログのみ出力するインターセプター
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // body無しリクエストなのに Content-Type: application/json が付くと、
        // Fastify 側で "Body cannot be empty when content-type is set to 'application/json'" になり得る。
        if (options.data == null) {
          options.headers.remove('Content-Type');
          options.headers.remove('content-type');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          final path = response.requestOptions.path;
          if (path == '/api/me') {
            final data = response.data;
            if (data is Map && data['user'] is Map) {
              final user = data['user'] as Map;
              final coins = user['coins'];
              final soulCount = user['soulCount'];
              stderr.writeln('[API] GET /api/me -> coins=$coins soulCount=$soulCount');
            } else {
              stderr.writeln('[API] GET /api/me -> (unexpected body)');
            }
          }

          if (path.contains('/api/pvp/') && (path.endsWith('/submit') || path.endsWith('/check-time'))) {
            stderr.writeln('[API] ${response.requestOptions.method} $path -> ${response.statusCode}');
          }
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          stderr.writeln('[API Error] ${error.requestOptions.method} ${error.requestOptions.uri}');
          stderr.writeln('[API Error] ${error.type}: ${error.message}');
          if (error.response != null) {
            stderr.writeln('[API Error] Status: ${error.response?.statusCode}');
            stderr.writeln('[API Error] Body: ${error.response?.data}');
          }
          stderr.writeln('[API Error] Stack: ${error.stackTrace}');
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  /// Bearer認証用のOptionsを生成
  static Options authorizedOptions({required String token}) {
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
