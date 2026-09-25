import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'platform_client.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode, this.code]);
  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => message;
}

final apiClient = ApiClient();

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? createHttpClient();
  static const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:4000/api');
  final http.Client _client;
  final authState = ValueNotifier(false);
  String? _accessToken;

  bool get isAuthenticated => _accessToken != null;

  Future<Map<String, dynamic>> signUp(Map<String, dynamic> input) => _send('POST', '/auth/register', body: input);
  Future<Map<String, dynamic>> signIn(String email, String password) => _send('POST', '/auth/login', body: {'email': email, 'password': password});
  Future<Map<String, dynamic>> verifyEmail(String challengeId, String code) => _session('/auth/verify-email', challengeId, code);
  Future<Map<String, dynamic>> verifyLogin(String challengeId, String code) => _session('/auth/verify-login', challengeId, code);
  Future<Map<String, dynamic>> forgotPassword(String email) => _send('POST', '/auth/forgot-password', body: {'email': email});
  Future<Map<String, dynamic>> resetPassword(String challengeId, String code, String password) => _send('POST', '/auth/reset-password', body: {'challengeId': challengeId, 'code': code, 'newPassword': password});
  Future<Map<String, dynamic>> dashboard() => _send('GET', '/dashboard', authenticated: true);

  Future<void> restoreSession() async {
    try { _acceptSession(await _send('POST', '/auth/refresh')); } catch (_) { clearSession(); }
  }

  Future<void> logout() async {
    try { await _send('POST', '/auth/logout'); } finally { clearSession(); }
  }

  Future<Map<String, dynamic>> _session(String path, String challengeId, String code) async {
    final result = await _send('POST', path, body: {'challengeId': challengeId, 'code': code});
    _acceptSession(result);
    return result;
  }

  void _acceptSession(Map<String, dynamic> result) {
    _accessToken = result['accessToken'] as String?;
    authState.value = _accessToken != null;
  }

  void clearSession() { _accessToken = null; authState.value = false; }

  Future<Map<String, dynamic>> _send(String method, String path, {Map<String, dynamic>? body, bool authenticated = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated && _accessToken != null) headers['Authorization'] = 'Bearer $_accessToken';
    final request = http.Request(method, Uri.parse('$baseUrl$path'))..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final rawMessage = decoded['message'];
      throw ApiException(rawMessage is List ? rawMessage.join(', ') : rawMessage?.toString() ?? 'Request failed', response.statusCode, decoded['code']?.toString());
    }
    return decoded;
  }
}
