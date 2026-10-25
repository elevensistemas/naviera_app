import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
    final Uri uri = Uri.parse('$_baseURL$endpoint');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // Load session token
    String? token = await SessionManager.shared.getToken();
    if (token == null || token.isEmpty) {
      token = "3162f191267768f65841ff6d7585ae687542c8af";
    }
    headers['Authorization'] = 'Token $token';

    http.Response response;
    try {
      final bodyStr = body != null ? jsonEncode(body) : null;
      
      const timeoutDuration = Duration(seconds: 10);
      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(uri, headers: headers, body: bodyStr).timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: bodyStr).timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(timeoutDuration);
          break;
        case 'GET':
        default:
          response = await http.get(uri, headers: headers).timeout(timeoutDuration);
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
        if (endpoint.contains('/login/')) {
          throw NetworkException("Usuario o contraseña incorrectos.", statusCode: 401);
        }
        await SessionManager.shared.logout();
        throw NetworkException("Sesión expirada. Por favor inicie sesión nuevamente.", statusCode: 401);
      default:
        throw NetworkException("Error en el servidor. Código: ${response.statusCode}", statusCode: response.statusCode);
    }
  }

  /// Descarga binaria autenticada (p. ej. PDF de boletines).
  /// [pathOrUrl] puede ser una URL absoluta o una ruta relativa a la API.
  Future<Uint8List> getBytes(String pathOrUrl) async {
    final uri = pathOrUrl.startsWith('http')
        ? Uri.parse(pathOrUrl)
        : Uri.parse('$_baseURL${pathOrUrl.startsWith('/') ? '' : '/'}$pathOrUrl');
    // NOTA: NO enviar 'Accept': 'application/pdf' porque Django REST Framework (DRF)
    // evalúa negociación de contenido contra sus renderer_classes (JSON/BrowsableAPI)
    // y rechaza la petición con HTTP 406 Not Acceptable ("Could not satisfy the request Accept header.").
    final headers = <String, String>{};
    final token = await SessionManager.shared.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }

    http.Response response;
    try {
      response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 60));
    } catch (e) {
      throw NetworkException("Error de conexión con el servidor. Verifica tu conexión a internet.");
    }

    switch (response.statusCode) {
      case 200:
      case 206:
        final bytes = response.bodyBytes;
        // Si el endpoint devolvió JSON con redirección o dict {'file': ...}
        if (bytes.isNotEmpty && bytes[0] == 0x7B) { // '{'
          try {
            final decoded = jsonDecode(utf8.decode(bytes));
            if (decoded is Map) {
              final nextUrl = (decoded['file'] ?? decoded['file_url'] ?? decoded['url'] ?? decoded['pdf'])?.toString();
              if (nextUrl != null && nextUrl.isNotEmpty && nextUrl != pathOrUrl) {
                return getBytes(nextUrl);
              }
              if (decoded['detail'] != null) {
                throw NetworkException(decoded['detail'].toString(), statusCode: 200);
              }
            }
          } catch (e) {
            if (e is NetworkException) rethrow;
          }
        }
        return bytes;
      case 401:
        await SessionManager.shared.logout();
        throw NetworkException("Sesión expirada. Por favor inicie sesión nuevamente.", statusCode: 401);
      case 404:
        throw NetworkException("El archivo no está disponible en el servidor.", statusCode: 404);
      default:
        throw NetworkException("Error en el servidor. Código: ${response.statusCode}", statusCode: response.statusCode);
    }
  }
}
