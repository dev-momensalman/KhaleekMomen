import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  NetworkException({required this.message, this.statusCode});
  @override
  String toString() => 'NetworkException: $message (Status: $statusCode)';
}

class HttpService {
  final String baseUrl;
  final Duration timeout;

  HttpService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
  });

  Map<String, String> _defaultHeaders() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$path');
    final mergedHeaders = {..._defaultHeaders(), ...?headers};
    developer.log('GET request to: $url', name: 'HttpService');
    try {
      final response = await http
          .get(url, headers: mergedHeaders)
          .timeout(timeout);
      return _processResponse(response);
    } on TimeoutException {
      developer.log('GET timeout: $url', name: 'HttpService');
      throw NetworkException(
        message: 'Connection timed out. Please check your internet connection.',
      );
    } on http.ClientException catch (e) {
      developer.log('GET client exception: ${e.message}', name: 'HttpService');
      throw NetworkException(
        message:
            'Failed to connect to the server. Please check your connection.',
      );
    } catch (e) {
      developer.log('GET unexpected error: $e', name: 'HttpService');
      throw NetworkException(message: 'An unexpected error occurred: $e');
    }
  }

  /// GET request to external full URL (not base URL)
  Future<dynamic> getExternal(
    String fullUrl, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(fullUrl).replace(queryParameters: queryParams);
      developer.log('GET External: $uri', name: 'HttpService');
      // ✅ استخدام http.get مباشرة بدل _client
      final response = await http
          .get(uri, headers: _defaultHeaders())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('HTTP ${response.statusCode}');
    } on TimeoutException {
      throw NetworkException(message: 'External request timed out.');
    } on http.ClientException catch (e) {
      throw NetworkException(message: 'External request failed: ${e.message}');
    } catch (e) {
      developer.log('getExternal error: $e', name: 'HttpService');
      rethrow;
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final mergedHeaders = {..._defaultHeaders(), ...?headers};
    final encodedBody = body != null ? jsonEncode(body) : null;
    developer.log('POST request to: $url', name: 'HttpService');
    try {
      final response = await http
          .post(url, headers: mergedHeaders, body: encodedBody)
          .timeout(timeout);
      return _processResponse(response);
    } on TimeoutException {
      developer.log('POST timeout: $url', name: 'HttpService');
      throw NetworkException(
        message: 'Connection timed out. Please check your internet connection.',
      );
    } on http.ClientException catch (e) {
      developer.log('POST client exception: ${e.message}', name: 'HttpService');
      throw NetworkException(message: 'Failed to connect to the server.');
    } catch (e) {
      developer.log('POST unexpected error: $e', name: 'HttpService');
      throw NetworkException(message: 'An unexpected error occurred: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    developer.log(
      'Response status: $statusCode for ${response.request?.url}',
      name: 'HttpService',
    );
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (statusCode == 401 || statusCode == 403) {
      throw NetworkException(
        message: 'Unauthorized access.',
        statusCode: statusCode,
      );
    } else if (statusCode >= 400 && statusCode < 500) {
      throw NetworkException(
        message: 'Client error occurred.',
        statusCode: statusCode,
      );
    } else {
      throw NetworkException(
        message: 'Server error. Please try again later.',
        statusCode: statusCode,
      );
    }
  }
}
