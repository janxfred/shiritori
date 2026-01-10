import 'dart:io';
import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;

  static String get _baseUrl {
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
      onError: (error, handler) {
        print('[API Error] ${error.requestOptions.method} ${error.requestOptions.uri}');
        print('[API Error] ${error.type}: ${error.message}');
        if (error.response != null) {
          print('[API Error] Status: ${error.response?.statusCode}');
          print('[API Error] Body: ${error.response?.data}');
        }
        if (error.stackTrace != null) {
          print('[API Error] Stack: ${error.stackTrace}');
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }
}
