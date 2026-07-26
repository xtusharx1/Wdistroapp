import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../state/app_state.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  Uri _uri(String path) => Uri.parse('$kBaseUrl$path');

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(kNgrokHeaders);
    if (AppState.instance.shop != null) {
      headers['x-shop-id'] = AppState.instance.shop!.id.toString();
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(_uri(path), headers: _headers);
    return _handle(response);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(_uri(path), headers: _headers);
    return _handle(response);
  }

  Map<String, dynamic> _handle(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded['message'] ?? 'Request failed';
    throw ApiException(message, statusCode: response.statusCode);
  }
}
