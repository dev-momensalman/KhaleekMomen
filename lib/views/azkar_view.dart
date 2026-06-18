import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/azkar_controller.dart';
import 'package:islamic_audio_hub/widgets/azkar_card.dart';

class AzkarView extends StatelessWidget {
  const AzkarView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final azkarController = Provider.of<AzkarController>(context);
    final categories = azkarController.getCategories();

    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          // Category Tabs Header
          TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: categories.map((cat) {
              return Tab(
                text: _localizedCategoryName(cat, l10n),
                icon: Icon(_getCategoryIcon(cat)),
              );
            }).toList(),
          ),

          // Main View Tabs
          Expanded(
            child: TabBarView(
              children: categories.map((category) {
                final list = azkarController.getAzkar(category);

                return Column(
                  children: [
                    // Row control (Reset All)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            icon: const Icon(Icons.restart_alt_rounded, size: 18),
                            label: Text(l10n.resetAllCategory),
                            onPressed: () {
                              _showConfirmResetDialog(
                                context,
                                azkarController,
                                category,
                                l10n,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Cards List
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return AzkarCard(
                            item: item,
                            controller: azkarController,
                          );
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmResetDialog(
    BuildContext context,
    AzkarController controller,
    String category,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.resetCountersTitle),
          content: Text(
            l10n.resetCountersMessage(_localizedCategoryName(category, l10n)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () {
                controller.resetCategoryCounts(category);
                Navigator.pop(context);
              },
              child: Text(l10n.reset),
            ),
          ],
        );
      },
    );
  }

  String _localizedCategoryName(String cat, AppLocalizations l10n) {
    switch (cat.toLowerCase()) {
      case 'morning':
        return l10n.morningAzkar;
      case 'evening':
        return l10n.eveningAzkar;
      case 'sleep':
        return l10n.sleepAzkar;
      default:
        return l10n.generalAzkar;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.mode_night_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      default:
        return Icons.menu_open_rounded;
    }
  }
}
