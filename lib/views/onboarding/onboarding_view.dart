import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingView — First-launch walkthrough with permission requests
//
// Shows 5 pages:
//   0. Welcome
//   1. Location permission  (prayer times + Qibla)
//   2. Notifications        (prayer time alerts)
//   3. Exact Alarms         (precise Adhan delivery)
//   4. Battery Optimization (keep Adhan reliable when screen is off)
//   5. All Done             (finish and enter app)
//
// After completion, sets StorageService.onboardingCompleted = true so
// the screen is never shown again.
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

  // Track which permissions were already granted so we can skip their requests
  bool _locationGranted = false;
  bool _notificationsGranted = false;
  bool _exactAlarmsGranted = false;
  bool _batteryOptGranted = false;

  // Animation controller for the icon on each page
  late final AnimationController _iconAnimController;
  late final Animation<double> _iconScaleAnim;

  static const int _totalPages = 6;

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScaleAnim = CurvedAnimation(
      parent: _iconAnimController,
      curve: Curves.elasticOut,
    );
    _iconAnimController.forward();
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
    _iconAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _iconAnimController.reset();
    _iconAnimController.forward();
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

  // ── Permission Request Handlers ──────────────────────────────────────────

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    setState(() => _locationGranted = status.isGranted);
    developer.log('Location permission: $status', name: 'Onboarding');
    if (status.isPermanentlyDenied) _showSettingsDialog();
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    setState(() => _notificationsGranted = status.isGranted);
    developer.log('Notification permission: $status', name: 'Onboarding');
    if (status.isPermanentlyDenied) _showSettingsDialog();
  }

  Future<void> _requestExactAlarms() async {
    final status = await Permission.scheduleExactAlarm.request();
    setState(() => _exactAlarmsGranted = status.isGranted);
    developer.log('Exact alarm permission: $status', name: 'Onboarding');
  }

  Future<void> _requestBatteryOpt() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    setState(() => _batteryOptGranted = status.isGranted);
    developer.log('Battery opt permission: $status', name: 'Onboarding');
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
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button (top right) ──────────────────────────────────
            Align(
              alignment:
                  isRtl ? Alignment.topLeft : Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    : const SizedBox(height: 40),
              ),
            ),

            // ── Page content ─────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomePage(l10n),
                  _buildPermissionPage(
                    l10n: l10n,
                    icon: Icons.location_on_rounded,
                    iconColor: Colors.teal,
                    title: l10n.onboardLocationTitle,
                    subtitle: l10n.onboardLocationSubtitle,
                    bulletPoints: [
                      l10n.onboardLocationBullet1,
                      l10n.onboardLocationBullet2,
                      l10n.onboardLocationBullet3,
                    ],
                    isGranted: _locationGranted,
                    onGrant: _requestLocation,
                    grantLabel: l10n.onboardGrantLocation,
                  ),
                  _buildPermissionPage(
                    l10n: l10n,
                    icon: Icons.notifications_rounded,
                    iconColor: Colors.amber,
                    title: l10n.onboardNotifTitle,
                    subtitle: l10n.onboardNotifSubtitle,
                    bulletPoints: [
                      l10n.onboardNotifBullet1,
                      l10n.onboardNotifBullet2,
                      l10n.onboardNotifBullet3,
                    ],
                    isGranted: _notificationsGranted,
                    onGrant: _requestNotifications,
                    grantLabel: l10n.onboardGrantNotif,
                  ),
                  _buildPermissionPage(
                    l10n: l10n,
                    icon: Icons.alarm_rounded,
                    iconColor: Colors.deepOrange,
                    title: l10n.onboardAlarmTitle,
                    subtitle: l10n.onboardAlarmSubtitle,
                    bulletPoints: [
                      l10n.onboardAlarmBullet1,
                      l10n.onboardAlarmBullet2,
                      l10n.onboardAlarmBullet3,
                    ],
                    isGranted: _exactAlarmsGranted,
                    onGrant: _requestExactAlarms,
                    grantLabel: l10n.onboardGrantAlarm,
                  ),
                  _buildPermissionPage(
                    l10n: l10n,
                    icon: Icons.battery_saver_rounded,
                    iconColor: Colors.green,
                    title: l10n.onboardBatteryTitle,
                    subtitle: l10n.onboardBatterySubtitle,
                    bulletPoints: [
                      l10n.onboardBatteryBullet1,
                      l10n.onboardBatteryBullet2,
                      l10n.onboardBatteryBullet3,
                    ],
                    isGranted: _batteryOptGranted,
                    onGrant: _requestBatteryOpt,
                    grantLabel: l10n.onboardGrantBattery,
                  ),
                  _buildDonePage(l10n),
                ],
              ),
            ),

            // ── Bottom navigation (dots + button) ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? AppTheme.primaryEmerald
                              : AppTheme.primaryEmerald.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Next / Finish button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Page builders ─────────────────────────────────────────────────────────

  Widget _buildWelcomePage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _iconScaleAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🕌',
                  style: TextStyle(fontSize: 58),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardWelcomeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          // Feature highlights
          _buildFeatureRow('🎙️', l10n.onboardFeatureQuran),
          const SizedBox(height: 10),
          _buildFeatureRow('🕐', l10n.onboardFeaturePrayer),
          const SizedBox(height: 10),
          _buildFeatureRow('📻', l10n.onboardFeatureRadio),
          const SizedBox(height: 10),
          _buildFeatureRow('📿', l10n.onboardFeatureAzkar),
        ],
      ),
    );
  }

  Widget _buildPermissionPage({
    required AppLocalizations l10n,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> bulletPoints,
    required bool isGranted,
    required VoidCallback onGrant,
    required String grantLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: ScaleTransition(
                scale: _iconScaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 50, color: iconColor),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryEmerald,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Why we need this section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboardWhyNeeded,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...bulletPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✦  ',
                              style: TextStyle(
                                  color: AppTheme.primaryEmerald,
                                  fontSize: 12)),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Grant / Already granted state
            if (isGranted)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l10n.onboardPermissionGranted,
                      style: const TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onGrant,
                  icon: const Icon(Icons.security_rounded, size: 20),
                  label: Text(grantLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryEmerald,
                    side: const BorderSide(
                        color: AppTheme.primaryEmerald, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDonePage(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _iconScaleAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✅', style: TextStyle(fontSize: 58)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardDoneTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryEmerald,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardDoneSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 28),
          // Summary of what was set up
          _buildSetupRow(
              Icons.location_on_rounded, Colors.teal, l10n.onboardFeaturePrayer,
              _locationGranted),
          const SizedBox(height: 10),
          _buildSetupRow(
              Icons.notifications_rounded, Colors.amber, l10n.onboardDoneNotif,
              _notificationsGranted),
          const SizedBox(height: 10),
          _buildSetupRow(
              Icons.alarm_rounded, Colors.deepOrange, l10n.onboardDoneAlarm,
              _exactAlarmsGranted),
          const SizedBox(height: 10),
          _buildSetupRow(
              Icons.battery_saver_rounded, Colors.green, l10n.onboardDoneBattery,
              _batteryOptGranted),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupRow(
      IconData icon, Color color, String label, bool isGranted) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Icon(
          isGranted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: isGranted ? Colors.green : Colors.grey,
          size: 20,
        ),
      ],
    );
  }
}
