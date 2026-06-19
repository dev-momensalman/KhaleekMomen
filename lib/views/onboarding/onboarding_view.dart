// lib/views/onboarding/onboarding_view.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingView — 4 صفحات فقط
//   0. الترحيب
//   1. إذن الموقع
//   2. أذونات الأذان (الإشعارات + التنبيه + الخلفية)
//   3. كل شيء جاهز
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingView extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingView({super.key, required this.onComplete});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _locationGranted = false;
  bool _notificationsGranted = false;
  bool _exactAlarmsGranted = false;
  bool _batteryOptGranted = false;

  late final AnimationController _heroAnimController;
  late final Animation<double> _heroScaleAnim;
  late final Animation<double> _heroFadeAnim;

  static const int _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _heroAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heroScaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _heroAnimController, curve: Curves.easeOutBack),
    );
    _heroFadeAnim = CurvedAnimation(
      parent: _heroAnimController,
      curve: Curves.easeIn,
    );
    _heroAnimController.forward();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final loc = await Permission.location.status;
    final notif = await Permission.notification.status;
    final alarm = await Permission.scheduleExactAlarm.status;
    final battery = await Permission.ignoreBatteryOptimizations.status;
    if (!mounted) return;
    setState(() {
      _locationGranted = loc.isGranted;
      _notificationsGranted = notif.isGranted;
      _exactAlarmsGranted = alarm.isGranted;
      _batteryOptGranted = battery.isGranted;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heroAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _heroAnimController.reset();
    _heroAnimController.forward();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await StorageService.setOnboardingCompleted();
    widget.onComplete();
  }

  // ── Permission Handlers ───────────────────────────────────────────────────

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    if (mounted) setState(() => _locationGranted = status.isGranted);
    if (status.isPermanentlyDenied) _showSettingsDialog();
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    if (mounted) setState(() => _notificationsGranted = status.isGranted);
    if (status.isPermanentlyDenied) _showSettingsDialog();
  }

  Future<void> _requestExactAlarms() async {
    final status = await Permission.scheduleExactAlarm.request();
    if (mounted) setState(() => _exactAlarmsGranted = status.isGranted);
  }

  Future<void> _requestBatteryOpt() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (mounted) setState(() => _batteryOptGranted = status.isGranted);
  }

  void _showSettingsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.permissionDeniedTitle),
        content: Text(l10n.permissionDeniedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(l10n.openSettings),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ───────────────────────────────────────────────────────
            SizedBox(
              height: 48,
              child: Align(
                alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _currentPage < _totalPages - 1
                      ? TextButton(
                          onPressed: _finishOnboarding,
                          child: Text(
                            l10n.skip,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // ── Pages ───────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(l10n, theme),
                  _buildLocationPage(l10n, theme),
                  _buildAdhanPermissionsPage(l10n, theme),
                  _buildDonePage(l10n, theme),
                ],
              ),
            ),

            // ── Bottom Nav ─────────────────────────────────────────────────
            _buildBottomNav(l10n, theme),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav(AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _totalPages,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? AppTheme.primaryEmerald
                      : AppTheme.primaryEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _nextPage,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentPage == _totalPages - 1
                    ? l10n.onboardFinish
                    : l10n.onboardNext,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Page 0 — الترحيب
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWelcomePage(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Hero ──────────────────────────────────────────────────────────
          FadeTransition(
            opacity: _heroFadeAnim,
            child: ScaleTransition(
              scale: _heroScaleAnim,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryEmerald, Color(0xFF1A5C4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            l10n.onboardWelcomeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 28),

          // ── Features ──────────────────────────────────────────────────────
          _FeatureCard(
            emoji: '🎙️',
            text: l10n.onboardFeatureQuran,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            emoji: '🕐',
            text: l10n.onboardFeaturePrayer,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            emoji: '📻',
            text: l10n.onboardFeatureRadio,
            theme: theme,
          ),
          const SizedBox(height: 10),
          _FeatureCard(
            emoji: '📿',
            text: l10n.onboardFeatureAzkar,
            theme: theme,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Page 1 — إذن الموقع
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLocationPage(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Hero ──────────────────────────────────────────────────────────
          FadeTransition(
            opacity: _heroFadeAnim,
            child: ScaleTransition(
              scale: _heroScaleAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.teal.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 52,
                  color: Colors.teal,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            l10n.onboardLocationTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onboardLocationSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // ── Info Card ─────────────────────────────────────────────────────
          _InfoCard(
            color: Colors.teal,
            bullets: [l10n.onboardLocationBullet1, l10n.onboardLocationBullet2],
            theme: theme,
          ),

          const SizedBox(height: 24),

          // ── Grant Button ──────────────────────────────────────────────────
          _PermissionButton(
            isGranted: _locationGranted,
            label: l10n.onboardGrantLocation,
            grantedLabel: l10n.onboardPermissionGranted,
            color: Colors.teal,
            onGrant: _requestLocation,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Page 2 — أذونات الأذان (3 في صفحة واحدة)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAdhanPermissionsPage(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Hero ──────────────────────────────────────────────────────────
          FadeTransition(
            opacity: _heroFadeAnim,
            child: ScaleTransition(
              scale: _heroScaleAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 52,
                  color: AppTheme.primaryEmerald,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            l10n.onboardAdhanTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onboardAdhanSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          // ── 3 Permission Tiles ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                _AdhanPermTile(
                  icon: Icons.notifications_rounded,
                  color: Colors.amber,
                  label: l10n.onboardNotifLabel,
                  grantLabel: l10n.onboardGrantNotif,
                  grantedLabel: l10n.onboardPermissionGranted,
                  isGranted: _notificationsGranted,
                  onGrant: _requestNotifications,
                  theme: theme,
                  showDivider: true,
                ),
                _AdhanPermTile(
                  icon: Icons.alarm_rounded,
                  color: Colors.deepOrange,
                  label: l10n.onboardAlarmLabel,
                  grantLabel: l10n.onboardGrantAlarm,
                  grantedLabel: l10n.onboardPermissionGranted,
                  isGranted: _exactAlarmsGranted,
                  onGrant: _requestExactAlarms,
                  theme: theme,
                  showDivider: true,
                ),
                _AdhanPermTile(
                  icon: Icons.battery_saver_rounded,
                  color: Colors.green,
                  label: l10n.onboardBatteryLabel,
                  grantLabel: l10n.onboardGrantBattery,
                  grantedLabel: l10n.onboardPermissionGranted,
                  isGranted: _batteryOptGranted,
                  onGrant: _requestBatteryOpt,
                  theme: theme,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Page 3 — كل شيء جاهز
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDonePage(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Hero ──────────────────────────────────────────────────────────
          FadeTransition(
            opacity: _heroFadeAnim,
            child: ScaleTransition(
              scale: _heroScaleAnim,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryEmerald, Color(0xFF1A5C4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryEmerald.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            l10n.onboardDoneTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardDoneSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 28),

          // ── Summary ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                _DoneRow(
                  icon: Icons.location_on_rounded,
                  color: Colors.teal,
                  label: l10n.onboardFeaturePrayer,
                  isGranted: _locationGranted,
                ),
                const SizedBox(height: 10),
                _DoneRow(
                  icon: Icons.notifications_rounded,
                  color: Colors.amber,
                  label: l10n.onboardDoneNotif,
                  isGranted: _notificationsGranted,
                ),
                const SizedBox(height: 10),
                _DoneRow(
                  icon: Icons.alarm_rounded,
                  color: Colors.deepOrange,
                  label: l10n.onboardDoneAlarm,
                  isGranted: _exactAlarmsGranted,
                ),
                const SizedBox(height: 10),
                _DoneRow(
                  icon: Icons.battery_saver_rounded,
                  color: Colors.green,
                  label: l10n.onboardDoneBattery,
                  isGranted: _batteryOptGranted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String text;
  final ThemeData theme;
  const _FeatureCard({
    required this.emoji,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color color;
  final List<String> bullets;
  final ThemeData theme;
  const _InfoCard({
    required this.color,
    required this.bullets,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: bullets
            .map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PermissionButton extends StatelessWidget {
  final bool isGranted;
  final String label;
  final String grantedLabel;
  final Color color;
  final VoidCallback onGrant;
  const _PermissionButton({
    required this.isGranted,
    required this.label,
    required this.grantedLabel,
    required this.color,
    required this.onGrant,
  });

  @override
  Widget build(BuildContext context) {
    if (isGranted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
          const SizedBox(width: 8),
          Text(
            grantedLabel,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onGrant,
        icon: const Icon(Icons.security_rounded, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _AdhanPermTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String grantLabel;
  final String grantedLabel;
  final bool isGranted;
  final VoidCallback onGrant;
  final ThemeData theme;
  final bool showDivider;

  const _AdhanPermTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.grantLabel,
    required this.grantedLabel,
    required this.isGranted,
    required this.onGrant,
    required this.theme,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Label
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status
              isGranted
                  ? Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 24,
                    )
                  : GestureDetector(
                      onTap: onGrant,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'تفعيل',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}

class _DoneRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isGranted;
  const _DoneRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.isGranted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Icon(
          isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: isGranted ? Colors.green : Colors.grey,
          size: 20,
        ),
      ],
    );
  }
}
