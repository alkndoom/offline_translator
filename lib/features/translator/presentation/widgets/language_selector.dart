import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../../domain/entities/language.dart';
import '../controllers/translator_controller.dart';

/// Source / target language pickers with a swap button between the two.
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
            () => _LanguageButton(
              language: controller.state.sourceLang,
              onSelected: controller.setSourceLanguage,
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
            () => _LanguageButton(
              language: controller.state.targetLang,
              onSelected: controller.setTargetLanguage,
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final Language language;
  final ValueChanged<Language> onSelected;

  const _LanguageButton({required this.language, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _pick(context),
      child: Text(
        language.name,
        style: AppTextStyles.button.copyWith(color: AppColors.primary),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<Language>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusCard),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final lang in kSupportedLanguages)
              ListTile(
                title: Text(lang.name, style: AppTextStyles.body),
                trailing: lang == language
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(lang),
              ),
          ],
        ),
      ),
    );
    if (selected != null) onSelected(selected);
  }
}
