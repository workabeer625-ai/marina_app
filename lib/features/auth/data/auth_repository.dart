import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class UserSession {
  const UserSession({
    required this.id,
    required this.deviceName,
    required this.lastSeenUtc,
    this.ipAddress,
  });
  final String id, deviceName;
  final String? ipAddress;
  final DateTime lastSeenUtc;

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    id: json['id'].toString(),
    deviceName: (json['deviceName'] ?? 'Unknown device').toString(),
    ipAddress: json['ipAddress']?.toString(),
    lastSeenUtc:
        DateTime.tryParse((json['lastSeenUtc'] ?? '').toString()) ??
        DateTime.now(),
  );
}

class AuthRepository {
  const AuthRepository(this.client);
  final ApiClient client;

  Future<Map<String, dynamic>> login(String email, String password) async =>
      (await client.dio.post(
            '/auth/login',
            data: {
              'email': email.trim(),
              'password': password,
              'device': 'MARINA Flutter',
            },
          )).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> completeMfa(
    String email,
    String password,
    String code,
  ) async =>
      (await client.dio.post(
            '/auth/mfa-login',
            data: {
              'email': email.trim(),
              'password': password,
              'code': code.trim(),
              'device': 'MARINA Flutter',
            },
          )).data
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async =>
      (await client.dio.post(
            '/auth/register',
            data: {
              'displayName': name.trim(),
              'email': email.trim(),
              'password': password,
            },
          )).data
          as Map<String, dynamic>;

  Future<void> forgotPassword(String email) =>
      client.dio.post('/auth/forgot-password', data: {'email': email.trim()});

  Future<void> resetPassword(String email, String token, String password) =>
      client.dio.post(
        '/auth/reset-password',
        data: {
          'email': email.trim(),
          'token': token.trim(),
          'newPassword': password,
        },
      );

  Future<void> verifyEmail(String email, String token) => client.dio.post(
    '/auth/verify-email',
    data: {'email': email.trim(), 'token': token.trim()},
  );

  Future<void> resendVerification(String email) =>
      client.dio.post('/auth/resend-verification', data: {'email': email.trim()});

  Future<void> changePassword(String currentPassword, String newPassword) =>
      client.dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

  Future<List<UserSession>> sessions() async =>
      ((await client.dio.get('/auth/sessions')).data as List)
          .map((x) => UserSession.fromJson(x as Map<String, dynamic>))
          .toList();

  Future<void> revokeSession(String id) =>
      client.dio.delete('/auth/sessions/$id');
}

final authRepositoryProvider = Provider((_) => AuthRepository(apiClient));
final userSessionsProvider = FutureProvider<List<UserSession>>(
  (ref) => ref.watch(authRepositoryProvider).sessions(),
);
