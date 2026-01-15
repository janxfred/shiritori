import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class EmailStatus {
  EmailStatus({
    required this.email,
    required this.linkedAt,
    required this.rewardCoins,
    required this.rewarded,
  });

  final String? email;
  final DateTime? linkedAt;
  final int rewardCoins;
  final bool rewarded;

  factory EmailStatus.fromJson(Map<String, dynamic> json) {
    return EmailStatus(
      email: json['email'] as String?,
      linkedAt: json['linkedAt'] != null
          ? DateTime.parse(json['linkedAt'] as String)
          : null,
      rewardCoins: (json['rewardCoins'] as num).toInt(),
      rewarded: json['rewarded'] as bool,
    );
  }
}

class SetEmailResult {
  SetEmailResult({
    required this.email,
    required this.linkedAt,
    required this.coins,
    required this.rewarded,
  });

  final String email;
  final DateTime linkedAt;
  final int coins;
  final bool rewarded;

  factory SetEmailResult.fromJson(Map<String, dynamic> json) {
    return SetEmailResult(
      email: json['email'] as String,
      linkedAt: DateTime.parse(json['linkedAt'] as String),
      coins: (json['coins'] as num).toInt(),
      rewarded: json['rewarded'] as bool,
    );
  }
}

class UnlinkEmailResult {
  UnlinkEmailResult({
    required this.email,
    required this.linkedAt,
    required this.rewardCoins,
    required this.rewarded,
  });

  final String? email;
  final DateTime? linkedAt;
  final int rewardCoins;
  final bool rewarded;

  factory UnlinkEmailResult.fromJson(Map<String, dynamic> json) {
    return UnlinkEmailResult(
      email: json['email'] as String?,
      linkedAt: json['linkedAt'] != null
          ? DateTime.parse(json['linkedAt'] as String)
          : null,
      rewardCoins: (json['rewardCoins'] as num).toInt(),
      rewarded: json['rewarded'] as bool,
    );
  }
}

class AccountApi {
  AccountApi({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<EmailStatus> getEmailStatus({required String token}) async {
    final res = await _dio.get(
      '/api/account/email',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return EmailStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SetEmailResult> setEmail({required String token, required String email}) async {
    final res = await _dio.post(
      '/api/account/email',
      data: {'email': email},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return SetEmailResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UnlinkEmailResult> unlinkEmail({required String token}) async {
    final res = await _dio.delete(
      '/api/account/email',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return UnlinkEmailResult.fromJson(res.data as Map<String, dynamic>);
  }
}
