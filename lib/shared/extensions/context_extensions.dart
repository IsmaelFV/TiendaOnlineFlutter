import 'package:flutter/material.dart';

/// Extensiones útiles sobre BuildContext
extension ContextExtensions on BuildContext {
  /// Acceso rápido al tema
  ThemeData get theme => Theme.of(this);

  /// Acceso rápido al color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Acceso rápido al text theme
  TextTheme get textTheme => theme.textTheme;

  /// Acceso rápido a MediaQuery
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Ancho de pantalla
  double get screenWidth => mediaQuery.size.width;

  /// Alto de pantalla
  double get screenHeight => mediaQuery.size.height;

  /// Padding seguro (notch, barra de estado)
  EdgeInsets get safePadding => mediaQuery.padding;

  /// ¿Es pantalla pequeña? (< 360dp)
  bool get isSmallScreen => screenWidth < 360;

  /// ¿Es tablet? (> 600dp)
  bool get isTablet => screenWidth > 600;

  /// Mostrar SnackBar rápido
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  /// Mostrar SnackBar de error
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: colorScheme.error);
  }

  /// Mostrar SnackBar de éxito
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: const Color(0xFF22C55E));
  }
}
