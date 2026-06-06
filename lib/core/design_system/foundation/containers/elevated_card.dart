import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_dimensions.dart';

/// Semantic surface wrapper: a rounded, softly-shadowed card. Encodes the
/// recurring "this is a card surface" intent so feature code never passes raw
/// colors, radii, or shadows.
class ElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When true, uses the faint primary tint (e.g. the translation output card).
  final bool tinted;

  const ElevatedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.gapMd),
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tinted ? AppColors.primaryTint : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        boxShadow: AppDimensions.softShadow,
      ),
      child: child,
    );
  }
}
