import 'package:flutter/material.dart';

/// Gradientes del tema Fashion Store
abstract class AppGradients {
  /// Gradiente dorado brillante (botones premium, CTA)
  static const gold = LinearGradient(
    begin: Alignment(-0.5, -0.5),
    end: Alignment(0.5, 0.5),
    colors: [Color(0xFFD4AF37), Color(0xFFF4E5AF), Color(0xFFD4AF37)],
  );

  /// Gradiente dorado sutil (fondos de cards destacadas)
  static const goldSubtle = LinearGradient(
    begin: Alignment(-0.5, -0.5),
    end: Alignment(0.5, 0.5),
    colors: [Color(0x1AD4AF37), Color(0x0DD4AF37)],
  );

  /// Gradiente esmeralda (acciones secundarias)
  static const emerald = LinearGradient(
    begin: Alignment(-0.5, -0.5),
    end: Alignment(0.5, 0.5),
    colors: [Color(0xFF10B981), Color(0xFF34D399), Color(0xFF10B981)],
  );

  /// Gradiente de superficie (fondo de secciones)
  static const surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A0A), Color(0xFF171717)],
  );

  /// Gradiente de card (cards con profundidad)
  static const cardGradient = LinearGradient(
    begin: Alignment(-0.3, -0.5),
    end: Alignment(0.3, 0.5),
    colors: [Color(0xFF262626), Color(0xFF1C1C1C)],
  );
}
