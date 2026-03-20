import 'package:flutter/material.dart';

/// Centralized configuration for mode-specific colors and styling in the Home screen.
class HomeModeConfig {
  final String mode;
  final Color primaryColor;
  final List<Color> fabGradient;
  final Color fabShadow;
  final Color fabRing;

  const HomeModeConfig({
    required this.mode,
    required this.primaryColor,
    required this.fabGradient,
    required this.fabShadow,
    required this.fabRing,
  });

  /// Factory constructor to create mode-specific configs
  factory HomeModeConfig.fromMode(String mode) {
    switch (mode) {
      case 'preg':
        return const HomeModeConfig(
          mode: 'preg',
          primaryColor: Color(0xFF4A70B0),
          fabGradient: [Color(0xFF7AA0E0), Color(0xFF4A70B0)],
          fabShadow: Color(0xFF4A70B0),
          fabRing: Color(0xFFC8DCF8),
        );
      case 'ovul':
        return const HomeModeConfig(
          mode: 'ovul',
          primaryColor: Color(0xFF5A8E6A),
          fabGradient: [Color(0xFF78C890), Color(0xFF5A8E6A)],
          fabShadow: Color(0xFF5A8E6A),
          fabRing: Color(0xFFBEE6CD),
        );
      default: // 'period'
        return const HomeModeConfig(
          mode: 'period',
          primaryColor: Color(0xFFD97B8A),
          fabGradient: [Color(0xFFE8789A), Color(0xFFC95678)],
          fabShadow: Color(0xFFC95678),
          fabRing: Color(0xFFFCDCE6),
        );
    }
  }
}
