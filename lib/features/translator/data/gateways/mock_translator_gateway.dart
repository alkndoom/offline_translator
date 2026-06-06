import '../../domain/entities/task_mode.dart';
import '../../domain/gateways/translator_gateway.dart';

/// Simulates an on-device LLM streaming tokens: emits a deterministic mock
/// result word-by-word with a short delay. No network, no DTOs.
class MockTranslatorGateway implements TranslatorGateway {
  @override
  Stream<String> run(
    TaskMode mode,
    String input, {
    required String source,
    required String target,
  }) async* {
    final words = '[${mode.actionLabel} → $target] $input'.split(' ');
    final buffer = StringBuffer();
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(word);
      yield buffer.toString();
    }
  }
}
