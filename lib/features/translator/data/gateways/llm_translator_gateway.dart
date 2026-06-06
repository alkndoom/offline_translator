import '../../../../core/ports/llm_engine.dart';
import '../../domain/entities/translation_entity.dart';
import '../../domain/gateways/translator_gateway.dart';

/// Translates by prompting the shared on-device [LlmEngine]. This gateway is a
/// thin prompt builder — the model is general infrastructure, not a translator,
/// so all translation-specific knowledge lives here while the engine stays
/// reusable by other features.
class LlmTranslatorGateway implements TranslatorGateway {
  final LlmEngine _llm;

  LlmTranslatorGateway(this._llm);

  @override
  Stream<TranslationEntity> translate(
    String text,
    String source,
    String target,
  ) async* {
    final messages = [
      LlmMessage.system(
        'You are a translation engine. Translate the user message from '
        '$source to $target. Output ONLY the translation — no quotes, no '
        'notes, no explanations.',
      ),
      LlmMessage.user(text),
    ];

    // Low temperature for deterministic translation. Forward each token as a
    // cumulative snapshot so the UI can render the translation as it streams.
    final buffer = StringBuffer();
    await for (final chunk in _llm.chat(
      messages,
      temperature: 0.2,
      maxTokens: 512,
    )) {
      buffer.write(chunk);
      yield TranslationEntity(
        sourceText: text,
        translatedText: buffer.toString().trimLeft(),
        sourceLang: source,
        targetLang: target,
      );
    }
  }
}
