import 'package:flutter/material.dart';

import '../../../../core/design_system/index.dart';

/// Full-screen progress indicator shown while the local model is provisioned.
class ModelLoadingView extends StatelessWidget {
  final String label;

  /// 0–1 fraction; 0 renders an indeterminate spinner.
  final double progress;

  const ModelLoadingView({
    super.key,
    required this.label,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).round();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 56,
            width: 56,
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 4,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.gapLg),
          Text(label, style: AppTextStyles.title),
          const SizedBox(height: AppDimensions.gapSm),
          Text(
            progress > 0 ? '$percent%' : 'Preparing local AI…',
            style: AppTextStyles.hint,
          ),
        ],
      ),
    );
  }
}
