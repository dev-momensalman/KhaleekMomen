import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/controllers/radio_controller.dart';
import 'package:islamic_audio_hub/data/models/station.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';

class StationCard extends StatelessWidget {
  final Station station;
  final RadioController controller;

  const StationCard({
    super.key,
    required this.station,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPlaying = controller.isStationPlaying(station);
    final isActive = controller.isStationActive(station);
    final isFav = controller.isFavorite(station);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {
            if (isPlaying) {
              controller.stopStation();
            } else {
              controller.playStation(station);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFE67E22).withValues(alpha: 0.08)
                  : isDark
                      ? theme.colorScheme.surfaceContainer
                      : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFE67E22).withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant
                        .withValues(alpha: 0.4),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE67E22)
                            .withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // ── Play Button ─────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isPlaying
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFE67E22),
                              Color(0xFFC0392B),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isPlaying
                        ? null
                        : isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : const Color(0xFFFEF3E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isPlaying
                        ? Icons.graphic_eq_rounded
                        : Icons.play_arrow_rounded,
                    color: isPlaying
                        ? Colors.white
                        : const Color(0xFFE67E22),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),

                // ── Station Info ────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? const Color(0xFFE67E22)
                                  : null,
                              fontSize: 14,
                            )
                            .merge(AppTheme.uiTextStyle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.public_rounded,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            station.country,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          if (isPlaying) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE67E22)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'مباشر 🔴',
                                style:
                                    theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFFE67E22),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Favorite Button ─────────────────────────────
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(isFav),
                      color: isFav
                          ? Colors.redAccent
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  onPressed: () => controller.toggleFavorite(station),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}