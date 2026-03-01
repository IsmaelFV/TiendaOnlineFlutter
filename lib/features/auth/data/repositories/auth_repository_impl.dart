import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/exceptions/failure.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  AuthRepositoryImpl(this._client);

  @override
  Future<Either<Failure, UserModel>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return left(const Failure.auth(message: 'No se pudo iniciar sesión'));
      }

      final isAdminResult = await isAdmin(user.id);
      final adminStatus = isAdminResult.fold(
        (_) => false,
        (isAdmin) => isAdmin,
      );

      return right(
        UserModel(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String?,
          createdAt: user.createdAt,
          isAdmin: adminStatus,
        ),
      );
    } on AuthException catch (e) {
      return left(Failure.auth(message: _translateAuthError(e.message)));
    } on SocketException catch (_) {
      return left(
        const Failure.network(
          message: 'Sin conexión a internet. Comprueba tu red.',
        ),
      );
    } catch (e) {
      if (e.toString().contains('ClientException') ||
          e.toString().contains('SocketException')) {
        return left(
          const Failure.network(message: 'Error de conexión con el servidor.'),
        );
      }
      return left(Failure.unknown(message: 'Error inesperado', error: e));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      final user = response.user;
      if (user == null) {
        return left(const Failure.auth(message: 'No se pudo crear la cuenta'));
      }

      return right(
        UserModel(
          id: user.id,
          email: user.email ?? '',
          fullName: fullName,
          createdAt: user.createdAt,
        ),
      );
    } on AuthException catch (e) {
      return left(Failure.auth(message: _translateAuthError(e.message)));
    } on SocketException catch (_) {
      return left(
        const Failure.network(
          message: 'Sin conexión a internet. Comprueba tu red.',
        ),
      );
    } catch (e) {
      if (e.toString().contains('ClientException') ||
          e.toString().contains('SocketException')) {
        return left(
          const Failure.network(message: 'Error de conexión con el servidor.'),
        );
      }
      return left(Failure.unknown(message: 'Error inesperado', error: e));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.fashionstore.fashionstore://callback',
      );

      // El usuario se resuelve después del callback
      await Future.delayed(const Duration(seconds: 2));

      final user = _client.auth.currentUser;
      if (user == null) {
        return left(
          const Failure.auth(message: 'No se pudo iniciar sesión con Google'),
        );
      }

      return right(
        UserModel(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String?,
          avatarUrl: user.userMetadata?['avatar_url'] as String?,
          createdAt: user.createdAt,
        ),
      );
    } catch (e) {
      return left(Failure.unknown(message: 'Error con Google', error: e));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _client.auth.signOut();
      return right(unit);
    } catch (e) {
      return left(Failure.unknown(message: 'Error al cerrar sesión', error: e));
    }
  }

  @override
  Future<Either<Failure, UserModel?>> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return right(null);

      final isAdminResult = await isAdmin(user.id);
      final adminStatus = isAdminResult.fold(
        (_) => false,
        (isAdmin) => isAdmin,
      );

      return right(
        UserModel(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] as String?,
          avatarUrl: user.userMetadata?['avatar_url'] as String?,
          createdAt: user.createdAt,
          isAdmin: adminStatus,
        ),
      );
    } catch (e) {
      return left(Failure.unknown(message: 'Error inesperado', error: e));
    }
  }

  @override
  Future<Either<Failure, bool>> isAdmin(String userId) async {
    try {
      final result = await _client
          .from('admin_users')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return right(result != null);
    } catch (e) {
      return right(false);
    }
  }

  @override
  Future<Either<Failure, Unit>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final email = _client.auth.currentUser?.email;
      if (email == null) {
        return left(const Failure.auth(message: 'No hay sesión activa'));
      }

      // Verificar contraseña actual re-logueando
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // Actualizar contraseña
      await _client.auth.updateUser(UserAttributes(password: newPassword));

      return right(unit);
    } on AuthException catch (e) {
      return left(Failure.auth(message: _translateAuthError(e.message)));
    } on SocketException catch (_) {
      return left(
        const Failure.network(
          message: 'Sin conexión a internet. Comprueba tu red.',
        ),
      );
    } catch (e) {
      if (e.toString().contains('ClientException') ||
          e.toString().contains('SocketException')) {
        return left(
          const Failure.network(message: 'Error de conexión con el servidor.'),
        );
      }
      return left(
        Failure.unknown(message: 'Error al cambiar contraseña', error: e),
      );
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        createdAt: user.createdAt,
      );
    });
  }

  /// Traduce los mensajes de error de Supabase Auth al español
  String _translateAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('invalid login credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu email antes de iniciar sesión. Revisa tu bandeja de entrada.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'Este email ya está registrado. Intenta iniciar sesión.';
    }
    if (lower.contains('signup is disabled') ||
        lower.contains('signups not allowed')) {
      return 'El registro de nuevos usuarios está deshabilitado temporalmente.';
    }
    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
    }
    if (lower.contains('password') && lower.contains('weak')) {
      return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
    }
    if (lower.contains('email') && lower.contains('invalid')) {
      return 'El formato de email no es válido.';
    }
    if (lower.contains('session') && lower.contains('expired')) {
      return 'Tu sesión ha expirado. Inicia sesión de nuevo.';
    }
    if (lower.contains('unauthorized') || lower.contains('not authorized')) {
      return 'No tienes permiso para realizar esta acción.';
    }
    // Fallback: devolver mensaje original si no hay traducción
    return message;
  }
}
