import 'dart:async';

import 'package:fllama/fllama.dart';
import 'package:fllama/fllama_type.dart';

import '../../core/ports/llm_engine.dart';
import '../../core/ports/model_downloader.dart';

/// llama.cpp-backed [LlmEngine] (via the `fllama` plugin). Owns the native
/// inference context; the only place that knows the runtime exists. Provisions
/// the weights through an injected [ModelDownloader], then loads them. Kept
/// alive as an app-lifetime singleton so the slow init is paid once.
class LlamaCppEngine implements LlmEngine {
  LlamaCppEngine(
    this._downloader, {
    this.contextSize = 2048,
    this.gpuLayers = 0,
  });

  final ModelDownloader _downloader;
  final int contextSize;

  /// Layers offloaded to the GPU (Metal on iOS). 0 = CPU-only (most portable).
  final int gpuLayers;

  double? _contextId;
  Completer<void>? _loading;

  @override
  bool get isReady => _contextId != null;

  @override
  Future<void> load({
    void Function(LlmLoadPhase phase, double progress)? onProgress,
  }) async {
    if (isReady) return;
    if (_loading != null) return _loading!.future;

    final completer = _loading = Completer<void>();
    StreamSubscription<Map<Object?, dynamic>>? progressSub;
    try {
      // Phase 1: provision the weights (downloads on first run if absent).
      final path = await _downloader.ensureModelFile(
        onProgress: (p) => onProgress?.call(LlmLoadPhase.downloading, p),
      );

      // Phase 2: load into the native context.
      onProgress?.call(LlmLoadPhase.loading, 0);
      if (onProgress != null) {
        // Native emits an int 0–100 under {function: 'loadProgress'}.
        progressSub = Fllama.instance()?.onTokenStream?.listen((event) {
          if (event['function'] == 'loadProgress') {
            final pct = event['result'];
            if (pct is num) {
              onProgress(
                LlmLoadPhase.loading,
                (pct / 100).clamp(0.0, 1.0).toDouble(),
              );
            }
          }
        });
      }
      final ctx = await Fllama.instance()?.initContext(
        path,
        nCtx: contextSize,
        nGpuLayers: gpuLayers,
        emitLoadProgress: onProgress != null,
      );
      final id = double.tryParse(ctx?['contextId']?.toString() ?? '');
      if (id == null || id <= 0) {
        throw StateError('Failed to initialize the llama.cpp context.');
      }
      _contextId = id;
      completer.complete();
    } catch (e, st) {
      _loading = null;
      completer.completeError(e, st);
      rethrow;
    } finally {
      await progressSub?.cancel();
    }
  }

  @override
  Stream<String> chat(
    List<LlmMessage> messages, {
    double temperature = 0.2,
    int maxTokens = 256,
    List<String> stop = const [],
  }) {
    final controller = StreamController<String>();
    StreamSubscription<Map<Object?, dynamic>>? sub;

    Future<void> run() async {
      await load();
      final id = _contextId!;
      final fllama = Fllama.instance()!;

      // Apply the GGUF's built-in chat template; fall back to a plain join.
      final prompt =
          await fllama.getFormattedChat(
            id,
            messages: messages
                .map((m) => RoleContent(role: m.role, content: m.content))
                .toList(),
          ) ??
          messages.map((m) => '${m.role}: ${m.content}').join('\n');

      // Forward incremental tokens emitted during this completion. The token
      // stream is process-wide, so callers must not run two chats concurrently
      // (the controller's runSafe re-entrancy guard already prevents that).
      sub = fllama.onTokenStream?.listen((event) {
        if (event['function'] == 'completion') {
          final token = event['result']?['token'];
          if (token is String && token.isNotEmpty && !controller.isClosed) {
            controller.add(token);
          }
        }
      });

      await fllama.completion(
        id,
        prompt: prompt,
        temperature: temperature,
        nPredict: maxTokens,
        stop: stop,
        emitRealtimeCompletion: true,
      );
    }

    run().then(
      (_) async {
        await sub?.cancel();
        await controller.close();
      },
      onError: (Object e, StackTrace st) async {
        await sub?.cancel();
        if (!controller.isClosed) {
          controller.addError(e, st);
          await controller.close();
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    final id = _contextId;
    if (id != null) {
      await Fllama.instance()?.releaseContext(id);
      _contextId = null;
    }
  }
}
