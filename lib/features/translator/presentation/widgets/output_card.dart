import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../controllers/translator_controller.dart';

/// Faintly-tinted result card. Renders only once a translation is available,
/// with a copy-to-clipboard action.
class OutputCard extends StatelessWidget {
  const OutputCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TranslatorController>();
    return Obx(() {
      if (!controller.state.hasOutput) return const SizedBox.shrink();
      return ElevatedCard(
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(controller.state.outputText, style: AppTextStyles.body),
            const SizedBox(height: AppDimensions.gapSm),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: controller.copyOutput,
                icon: const Icon(Icons.copy, color: AppColors.primary),
                tooltip: 'Copy',
              ),
            ),
          ],
        ),
      );
    });
  }
}
