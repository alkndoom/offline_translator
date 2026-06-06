/// Typed exception hierarchy. A single base lets the error funnel reason about
/// failure modes and extract a user-facing message uniformly.
abstract class AppException implements Exception {
  final String message;
  final int? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => '$runtimeType: $message';
}

/// Raised when the (mock) local translation engine fails to produce a result.
class TranslationException extends AppException {
  const TranslationException({
    super.message = 'Translation failed. Please try again.',
    super.code,
  });
}

/// Fallback for anything not mapped to a more specific type.
class UnknownException extends AppException {
  const UnknownException({super.message = 'Something went wrong.', super.code});
}
