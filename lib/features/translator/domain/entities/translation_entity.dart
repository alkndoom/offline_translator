/// Plain, dependency-free business object representing a completed translation.
class TranslationEntity {
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;

  const TranslationEntity({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
  });
}
