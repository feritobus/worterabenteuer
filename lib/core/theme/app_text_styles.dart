import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display — Baloo 2 para títulos y encabezados
  static TextStyle display1 = GoogleFonts.baloo2(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    height: 1.2,
  );

  static TextStyle display2 = GoogleFonts.baloo2(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    height: 1.2,
  );

  static TextStyle headline = GoogleFonts.baloo2(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.3,
  );

  static TextStyle title = GoogleFonts.baloo2(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.3,
  );

  // Body — Nunito para texto general de UI
  static TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.5,
  );

  static TextStyle body = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.5,
  );

  static TextStyle bodyBold = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    height: 1.5,
  );

  static TextStyle label = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.4,
  );

  static TextStyle caption = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.ink.withValues(alpha: 0.7),
    height: 1.4,
  );

  // Variantes de color
  static TextStyle displayWhite = display1.copyWith(color: AppColors.cloud);
  static TextStyle headlineWhite = headline.copyWith(color: AppColors.cloud);
  static TextStyle titleWhite = title.copyWith(color: AppColors.cloud);
  static TextStyle bodyWhite = bodyLarge.copyWith(color: AppColors.cloud);
  static TextStyle labelWhite = label.copyWith(color: AppColors.cloud);

  // Alemán — destaca las palabras del idioma objetivo
  static TextStyle germanWord = GoogleFonts.baloo2(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.violet,
    height: 1.2,
  );

  static TextStyle germanSentence = GoogleFonts.nunito(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.violet,
    height: 1.4,
  );
}
