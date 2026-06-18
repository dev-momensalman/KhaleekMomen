import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/controllers/azkar_controller.dart';
import 'package:islamic_audio_hub/data/models/azkar_item.dart';

class AzkarCard extends StatelessWidget {
  final AzkarItem item;
  final AzkarController controller;

  const AzkarCard({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = controller.getCount(item.id);
    final isDone = controller.isCompleted(item);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: isDone 
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2) 
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone ? theme.colorScheme.primary.withValues(alpha: 0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic Text
            Text(
              item.text,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.6,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            
            // Translation
            Text(
              item.translation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Divider(height: 24),

            // Controls & Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reset Button
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reset count',
                  onPressed: count > 0 ? () => controller.resetCount(item.id) : null,
                ),

                // Interactive Counter Circular Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primaryContainer,
                    foregroundColor: isDone 
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: Icon(
                    isDone ? Icons.check_circle_rounded : Icons.plus_one_rounded,
                  ),
                  label: Text(
                    '$count / ${item.count}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: isDone ? null : () => controller.incrementCount(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
