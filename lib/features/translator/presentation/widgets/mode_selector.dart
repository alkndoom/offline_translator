import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../../domain/entities/task_mode.dart';
import '../controllers/translator_controller.dart';

/// Task picker: Translate / Summarize / Simplify / Explain.
class ModeSelector extends StatelessWidget {
  const ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TranslatorController>();
    return SizedBox(
      height: 40,
      child: Obx(() {
        final selected = controller.state.taskMode;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: TaskMode.values.length,
          separatorBuilder: (_, _) =>
              const SizedBox(width: AppDimensions.gapSm),
          itemBuilder: (context, i) {
            final mode = TaskMode.values[i];
            final isSelected = mode == selected;
            return ChoiceChip(
              label: Text(mode.actionLabel),
              selected: isSelected,
              onSelected: (_) => controller.setMode(mode),
              showCheckmark: false,
              labelStyle: AppTextStyles.button.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
              ),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusField),
                side: const BorderSide(color: AppColors.outline),
              ),
            );
          },
        );
      }),
    );
  }
}
