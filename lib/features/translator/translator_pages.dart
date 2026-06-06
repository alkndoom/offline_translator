import 'package:get/get.dart';

import 'presentation/bindings/translator_binding.dart';
import 'presentation/views/translator_screen.dart';

/// Route table for the translator feature. Attaching the binding to the route
/// ties DI to navigation: visiting builds the slice; leaving tears it down.
class TranslatorPages {
  TranslatorPages._();

  static const _prefix = '/translator';
  static const translator = _prefix;

  static final routes = [
    GetPage(
      name: translator,
      page: () => const TranslatorScreen(),
      binding: TranslatorBinding(),
    ),
  ];
}
