import 'package:flutter/material.dart';

/// Sistema de sombras para tema oscuro premium
abstract class AppShadows {
  static const xs = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x4D000000)),
  ];

  static const sm = [
    BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x66000000)),
  ];

  static const md = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x80000000)),
  ];

  static const lg = [
    BoxShadow(offset: Offset(0, 12), blurRadius: 32, color: Color(0x99000000)),
  ];

  static const xl = [
    BoxShadow(offset: Offset(0, 20), blurRadius: 48, color: Color(0xB3000000)),
  ];

  /// Brillo dorado (para botones CTA y cards destacadas)
  static const glowGold = [
    BoxShadow(blurRadius: 40, color: Color(0x40D4AF37)),
    BoxShadow(blurRadius: 80, color: Color(0x1AD4AF37)),
  ];

  /// Brillo esmeralda (para badges de éxito)
  static const glowEmerald = [
    BoxShadow(blurRadius: 40, color: Color(0x3310B981)),
    BoxShadow(blurRadius: 80, color: Color(0x1410B981)),
  ];

  /// Sombra de card en hover (efecto elevación)
  static const cardHover = [
    BoxShadow(offset: Offset(0, 8), blurRadius: 32, color: Color(0x99000000)),
  ];
}
