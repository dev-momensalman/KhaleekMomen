// lib/widgets/azkar_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:islamic_audio_hub/controllers/azkar_controller.dart';
import 'package:islamic_audio_hub/data/models/azkar_item.dart';

class AzkarCard extends StatelessWidget {
  final AzkarItem item;
  final AzkarController controller;

  const AzkarCard({super.key, required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = controller.getCount(item.id);
    final isDone = controller.isCompleted(item);
    final progress = item.count > 0 ? count / item.count : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDone
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isDone
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  controller.incrementCount(item);
                },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Arabic Text ─────────────────────────────────
                Text(
                  item.text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 2.0,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 10),

                // ── Translation ──────────────────────────────────
                Text(
                  item.translation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),

                // ── Source ───────────────────────────────────────
                if (item.source != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 12,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.source!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                Divider(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                  height: 1,
                ),
                const SizedBox(height: 14),

                // ── Progress + Counter ───────────────────────────
                Row(
                  children: [
                    // Progress Ring
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4,
                            backgroundColor: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDone
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                          ),
                          if (isDone)
                            Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            )
                          else
                            Text(
                              '$count',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Counter label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDone ? 'اكتمل ✓' : '$count من ${item.count}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDone
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            isDone ? 'تم بحمد الله' : 'اضغط للتسبيح',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Reset button
                    if (count > 0)
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'إعادة',
                        onPressed: () => controller.resetCount(item.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
