import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  final Function(int) onTabSelected;

  const HomeView({
    super.key,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final homeController = Provider.of<HomeController>(context);
    final nextPrayer = homeController.nextPrayerName ?? l10n.prayer;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Next Prayer Countdown Card (Serene Teal Gradient)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withRed(15).withGreen(120),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  l10n.nextPrayer(nextPrayer),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  homeController.countdownText,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.liveDeviceScheduler,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Last Played Audio Resumption Section
          if (homeController.lastPlayed != null) ...[
            Text(
              l10n.recentlyPlayed,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildLastPlayedCard(context, homeController, l10n),
            const SizedBox(height: 24),
          ],

          // 3. Quick Navigation Hub
          Text(
            l10n.exploreHub,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildHubItem(
                context,
                title: l10n.nobleQuran,
                subtitle: l10n.listenToReciters,
                icon: Icons.menu_book_rounded,
                color: const Color(0xFFE0F2F1),
                iconColor: const Color(0xFF004D40),
                onTap: () => onTabSelected(1),
              ),
              _buildHubItem(
                context,
                title: l10n.islamicRadio,
                subtitle: l10n.liveStations,
                icon: Icons.radio_rounded,
                color: const Color(0xFFFFF8E1),
                iconColor: const Color(0xFFFF8F00),
                onTap: () => onTabSelected(2),
              ),
              _buildHubItem(
                context,
                title: l10n.dailyAzkar,
                subtitle: l10n.countersAndText,
                icon: Icons.brightness_medium_rounded,
                color: const Color(0xFFF3E5F5),
                iconColor: const Color(0xFF6A1B9A),
                onTap: () => onTabSelected(3),
              ),
              _buildHubItem(
                context,
                title: l10n.prayerAndQibla,
                subtitle: l10n.adhanAndQibla,
                icon: Icons.access_time_filled_rounded,
                color: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2E7D32),
                onTap: () => onTabSelected(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastPlayedCard(
    BuildContext context,
    HomeController controller,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final data = controller.lastPlayed!;
    final isPlaying = controller.isLastPlayedPlaying();
    final type = data['type'] as String;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            type == 'radio' ? Icons.radio_rounded : Icons.menu_book_rounded,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          data['title']?.toString() ?? l10n.unknownAudio,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          data['subtitle']?.toString() ?? l10n.islamicAudioHub,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            isPlaying
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_fill_rounded,
            size: 36,
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            if (isPlaying) {
              controller.audioService.stop();
            } else {
              controller.playLastPlayed();
            }
          },
        ),
      ),
    );
  }

  Widget _buildHubItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainer : color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : iconColor.withValues(alpha: 0.1),
              child: Icon(
                icon,
                color: isDark ? theme.colorScheme.primary : iconColor,
                size: 20,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
