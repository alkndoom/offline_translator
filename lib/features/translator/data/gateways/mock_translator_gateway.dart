import '../../domain/entities/translation_entity.dart';
import '../../domain/gateways/translator_gateway.dart';

/// Simulates an on-device LLM streaming tokens: emits a deterministic mock
/// translation word-by-word with a short delay. No network, no DTOs.
class MockTranslatorGateway implements TranslatorGateway {
  @override
  Stream<TranslationEntity> translate(
    String text,
    String source,
    String target,
  ) async* {
    final words = '[$target] $text'.split(' ');
    final buffer = StringBuffer();
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(word);
      yield TranslationEntity(
        sourceText: text,
        translatedText: buffer.toString(),
        sourceLang: source,
        targetLang: target,
      );
    }
  }
}
