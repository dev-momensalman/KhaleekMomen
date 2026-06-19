// lib/views/azkar_view.dart

import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/azkar_controller.dart';
import 'package:islamic_audio_hub/widgets/azkar_card.dart';

class AzkarView extends StatefulWidget {
  const AzkarView({super.key});

  @override
  State<AzkarView> createState() => _AzkarViewState();
}

class _AzkarViewState extends State<AzkarView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categories = ['morning', 'evening', 'sleep', 'general'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = Provider.of<AzkarController>(context);

    return Column(
      children: [
        // ── Tab Bar ───────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: theme.textTheme.labelSmall,
            padding: const EdgeInsets.all(4),
            tabs: _categories.map((cat) {
              return Tab(
                icon: Icon(_getCategoryIcon(cat), size: 18),
                text: _localizedCategoryName(cat, l10n),
                height: 52,
              );
            }).toList(),
          ),
        ),

        // ── Tab Content ───────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              return _CategoryPage(
                category: category,
                controller: controller,
                l10n: l10n,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _localizedCategoryName(String cat, AppLocalizations l10n) {
    switch (cat) {
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
    switch (cat) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.mode_night_rounded;
      case 'sleep':
        return Icons.bedtime_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

// ─── Category Page ──────────────────────────────────────────────────────────

class _CategoryPage extends StatelessWidget {
  final String category;
  final AzkarController controller;
  final AppLocalizations l10n;

  const _CategoryPage({
    required this.category,
    required this.controller,
    required this.l10n,
  });

  // ✅ FIX: اسم الفئة بالغة المختارة بدل _arabicName()
  String _localizedName(String cat) {
    switch (cat) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = controller.getAzkar(category);
    final doneCount = items.where((i) => controller.isCompleted(i)).length;
    final total = items.length;
    final allDone = total > 0 && doneCount == total;
    final progress = total > 0 ? doneCount / total : 0.0;

    return Column(
      children: [
        // ── Progress Header ──────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: allDone
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        allDone
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        size: 16,
                        color: allDone
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        // ✅ FIX: l10n بدل نصوص عربية ثابتة
                        allDone
                            ? l10n.azkarCompleted
                            : l10n.azkarProgress(doneCount, total),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: allDone
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 15),
                    label: Text(
                      l10n.resetAllCategory,
                      style: theme.textTheme.labelSmall,
                    ),
                    onPressed: () => _showConfirmResetDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary.withValues(
                      alpha: allDone ? 1.0 : 0.7,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Azkar List ───────────────────────────────────────
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    // ✅ FIX: l10n.noAzkarFound
                    l10n.noAzkarFound,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return AzkarCard(
                      item: items[index],
                      controller: controller,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showConfirmResetDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetCountersTitle),
        // ✅ FIX: _localizedName() بدل _arabicName() — اسم الفئة بلغة المستخدم
        content: Text(l10n.resetCountersMessage(_localizedName(category))),
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
      ),
    );
  }
}
