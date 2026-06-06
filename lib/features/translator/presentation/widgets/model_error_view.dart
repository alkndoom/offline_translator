import 'package:flutter/material.dart';

import '../../../../core/design_system/index.dart';

/// Shown when the local model fails to load, with a retry action.
class ModelErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const ModelErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: AppDimensions.gapMd),
            const Text(
              "Couldn't load the local model.",
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.gapSm),
            const Text(
              'Check your connection, or that the model is installed.',
              style: AppTextStyles.hint,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.gapLg),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
