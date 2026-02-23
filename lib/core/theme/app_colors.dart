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

  // Mode-specific colors (Original Darker)
  static const Color periodRose = Color(0xFFD97B8A);
  static const Color pregBlue = Color(0xFF4A70B0);
  static const Color ovulGreen = Color(0xFF5A8E6A);

  // Softer Mode-specific colors (Previous Very Soft Variants)
  static const Color softPeriodRose = Color(0xFFE59CA8);
  static const Color softPregBlue = Color(0xFF7B99CB);
  static const Color softOvulGreen = Color(0xFF88AF93);

  // Medium-Soft Mode-specific colors (Balanced Variants)
  static const Color mediumPeriodRose = Color(0xFFE08B99); // Balanced between D97B8A and E59CA8
  static const Color mediumPregBlue = Color(0xFF6284BD);   // Balanced between 4A70B0 and 7B99CB
  static const Color mediumOvulGreen = Color(0xFF719E7E);  // Balanced between 5A8E6A and 88AF93

  static Color getModeColor(String mode, {bool soft = false}) {
    if (soft) {
      switch (mode) {
        case 'preg':
          return mediumPregBlue;
        case 'ovul':
          return mediumOvulGreen;
        default:
          return mediumPeriodRose;
      }
    }
    switch (mode) {
      case 'preg':
        return pregBlue;
      case 'ovul':
        return ovulGreen;
      default:
        return periodRose;
    }
  }

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
