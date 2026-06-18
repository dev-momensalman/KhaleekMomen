import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:islamic_audio_hub/controllers/quran_controller.dart';
import 'package:islamic_audio_hub/data/models/surah.dart';
import 'package:islamic_audio_hub/views/surah_detail_view.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';

class SurahTile extends StatelessWidget {
  final Surah surah;
  final QuranController controller;

  const SurahTile({super.key, required this.surah, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isPlaying = controller.isSurahPlaying(surah);
    final isActive = controller.isSurahActive(surah);
    final isFav = controller.isSurahFavorite(surah);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailView(surah: surah),
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : isDark
                  ? theme.colorScheme.surfaceContainer
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
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
                // ── Number Badge ───────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isActive
                        ? null
                        : isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : const Color(0xFFEFF8F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      surah.number.toString(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Names & Info ───────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // الاسم الرئيسي حسب اللغة
                          Expanded(
                            child: Text(
                              isArabic ? surah.name : surah.englishName,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : null,
                                    fontSize: 14,
                                  )
                                  .merge(
                                    isArabic ? AppTheme.uiTextStyle : null,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // الاسم العربي كـ hint صغير لو اللغة إنجليزي
                          if (!isArabic) ...[
                            const SizedBox(width: 8),
                            Text(
                              surah.name,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                    fontSize: 12,
                                  )
                                  .merge(AppTheme.uiTextStyle),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${surah.revelationType} • ${surah.numberOfAyahs} ${l10n.verses}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // ── Favorite Button ────────────────────────────────
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
                  onPressed: () => controller.toggleSurahFavorite(surah),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),

                // ── Play Button ────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    if (isPlaying) {
                      controller.pauseSurah();
                    } else {
                      controller.playSurah(surah);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isPlaying
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: isPlaying
                          ? Colors.white
                          : theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
