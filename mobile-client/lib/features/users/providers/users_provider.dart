import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../../../core/api/api_client.dart';

final usersProvider = FutureProvider<UserListResponse>((ref) async {
  final response = await ApiClient().dio.get('/api/users');
  return UserListResponse.fromJson(response.data);
});

final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final response = await ApiClient().dio.get('/api/users/$userId');
  return User.fromJson(response.data);
});
