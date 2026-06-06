import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/design_system/index.dart';
import '../controllers/translator_controller.dart';

/// Bottom sheet listing past translations: tap to reuse, star to favorite,
/// delete individually, or clear all.
class HistorySheet extends StatelessWidget {
  const HistorySheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusCard),
      ),
    ),
    builder: (_) => const HistorySheet(),
  );

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TranslatorController>();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.screenPadding,
                AppDimensions.gapMd,
                AppDimensions.gapSm,
                0,
              ),
              child: Row(
                children: [
                  const Text('History', style: AppTextStyles.title),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.clearHistory,
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final items = controller.state.history;
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No translations yet.',
                      style: AppTextStyles.hint,
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.outline),
                  itemBuilder: (context, i) {
                    final entry = items[i];
                    return ListTile(
                      title: Text(
                        entry.sourceText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body,
                      ),
                      subtitle: Text(
                        '${entry.task} • ${entry.translatedText}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.hint,
                      ),
                      leading: IconButton(
                        icon: Icon(
                          entry.isFavorite ? Icons.star : Icons.star_border,
                          color: entry.isFavorite
                              ? AppColors.primary
                              : AppColors.onSurfaceMuted,
                        ),
                        onPressed: () => controller.toggleFavorite(entry),
                        tooltip: 'Favorite',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.onSurfaceMuted,
                        ),
                        onPressed: () => controller.deleteHistory(entry),
                        tooltip: 'Delete',
                      ),
                      onTap: () {
                        controller.reuseHistory(entry);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
