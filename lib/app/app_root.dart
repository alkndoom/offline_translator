import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/design_system/index.dart';
import 'di/global_bindings.dart';
import 'routing/app_router.dart';

/// The app shell: theme, route table, and global DI. Holds no business logic.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Offline Translator',
      debugShowCheckedModeBanner: false,
      initialBinding: GlobalBindings(),
      theme: AppTheme.light(),
      initialRoute: AppRouter.initial,
      getPages: AppRouter.routes,
    );
  }
}
