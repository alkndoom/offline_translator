import 'package:get/get.dart';

import '../../../../core/controllers/shared_state.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/scenario.dart';
import '../../domain/entities/task_mode.dart';

/// Lifecycle of the shared on-device model, as seen by the UI.
enum ModelStatus { downloading, loading, ready, error }

/// Reactive, resettable state shared within the translator feature.
class TranslatorSharedState extends SharedState {
  final _sourceLang = kSupportedLanguages[0].obs; // English
  final _targetLang = kSupportedLanguages[1].obs; // Turkish
  final _outputText = ''.obs;
  final _modelStatus = ModelStatus.loading.obs;
  final _modelProgress = 0.0.obs;
  final _isListening = false.obs;
  final _taskMode = TaskMode.translate.obs;
  final _scenario = Scenario.general.obs;
  final _phraseUsage = <String, int>{}.obs;
  final _history = <HistoryEntry>[].obs;

  Language get sourceLang => _sourceLang.value;
  Language get targetLang => _targetLang.value;
  String get outputText => _outputText.value;
  ModelStatus get modelStatus => _modelStatus.value;

  /// Model load progress as a 0–1 fraction (0 = unknown/indeterminate).
  double get modelProgress => _modelProgress.value;

  /// Whether the microphone is actively dictating into the input field.
  bool get isListening => _isListening.value;

  /// The currently selected generative task.
  TaskMode get taskMode => _taskMode.value;

  /// The currently selected travel scenario.
  Scenario get scenario => _scenario.value;

  /// Per-phrase tap counts, keyed by phrase id.
  Map<String, int> get phraseUsage => Map.unmodifiable(_phraseUsage);

  /// Past translations, newest first.
  List<HistoryEntry> get history => _history.toList(growable: false);

  bool get hasOutput => _outputText.value.isNotEmpty;

  set sourceLang(Language value) => _sourceLang.value = value;
  set targetLang(Language value) => _targetLang.value = value;
  set outputText(String value) => _outputText.value = value;
  set modelStatus(ModelStatus value) => _modelStatus.value = value;
  set modelProgress(double value) => _modelProgress.value = value;
  set isListening(bool value) => _isListening.value = value;
  set taskMode(TaskMode value) => _taskMode.value = value;
  set scenario(Scenario value) => _scenario.value = value;

  void setPhraseUsage(Map<String, int> counts) =>
      _phraseUsage.assignAll(counts);

  void setHistory(List<HistoryEntry> entries) => _history.assignAll(entries);

  /// Swap source/target languages, clearing any stale result.
  void swapLanguages() {
    final previousSource = _sourceLang.value;
    _sourceLang.value = _targetLang.value;
    _targetLang.value = previousSource;
    _outputText.value = '';
  }

  @override
  void reset() {
    _sourceLang.value = kSupportedLanguages[0];
    _targetLang.value = kSupportedLanguages[1];
    _outputText.value = '';
    _modelProgress.value = 0;
    _taskMode.value = TaskMode.translate;
    _scenario.value = Scenario.general;
    _phraseUsage.clear();
    _history.clear();
  }
}
