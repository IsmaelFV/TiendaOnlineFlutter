import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio singleton de Supabase
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  static String? get accessToken => client.auth.currentSession?.accessToken;

  static bool get isAuthenticated => client.auth.currentSession != null;
}
