import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/config.dart';
import 'storage.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class APIClient {
  static final APIClient shared = APIClient._internal();
  APIClient._internal();

  final String _baseURL = AppConfig.apiBaseURL;

  Future<dynamic> request({
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseURL$endpoint');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // Load session token
    final token = await SessionManager.shared.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }

    http.Response response;
    try {
      final bodyStr = body != null ? jsonEncode(body) : null;
      
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(uri, headers: headers, body: bodyStr);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: bodyStr);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: bodyStr);
          break;
        case 'GET':
        default:
          response = await http.get(uri, headers: headers);
          break;
      }
    } catch (e) {
      throw NetworkException("Error de conexión con el servidor. Verifica tu conexión a internet.");
    }

    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        if (response.body.isEmpty) return {};
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw NetworkException("Error al procesar la respuesta del servidor.");
        }
      case 401:
        await SessionManager.shared.logout();
        throw NetworkException("Sesión expirada. Por favor inicie sesión nuevamente.", statusCode: 401);
      default:
        throw NetworkException("Error en el servidor. Código: ${response.statusCode}", statusCode: response.statusCode);
    }
  }
}
