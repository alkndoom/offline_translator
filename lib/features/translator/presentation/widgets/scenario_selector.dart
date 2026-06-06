import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../../domain/entities/scenario.dart';
import '../controllers/translator_controller.dart';

/// Travel-scenario picker that scopes the quick-phrase list. The Emergency
/// scenario uses a red accent.
class ScenarioSelector extends StatelessWidget {
  const ScenarioSelector({super.key});

  static IconData _iconFor(Scenario s) => switch (s) {
    Scenario.general => Icons.chat_bubble_outline,
    Scenario.airport => Icons.flight,
    Scenario.hotel => Icons.hotel,
    Scenario.customs => Icons.badge_outlined,
    Scenario.emergency => Icons.emergency,
  };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TranslatorController>();
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Obx(() {
        final selected = controller.state.scenario;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: Scenario.values.length,
          separatorBuilder: (_, _) =>
              const SizedBox(width: AppDimensions.gapSm),
          itemBuilder: (context, i) {
            final scenario = Scenario.values[i];
            final isSelected = scenario == selected;
            final accent = scenario.isEmergency
                ? AppColors.error
                : AppColors.primary;
            return ChoiceChip(
              avatar: Icon(
                _iconFor(scenario),
                size: 18,
                color: isSelected ? AppColors.onPrimary : accent,
              ),
              label: Text(scenario.label),
              selected: isSelected,
              onSelected: (_) => controller.selectScenario(scenario),
              showCheckmark: false,
              labelStyle: AppTextStyles.button.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
              ),
              selectedColor: accent,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusField),
                side: BorderSide(
                  color: scenario.isEmergency
                      ? AppColors.error
                      : AppColors.outline,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
