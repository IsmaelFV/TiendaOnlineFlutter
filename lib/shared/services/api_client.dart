import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/constants/environment.dart';

/// Cliente HTTP centralizado para comunicarse con el backend de Astro.
///
/// - Añade automáticamente `Authorization: Bearer <supabase_access_token>`
/// - Base URL configurable vía [AppConstants.backendBaseUrl]
/// - Manejo de errores HTTP centralizado
class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  static const _baseUrl = AppConstants.backendBaseUrl;

  /// Token de acceso de Supabase del usuario actual.
  String? get _accessToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  // ─── POST genérico ───
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final httpClient = HttpClient();

    try {
      final request = await httpClient.postUrl(url);
      request.headers.set('Content-Type', 'application/json');

      // Auth: Bearer token de Supabase
      final token = _accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $token');
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      Map<String, dynamic> data;
      try {
        data = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {
        data = {'raw': responseBody};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      // Error del backend
      final errorMsg = data['message'] ?? data['error'] ?? 'Error del servidor';
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMsg.toString(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ApiClient] Error en POST $path: $e');
      throw ApiException(statusCode: 0, message: 'Error de conexión: $e');
    } finally {
      httpClient.close();
    }
  }

  // ─── POST a Supabase Edge Function ───
  /// Llama a una Edge Function de Supabase por nombre.
  /// Añade automáticamente `apikey` y `Authorization: Bearer`.
  Future<Map<String, dynamic>> postFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('${AppConstants.supabaseFunctionsUrl}/$functionName');
    final httpClient = HttpClient();

    try {
      final request = await httpClient.postUrl(url);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('apikey', AppConstants.supabaseAnonKey);

      final token = _accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $token');
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      Map<String, dynamic> data;
      try {
        data = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {
        data = {'raw': responseBody};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      final errorMsg = data['message'] ?? data['error'] ?? 'Error del servidor';
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMsg.toString(),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ApiClient] Error en postFunction $functionName: $e');
      throw ApiException(statusCode: 0, message: 'Error de conexión: $e');
    } finally {
      httpClient.close();
    }
  }
}

/// Excepción personalizada para errores de la API.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
