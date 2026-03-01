import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// StreamProvider de ofertas flash desde site_settings (Realtime).
/// Escucha cambios en la tabla site_settings.
/// Maneja errores de red retornando false como valor por defecto.
final flashOffersEnabledProvider = StreamProvider<bool>((ref) {
  try {
    final stream = Supabase.instance.client
        .from('site_settings')
        .stream(primaryKey: ['key'])
        .eq('key', 'flash_offers_enabled')
        .map((rows) {
          if (rows.isEmpty) return false;
          final value = rows.first['value'];
          if (value is bool) return value;
          if (value is String) return value.toLowerCase() == 'true';
          return false;
        })
        .handleError((error) {
          // En caso de error de red, emitir false silenciosamente
          return false;
        });

    return stream;
  } catch (e) {
    // Si la creación del stream falla (ej: sin conexión), devolver false
    return Stream.value(false);
  }
});

/// Provider para la configuración general del sitio
final siteSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('site_settings')
        .select();

    final Map<String, dynamic> settings = {};
    for (final row in response as List) {
      settings[row['key'] as String] = row['value'];
    }
    return settings;
  } catch (e) {
    // Si falla la red, devolver settings vacíos
    return {};
  }
});
