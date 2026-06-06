import 'package:get/get.dart';

import '../../core/ports/llm_engine.dart';
import '../../core/ports/model_downloader.dart';
import '../infrastructure/http_model_downloader.dart';
import '../infrastructure/llama_cpp_engine.dart';

/// Registers app-lifetime singletons. The local LLM engine is shared
/// infrastructure (the offline analog of an HTTP client), bound under its port
/// interface so features depend only on [LlmEngine]. The engine provisions its
/// weights through a [ModelDownloader]. Neither is loaded here — the first
/// translation screen triggers the lazy `load()` (covered by the indicator).
class GlobalBindings extends Bindings {
  /// Direct URL to the `.gguf`, supplied at build time:
  ///   flutter run --dart-define=MODEL_URL=https://example.com/model.gguf
  /// Leave empty to require a manually-installed model (adb push / Files).
  static const _modelUrl = String.fromEnvironment('MODEL_URL');

  @override
  void dependencies() {
    if (!Get.isRegistered<ModelDownloader>()) {
      Get.put<ModelDownloader>(
        HttpModelDownloader(url: _modelUrl),
        permanent: true,
      );
    }
    if (!Get.isRegistered<LlmEngine>()) {
      Get.put<LlmEngine>(
        LlamaCppEngine(Get.find<ModelDownloader>()),
        permanent: true,
      );
    }
  }
}
