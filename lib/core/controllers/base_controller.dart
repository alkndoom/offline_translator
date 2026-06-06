import 'dart:async';

import 'package:get/get.dart';

import '../error/error_handler.dart';
import 'shared_state.dart';

/// Intentionally boring base controller. Owns only cross-cutting controller
/// mechanics: tag-based loading state and safe async execution. No navigator,
/// no global services — those are injected where actually needed.
abstract class BaseController<T extends SharedState> extends GetxController {
  final T state;

  BaseController(this.state);

  // Tag-based loading: tracks a set of in-flight operation tags so independent
  // operations can show spinners without clobbering each other.
  final _loadingStates = <String>[].obs;

  bool isLoading([String? tag]) =>
      tag == null ? _loadingStates.isNotEmpty : _loadingStates.contains(tag);

  void setLoading(bool value, [String? tag]) {
    final key = tag ?? 'default';
    if (value) {
      if (!_loadingStates.contains(key)) _loadingStates.add(key);
    } else {
      _loadingStates.remove(key);
    }
  }

  /// Run an async action with automatic loading + error handling and a
  /// re-entrancy guard (won't fire twice while the same tag is already loading).
  Future<void> runSafe({
    String? tag,
    String? errorMessage,
    bool silent = false,
    required Future<void> Function() action,
    FutureOr<void> Function(Object e, StackTrace st)? onError,
    FutureOr<void> Function()? onSuccess,
    FutureOr<void> Function()? onFinally,
  }) async {
    if (isLoading(tag)) return;
    await safeExecute(
      () async {
        if (!silent) setLoading(true, tag);
        await action();
      },
      errorMessage: errorMessage,
      onError: onError,
      onSuccess: onSuccess,
      onFinally: () async {
        await onFinally?.call();
        if (!silent) setLoading(false, tag);
      },
    );
  }
}
