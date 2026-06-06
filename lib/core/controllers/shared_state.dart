import 'package:get/get.dart';

/// Base for per-feature shared state. Every shared state must define how it
/// clears itself so user data can be wiped on logout/reset.
abstract class SharedState extends GetxController {
  void reset();
}
