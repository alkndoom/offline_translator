/// A role-tagged message in a chat exchange with the local model.
class LlmMessage {
  /// 'system' | 'user' | 'assistant'.
  final String role;
  final String content;

  const LlmMessage(this.role, this.content);
  const LlmMessage.system(this.content) : role = 'system';
  const LlmMessage.user(this.content) : role = 'user';
}

/// Phases the engine goes through to become ready. Surfaced so the UI can
/// distinguish a one-time model download from the per-launch model load.
enum LlmLoadPhase { downloading, loading }

/// Contract for an on-device language model — the offline analog of the app's
/// shared HTTP client: one engine, owned by the composition root, borrowed by
/// any feature. Implementations wrap a native runtime (llama.cpp, MediaPipe…).
abstract class LlmEngine {
  /// Whether the model weights are loaded and ready for inference.
  bool get isReady;

  /// Makes the model ready: provisions the weights (downloading on first run if
  /// absent), then loads them into memory. Idempotent and safe to call
  /// repeatedly; concurrent callers share the same in-flight load. [onProgress]
  /// reports the current [LlmLoadPhase] and its completion as a 0–1 fraction.
  Future<void> load({
    void Function(LlmLoadPhase phase, double progress)? onProgress,
  });

  /// Streams generated text for a chat exchange. Joining the stream yields the
  /// full completion; listening incrementally enables token-by-token UI.
  Stream<String> chat(
    List<LlmMessage> messages, {
    double temperature = 0.2,
    int maxTokens = 256,
    List<String> stop = const [],
  });

  /// Releases native resources held by the engine.
  Future<void> dispose();
}
