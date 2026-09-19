import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'media_url_resolver.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode, this.errors});
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;
}

String apiFailureMessage(Object error, String fallback) {
  if (error is ApiFailure) return error.message;
  if (error is DioException && error.error is ApiFailure) {
    return (error.error! as ApiFailure).message;
  }
  return fallback;
}

class ApiClient {
  ApiClient({String? baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? _configuredBaseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          o.extra['accountRevision'] = accountRevision.value;
          final token = await _storage.read(key: 'access_token');
          if (token != null) o.headers['Authorization'] = 'Bearer $token';
          h.next(o);
        },
        onError: (e, h) async {
          if (e.requestOptions.extra['accountRevision'] != accountRevision.value) {
            h.next(_normalize(e));
            return;
          }
          if (e.requestOptions.extra['noRefresh'] == true ||
              e.requestOptions.path.startsWith('/auth/')) {
            h.next(_normalize(e));
            return;
          }
          if (e.response?.statusCode != 401 ||
              e.requestOptions.extra['retried'] == true) {
            h.next(_normalize(e));
            return;
          }
          try {
            await _refreshOnce();
            final token = await _storage.read(key: 'access_token');
            final request = e.requestOptions..extra['retried'] = true;
            if (token != null) {
              request.headers['Authorization'] = 'Bearer $token';
            }
            h.resolve(await dio.fetch(request));
          } catch (_) {
            if (e.requestOptions.extra['accountRevision'] == accountRevision.value) {
              await clearSession(expired: true);
            }
            h.next(_normalize(e));
          }
        },
      ),
    );
  }
  final Dio dio;
  final _storage = const FlutterSecureStorage();
  final sessionExpired = ValueNotifier<bool>(false);
  final accountRevision = ValueNotifier<int>(0);
  String? _account;
  bool get isAuthenticated => _account != null;
  bool lastRestoreWasNetworkFailure = false;
  Completer<void>? _refreshing;
  static const _environmentUrl = String.fromEnvironment('API_URL');
  static String get _configuredBaseUrl => _environmentUrl.isNotEmpty
      ? _environmentUrl
      : kIsWeb
      ? 'http://localhost:5199/api/v1'
      : 'http://10.0.2.2:5199/api/v1';
  String mediaUrl(String? value) =>
      MediaUrlResolver.resolve(value, apiBaseUrl: dio.options.baseUrl);
  Future<void> saveSession(Map<String, dynamic> data) async {
    await _storage.write(
      key: 'access_token',
      value: data['accessToken'] as String,
    );
    await _storage.write(
      key: 'refresh_token',
      value: data['refreshToken'] as String,
    );
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(
      (data['accessToken'] as String).split('.')[1],
    )))) as Map<String, dynamic>;
    final account = '${payload['sub']}:${payload['session_id']}';
    if (_account != account) {
      _account = account;
      accountRevision.value++;
    }
    sessionExpired.value = false;
  }

  Future<void> clearSession({bool expired = false}) async {
    await Future.wait([
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'refresh_token'),
    ]);
    _account = null;
    accountRevision.value++;
    sessionExpired.value = expired;
  }

  /// Revokes the current server session before removing local credentials.
  /// Returns false when revocation could not be confirmed; credentials are
  /// still cleared so a temporary network failure cannot trap the user.
  Future<bool> logout() async {
    var revoked = false;
    try {
      await dio.post(
        '/auth/logout',
        options: Options(extra: {'noRefresh': true}),
      );
      revoked = true;
    } catch (_) {
      revoked = false;
    } finally {
      await clearSession();
    }
    return revoked;
  }

  Future<bool> hasSession() async =>
      (await _storage.read(key: 'refresh_token')) != null;

  Future<Set<String>> currentPermissions() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return const {};
    try {
      final parts = token.split('.');
      if (parts.length != 3) return const {};
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final raw = payload['permission'];
      if (raw is List) return raw.map((x) => x.toString()).toSet();
      if (raw is String && raw.isNotEmpty) return {raw};
    } catch (_) {
      return const {};
    }
    return const {};
  }

  Future<bool> restoreSession() async {
    lastRestoreWasNetworkFailure = false;
    if (!await hasSession()) return false;
    try {
      await _refreshOnce();
      return true;
    } catch (error) {
      lastRestoreWasNetworkFailure =
          error is DioException && error.response == null;
      await clearSession();
      return false;
    }
  }

  Future<void> _refreshOnce() {
    if (_refreshing != null) return _refreshing!.future;
    final completer = Completer<void>();
    _refreshing = completer;
    final generation = accountRevision.value;
    () async {
      final clean = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
      ));
      try {
        final refresh = await _storage.read(key: 'refresh_token');
        if (refresh == null) throw const ApiFailure('Session expired');
        final response = await clean.post('/auth/refresh',
          data: {'refreshToken': refresh, 'device': 'Flutter'});
        if (generation != accountRevision.value) {
          throw const ApiFailure('Account changed');
        }
        await saveSession(response.data as Map<String, dynamic>);
        completer.complete();
      } catch (error, stack) {
        completer.completeError(error, stack);
      } finally {
        clean.close();
        _refreshing = null;
      }
    }();
    return completer.future;
  }

  DioException _normalize(DioException e) {
    final data = e.response?.data;
    final message = data is Map<String, dynamic>
        ? (data['title'] ?? data['message'] ?? 'Request failed').toString()
        : e.type == DioExceptionType.connectionTimeout
        ? 'Connection timed out'
        : 'Unable to complete the request';
    return e.copyWith(
      error: ApiFailure(
        message,
        statusCode: e.response?.statusCode,
        errors: data is Map<String, dynamic> ? data : null,
      ),
    );
  }
}

final apiClient = ApiClient();
