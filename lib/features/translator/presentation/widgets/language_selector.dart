import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../controllers/translator_controller.dart';

/// Source / target language row with a swap button between the two.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TranslatorController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Obx(
            () => TextButton(
              onPressed: () {},
              child: Text(
                controller.state.sourceLang,
                style: AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: controller.swap,
          icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
          tooltip: 'Swap languages',
        ),
        Expanded(
          child: Obx(
            () => TextButton(
              onPressed: () {},
              child: Text(
                controller.state.targetLang,
                style: AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
