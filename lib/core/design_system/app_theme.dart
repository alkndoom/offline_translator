import 'package:flutter/material.dart';

import 'foundation/app_colors.dart';
import 'foundation/app_dimensions.dart';
import 'foundation/app_text_styles.dart';

/// Maps design-system tokens onto Material's [ThemeData] so the default widget
/// catalog inherits the system's color and typography.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.title,
        foregroundColor: AppColors.onSurface,
      ),
      textTheme: const TextTheme(
        titleLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTextStyles.button,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusField),
          ),
        ),
      ),
    );
  }
}
