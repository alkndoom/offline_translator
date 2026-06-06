import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The type scale. Mapped onto the Material text theme in [AppTheme].
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 1.4,
    color: AppColors.onSurface,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 16,
    color: AppColors.onSurfaceMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}
