import 'package:get/get.dart';

import '../../../../core/controllers/shared_state.dart';

/// Lifecycle of the shared on-device model, as seen by the UI.
enum ModelStatus { downloading, loading, ready, error }

/// Reactive, resettable state shared within the translator feature.
class TranslatorSharedState extends SharedState {
  final _sourceLang = 'English'.obs;
  final _targetLang = 'Turkish'.obs;
  final _outputText = ''.obs;
  final _modelStatus = ModelStatus.loading.obs;
  final _modelProgress = 0.0.obs;

  String get sourceLang => _sourceLang.value;
  String get targetLang => _targetLang.value;
  String get outputText => _outputText.value;
  ModelStatus get modelStatus => _modelStatus.value;

  /// Model load progress as a 0–1 fraction (0 = unknown/indeterminate).
  double get modelProgress => _modelProgress.value;

  bool get hasOutput => _outputText.value.isNotEmpty;

  set outputText(String value) => _outputText.value = value;
  set modelStatus(ModelStatus value) => _modelStatus.value = value;
  set modelProgress(double value) => _modelProgress.value = value;

  /// Swap source/target languages, clearing any stale result.
  void swapLanguages() {
    final previousSource = _sourceLang.value;
    _sourceLang.value = _targetLang.value;
    _targetLang.value = previousSource;
    _outputText.value = '';
  }

  @override
  void reset() {
    _sourceLang.value = 'English';
    _targetLang.value = 'Turkish';
    _outputText.value = '';
    _modelProgress.value = 0;
  }
}
