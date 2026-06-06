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
  Stream<TranslationEntity> translate(String text, String source, String target) async* {
    final messages = [
      LlmMessage.system(
        'You are a $source to $target translation assistant specialized in airplane, airport boarding, cabin, passenger, and flight-related situations.'
        'Your task is to translate the user\'s sentence between $source and $target.'
        'Rules:'
        '- If the input is $source, translate it into natural $target.'
        '- If the input is $target, translate it into natural $source.'
        '- Preserve the meaning, politeness level, urgency, and speaker intent.'
        '- Use simple, clear, practical language suitable for airplane passengers and cabin crew.'
        '- Do not add explanations.'
        '- Do not answer the user\'s request.'
        '- Do not roleplay.'
        '- Only return the translated sentence.'
        '- For emergency sentences, keep the translation direct and accurate.'
        '- For polite requests, preserve politeness naturally.'
        '- For announcements or crew instructions, use clear formal language.',
      ),
      LlmMessage.user(text),
    ];

    // Low temperature for deterministic translation. Forward each token as a
    // cumulative snapshot so the UI can render the translation as it streams.
    final buffer = StringBuffer();
    await for (final chunk in _llm.chat(messages, temperature: 0.2, maxTokens: 512)) {
      buffer.write(chunk);
      yield TranslationEntity(
        sourceText: text,
        translatedText: _clean(buffer.toString()),
        sourceLang: source,
        targetLang: target,
      );
    }
  }

  /// Strip chat-model special tokens that can leak into generated text.
  String _clean(String text) {
    var out = text;
    for (final token in const ['<|eot_id|>', '<|end_of_text|>', '<|im_end|>', '<end_of_turn>', '<|endoftext|>']) {
      out = out.replaceAll(token, '');
    }
    return out.trimLeft();
  }
}
