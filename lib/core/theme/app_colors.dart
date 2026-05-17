import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primarios
  static const Color violet = Color(0xFF7C4DFF);
  static const Color sky = Color(0xFF29B6F6);
  static const Color mint = Color(0xFF00BCD4);

  // Acentos
  static const Color sun = Color(0xFFFFA726);
  static const Color gold = Color(0xFFFFD600);
  static const Color berry = Color(0xFFEF5350);
  static const Color peach = Color(0xFFFF7043);
  static const Color grass = Color(0xFF4CAF50);

  // Neutros
  static const Color ink = Color(0xFF0D1B2A);
  static const Color cloud = Color(0xFFFFFFFF);
  static const Color pale = Color(0xFFF0F4FF);
  static const Color paleGray = Color(0xFFE8EEF9);

  // Estados
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);

  // Gradientes
  static const LinearGradient violetSky = LinearGradient(
    colors: [violet, sky],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetSkyVertical = LinearGradient(
    colors: [violet, sky],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sunPeach = LinearGradient(
    colors: [sun, peach],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
