import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/gateways/speech_gateways.dart';

/// [SpeechRecognizer] backed by the `speech_to_text` plugin (on-device dictation).
class DeviceSpeechRecognizer implements SpeechRecognizer {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    _ready = await _stt.initialize();
    return _ready;
  }

  @override
  Stream<String> listen({required String languageTag}) {
    final controller = StreamController<String>();
    () async {
      if (!await initialize()) {
        controller.addError(StateError('Speech recognition unavailable.'));
        await controller.close();
        return;
      }
      await _stt.listen(
        onResult: (result) {
          if (!controller.isClosed) controller.add(result.recognizedWords);
        },
        // The plugin expects an underscore locale id (e.g. en_US).
        listenOptions: SpeechListenOptions(
          localeId: languageTag.replaceAll('-', '_'),
        ),
      );
      // Close the stream once the engine stops listening (pause or stop()).
      _stt.statusListener = (status) {
        if (status == 'done' || status == 'notListening') {
          if (!controller.isClosed) controller.close();
        }
      };
    }();
    return controller.stream;
  }

  @override
  Future<void> stop() => _stt.stop();
}
