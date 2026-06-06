import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/base_controller.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/ports/llm_engine.dart';
import '../../domain/gateways/translator_gateway.dart';
import 'translator_shared_state.dart';

/// Presentation logic for the translator screen. Translation goes through the
/// [TranslatorGateway] contract; the shared [LlmEngine] is observed only to
/// warm up the model and surface its load status (analogous to a SessionProvider).
class TranslatorController extends BaseController<TranslatorSharedState> {
  final TranslatorGateway _gateway;
  final LlmEngine _llm;

  TranslatorController(super.state, this._gateway, this._llm);

  final inputController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    warmUpModel();
  }

  /// Loads the model when the screen first opens (downloading it on first run),
  /// driving the loading indicator.
  Future<void> warmUpModel() => runSafe(
    tag: 'model',
    action: () async {
      await _llm.load(
        onProgress: (phase, progress) {
          state.modelStatus = switch (phase) {
            LlmLoadPhase.downloading => ModelStatus.downloading,
            LlmLoadPhase.loading => ModelStatus.loading,
          };
          state.modelProgress = progress;
        },
      );
      state.modelStatus = ModelStatus.ready;
    },
    onError: (_, _) => state.modelStatus = ModelStatus.error,
  );

  Future<void> translate() => runSafe(
    tag: 'translate',
    errorMessage: 'Translation failed. Please try again.',
    action: () async {
      final text = inputController.text.trim();
      if (text.isEmpty) {
        throw const TranslationException(
          message: 'Enter some text to translate.',
        );
      }
      state.outputText = '';
      // Render each cumulative snapshot as tokens stream in.
      await for (final entity in _gateway.translate(
        text,
        state.sourceLang,
        state.targetLang,
      )) {
        state.outputText = entity.translatedText;
      }
    },
  );

  void clearInput() {
    inputController.clear();
    state.outputText = '';
  }

  void swap() => state.swapLanguages();

  Future<void> copyOutput() async {
    if (!state.hasOutput) return;
    await Clipboard.setData(ClipboardData(text: state.outputText));
    Get.snackbar(
      'Copied',
      'Translation copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  void onClose() {
    inputController.dispose();
    super.onClose();
  }
}
