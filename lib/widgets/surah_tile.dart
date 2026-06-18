import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:islamic_audio_hub/controllers/quran_controller.dart';
import 'package:islamic_audio_hub/data/models/surah.dart';
import 'package:islamic_audio_hub/views/surah_detail_view.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';

class SurahTile extends StatelessWidget {
  final Surah surah;
  final QuranController controller;

  const SurahTile({
    super.key,
    required this.surah,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isPlaying = controller.isSurahPlaying(surah);
    final isActive = controller.isSurahActive(surah);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      color: isActive ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailView(surah: surah),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: isActive ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer,
          child: Text(
            surah.number.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isActive ? theme.colorScheme.onPrimary : null,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                surah.englishName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isActive ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            Text(
              surah.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: isActive ? theme.colorScheme.primary : null,
              ).merge(AppTheme.uiTextStyle), // Explicitly UI font (not Quran font)
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '${surah.revelationType} • ${surah.numberOfAyahs} ${l10n.verses}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favorite Toggle
            IconButton(
              icon: Icon(
                controller.isSurahFavorite(surah)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: controller.isSurahFavorite(surah) ? Colors.red : null,
              ),
              onPressed: () => controller.toggleSurahFavorite(surah),
            ),
            
            // Play Button
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              onPressed: () {
                if (isPlaying) {
                  controller.pauseSurah();
                } else {
                  controller.playSurah(surah);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
