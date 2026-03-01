import 'package:freezed_annotation/freezed_annotation.dart';
part 'failure.freezed.dart';

/// Clase base de errores con Freezed para manejo funcional con Either
@freezed
class Failure with _$Failure {
  /// Error de red (sin conexión, timeout, servidor caído)
  const factory Failure.network({required String message, int? statusCode}) =
      NetworkFailure;

  /// Error de autenticación (token expirado, no autorizado)
  const factory Failure.auth({required String message}) = AuthFailure;

  /// Error de lógica de negocio (stock insuficiente, etc.)
  const factory Failure.business({required String message}) = BusinessFailure;

  /// Error de caché/local (Hive, SharedPreferences)
  const factory Failure.cache({required String message}) = CacheFailure;

  /// Error desconocido
  const factory Failure.unknown({required String message, Object? error}) =
      UnknownFailure;

  const Failure._();

  /// Mensaje legible para el usuario
  String get userMessage => when(
    network: (msg, _) => msg,
    auth: (msg) => msg,
    business: (msg) => msg,
    cache: (msg) => msg,
    unknown: (msg, _) => msg,
  );
}
