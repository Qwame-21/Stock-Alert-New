import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final dynamic details;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;
}

class ApiResponse<T> {
  final T data;
  final Map<String, dynamic> meta;

  const ApiResponse(this.data, this.meta);
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  final http.Client _http = http.Client();

  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) {
    return _send('GET', path, query: query);
  }

  Future<ApiResponse<dynamic>> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<ApiResponse<dynamic>> patch(String path, {Object? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<ApiResponse<dynamic>> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<ApiResponse<dynamic>> delete(String path, {Object? body}) {
    return _send('DELETE', path, body: body);
  }

  Future<ApiResponse<dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final requestId = const Uuid().v4();
    final stopwatch = Stopwatch()..start();
    var uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query != null) {
      uri = uri.replace(queryParameters: query);
    }

    final headers = <String, String>{
      'accept': 'application/json',
      'x-request-id': requestId,
      if (body != null) 'content-type': 'application/json',
    };
    if (authenticated) {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw const ApiException(
          statusCode: 401,
          code: 'UNAUTHENTICATED',
          message: 'Please log in again.',
        );
      }
      headers['authorization'] = 'Bearer $token';
    }

    final encodedBody = body == null ? null : jsonEncode(body);
    _logApiEvent('flutter_api_request', {
      'requestId': requestId,
      'method': method,
      'url': uri.toString(),
      'body': redactApiLogValue(body),
    });

    try {
      late http.Response response;
      switch (method) {
        case 'GET':
          response = await _http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
        case 'POST':
          response = await _http
              .post(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 30));
        case 'PATCH':
          response = await _http
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 30));
        case 'PUT':
          response = await _http
              .put(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 30));
        case 'DELETE':
          response = await _http
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(const Duration(seconds: 30));
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      _logApiEvent('flutter_api_response', {
        'requestId': requestId,
        'method': method,
        'url': uri.toString(),
        'status': response.statusCode,
        'durationMs': stopwatch.elapsedMilliseconds,
        'body': redactApiLogValue(decoded),
      });

      final error = decoded['error'] as Map<String, dynamic>?;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          error != null) {
        throw ApiException(
          statusCode: response.statusCode,
          code: error?['code'] as String? ?? 'HTTP_ERROR',
          message: error?['message'] as String? ?? 'Request failed.',
          details: error?['details'],
        );
      }

      return ApiResponse(
        decoded['data'],
        Map<String, dynamic>.from(decoded['meta'] as Map? ?? const {}),
      );
    } catch (error) {
      if (error is! ApiException) {
        _logApiEvent('flutter_api_failure', {
          'requestId': requestId,
          'method': method,
          'url': uri.toString(),
          'durationMs': stopwatch.elapsedMilliseconds,
          'errorType': error.runtimeType.toString(),
          'error': error.toString(),
        });
      }
      rethrow;
    }
  }
}

const _sensitiveApiLogKeys = {
  'authorization',
  'password',
  'accessToken',
  'refreshToken',
  'token',
  'qrToken',
  'qr_token',
  'documentPath',
  'document_path',
  'knownAllergies',
  'known_allergies',
  'chronicConditions',
  'chronic_conditions',
  'currentMedication',
  'current_medication',
  'emergencyContactName',
  'emergencyContactPhone',
  'emergencyContactEmail',
  'contentBase64',
};

dynamic redactApiLogValue(dynamic value) {
  if (value is List) {
    return value.map(redactApiLogValue).toList();
  }
  if (value is Map) {
    return value.map(
      (key, nested) => MapEntry(
        key,
        _sensitiveApiLogKeys.contains(key)
            ? '[REDACTED]'
            : redactApiLogValue(nested),
      ),
    );
  }
  return value;
}

void _logApiEvent(String event, Map<String, dynamic> fields) {
  if (!kDebugMode) return;
  debugPrint(jsonEncode({
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'event': event,
    ...fields,
  }));
}
