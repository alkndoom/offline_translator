import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/gateways/speech_gateways.dart';

/// [TextToSpeech] backed by the `flutter_tts` plugin (on-device synthesis).
class DeviceTextToSpeech implements TextToSpeech {
  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> speak(String text, {required String languageTag}) async {
    if (text.trim().isEmpty) return;
    await _tts.setLanguage(languageTag);
    await _tts.stop(); // interrupt any in-progress utterance
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
