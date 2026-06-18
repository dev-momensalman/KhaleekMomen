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

        // Don't show if player is idle/inactive
        if (state.mode == AudioMode.idle || state.currentSource == null) {
          return const SizedBox.shrink();
        }

        final isAdhan = state.mode == AudioMode.adhan;
        final theme = Theme.of(context);

        return Card(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          elevation: 6,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isAdhan 
                  ? theme.colorScheme.error.withValues(alpha: 0.3) 
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Visual Indicator / Mode Icon
                    CircleAvatar(
                      backgroundColor: isAdhan
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer,
                      child: Icon(
                        _getModeIcon(state.mode),
                        color: isAdhan
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.currentSource.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            isAdhan 
                                ? AppLocalizations.of(context)!.adhanPrioritySystem 
                                : _getModeSubtitle(context, state.mode),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Locking / Playing control indicators
                    if (state.isLocked && !isAdhan) ...[
                      const Icon(Icons.lock_clock, color: Colors.orange),
                      const SizedBox(width: 8),
                    ],

                    // Media Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state.isPlaying)
                          IconButton(
                            icon: const Icon(Icons.pause_circle_filled),
                            iconSize: 36,
                            color: isAdhan ? theme.colorScheme.error : theme.colorScheme.primary,
                            onPressed: state.isLocked && !isAdhan ? null : () => audioService.pause(),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.play_circle_filled),
                            iconSize: 36,
                            color: isAdhan ? theme.colorScheme.error : theme.colorScheme.primary,
                            onPressed: state.isLocked && !isAdhan ? null : () => audioService.resume(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.stop_rounded),
                          iconSize: 28,
                          color: theme.colorScheme.onSurfaceVariant,
                          onPressed: () => audioService.stop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Position Progress indicator (Only for Quran playback)
              if (state.mode == AudioMode.quran)
                _QuranProgressBar(audioService: audioService),
            ],
          ),
        );
      },
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
            
            // Protect math bounds
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
                        _formatDuration(position),
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
