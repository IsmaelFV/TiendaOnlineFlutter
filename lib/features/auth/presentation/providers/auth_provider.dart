import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

/// Provider del repositorio de autenticación
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(Supabase.instance.client);
});

/// Provider del estado del usuario actual
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Provider del usuario actual (FutureProvider)
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final result = await repo.getCurrentUser();
  return result.fold((failure) => null, (user) => user);
});

/// Provider para verificar si es admin
final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return false;

  final repo = ref.watch(authRepositoryProvider);
  final result = await repo.isAdmin(user.id);
  return result.fold((_) => false, (isAdmin) => isAdmin);
});

/// Notifier para acciones de autenticación
final authActionsProvider =
    NotifierProvider<AuthActionsNotifier, AsyncValue<void>>(
      AuthActionsNotifier.new,
    );

class AuthActionsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<UserModel?> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signInWithEmail(email, password);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return null;
      },
      (user) {
        state = const AsyncValue.data(null);
        ref.invalidate(currentUserProvider);
        return user;
      },
    );
  }

  Future<UserModel?> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signUp(email, password, fullName);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return null;
      },
      (user) {
        state = const AsyncValue.data(null);
        return user;
      },
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncValue.data(null);
    ref.invalidate(currentUserProvider);
    // Forzar reconstrucción del carrito para limpiar datos del usuario anterior
    ref.invalidate(cartProvider);
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.changePassword(currentPassword, newPassword);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}
