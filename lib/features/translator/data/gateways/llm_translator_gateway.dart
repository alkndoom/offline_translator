import '../../../../core/ports/llm_engine.dart';
import '../../domain/entities/task_mode.dart';
import '../../domain/gateways/translator_gateway.dart';

/// Runs tasks by prompting the shared on-device [LlmEngine]. This gateway is a
/// thin prompt builder — the model is general infrastructure, not a translator,
/// so all task-specific knowledge lives here while the engine stays reusable.
class LlmTranslatorGateway implements TranslatorGateway {
  final LlmEngine _llm;

  LlmTranslatorGateway(this._llm);

  @override
  Stream<String> run(
    TaskMode mode,
    String input, {
    required String source,
    required String target,
  }) async* {
    final messages = [
      LlmMessage.system(_systemPrompt(mode, source, target)),
      LlmMessage.user(input),
    ];

    // Low temperature for deterministic output. Forward each token as a
    // cumulative snapshot so the UI can render the result as it streams.
    final buffer = StringBuffer();
    await for (final chunk in _llm.chat(
      messages,
      temperature: 0.2,
      maxTokens: 512,
    )) {
      buffer.write(chunk);
      yield _clean(buffer.toString());
    }
  }

  String _systemPrompt(TaskMode mode, String source, String target) {
    switch (mode) {
      case TaskMode.translate:
        return 'You are a $source to $target translation assistant specialized in airplane, airport boarding, cabin, passenger, and flight-related situations.'
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
            '- For announcements or crew instructions, use clear formal language.';
      case TaskMode.summarize:
        return 'You are a concise summarization assistant. Summarize the '
            'user\'s text in clear $target. Keep only the key points. Output '
            'ONLY the summary — no preamble, no notes.';
      case TaskMode.simplify:
        return 'You are a plain-language assistant. Rewrite the user\'s text in '
            'simple, easy-to-understand $target while preserving the meaning. '
            'Output ONLY the simplified text.';
      case TaskMode.explain:
        return 'You are an explanation assistant. Explain the meaning of the '
            'user\'s word or phrase in clear $target, briefly, adding a short '
            'example if helpful. Output ONLY the explanation.';
    }
  }

  /// Strip chat-model special tokens that can leak into generated text.
  String _clean(String text) {
    var out = text;
    for (final token in const [
      '<|eot_id|>',
      '<|end_of_text|>',
      '<|im_end|>',
      '<end_of_turn>',
      '<|endoftext|>',
    ]) {
      out = out.replaceAll(token, '');
    }
    return out.trimLeft();
  }
}
