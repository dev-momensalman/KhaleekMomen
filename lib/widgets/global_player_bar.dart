import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';

class GlobalPlayerBar extends StatelessWidget {
  const GlobalPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = Provider.of<AudioServiceWrapper>(context);

    return StreamBuilder<AudioState>(
      stream: audioService.stateStream,
      initialData: audioService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data!;

        if (state.mode == AudioMode.idle || state.currentSource == null) {
          return const SizedBox.shrink();
        }

        final isAdhan = state.mode == AudioMode.adhan;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context)!;

        // ── العنوان والـ subtitle ──────────────────────────────────
        final title = state.displayTitle?.isNotEmpty == true
            ? state.displayTitle!
            : state.currentSource.toString();

        final subtitleText = isAdhan
            ? l10n.adhanPrioritySystem
            : (state.subtitle?.isNotEmpty == true
                  ? state.subtitle!
                  : _getModeSubtitle(context, state.mode));

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAdhan
                    ? theme.colorScheme.error.withValues(alpha: 0.4)
                    : theme.colorScheme.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isAdhan
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary)
                          .withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      // ── Mode Icon ──────────────────────────────
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isAdhan
                              ? theme.colorScheme.errorContainer
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getModeIcon(state.mode),
                          color: isAdhan
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Title & Subtitle ───────────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'سورة: ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isAdhan
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  isAdhan ? '' : 'القارئ: ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    subtitleText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Lock indicator ─────────────────────────
                      if (state.isLocked && !isAdhan) ...[
                        Icon(Icons.lock_clock, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                      ],

                      // ── Controls ───────────────────────────────
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildControlButton(
                            context: context,
                            icon: state.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            isAdhan: isAdhan,
                            size: 32,
                            enabled: !(state.isLocked && !isAdhan),
                            onPressed: state.isLocked && !isAdhan
                                ? null
                                : () => state.isPlaying
                                      ? audioService.pause()
                                      : audioService.resume(),
                          ),
                          _buildControlButton(
                            context: context,
                            icon: Icons.stop_rounded,
                            isAdhan: isAdhan,
                            size: 24,
                            useVariant: true,
                            onPressed: () => audioService.stop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Progress Bar (Quran only) ────────────────────
                if (state.mode == AudioMode.quran)
                  _QuranProgressBar(audioService: audioService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required bool isAdhan,
    required double size,
    bool useVariant = false,
    bool enabled = true,
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final color = useVariant
        ? theme.colorScheme.onSurfaceVariant
        : isAdhan
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return IconButton(
      icon: Icon(icon, size: size + 4),
      color: enabled ? color : color.withValues(alpha: 0.4),
      onPressed: enabled ? onPressed : null,
      padding: const EdgeInsets.all(6),
      constraints: BoxConstraints(minWidth: size + 16, minHeight: size + 16),
    );
  }

  IconData _getModeIcon(AudioMode mode) {
    switch (mode) {
      case AudioMode.quran:
        return Icons.menu_book_rounded;
      case AudioMode.radio:
        return Icons.radio_rounded;
      case AudioMode.adhan:
        return Icons.notifications_active_rounded;
      default:
        return Icons.music_note_rounded;
    }
  }

  String _getModeSubtitle(BuildContext context, AudioMode mode) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case AudioMode.quran:
        return l10n.quranRecitation;
      case AudioMode.radio:
        return l10n.islamicRadioStation;
      case AudioMode.adhan:
        return l10n.adhanBroadcast;
      default:
        return l10n.audioPlayer;
    }
  }
}

// ─────────────────────────────────────────────────────────────
class _QuranProgressBar extends StatelessWidget {
  final AudioServiceWrapper audioService;
  const _QuranProgressBar({required this.audioService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Duration?>(
      stream: audioService.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: audioService.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final totalMs = duration.inMilliseconds.toDouble();
            final currentMs = position.inMilliseconds.toDouble();
            double progress = 0.0;
            if (totalMs > 0 && currentMs <= totalMs) {
              progress = currentMs / totalMs;
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt(position),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _fmt(duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}
