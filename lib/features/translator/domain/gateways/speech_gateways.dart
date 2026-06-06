// Contracts over the device's speech capabilities. Both are platform/device
// gateways: the presentation layer programs to these interfaces and the
// concrete plugin-backed implementations are wired in at composition time.

/// Speech-to-text: dictate into the input field.
abstract class SpeechRecognizer {
  /// Prepares the engine and requests microphone permission. Returns whether
  /// speech recognition is available on this device.
  Future<bool> initialize();

  /// Streams recognized text (partial, then final) until [stop] is called or
  /// the speaker pauses. [languageTag] is BCP-47, e.g. 'en-US'.
  Stream<String> listen({required String languageTag});

  Future<void> stop();
}

/// Text-to-speech: read a translation aloud.
abstract class TextToSpeech {
  /// Speaks [text] in [languageTag] (BCP-47, e.g. 'tr-TR').
  Future<void> speak(String text, {required String languageTag});

  Future<void> stop();
}
