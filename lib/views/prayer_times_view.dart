// lib/views/prayer_times_view.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:islamic_audio_hub/controllers/prayer_controller.dart';
import 'package:islamic_audio_hub/core/services/qibla_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PrayerTimesView
// ─────────────────────────────────────────────────────────────────────────────

class PrayerTimesView extends StatefulWidget {
  const PrayerTimesView({super.key});

  @override
  State<PrayerTimesView> createState() => _PrayerTimesViewState();
}

class _PrayerTimesViewState extends State<PrayerTimesView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh "current prayer" highlight every minute
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    Provider.of<PrayerController>(
      context,
      listen: false,
    ).refreshCityNameForLocale(locale);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Locale helper ─────────────────────────────────────────────────────────
  static String _tr(
    BuildContext context, {
    required String ar,
    required String en,
  }) => Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  // ── 12-hour format — respects app locale ──────────────────────────────────
  static String _to12h(String timeStr, String locale) {
    try {
      final clean = timeStr.trim().split(' ').first;
      final parts = clean.split(':');
      if (parts.length != 2) return timeStr;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final dt = DateTime(2000, 1, 1, h, m);
      return DateFormat('h:mm a', locale).format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final prayerController = Provider.of<PrayerController>(context);
    final times = prayerController.todayTimes;

    return RefreshIndicator(
      onRefresh: () async {
        await prayerController.fetchPrayerTimes(force: true);
        if (context.mounted) {
          final locale = Localizations.localeOf(context).languageCode;
          prayerController.refreshCityNameForLocale(locale);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeader(context, prayerController, l10n),
            const SizedBox(height: 12),

            if (prayerController.isLoading && times == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(36),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (prayerController.errorMessage != null && times == null)
              _buildOfflineErrorWidget(context, prayerController, l10n)
            else if (times != null) ...[
              const SizedBox(height: 10),
              // Prayer timeline
              Text(
                l10n.todaysTimings,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPrayerTimeline(context, times, l10n),
              const SizedBox(height: 24),
              // Qibla
              Text(
                l10n.qiblaDirection,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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

  // ── Status Header ─────────────────────────────────────────────────────────

  Widget _buildStatusHeader(
    BuildContext context,
    PrayerController controller,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final cityName = controller.cityName;
    final isOffline = controller.isOfflineUsingCache;
    final hasError =
        controller.errorMessage != null && controller.todayTimes == null;

    final Color accentColor = hasError
        ? theme.colorScheme.error
        : isOffline
        ? Colors.amber.shade700
        : theme.colorScheme.primary;

    final cachedLabel = _tr(context, ar: 'مخزن', en: 'Cached');
    final locatingLabel = _tr(
      context,
      ar: 'جاري تحديد الموقع...',
      en: 'Locating...',
    );

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasError
                      ? Icons.location_off_rounded
                      : isOffline
                      ? Icons.cloud_off_rounded
                      : Icons.location_on_rounded,
                  size: 15,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: cityName != null
                      ? Text(
                          cityName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hasError
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: theme.colorScheme.primary,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              locatingLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
                if (isOffline && cityName != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cachedLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.amber.shade800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.my_location_rounded),
          tooltip: l10n.updateCoordinates,
          visualDensity: VisualDensity.compact,
          onPressed: () async {
            await controller.fetchPrayerTimes(force: true);
            if (context.mounted) {
              final locale = Localizations.localeOf(context).languageCode;
              controller.refreshCityNameForLocale(locale);
            }
          },
        ),
      ],
    );
  }

  // ── Prayer Timeline ───────────────────────────────────────────────────────

  Widget _buildPrayerTimeline(
    BuildContext context,
    dynamic times,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final currentLabel = _tr(context, ar: 'الوقت الحالي', en: 'Current');
    final nextLabel = _tr(context, ar: 'القادمة', en: 'Next');

    final list = [
      _PrayerItem(l10n.fajr, times.fajr, Icons.brightness_3_rounded),
      _PrayerItem(l10n.sunrise, times.sunrise, Icons.wb_sunny_outlined),
      _PrayerItem(l10n.dhuhr, times.dhuhr, Icons.wb_sunny_rounded),
      _PrayerItem(l10n.asr, times.asr, Icons.filter_drama_rounded),
      _PrayerItem(l10n.maghrib, times.maghrib, Icons.nights_stay_rounded),
      _PrayerItem(l10n.isha, times.isha, Icons.dark_mode_rounded),
    ];

    final now = DateTime.now();
    int nextIndex = -1;
    for (int i = 0; i < list.length; i++) {
      final t = times.getDateTimeForPrayer(list[i].time);
      if (t != null && t.isAfter(now)) {
        nextIndex = i;
        break;
      }
    }
    final currentIndex = nextIndex > 0 ? nextIndex - 1 : -1;

    return Column(
      children: list.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isCurrent = index == currentIndex;
        final isNext = index == nextIndex;
        final isPast = nextIndex != -1 && index < currentIndex;

        Color cardColor;
        BorderSide borderSide;
        Color textColor;
        Color iconColor;

        if (isCurrent) {
          cardColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.4);
          borderSide = BorderSide(color: theme.colorScheme.primary, width: 1.5);
          textColor = theme.colorScheme.primary;
          iconColor = theme.colorScheme.primary;
        } else if (isNext) {
          cardColor = theme.colorScheme.secondaryContainer.withValues(
            alpha: 0.3,
          );
          borderSide = BorderSide(
            color: theme.colorScheme.secondary.withValues(alpha: 0.6),
            width: 1.5,
          );
          textColor = theme.colorScheme.secondary;
          iconColor = theme.colorScheme.secondary;
        } else if (isPast) {
          cardColor = Colors.transparent;
          borderSide = BorderSide.none;
          textColor = theme.colorScheme.onSurface.withValues(alpha: 0.38);
          iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.28);
        } else {
          cardColor = theme.colorScheme.surfaceContainerLow;
          borderSide = BorderSide.none;
          textColor = theme.colorScheme.onSurface;
          iconColor = theme.colorScheme.onSurfaceVariant;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(borderSide),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 20, color: iconColor),
            ),
            title: Text(
              item.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isCurrent || isNext
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
            subtitle: isCurrent
                ? Text(
                    currentLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  )
                : isNext
                ? Text(
                    nextLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.8),
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _to12h(item.time, locale),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ] else if (isNext) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Offline Error ─────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
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

  // ── Qibla Card ────────────────────────────────────────────────────────────

  Widget _buildQiblaCard(
    BuildContext context,
    dynamic times,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);

    if (times.latitude == null || times.longitude == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(l10n.coordsUnavailable)),
        ),
      );
    }

    // QiblaService uses the correct great-circle bearing formula
    // and works accurately for any country on Earth.
    final qiblaDirection = QiblaService.calculateQiblaDirection(
      times.latitude!,
      times.longitude!,
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.explore_rounded,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.kaabaDirAngle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
            _LiveQiblaCompass(qiblaDirection: qiblaDirection, theme: theme),
            const SizedBox(height: 16),
            Text(
              l10n.qiblaDegrees(qiblaDirection.toStringAsFixed(1)),
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

// ─────────────────────────────────────────────────────────────────────────────
// _LiveQiblaCompass
// ─────────────────────────────────────────────────────────────────────────────
//
// How it works:
//   • accelerometerEventStream  → gravity vector (tilt data)
//   • magnetometerEventStream   → magnetic field vector
//   • NXP AN4248 algorithm      → tilt-compensated magnetic heading
//
// Needle direction:
//   needleAngle = qiblaDirection - deviceHeading
//   When needleAngle ≈ 0°  →  the needle points UP  →  user faces Mecca ✓
//
// Wrap-around fix:
//   We accumulate heading using shortest-path deltas (−180° to +180°)
//   so AnimatedRotation never takes the long way around (the 330° spin bug).
//
// Alignment detection:
//   When |needleAngle| < _alignThresholdDeg (5°) we show a green "aligned"
//   state so the user knows exactly when to stop rotating.
// ─────────────────────────────────────────────────────────────────────────────

class _LiveQiblaCompass extends StatefulWidget {
  /// True geographic bearing to Mecca in degrees (0–360° CW from true north).
  /// Calculated by QiblaService using the correct great-circle formula.
  final double qiblaDirection;
  final ThemeData theme;

  const _LiveQiblaCompass({required this.qiblaDirection, required this.theme});

  @override
  State<_LiveQiblaCompass> createState() => _LiveQiblaCompassState();
}

class _LiveQiblaCompassState extends State<_LiveQiblaCompass>
    with SingleTickerProviderStateMixin {
  // ── Sensor subscriptions ──────────────────────────────────────────────────
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  // ── Low-pass filtered sensor values ──────────────────────────────────────
  // Using typed List<double> (not dynamic) to avoid runtime cast errors.
  final List<double> _accelF = [0.0, 0.0, 9.81];
  final List<double> _magF = [0.0, 0.0, 0.0];

  // Low-pass filter coefficient.
  // 0.15 at ~5 Hz (normalInterval) gives a good balance of smoothness vs lag.
  static const double _alpha = 0.15;

  // ── Heading state ─────────────────────────────────────────────────────────
  // We use ACCUMULATED turns to prevent AnimatedRotation wrap-around bugs.
  // Instead of passing angle/360 directly, we add the shortest-path delta
  // each update, so the value monotonically increases/decreases.
  double _needleTurnsAccum = 0.0; // accumulated needle turns
  double _dialTurnsAccum = 0.0; // accumulated dial turns
  double _prevNeedleAngle = 0.0; // last needle angle in degrees (0–360)
  double _prevDialAngle = 0.0; // last dial angle in degrees (0–360)

  bool _hasReading = false;
  double _calibration = 1.0; // 0.0–1.0, based on magnetic field magnitude

  // ── Alignment detection ───────────────────────────────────────────────────
  // User is "aligned" when the needle points up (≈ 0°), meaning they face Mecca.
  static const double _alignThresholdDeg = 5.0;
  bool _isAligned = false;

  // ── Alignment pulse animation ─────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Pulse animation plays when aligned
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startListening();
  }

  void _startListening() {
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval, // ~200 ms
        ).listen((e) {
          _accelF[0] += _alpha * (e.x - _accelF[0]);
          _accelF[1] += _alpha * (e.y - _accelF[1]);
          _accelF[2] += _alpha * (e.z - _accelF[2]);
          _update();
        });

    _magSub =
        magnetometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen((e) {
          _magF[0] += _alpha * (e.x - _magF[0]);
          _magF[1] += _alpha * (e.y - _magF[1]);
          _magF[2] += _alpha * (e.z - _magF[2]);
          _update();
        });
  }

  // ── Core update ───────────────────────────────────────────────────────────

  void _update() {
    final heading = _computeHeading(
      _accelF[0],
      _accelF[1],
      _accelF[2],
      _magF[0],
      _magF[1],
      _magF[2],
    );
    if (heading == null || !mounted) return;

    // ── Wrap-around fix ───────────────────────────────────────────────────
    // needle angle = how far to rotate the needle from "up" to point to Mecca
    final needleAngle = (widget.qiblaDirection - heading) % 360.0;
    // dial   angle = rotate dial opposite to device so N stays on real north
    final dialAngle = (-heading) % 360.0;

    // Shortest-path delta: normalise to (−180, +180]
    final needleDelta = _shortestDelta(_prevNeedleAngle, needleAngle);
    final dialDelta = _shortestDelta(_prevDialAngle, dialAngle);

    _needleTurnsAccum += needleDelta / 360.0;
    _dialTurnsAccum += dialDelta / 360.0;
    _prevNeedleAngle = needleAngle;
    _prevDialAngle = dialAngle;

    // ── Alignment detection ───────────────────────────────────────────────
    // needleAngle near 0° means needle points up = user faces Mecca
    final absNeedle = needleAngle <= 180 ? needleAngle : 360 - needleAngle;
    final aligned = absNeedle < _alignThresholdDeg;

    // Manage pulse animation
    if (aligned && !_isAligned) {
      _pulseController.repeat(reverse: true);
    } else if (!aligned && _isAligned) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // ── Calibration heuristic ─────────────────────────────────────────────
    // Earth's magnetic field is ~25–65 µT.
    // Outside this range indicates ferromagnetic interference.
    final norm = sqrt(
      _magF[0] * _magF[0] + _magF[1] * _magF[1] + _magF[2] * _magF[2],
    );
    final calib = (norm < 20 || norm > 80)
        ? 0.4
        : (norm < 25 || norm > 65)
        ? 0.7
        : 1.0;

    setState(() {
      _hasReading = true;
      _isAligned = aligned;
      _calibration = calib;
    });
  }

  /// Returns the shortest angular delta from [from] to [to] in (−180, +180].
  /// Both inputs are in degrees [0, 360).
  static double _shortestDelta(double from, double to) {
    double d = (to - from) % 360.0;
    if (d > 180.0) d -= 360.0;
    if (d < -180.0) d += 360.0;
    return d;
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Tilt-compensated heading — NXP AN4248 ─────────────────────────────────
  //
  // Returns magnetic north heading in degrees (0–360 CW), or null if sensors
  // are in free-fall / initialising (normA < 0.5 m/s²).
  //
  // Works correctly for any device tilt / country / geographic location.
  // The compass measures MAGNETIC north. The Qibla bearing from QiblaService
  // is relative to TRUE (geographic) north. The difference is "magnetic
  // declination", which varies from −30° (W Alaska) to +30° (E Siberia).
  // For all Arab countries it is < 5°, well within practical Qibla accuracy.
  //
  // Reference: NXP Application Note AN4248 Rev 3.
  static double? _computeHeading(
    double ax,
    double ay,
    double az, // accelerometer (m/s²)
    double mx,
    double my,
    double mz, // magnetometer (µT)
  ) {
    final normA = sqrt(ax * ax + ay * ay + az * az);
    if (normA < 0.5) return null; // free-fall or uninitialised

    // Roll φ and pitch θ from accelerometer
    final phi = atan2(ay, az);
    final theta = atan2(-ax, sqrt(ay * ay + az * az));

    final cosPhi = cos(phi);
    final sinPhi = sin(phi);
    final cosTheta = cos(theta);
    final sinTheta = sin(theta);

    // Tilt-compensated magnetic field in the horizontal plane
    final bfx = mx * cosTheta + my * sinPhi * sinTheta + mz * cosPhi * sinTheta;
    final bfy = my * cosPhi - mz * sinPhi;

    // Azimuth — CW from magnetic north
    var h = atan2(-bfy, bfx) * 180.0 / pi;
    return (h + 360.0) % 360.0;
  }

  // ── Calibration helpers ───────────────────────────────────────────────────

  Color _calibColor() {
    if (_calibration >= 0.9) return Colors.green;
    if (_calibration >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _calibLabel(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_calibration >= 0.9) {
      return isAr ? 'دقة عالية' : 'High accuracy';
    } else if (_calibration >= 0.6) {
      return isAr ? 'دقة متوسطة' : 'Medium accuracy';
    } else {
      return isAr
          ? 'تداخل — ابتعد عن الأجهزة المعدنية'
          : 'Interference — move from metal/electronics';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // First-time initialisation — no sensor reading yet
    if (!_hasReading) {
      return Column(
        children: [
          SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                Icon(
                  Icons.explore_rounded,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAr ? 'جاري تهيئة البوصلة...' : 'Initializing compass...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // ── Compass dial ─────────────────────────────────────────────────
        ScaleTransition(
          scale: _isAligned ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
          child: SizedBox(
            width: 210,
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Alignment glow ring (shown when user faces Mecca) ────
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: _isAligned ? 1.0 : 0.0,
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // ① Cardinal ring — rotates so N faces real geographic north
                AnimatedRotation(
                  turns: _dialTurns,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                  child: _DialRing(theme: theme, isAligned: _isAligned),
                ),

                // ② Inner glow circle
                Container(
                  width: 135,
                  height: 135,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (_isAligned ? Colors.green : theme.colorScheme.primary)
                            .withValues(alpha: 0.05),
                  ),
                ),

                // ③ Qibla needle — always points to Mecca
                AnimatedRotation(
                  turns: _needleTurns,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                  child: _QiblaNeedle(theme: theme, isAligned: _isAligned),
                ),

                // ④ Kaaba icon at centre
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAligned
                        ? Colors.green.shade100
                        : theme.colorScheme.secondaryContainer,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.mosque_rounded,
                    color: _isAligned
                        ? Colors.green.shade700
                        : theme.colorScheme.secondary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── Aligned label or calibration badge ───────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _isAligned
              ? _AlignedBadge(isAr: isAr, key: const ValueKey('aligned'))
              : _CalibBadge(
                  color: _calibColor(),
                  label: _calibLabel(context),
                  key: const ValueKey('calib'),
                ),
        ),
      ],
    );
  }

  // Expose accumulated turns as getters (not inline expressions)
  // so we never accidentally pass a raw modulo value to AnimatedRotation.
  double get _needleTurns => _needleTurnsAccum;
  double get _dialTurns => _dialTurnsAccum;
}

// ─────────────────────────────────────────────────────────────────────────────
// "You're aligned" badge
// ─────────────────────────────────────────────────────────────────────────────

class _AlignedBadge extends StatelessWidget {
  final bool isAr;
  const _AlignedBadge({required this.isAr, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(
            isAr ? 'أنت تواجه القبلة الآن' : 'You are facing the Qibla',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calibration badge
// ─────────────────────────────────────────────────────────────────────────────

class _CalibBadge extends StatelessWidget {
  final Color color;
  final String label;
  const _CalibBadge({required this.color, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DialRing — cardinal directions ring
// Rotates so N always faces real geographic north on screen.
// ─────────────────────────────────────────────────────────────────────────────

class _DialRing extends StatelessWidget {
  final ThemeData theme;
  final bool isAligned;
  const _DialRing({required this.theme, required this.isAligned});

  @override
  Widget build(BuildContext context) {
    final ringColor = isAligned
        ? Colors.green.withValues(alpha: 0.7)
        : theme.colorScheme.outlineVariant;

    return Container(
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tick marks every 45°
          ...List.generate(8, (i) {
            return Transform.rotate(
              angle: i * 45.0 * pi / 180.0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: i % 2 == 0 ? 2.0 : 1.0,
                  height: i % 2 == 0 ? 10.0 : 6.0,
                  color: theme.colorScheme.outline.withValues(
                    alpha: i % 2 == 0 ? 0.8 : 0.35,
                  ),
                ),
              ),
            );
          }),

          // N — always red (real north)
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 22),
              child: Text(
                'N',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Text(
                'S',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                'W',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 22),
              child: Text(
                'E',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QiblaNeedle — always points toward Mecca
// ─────────────────────────────────────────────────────────────────────────────

class _QiblaNeedle extends StatelessWidget {
  final ThemeData theme;
  final bool isAligned;
  const _QiblaNeedle({required this.theme, required this.isAligned});

  @override
  Widget build(BuildContext context) {
    final headColor = isAligned ? Colors.green : theme.colorScheme.primary;
    final tailColor = isAligned
        ? Colors.green.withValues(alpha: 0.3)
        : theme.colorScheme.outline.withValues(alpha: 0.35);

    return SizedBox(
      width: 210,
      height: 210,
      child: Center(
        child: CustomPaint(
          size: const Size(18, 110),
          painter: _NeedlePainter(
            headColor: headColor,
            tailColor: tailColor,
            dotColor: headColor,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NeedlePainter
// ─────────────────────────────────────────────────────────────────────────────

class _NeedlePainter extends CustomPainter {
  final Color headColor;
  final Color tailColor;
  final Color dotColor;

  const _NeedlePainter({
    required this.headColor,
    required this.tailColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final pivot = size.height * 0.60; // centre of compass

    // Head (↑) — points to Mecca
    canvas.drawPath(
      Path()
        ..moveTo(cx, 0)
        ..lineTo(cx + cx, pivot)
        ..lineTo(cx - cx, pivot)
        ..close(),
      Paint()..color = headColor,
    );

    // Tail (↓)
    canvas.drawPath(
      Path()
        ..moveTo(cx, size.height)
        ..lineTo(cx + cx, pivot)
        ..lineTo(cx - cx, pivot)
        ..close(),
      Paint()..color = tailColor,
    );

    // Centre pivot dot
    canvas.drawCircle(Offset(cx, pivot), 5, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) =>
      old.headColor != headColor ||
      old.tailColor != tailColor ||
      old.dotColor != dotColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// _PrayerItem model
// ─────────────────────────────────────────────────────────────────────────────

class _PrayerItem {
  final String name;
  final String time;
  final IconData icon;
  const _PrayerItem(this.name, this.time, this.icon);
}
