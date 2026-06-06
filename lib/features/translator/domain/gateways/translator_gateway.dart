import '../entities/task_mode.dart';

/// Contract over the device-local language model (the local-LLM stand-in). The
/// presentation layer programs to this interface; the concrete implementation
/// is wired in at composition time.
abstract class TranslatorGateway {
  /// Runs [mode] on [input]. [source]/[target] are the selected languages
  /// (Translate goes source→target; other modes produce output in [target]).
  /// Each emission is a cumulative snapshot of the growing output text, enabling
  /// token-by-token UI.
  Stream<String> run(
    TaskMode mode,
    String input, {
    required String source,
    required String target,
  });
}
