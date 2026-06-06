import '../entities/translation_entity.dart';

/// Contract over the device-local translation capability (the local-LLM
/// stand-in). The presentation layer programs to this interface; the concrete
/// implementation is wired in at composition time.
abstract class TranslatorGateway {
  /// Streams the translation as it is produced. Each emission is a cumulative
  /// snapshot whose [TranslationEntity.translatedText] grows toward the final
  /// result, enabling token-by-token UI.
  Stream<TranslationEntity> translate(
    String text,
    String source,
    String target,
  );
}
