import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../controllers/translator_controller.dart';

/// Most-used phrases for the active scenario, shown in the source language.
/// One tap fills input + output instantly (no model call). The priority feature.
class QuickPhrases extends StatelessWidget {
  const QuickPhrases({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TranslatorController>();
    return Obx(() {
      final scenario = controller.state.scenario;
      final source = controller.state.sourceLang;
      final phrases = controller.quickPhrases; // reacts to usage + scenario
      final isEmergency = scenario.isEmergency;
      final accent = isEmergency ? AppColors.error : AppColors.primary;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEmergency ? 'Emergency phrases' : 'Quick phrases',
            style: AppTextStyles.button.copyWith(color: accent),
          ),
          const SizedBox(height: AppDimensions.gapSm),
          Wrap(
            spacing: AppDimensions.gapSm,
            runSpacing: AppDimensions.gapSm,
            children: [
              for (final phrase in phrases)
                ActionChip(
                  label: Text(phrase.inLanguage(source.name)),
                  onPressed: () => controller.usePhrase(phrase),
                  labelStyle: AppTextStyles.body.copyWith(color: accent),
                  backgroundColor: isEmergency
                      ? AppColors.errorTint
                      : AppColors.primaryTint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusField,
                    ),
                    side: BorderSide(color: accent.withValues(alpha: 0.3)),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
