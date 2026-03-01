import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/constants/environment.dart';
import 'config/router/app_router.dart';
import 'config/theme/app_theme.dart';

void main() {
  runZonedGuarded(
    () async {
      // 1. Binding (dentro de la misma zone que runApp)
      WidgetsFlutterBinding.ensureInitialized();

      // 2. Orientación portrait únicamente
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // 3. Status bar transparente
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );

      // 4. Hive (caché local para carrito)
      await Hive.initFlutter();

      // 5. Supabase (puede fallar si no hay red; la app sigue)
      try {
        await Supabase.initialize(
          url: AppConstants.supabaseUrl,
          anonKey: AppConstants.supabaseAnonKey,
        );
      } catch (e) {
        debugPrint('[Fashion Store] Supabase init error: $e');
      }

      // 6. Stripe
      Stripe.publishableKey = AppConstants.stripePublishableKey;

      // 7. Google Fonts — permitir descarga de fuentes
      GoogleFonts.config.allowRuntimeFetching = true;

      // 8. Inicializar datos de locale para DateFormat en español
      await initializeDateFormatting('es_ES', null);

      // 9. Error global — para que errores no manejados no pinten pantalla roja
      ErrorWidget.builder = (FlutterErrorDetails details) {
        debugPrint('[ErrorWidget] ${details.exceptionAsString()}');
        debugPrint('[ErrorWidget STACK] ${details.stack}');
        return Container(
          color: const Color(0xFF0A0A0A),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Algo salió mal.\nInténtalo de nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: GoogleFonts.lato().fontFamily,
                ),
              ),
            ],
          ),
        );
      };

      // 9. Capturar errores no manejados de Futures/Streams
      FlutterError.onError = (details) {
        debugPrint('[Flutter Error] ${details.exceptionAsString()}');
      };

      // 10. Lanzar app
      runApp(const ProviderScope(child: FashionStoreApp()));
    },
    (error, stackTrace) {
      debugPrint('[Unhandled] $error');
    },
  );
}

/// Widget raíz de la aplicación Fashion Store
class FashionStoreApp extends ConsumerWidget {
  const FashionStoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Fashion Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        // Deshabilitar escalado de texto del sistema
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
