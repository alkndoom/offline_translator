import 'package:get/get.dart';

import '../../../../core/ports/llm_engine.dart';
import '../../data/gateways/device_speech_recognizer.dart';
import '../../data/gateways/device_text_to_speech.dart';
import '../../data/gateways/llm_translator_gateway.dart';
import '../../data/repositories/prefs_history_repository.dart';
import '../../data/repositories/prefs_phrase_repository.dart';
import '../../domain/gateways/speech_gateways.dart';
import '../../domain/gateways/translator_gateway.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/phrase_repository.dart';
import '../controllers/translator_controller.dart';
import '../controllers/translator_shared_state.dart';

/// Wires the feature's object graph in dependency order. This is the only place
/// that names the concrete gateway implementation; everything else programs to
/// the [TranslatorGateway] contract. The gateway borrows the shared [LlmEngine]
/// registered globally. Dependencies resolve inside the closures so nothing is
/// built until the controller is first requested.
class TranslatorBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TranslatorGateway>(
      () => LlmTranslatorGateway(Get.find<LlmEngine>()),
      fenix: true,
    );
    Get.lazyPut<SpeechRecognizer>(() => DeviceSpeechRecognizer(), fenix: true);
    Get.lazyPut<TextToSpeech>(() => DeviceTextToSpeech(), fenix: true);
    Get.lazyPut<HistoryRepository>(() => PrefsHistoryRepository(), fenix: true);
    Get.lazyPut<PhraseRepository>(() => PrefsPhraseRepository(), fenix: true);
    Get.lazyPut(() => TranslatorSharedState(), fenix: true);
    Get.lazyPut(
      () => TranslatorController(
        Get.find(),
        Get.find<TranslatorGateway>(),
        Get.find<LlmEngine>(),
        Get.find<SpeechRecognizer>(),
        Get.find<TextToSpeech>(),
        Get.find<HistoryRepository>(),
        Get.find<PhraseRepository>(),
      ),
      fenix: true,
    );
  }
}
