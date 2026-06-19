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

  // ── 12-hour format ────────────────────────────────────────────────────────
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
              Text(
                l10n.todaysTimings,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildPrayerTimeline(context, times, l10n),
              const SizedBox(height: 24),
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

// ─── Live Qibla Compass ───────────────────────────────────────────────────────

class _LiveQiblaCompass extends StatefulWidget {
  /// True geographic bearing to Mecca (0–360° clockwise from north).
  final double qiblaDirection;
  final ThemeData theme;

  const _LiveQiblaCompass({required this.qiblaDirection, required this.theme});

  @override
  State<_LiveQiblaCompass> createState() => _LiveQiblaCompassState();
}

class _LiveQiblaCompassState extends State<_LiveQiblaCompass> {
  // Latest sensor readings
  AccelerometerEvent? _accel;
  MagnetometerEvent? _mag;

  // Low-pass filtered values for smooth rendering
  final List<double> _accelF = [0, 0, 9.8];
  final List<double> _magF = [0, 0, 0];

  // Computed heading (magnetic north, degrees CW)
  double _heading = 0.0;
  bool _hasReading = false;

  // Calibration quality (0–1)
  double _calibration = 1.0;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  // Low-pass filter coefficient (0 = no update, 1 = raw)
  // Lower = smoother but more lag. 0.1 is a good balance.
  static const double _alpha = 0.1;

  @override
  void initState() {
    super.initState();
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen((e) {
          _accel = e;
          _accelF[0] = _accelF[0] + _alpha * (e.x - _accelF[0]);
          _accelF[1] = _accelF[1] + _alpha * (e.y - _accelF[1]);
          _accelF[2] = _accelF[2] + _alpha * (e.z - _accelF[2]);
          _update();
        });

    _magSub =
        magnetometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen((e) {
          _mag = e;
          _magF[0] = _magF[0] + _alpha * (e.x - _magF[0]);
          _magF[1] = _magF[1] + _alpha * (e.y - _magF[1]);
          _magF[2] = _magF[2] + _alpha * (e.z - _magF[2]);
          _update();
        });
  }

  void _update() {
    if (_accel == null || _mag == null) return;
    final h = _computeHeading(
      _accelF[0],
      _accelF[1],
      _accelF[2],
      _magF[0],
      _magF[1],
      _magF[2],
    );
    if (h == null) return;
    if (!mounted) return;
    setState(() {
      _heading = h;
      _hasReading = true;
      // Calibration heuristic: check magnetic field magnitude
      // Earth's field is ~25–65 µT. Too low or too high = interference.
      final norm = sqrt(
        _magF[0] * _magF[0] + _magF[1] * _magF[1] + _magF[2] * _magF[2],
      );
      if (norm < 20 || norm > 80) {
        _calibration = 0.4; // low — near interference
      } else if (norm < 25 || norm > 65) {
        _calibration = 0.7; // medium
      } else {
        _calibration = 1.0; // good
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }

  // ── Tilt-compensated heading (NXP AN4248 algorithm) ───────────────────────
  //
  // Input : raw accelerometer (gravity, m/s²) + magnetometer (µT)
  // Output: magnetic north heading in degrees (0–360 CW) — or null if invalid
  //
  // Works in any device orientation (portrait, landscape, tilted).
  // Magnetic declination is NOT applied here; for most Muslim-majority
  // countries the declination is ≤ 5° which is within compass accuracy.
  // Users can visually verify by aligning with known landmarks.
  static double? _computeHeading(
    double ax,
    double ay,
    double az, // accelerometer (gravity)
    double mx,
    double my,
    double mz, // magnetometer
  ) {
    final normA = sqrt(ax * ax + ay * ay + az * az);
    if (normA < 0.5) return null; // free-fall or bad reading

    // Roll (φ) and pitch (θ) from accelerometer
    final phi = atan2(ay, az);
    final theta = atan2(-ax, sqrt(ay * ay + az * az));

    // Tilt-compensated magnetic field components in horizontal plane
    final cosPhi = cos(phi);
    final sinPhi = sin(phi);
    final cosTheta = cos(theta);
    final sinTheta = sin(theta);

    // Rotate magnetometer reading into horizontal plane
    final bfx = mx * cosTheta + my * sinPhi * sinTheta + mz * cosPhi * sinTheta;

    final bfy = my * cosPhi - mz * sinPhi;

    // Heading (azimuth) — CW from magnetic north
    var heading = atan2(-bfy, bfx) * 180.0 / pi;
    if (heading < 0) heading += 360.0;
    if (heading > 360) heading -= 360.0;
    return heading;
  }

  // ── Needle and dial turns ─────────────────────────────────────────────────
  //
  // needleTurns: needle always points to Mecca regardless of device orientation
  //   = (qiblaDirection - deviceHeading) / 360
  //
  // dialTurns: dial rotates opposite to device so "N" always faces real north
  //   = -deviceHeading / 360
  double get _needleTurns => (widget.qiblaDirection - _heading) / 360.0;
  double get _dialTurns => -_heading / 360.0;

  // ── Calibration colour and label ──────────────────────────────────────────
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
          ? 'تداخل مغناطيسي — ابتعد عن الأجهزة المعدنية'
          : 'Interference — move away from metal/electronics';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // Waiting for first reading
    if (!_hasReading) {
      return Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                Icon(
                  Icons.explore_rounded,
                  size: 44,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
        // ── Compass ─────────────────────────────────────────────────────────
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ① Cardinal ring — rotates so N faces real geographic north
              AnimatedRotation(
                turns: _dialTurns,
                duration: const Duration(milliseconds: 80),
                curve: Curves.linear,
                child: _DialRing(theme: theme),
              ),

              // ② Inner glow
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.04),
                ),
              ),

              // ③ Qibla needle — always points to Mecca
              AnimatedRotation(
                turns: _needleTurns,
                duration: const Duration(milliseconds: 80),
                curve: Curves.linear,
                child: _QiblaNeedle(theme: theme),
              ),

              // ④ Kaaba icon at centre
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.secondaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mosque_rounded,
                  color: theme.colorScheme.secondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Calibration badge ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _calibColor(),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _calibLabel(context),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Dial ring ────────────────────────────────────────────────────────────────

class _DialRing extends StatelessWidget {
  final ThemeData theme;
  const _DialRing({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
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

          // N — red
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
          // S
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
          // W
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
          // E
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

// ─── Qibla needle ─────────────────────────────────────────────────────────────

class _QiblaNeedle extends StatelessWidget {
  final ThemeData theme;
  const _QiblaNeedle({required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Center(
        child: CustomPaint(
          size: const Size(18, 104),
          painter: _NeedlePainter(
            headColor: theme.colorScheme.primary,
            tailColor: theme.colorScheme.outline.withValues(alpha: 0.35),
            dotColor: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

// ─── Needle painter ───────────────────────────────────────────────────────────

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
    final pivot = size.height * 0.60; // pivot point (centre of compass)

    // ↑ Head — points to Mecca
    final headPaint = Paint()..color = headColor;
    final headPath = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + cx, pivot)
      ..lineTo(cx - cx, pivot)
      ..close();
    canvas.drawPath(headPath, headPaint);

    // ↓ Tail
    final tailPaint = Paint()..color = tailColor;
    final tailPath = Path()
      ..moveTo(cx, size.height)
      ..lineTo(cx + cx, pivot)
      ..lineTo(cx - cx, pivot)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

    // Centre pivot dot
    canvas.drawCircle(Offset(cx, pivot), 5, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) =>
      old.headColor != headColor ||
      old.tailColor != tailColor ||
      old.dotColor != dotColor;
}

// ─── Prayer item model ────────────────────────────────────────────────────────

class _PrayerItem {
  final String name;
  final String time;
  final IconData icon;

  const _PrayerItem(this.name, this.time, this.icon);
}
