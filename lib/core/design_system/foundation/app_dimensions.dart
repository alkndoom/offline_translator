import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing and radius scale plus shared elevation tokens.
class AppDimensions {
  AppDimensions._();

  // Spacing scale.
  static const double gapXs = 4;
  static const double gapSm = 8;
  static const double gapMd = 16;
  static const double gapLg = 24;
  static const double screenPadding = 20;

  // Radius scale.
  static const double radiusField = 12;
  static const double radiusCard = 16;

  // Soft shadow for elevated surfaces.
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
  ];
}
