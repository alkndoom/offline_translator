import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../controllers/translator_controller.dart';

/// Borderless text entry card (~30% of screen height) with a clear action.
class InputCard extends StatelessWidget {
  const InputCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TranslatorController>();
    final height = MediaQuery.sizeOf(context).height * 0.3;
    return ElevatedCard(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => IconButton(
                    onPressed: controller.toggleDictation,
                    icon: Icon(
                      controller.state.isListening ? Icons.mic : Icons.mic_none,
                      color: controller.state.isListening
                          ? AppColors.primary
                          : AppColors.onSurfaceMuted,
                    ),
                    tooltip: 'Dictate',
                  ),
                ),
                IconButton(
                  onPressed: controller.clearInput,
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.onSurfaceMuted,
                  ),
                  tooltip: 'Clear',
                ),
              ],
            ),
            Expanded(
              child: Obx(
                () => TextField(
                  controller: controller.inputController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: controller.state.taskMode.inputHint,
                    hintStyle: AppTextStyles.hint,
                    isCollapsed: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
