import 'package:flutter/material.dart';

/// Color tokens. Defined once; referenced everywhere. No raw `Color(0x..)` in
/// feature code.
class AppColors {
  AppColors._();

  /// Neutral off-white app background.
  static const Color background = Color(0xFFF7F7FB);

  /// Card / input surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Calming blue/purple primary accent.
  static const Color primary = Color(0xFF6C63FF);

  /// Faint primary tint for the output card.
  static const Color primaryTint = Color(0xFFF0EFFF);

  /// Danger accent for emergency phrase surfaces.
  static const Color error = Color(0xFFE53935);

  /// Faint danger tint for emergency phrase surfaces.
  static const Color errorTint = Color(0xFFFDECEA);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C1B29);
  static const Color onSurfaceMuted = Color(0xFF8A8896);
  static const Color outline = Color(0xFFE6E5EF);
  static const Color shadow = Color(0x14000000);

  static const ColorScheme lightScheme = ColorScheme.light(
    primary: primary,
    onPrimary: onPrimary,
    surface: surface,
    onSurface: onSurface,
    outline: outline,
  );
}
