import 'package:flutter/material.dart';

/// Animaciones y curvas de timing
abstract class AppAnimations {
  // Duraciones estándar
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 400);
  static const slow = Duration(milliseconds: 600);

  // Curvas (equivalentes a los CSS timing functions)
  static const easeOutExpo = Cubic(0.16, 1, 0.3, 1);
  static const easeSmooth = Cubic(0.4, 0, 0.2, 1);
  static const easeBounce = Cubic(0.34, 1.56, 0.64, 1);
  static const easeElegant = Cubic(0.25, 0.46, 0.45, 0.94);
}
