import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../controllers/translator_controller.dart';
import '../controllers/translator_shared_state.dart';
import '../widgets/action_button.dart';
import '../widgets/history_sheet.dart';
import '../widgets/input_card.dart';
import '../widgets/language_selector.dart';
import '../widgets/local_ai_badge.dart';
import '../widgets/mode_selector.dart';
import '../widgets/model_error_view.dart';
import '../widgets/model_loading_view.dart';
import '../widgets/output_card.dart';
import '../widgets/quick_phrases.dart';
import '../widgets/scenario_selector.dart';

/// The single translator screen. Gates the content behind the model's load
/// status; holds no business logic.
class TranslatorScreen extends GetView<TranslatorController> {
  const TranslatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Offline Translator'),
        actions: [
          IconButton(
            onPressed: () => HistorySheet.show(context),
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
          const LocalAiBadge(),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          switch (controller.state.modelStatus) {
            case ModelStatus.downloading:
              return ModelLoadingView(
                label: 'Downloading model…',
                progress: controller.state.modelProgress,
              );
            case ModelStatus.loading:
              return ModelLoadingView(
                label: 'Loading model…',
                progress: controller.state.modelProgress,
              );
            case ModelStatus.error:
              return ModelErrorView(onRetry: controller.warmUpModel);
            case ModelStatus.ready:
              return const _TranslatorBody();
          }
        }),
      ),
    );
  }
}

class _TranslatorBody extends StatelessWidget {
  const _TranslatorBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          ModeSelector(),
          SizedBox(height: AppDimensions.gapMd),
          LanguageSelector(),
          SizedBox(height: AppDimensions.gapMd),
          InputCard(),
          SizedBox(height: AppDimensions.gapLg),
          ActionButton(),
          SizedBox(height: AppDimensions.gapLg),
          OutputCard(),
          SizedBox(height: AppDimensions.gapLg),
          ScenarioSelector(),
          SizedBox(height: AppDimensions.gapMd),
          QuickPhrases(),
        ],
      ),
    );
  }
}
