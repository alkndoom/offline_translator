import 'package:get/get.dart';

import '../../features/translator/translator_pages.dart';

/// Aggregates every feature's routes into one flat, readable table.
class AppRouter {
  AppRouter._();

  static const initial = TranslatorPages.translator;

  static final List<GetPage> routes = [...TranslatorPages.routes];
}
