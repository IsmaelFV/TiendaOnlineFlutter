import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos tipográficos de Fashion Store
/// Encabezados: Playfair Display (serif premium)
/// Cuerpo: Lato (sans-serif limpia)
abstract class AppTextStyles {
  // ─── ENCABEZADOS (Playfair Display, serif) ───
  static TextStyle h1 = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.64,
  );

  static TextStyle h2 = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.gray50,
    letterSpacing: -0.48,
  );

  static TextStyle h3 = GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.gray200,
    letterSpacing: -0.40,
  );

  static TextStyle h4 = GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.gray200,
    letterSpacing: -0.36,
  );

  // ─── CUERPO (Lato, sans-serif) ───
  static TextStyle bodyLarge = GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.gray200,
  );

  static TextStyle body = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.gray200,
  );

  static TextStyle bodySmall = GoogleFonts.lato(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.gray400,
  );

  // ─── BOTONES (uppercase, letter-spacing amplio) ───
  static TextStyle button = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
  );

  // ─── PRECIOS ───
  static TextStyle price = GoogleFonts.lato(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.accentGold,
  );

  static TextStyle priceOld = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.gray500,
    decoration: TextDecoration.lineThrough,
  );

  // ─── CAPTION / LABELS ───
  static TextStyle caption = GoogleFonts.lato(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.gray500,
    letterSpacing: 0.5,
  );
}
