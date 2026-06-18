import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/controllers/radio_controller.dart';
import 'package:islamic_audio_hub/data/models/station.dart';

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
    final isPlaying = controller.isStationPlaying(station);
    final isActive = controller.isStationActive(station);

    return Card(
      color: isActive ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? theme.colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Play/Pause circular container
            InkWell(
              onTap: () {
                if (isPlaying) {
                  controller.stopStation();
                } else {
                  controller.playStation(station);
                }
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: isPlaying
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primaryContainer,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isPlaying
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Station Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive ? theme.colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        station.country,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Favorite Button
            IconButton(
              icon: Icon(
                controller.isFavorite(station)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: controller.isFavorite(station) ? Colors.red : null,
              ),
              onPressed: () => controller.toggleFavorite(station),
            ),
          ],
        ),
      ),
    );
  }
}
