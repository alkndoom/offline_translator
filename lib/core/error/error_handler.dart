import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_exception.dart';

/// The universal try/catch wrapper. Runs [action], routing any error either to
/// a caller-supplied [onError] or to the global [handleError] funnel, and always
/// runs [onFinally].
FutureOr<void> safeExecute(
  Future<void> Function() action, {
  String? errorMessage,
  FutureOr<void> Function(Object e, StackTrace st)? onError,
  FutureOr<void> Function()? onSuccess,
  FutureOr<void> Function()? onFinally,
}) async {
  try {
    await action();
    await onSuccess?.call();
  } catch (e, st) {
    if (onError != null) {
      await onError(e, st);
    } else {
      handleError(e, st: st, customMessage: errorMessage);
    }
  } finally {
    await onFinally?.call();
  }
}

/// The single error-presentation path: extract a human-readable message and
/// surface it through a snackbar.
void handleError(Object e, {StackTrace? st, String? customMessage}) {
  // Surface the real error for debugging instead of swallowing it.
  debugPrint('[handleError] $e');
  if (st != null) debugPrint('$st');

  final message = customMessage ?? _messageFor(e);
  Get.snackbar(
    'Error',
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
  );
}

String _messageFor(Object e) {
  if (e is AppException) return e.message;
  return 'Something went wrong.';
}
