import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../controllers/translator_controller.dart';

/// Wide primary action. Shows an inline spinner while a translation is running.
class TranslateButton extends StatelessWidget {
  const TranslateButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TranslatorController>();
    return Obx(() {
      final loading = controller.isLoading('translate');
      return ElevatedButton(
        onPressed: loading ? null : controller.translate,
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : const Text('Translate'),
      );
    });
  }
}
