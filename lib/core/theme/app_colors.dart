import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFEF6F0);
  static const Color cardBg = Color(0xFFFFF8F5);
  static const Color primaryRose = Color(0xFFD97B8A);
  static const Color lightRose = Color(0xFFF09090);
  static const Color petalLight = Color(0xFFFDD0D0);
  static const Color border = Color(0xFFFCE8E4);
  static const Color textDark = Color(0xFF3D2828);
  static const Color textMid = Color(0xFFB09090);
  static const Color textMuted = Color(0xFFD0B0B8);
  static const Color sageGreen = Color(0xFF6A9E6A);
  static const Color lavender = Color(0xFFA880C8);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [lightRose, primaryRose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cycleCircleGradient = LinearGradient(
    colors: [Color(0xFFFCE8E8), Color(0xFFFDD5D5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient onboardingGradient = LinearGradient(
    colors: [Color(0xFFFFF8F5), Color(0xFFFEF0F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
