import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/prayer_controller.dart';
import 'package:islamic_audio_hub/core/services/qibla_service.dart';

class PrayerTimesView extends StatelessWidget {
  const PrayerTimesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final prayerController = Provider.of<PrayerController>(context);
    final times = prayerController.todayTimes;

    return RefreshIndicator(
      onRefresh: () => prayerController.fetchPrayerTimes(force: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Status Banner & Refresh
            _buildStatusHeader(context, prayerController, l10n),
            const SizedBox(height: 16),

            if (prayerController.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(36.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (prayerController.errorMessage != null && times == null)
              _buildOfflineErrorWidget(context, prayerController, l10n)
            else if (times != null) ...[
              // 2. Prayer Times Cards List
              Text(
                l10n.todaysTimings,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPrayerTimeline(context, times, l10n),
              const SizedBox(height: 24),

              // 3. Qibla Direction Card
              Text(
                l10n.qiblaDirection,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildQiblaCard(context, times, l10n),
              const SizedBox(height: 100),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(
    BuildContext context,
    PrayerController controller,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final hasTimes = controller.todayTimes != null;

    Color badgeColor = Colors.red;
    String statusText = l10n.noConnectionOffline;
    IconData icon = Icons.error_outline_rounded;

    if (hasTimes) {
      if (controller.isOfflineUsingCache) {
        badgeColor = Colors.amber.shade800;
        statusText = l10n.cachedOfflineData;
        icon = Icons.cloud_off_rounded;
      } else {
        badgeColor = theme.colorScheme.primary;
        statusText = l10n.liveApiSynced;
        icon = Icons.cloud_done_rounded;
      }
    }

    return Card(
      elevation: 0,
      color: badgeColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: badgeColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasTimes)
                    Text(
                      l10n.region(controller.todayTimes!.timezone),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.my_location_rounded),
              tooltip: l10n.updateCoordinates,
              onPressed: () => controller.fetchPrayerTimes(force: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineErrorWidget(
    BuildContext context,
    PrayerController controller,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              l10n.prayerTimesUnavailable,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage ?? l10n.prayerTimesDefaultError,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retryFetching),
              onPressed: () => controller.fetchPrayerTimes(force: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeline(
    BuildContext context,
    dynamic times,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    final list = [
      _PrayerItem(l10n.fajr, times.fajr, Icons.wb_twighlight),
      _PrayerItem(l10n.sunrise, times.sunrise, Icons.wb_sunny_outlined),
      _PrayerItem(l10n.dhuhr, times.dhuhr, Icons.wb_sunny_rounded),
      _PrayerItem(l10n.asr, times.asr, Icons.filter_drama_rounded),
      _PrayerItem(l10n.maghrib, times.maghrib, Icons.nights_stay_rounded),
      _PrayerItem(l10n.isha, times.isha, Icons.dark_mode_rounded),
    ];

    // Determine current/next prayer to highlight it
    final now = DateTime.now();
    int activeIndex = -1;
    for (int i = 0; i < list.length; i++) {
      final itemTime = times.getDateTimeForPrayer(list[i].time);
      if (itemTime != null && itemTime.isAfter(now)) {
        activeIndex = i;
        break;
      }
    }

    return Column(
      children: list.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isActive = index == activeIndex;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: isActive
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  isActive ? theme.colorScheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              item.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? theme.colorScheme.primary : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.time,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isActive ? theme.colorScheme.primary : null,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: theme.colorScheme.primary),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQiblaCard(
    BuildContext context,
    dynamic times,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    if (times.latitude == null || times.longitude == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: Text(l10n.coordsUnavailable)),
        ),
      );
    }

    // FIX: QiblaService.calculateQiblaDirection is now static — no instantiation needed.
    final direction =
        QiblaService.calculateQiblaDirection(times.latitude!, times.longitude!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.explore_rounded,
                      color: theme.colorScheme.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.kaabaDirAngle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        l10n.relativeToBearing,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mathematical compass needle pointing to Kaaba angle
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Compass Circle
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 2.5,
                      ),
                    ),
                    child: const Stack(
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: Text('N',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Text('S',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Kaaba Target Marker (Rotating pointer)
                  Transform.rotate(
                    angle: direction * (3.1415926535 / 180.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: theme.colorScheme.primary,
                          size: 48,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),

                  // Kaaba Mini Icon at Center
                  Icon(
                    Icons.mosque_rounded,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              l10n.qiblaDegrees(direction.toStringAsFixed(1)),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerItem {
  final String name;
  final String time;
  final IconData icon;

  _PrayerItem(this.name, this.time, this.icon);
}
