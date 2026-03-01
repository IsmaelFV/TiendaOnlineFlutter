import 'package:flutter/material.dart';

/// Paleta de colores completa de Fashion Store
/// Estética: "Minimalismo Sofisticado" - tema oscuro premium
abstract class AppColors {
  // ─── GRISES (Escala profesional con profundidad) ───
  static const gray50 = Color(0xFFFAFAFA);
  static const gray100 = Color(0xFFF5F5F5);
  static const gray200 = Color(0xFFE5E5E5);
  static const gray300 = Color(0xFFD4D4D4);
  static const gray400 = Color(0xFFA3A3A3);
  static const gray500 = Color(0xFF737373);
  static const gray600 = Color(0xFF525252);
  static const gray700 = Color(0xFF404040);
  static const gray800 = Color(0xFF262626);
  static const gray850 = Color(0xFF1C1C1C);
  static const gray900 = Color(0xFF171717);
  static const gray950 = Color(0xFF0A0A0A);

  // ─── BACKGROUNDS (Jerarquía de capas oscuras) ───
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF171717);
  static const surfaceElevated = Color(0xFF1C1C1C);
  static const card = Color(0xFF262626);
  static const cardHover = Color(0xFF2E2E2E);

  // ─── DORADO PREMIUM (Color principal de acento) ───
  static const gold50 = Color(0xFFFFFEF7);
  static const gold100 = Color(0xFFFFFBEB);
  static const gold200 = Color(0xFFFEF3C7);
  static const gold300 = Color(0xFFFDE68A);
  static const gold400 = Color(0xFFF4D467);
  static const gold500 = Color(0xFFD4AF37);
  static const gold600 = Color(0xFFB8942E);
  static const gold700 = Color(0xFFA88A2D);
  static const gold800 = Color(0xFF8A7024);
  static const gold900 = Color(0xFF6B5619);

  // ─── ALIAS DE ACENTO (uso semántico) ───
  static const accentGold = Color(0xFFD4AF37);
  static const accentGoldLight = Color(0xFFE8C96D);
  static const accentGoldDark = Color(0xFFB8942E);
  static const accentGoldMuted = Color(0xFFA88A2D);
  static const accentEmerald = Color(0xFF10B981);
  static const accentEmeraldDark = Color(0xFF059669);
  static const accentTeal = Color(0xFF14B8A6);

  // ─── TEXTO ───
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFE5E5E5);
  static const textMuted = Color(0xFFA3A3A3);
  static const textDisabled = Color(0xFF737373);

  // ─── BORDES ───
  static const border = Color(0x14FFFFFF);
  static const borderStrong = Color(0x1FFFFFFF);
  static const borderHover = Color(0x29FFFFFF);
  static const divider = Color(0x0FFFFFFF);

  // ─── ESTADO / FEEDBACK ───
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // ─── BADGES ESTADO DE PEDIDO ───
  static const orderPending = Color(0xFFF59E0B);
  static const orderConfirmed = Color(0xFF3B82F6);
  static const orderProcessing = Color(0xFF6366F1);
  static const orderShipped = Color(0xFF8B5CF6);
  static const orderDelivered = Color(0xFF22C55E);
  static const orderCancelled = Color(0xFFEF4444);
  static const orderRefunded = Color(0xFF6B7280);
  static const orderReturnRequested = Color(0xFFF97316);

  // ─── COLOR DE SELECCIÓN DE TEXTO ───
  static const selectionColor = Color(0x40D4AF37);
}
