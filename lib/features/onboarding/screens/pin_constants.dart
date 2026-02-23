import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════
//  PIN CONSTANTS
//  Shared colors, gradients and lists used across all
//  PIN-related screens and widgets.
// ═══════════════════════════════════════════════════════

/// Brand / palette colours
class PinColors {
  PinColors._();

  static const Color roseDeep = Color(0xFFD97B8A);
  static const Color roseLight = Color(0xFFF09090);
  static const Color amberGold = Color(0xFFC97B3A);
  static const Color darkBrown = Color(0xFF3D2828);
  static const Color mutedBrown = Color(0xFF5A3838);
  static const Color textMuted = Color(0xFFB09090);
  static const Color textHint = Color(0xFFC0A0A8);
  static const Color textSubtle = Color(0xFFD0B0B8);
  static const Color peachBorder = Color(0xFFFCE8E4);
  static const Color peachFill = Color(0xFFFFF8F5);
  static const Color errorRed = Color(0xFFC05050);
  static const Color errorRedLight = Color(0xFFF07070);
  static const Color greenSuccess = Color(0xFF5A8E6A);
  static const Color greenLight = Color(0xFF78C890);
  static const Color warnAmber = Color(0xFFC09050);
}

/// The main background gradient used on the PIN screen
/// and the Forgot PIN overlay.
const kPinBackgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFFF4F0),
    Color(0xFFFDE8F0),
    Color(0xFFEDE8FC),
    Color(0xFFE8EEFF),
  ],
  stops: [0.0, 0.38, 0.72, 1.0],
);

/// Rose gradient used on filled dots and buttons
const kRoseGradient = LinearGradient(
  colors: [Color(0xFFF09090), Color(0xFFD97B8A)],
);

/// Error-red gradient used on shaking / wrong dots
const kErrorGradient = LinearGradient(
  colors: [Color(0xFFF07070), Color(0xFFC05050)],
);

/// Success-green gradient used on confirmed dots
const kGreenGradient = LinearGradient(
  colors: [Color(0xFF78C890), Color(0xFF5A8E6A)],
);

/// PINs that are considered too weak
const kWeakPins = [
  '1234',
  '0000',
  '1111',
  '2222',
  '3333',
  '4444',
  '5555',
  '6666',
  '7777',
  '8888',
  '9999',
  '0123',
];

/// Numpad key definitions: digit label, optional sub-label
const kNumpadKeys = [
  ('1', ''),
  ('2', 'ABC'),
  ('3', 'DEF'),
  ('4', 'GHI'),
  ('5', 'JKL'),
  ('6', 'MNO'),
  ('7', 'PQRS'),
  ('8', 'TUV'),
  ('9', 'WXYZ'),
];
