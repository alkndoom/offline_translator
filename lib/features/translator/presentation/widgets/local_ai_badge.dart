import 'package:flutter/material.dart';

import '../../../../core/design_system/index.dart';

/// AppBar badge advertising that translation runs locally / offline.
class LocalAiBadge extends StatelessWidget {
  const LocalAiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.gapMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.gapSm,
          vertical: AppDimensions.gapXs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppDimensions.radiusField),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_bolt, size: 16, color: AppColors.primary),
            SizedBox(width: AppDimensions.gapXs),
            Text('Local AI', style: AppTextStyles.badge),
          ],
        ),
      ),
    );
  }
}
