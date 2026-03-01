import 'package:fpdart/fpdart.dart';
import '../../../../shared/exceptions/failure.dart';
import '../../data/models/user_model.dart';

/// Contrato del repositorio de autenticación
abstract class AuthRepository {
  /// Iniciar sesión con email y contraseña
  Future<Either<Failure, UserModel>> signInWithEmail(
    String email,
    String password,
  );

  /// Registrar nuevo usuario
  Future<Either<Failure, UserModel>> signUp(
    String email,
    String password,
    String fullName,
  );

  /// Iniciar sesión con Google OAuth
  Future<Either<Failure, UserModel>> signInWithGoogle();

  /// Cerrar sesión
  Future<Either<Failure, Unit>> signOut();

  /// Obtener usuario actual
  Future<Either<Failure, UserModel?>> getCurrentUser();

  /// Verificar si es administrador
  Future<Either<Failure, bool>> isAdmin(String userId);

  /// Cambiar contraseña
  Future<Either<Failure, Unit>> changePassword(
    String currentPassword,
    String newPassword,
  );

  /// Stream de cambios de autenticación
  Stream<UserModel?> authStateChanges();
}
