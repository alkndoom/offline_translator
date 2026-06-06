import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/controllers/base_controller.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/ports/llm_engine.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/entities/language.dart';
import '../../domain/entities/phrase.dart';
import '../../domain/entities/phrasebook_data.dart';
import '../../domain/entities/scenario.dart';
import '../../domain/entities/task_mode.dart';
import '../../domain/gateways/speech_gateways.dart';
import '../../domain/gateways/translator_gateway.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/phrase_repository.dart';
import 'translator_shared_state.dart';

/// Presentation logic for the translator screen. Translation goes through the
/// [TranslatorGateway] contract; the shared [LlmEngine] is observed only to
/// warm up the model and surface its load status (analogous to a SessionProvider).
class TranslatorController extends BaseController<TranslatorSharedState> {
  final TranslatorGateway _gateway;
  final LlmEngine _llm;
  final SpeechRecognizer _speech;
  final TextToSpeech _tts;
  final HistoryRepository _historyRepo;
  final PhraseRepository _phraseRepo;

  TranslatorController(
    super.state,
    this._gateway,
    this._llm,
    this._speech,
    this._tts,
    this._historyRepo,
    this._phraseRepo,
  );

  final inputController = TextEditingController();
  static const _historyLimit = 50;

  @override
  void onInit() {
    super.onInit();
    warmUpModel();
    loadHistory();
    loadPhraseUsage();
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

  /// Run the currently selected task on the input text.
  Future<void> runTask() => runSafe(
    tag: 'task',
    errorMessage: 'Could not complete the request. Please try again.',
    action: () async {
      final text = inputController.text.trim();
      if (text.isEmpty) {
        throw const TranslationException(message: 'Enter some text first.');
      }
      state.outputText = '';
      // Render each cumulative snapshot as tokens stream in.
      await for (final chunk in _gateway.run(
        state.taskMode,
        text,
        source: state.sourceLang.name,
        target: state.targetLang.name,
      )) {
        state.outputText = chunk;
      }
      if (state.outputText.trim().isNotEmpty) {
        await _addHistory(text, state.outputText);
      }
    },
  );

  // --- Mode & languages ------------------------------------------------------

  void setMode(TaskMode mode) {
    state.taskMode = mode;
    state.outputText = '';
  }

  // --- Phrasebook / quick phrases --------------------------------------------

  void selectScenario(Scenario scenario) => state.scenario = scenario;

  /// Curated phrases for the active scenario, most-used first.
  List<Phrase> get quickPhrases {
    final usage = state.phraseUsage;
    final phrases = kPhrasebook
        .where((phrase) => phrase.scenario == state.scenario)
        .toList();
    phrases.sort((a, b) => (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0));
    return phrases;
  }

  /// One-tap phrase translation without a model call.
  Future<void> usePhrase(Phrase phrase) {
    final source = phrase.inLanguage(state.sourceLang.name);
    final target = phrase.inLanguage(state.targetLang.name);
    inputController.text = source;
    state.outputText = target;

    final usage = Map<String, int>.from(state.phraseUsage);
    usage[phrase.id] = (usage[phrase.id] ?? 0) + 1;
    state.setPhraseUsage(usage);

    return runSafe(
      tag: 'phrase',
      silent: true,
      action: () async {
        await _phraseRepo.save(usage);
        await _addHistory(source, target);
      },
    );
  }

  Future<void> loadPhraseUsage() => runSafe(
    tag: 'phraseUsage',
    silent: true,
    action: () async =>
        state.setPhraseUsage(await _phraseRepo.getUsageCounts()),
  );

  void setSourceLanguage(Language language) {
    state.sourceLang = language;
    state.outputText = '';
  }

  void setTargetLanguage(Language language) {
    state.targetLang = language;
    state.outputText = '';
  }

  void swap() => state.swapLanguages();

  // --- Speech ----------------------------------------------------------------

  /// Toggle voice dictation into the input field, in the source language.
  Future<void> toggleDictation() async {
    if (state.isListening) {
      await _speech.stop();
      state.isListening = false;
      return;
    }
    await runSafe(
      tag: 'dictation',
      errorMessage: 'Microphone unavailable. Check permissions.',
      action: () async {
        state.isListening = true;
        await for (final words in _speech.listen(
          languageTag: state.sourceLang.localeTag,
        )) {
          inputController.text = words;
        }
      },
      onFinally: () => state.isListening = false,
    );
  }

  /// Read the current translation aloud, in the target language.
  Future<void> speakOutput() => runSafe(
    tag: 'speak',
    silent: true,
    action: () =>
        _tts.speak(state.outputText, languageTag: state.targetLang.localeTag),
  );

  // --- History ---------------------------------------------------------------

  Future<void> loadHistory() => runSafe(
    tag: 'history',
    silent: true,
    action: () async => state.setHistory(await _historyRepo.getAll()),
  );

  /// Load a past translation back into the screen.
  void reuseHistory(HistoryEntry entry) {
    inputController.text = entry.sourceText;
    state.sourceLang = _languageByName(entry.sourceLang);
    state.targetLang = _languageByName(entry.targetLang);
    state.outputText = entry.translatedText;
  }

  Future<void> toggleFavorite(HistoryEntry entry) => _persist(
    state.history
        .map(
          (e) => e.id == entry.id ? e.copyWith(isFavorite: !e.isFavorite) : e,
        )
        .toList(),
  );

  Future<void> deleteHistory(HistoryEntry entry) =>
      _persist(state.history.where((e) => e.id != entry.id).toList());

  Future<void> clearHistory() => _persist(const []);

  Future<void> _addHistory(String source, String translated) {
    final entry = HistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      task: state.taskMode.actionLabel,
      sourceText: source,
      translatedText: translated.trim(),
      sourceLang: state.sourceLang.name,
      targetLang: state.targetLang.name,
      createdAt: DateTime.now(),
    );
    final updated = [entry, ...state.history];
    if (updated.length > _historyLimit) {
      updated.removeRange(_historyLimit, updated.length);
    }
    return _persist(updated);
  }

  Future<void> _persist(List<HistoryEntry> entries) async {
    state.setHistory(entries);
    await _historyRepo.save(entries);
  }

  Language _languageByName(String name) => kSupportedLanguages.firstWhere(
    (l) => l.name == name,
    orElse: () => state.sourceLang,
  );

  // --- Input -----------------------------------------------------------------

  void clearInput() {
    inputController.clear();
    state.outputText = '';
  }

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
