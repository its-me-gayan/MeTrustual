import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// AppTheme applies the Nunito font family consistently across the entire app,
/// matching the exact font weights defined in metrustual-7.html:
///   - w400 (Regular)   → body text, descriptions
///   - w600 (SemiBold)  → sub-labels, secondary text
///   - w700 (Bold)      → labels, nav items, chip text
///   - w800 (ExtraBold) → section headers, button text
///   - w900 (Black)     → page titles, large numbers, primary headings
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
          // w800 matches .save-btn, .ob-btn, .jrn-btn font-weight: 800 in HTML
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      textTheme: TextTheme(
        // displayLarge: page titles, app name — w900 matches .sp-name, .ob-h, .mode-h
        displayLarge: GoogleFonts.nunito(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
        // displayMedium: large numbers (cycle day, kick count) — w900 matches .day-num, .kick-num
        displayMedium: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
        // displaySmall: section titles — w900 matches .page-title
        displaySmall: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
        // headlineLarge: card/section headings — w900 matches .ic-head, .bi-title
        headlineLarge: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
        // headlineMedium: sub-headings — w800 matches .mc-title, .art-title
        headlineMedium: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        // headlineSmall: smaller headings — w800 matches .cal-title, .priv-head
        headlineSmall: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        // titleLarge: screen titles — w900 matches .jrn-q, .name
        titleLarge: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
        // titleMedium: card titles — w800 matches .ob-tl, .sm-btn text
        titleMedium: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        // titleSmall: small titles — w800 matches .sm-title, .bc-week
        titleSmall: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
        ),
        // bodyLarge: primary body text — w600 matches .ob-p, .jrn-sub, .mc-desc
        bodyLarge: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        // bodyMedium: standard body text — w600 matches .bi-sub, .trust-text
        bodyMedium: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        // bodySmall: small body text — w600 matches .trow-sub, .ob-ts
        bodySmall: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
        // labelLarge: button labels — w800 matches .lang-btn, .cat-btn, .chip
        labelLarge: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        // labelMedium: nav labels, section headers — w800 matches .nav-item, .section
        labelMedium: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.4,
        ),
        // labelSmall: tiny labels, uppercase tags — w800 matches .pill-lbl, .log-date
        labelSmall: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
