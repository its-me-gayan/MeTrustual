import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.nunito().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryRose,
        secondary: AppColors.lightRose,
        surface: AppColors.cardBg,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRose,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.nunito(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        labelSmall: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
