// lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  final Function(int) onTabSelected;

  const HomeView({super.key, required this.onTabSelected});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _countdownController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _countdownPulse;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
    _countdownPulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final homeController = Provider.of<HomeController>(context);
    final nextPrayer = homeController.nextPrayerName ?? l10n.prayer;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Countdown Card ──────────────────────────────
              _PrayerCountdownCard(
                nextPrayer: nextPrayer,
                countdownText: homeController.countdownText,
                pulseAnim: _countdownPulse,
                l10n: l10n,
              ),
              const SizedBox(height: 20),

              // ── 2. Last Played ─────────────────────────────────
              if (homeController.lastPlayed != null) ...[
                _SectionTitle(title: l10n.recentlyPlayed),
                const SizedBox(height: 10),
                _LastPlayedCard(controller: homeController, l10n: l10n),
                const SizedBox(height: 20),
              ],

              // ── 3. Quick Hub ───────────────────────────────────
              _SectionTitle(title: l10n.exploreHub),
              const SizedBox(height: 12),
              _HubGrid(onTabSelected: widget.onTabSelected, l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Prayer Countdown Card
// ─────────────────────────────────────────────────────────────
class _PrayerCountdownCard extends StatelessWidget {
  final String nextPrayer;
  final String countdownText;
  final Animation<double> pulseAnim;
  final AppLocalizations l10n;

  const _PrayerCountdownCard({
    required this.nextPrayer,
    required this.countdownText,
    required this.pulseAnim,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [primary, Color.lerp(primary, const Color(0xFF004D40), 0.6)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mosque_rounded,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.nextPrayer(nextPrayer),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ScaleTransition(
                    scale: pulseAnim,
                    child: Text(
                      countdownText,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        fontSize: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l10n.liveDeviceScheduler,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Last Played Card
// ─────────────────────────────────────────────────────────────
class _LastPlayedCard extends StatelessWidget {
  final HomeController controller;
  final AppLocalizations l10n;

  const _LastPlayedCard({required this.controller, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.lastPlayed!;
    final isPlaying = controller.isLastPlayedPlaying();
    final type = data['type'] as String;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            type == 'radio' ? Icons.radio_rounded : Icons.menu_book_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          data['title']?.toString() ?? l10n.unknownAudio,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            data['subtitle']?.toString() ?? l10n.islamicAudioHub,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: GestureDetector(
          onTap: () {
            if (isPlaying) {
              controller.audioService.stop();
            } else {
              controller.playLastPlayed();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPlaying
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: isPlaying
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hub Grid
// ─────────────────────────────────────────────────────────────
class _HubGrid extends StatelessWidget {
  final Function(int) onTabSelected;
  final AppLocalizations l10n;

  const _HubGrid({required this.onTabSelected, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final items = [
      _HubItemData(
        icon: Icons.menu_book_rounded,
        gradient: const [Color(0xFF1A8F7A), Color(0xFF0D5C4E)],
        bgLight: const Color(0xFFE0F2EF),
        onTap: () => onTabSelected(1),
        getTitle: (l) => l.nobleQuran,
        getSubtitle: (l) => l.listenToReciters,
      ),
      _HubItemData(
        icon: Icons.radio_rounded,
        gradient: const [Color(0xFFE67E22), Color(0xFFC0392B)],
        bgLight: const Color(0xFFFFF3E0),
        onTap: () => onTabSelected(2),
        getTitle: (l) => l.islamicRadio,
        getSubtitle: (l) => l.liveStations,
      ),
      _HubItemData(
        icon: Icons.brightness_medium_rounded,
        gradient: const [Color(0xFF8E44AD), Color(0xFF6C3483)],
        bgLight: const Color(0xFFF3E5F5),
        onTap: () => onTabSelected(3),
        getTitle: (l) => l.dailyAzkar,
        getSubtitle: (l) => l.countersAndText,
      ),
      _HubItemData(
        icon: Icons.access_time_filled_rounded,
        gradient: const [Color(0xFF27AE60), Color(0xFF1E8449)],
        bgLight: const Color(0xFFE8F5E9),
        onTap: () => onTabSelected(4),
        getTitle: (l) => l.prayerAndQibla,
        getSubtitle: (l) => l.adhanAndQibla,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.25,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _AnimatedHubItem(
          data: items[index],
          l10n: l10n,
          delay: Duration(milliseconds: 100 * index),
        );
      },
    );
  }
}

class _HubItemData {
  final IconData icon;
  final List<Color> gradient;
  final Color bgLight;
  final VoidCallback onTap;
  final String Function(AppLocalizations) getTitle;
  final String Function(AppLocalizations) getSubtitle;

  const _HubItemData({
    required this.icon,
    required this.gradient,
    required this.bgLight,
    required this.onTap,
    required this.getTitle,
    required this.getSubtitle,
  });
}

class _AnimatedHubItem extends StatefulWidget {
  final _HubItemData data;
  final AppLocalizations l10n;
  final Duration delay;

  const _AnimatedHubItem({
    required this.data,
    required this.l10n,
    required this.delay,
  });

  @override
  State<_AnimatedHubItem> createState() => _AnimatedHubItemState();
}

class _AnimatedHubItemState extends State<_AnimatedHubItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final d = widget.data;

    return ScaleTransition(
      scale: _anim,
      child: FadeTransition(
        opacity: _anim,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: d.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: d.gradient[0].withValues(alpha: 0.15),
            highlightColor: d.gradient[0].withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainer : d.bgLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                      : d.gradient[0].withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: d.gradient[0].withValues(alpha: isDark ? 0.0 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon with gradient background
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ]
                            : d.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(d.icon, color: Colors.white, size: 20),
                  ),
                  // Texts
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.getTitle(widget.l10n),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.getSubtitle(widget.l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
