import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService — OS-level prayer time notification scheduler
//
// Schedules exact-alarm notifications that fire even when the app is killed.
// The Android system is responsible for delivery; no Dart runtime required.
//
// ─────────────────────────────────────────────────────────────────────────────
// BUG FIXES APPLIED:
//  #1  tz.setLocalLocation() now called with API timezone (e.g. Africa/Cairo)
//      → Fixes 2-3 hour delay for Egyptian users (tz.local was defaulting to UTC)
//  #2  Channel delete+recreate before each schedule
//      → Fixes Adhan sound not updating after user changes it in Settings
//  #3  fullScreenIntent: true
//      → Wakes screen like an alarm (was false — screen stayed off)
//  #4  Next-day scheduling when all today's prayers have passed
//      → Fixes "no Fajr notification" when app is killed after Isha
//  #5  Stale cache date handling: adjusts date to today/tomorrow
//      → Fixes 0 scheduled notifications when cache is from yesterday
//  #6  Exact alarm permission guard before zonedSchedule
//      → Falls back to inexact+warning instead of silent crash on Android 12+
//  #7  Notification tap handler (onDidReceiveNotificationResponse)
//      → Tapping notification now opens/resumes the app correctly
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool _initFailed = false;
  static bool _exactAlarmPermissionGranted = false;

  // Notification IDs — fixed per prayer so rescheduling replaces old ones.
  // IDs 101-105 = today's prayers, 111-115 = tomorrow's fallback prayers.
  static const int _fajrId = 101;
  static const int _dhuhrId = 102;
  static const int _asrId = 103;
  static const int _maghribId = 104;
  static const int _ishaId = 105;

  // Tomorrow fallback IDs (used when all today's prayers have passed)
  static const int _fajrNextId = 111;
  static const int _dhuhrNextId = 112;
  static const int _asrNextId = 113;
  static const int _maghribNextId = 114;
  static const int _ishaNextId = 115;

  static const String _channelId = 'prayer_times_channel';
  static const String _channelName = 'Prayer Times';
  static const String _channelDesc =
      'Azan notifications for daily prayer times';

  static bool get isInitialized => _isInitialized;
  static bool get initFailed => _initFailed;
  static bool get exactAlarmPermissionGranted => _exactAlarmPermissionGranted;

  // ── INIT ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_isInitialized || _initFailed) return;
    try {
      // 1. Load timezone database.
      //    tz.setLocalLocation() is called later in schedulePrayerNotifications()
      //    using the IANA timezone from the Aladhan API (e.g. "Africa/Cairo").
      //    We do NOT set it here because we don't know the timezone at boot time.
      tz_data.initializeTimeZones();

      // 2. Initialize plugin with notification tap handler
      //    BUG FIX #7: onDidReceiveNotificationResponse opens the app
      //    when the user taps a prayer notification.
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            _onNotificationTappedBackground,
      );

      // 3. Default channel (fallback — per-sound channels created in schedulePrayerNotifications)
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      // 4. Request permissions
      await androidPlugin?.requestNotificationsPermission();

      // BUG FIX #6: Check exact alarm permission and store result
      final exactResult = await androidPlugin?.requestExactAlarmsPermission();
      _exactAlarmPermissionGranted = exactResult ?? false;
      developer.log(
        'Exact alarm permission: ${_exactAlarmPermissionGranted ? "GRANTED" : "DENIED"}',
        name: 'NotificationService',
      );

      _isInitialized = true;
      developer.log(
        'NotificationService initialized.',
        name: 'NotificationService',
      );
    } catch (e, st) {
      _initFailed = true;
      developer.log(
        'NotificationService INIT FAILED.\n$e\n$st',
        name: 'NotificationService',
      );
    }
  }

  // BUG FIX #7: Notification tap callbacks ────────────────────────────────
  // Called when notification is tapped while app is in foreground/background.
  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    developer.log(
      'Notification tapped: id=${response.id} payload=${response.payload}',
      name: 'NotificationService',
    );
    // The system automatically brings the app to foreground when tapping a
    // notification. No explicit navigation needed here unless you want to
    // navigate to a specific screen (e.g. prayer times page).
    // To navigate, add: navigatorKey.currentState?.pushNamed('/prayer_times');
  }

  // Called when notification is tapped while app is terminated (background isolate).
  @pragma('vm:entry-point')
  static void _onNotificationTappedBackground(NotificationResponse response) {
    developer.log(
      'Background notification tapped: id=${response.id} payload=${response.payload}',
      name: 'NotificationService',
    );
  }

  // ── SCHEDULE ──────────────────────────────────────────────────────────────

  static Future schedulePrayerNotifications(
    PrayerTimes prayerTimes, {
    required StorageService storage,
    PrayerTimes? tomorrowPrayerTimes, // ← أضف هذا
  }) async {
    if (!_isInitialized) {
      developer.log(
        'NotificationService not ready — skipping schedule.',
        name: 'NotificationService',
      );
      return;
    }

    // ── BUG FIX #1: Set correct local timezone ────────────────────────────
    // tz.local defaults to UTC unless tz.setLocalLocation() is called.
    // Without this fix, all notifications fire 2-3 hours late for Cairo.
    final timezoneStr = prayerTimes.timezone.isNotEmpty
        ? prayerTimes.timezone
        : 'Africa/Cairo';
    try {
      tz.setLocalLocation(tz.getLocation(timezoneStr));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      } catch (_) {
        final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
        final match = tz.timeZoneDatabase.locations.values
            .cast<tz.Location?>()
            .firstWhere(
              (l) => l?.currentTimeZone.offset == offsetMs,
              orElse: () => null,
            );
        if (match != null) tz.setLocalLocation(match);
      }
    }
    developer.log(
      'Timezone set to: ${tz.local.name}',
      name: 'NotificationService',
    );

    // ── BUG FIX #5: Stale cache date correction ─────────────────────────
    // If prayerTimes.date is yesterday (or older), adjust it to today.
    // getDateTimeForPrayer uses prayerTimes.date, so a stale date means
    // ALL times resolve to the past → 0 notifications scheduled.
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tomorrowStr = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(const Duration(days: 1)));
    final effectiveTodayPrayerTimes = prayerTimes.isForToday
        ? prayerTimes
        : prayerTimes.withDate(
            todayStr,
          ); // approximate: same times, today's date

    if (!effectiveTodayPrayerTimes.isValidChronologically()) {
      developer.log(
        'Invalid prayer times — skipping.',
        name: 'NotificationService',
      );
      return;
    }
    // ───────────────────────────────────────────────────────────────────

    await cancelAllPrayerNotifications();

    // Resolve selected Adhan sound
    final savedSound = storage.getSelectedAdhanSound();
    final selectedOption = AdhanSoundOption.fromFileName(
      savedSound.isEmpty ? null : savedSound,
    );
    final rawResourceName = selectedOption.rawResourceName;
    final channelId = 'prayer_times_channel_$rawResourceName';
    final channelName = 'Prayer Times ($rawResourceName)';

    // ── BUG FIX #2: Delete + recreate channel so sound change takes effect ──
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    try {
      await androidPlugin?.deleteNotificationChannel(channelId);
    } catch (_) {}
    try {
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(rawResourceName),
          enableVibration: true,
          enableLights: true,
        ),
      );
    } catch (e) {
      developer.log('Channel creation error: $e', name: 'NotificationService');
    }

    // ── BUG FIX #6: Re-check exact alarm permission before scheduling ──────
    // Permission can be revoked in device Settings at any time.
    try {
      final canSchedule =
          await androidPlugin?.canScheduleExactNotifications() ?? false;
      _exactAlarmPermissionGranted = canSchedule;
      if (!canSchedule) {
        developer.log(
          'WARNING: SCHEDULE_EXACT_ALARM permission not granted! '
          'Notifications will use inexact timing (may fire slightly late).',
          name: 'NotificationService',
        );
      }
    } catch (_) {}

    final prayers = [
      (_fajrId, 'الفجر', 'Fajr', effectiveTodayPrayerTimes.fajr),
      (_dhuhrId, 'الظهر', 'Dhuhr', effectiveTodayPrayerTimes.dhuhr),
      (_asrId, 'العصر', 'Asr', effectiveTodayPrayerTimes.asr),
      (_maghribId, 'المغرب', 'Maghrib', effectiveTodayPrayerTimes.maghrib),
      (_ishaId, 'العشاء', 'Isha', effectiveTodayPrayerTimes.isha),
    ];

    final now = DateTime.now();
    int scheduled = 0;

    // Schedule remaining prayers for today
    for (final (id, arabic, english, timeStr) in prayers) {
      final prayerDt = effectiveTodayPrayerTimes.getDateTimeForPrayer(timeStr);
      if (prayerDt == null || !prayerDt.isAfter(now)) continue;
      final success = await _scheduleOne(
        id: id,
        arabic: arabic,
        english: english,
        scheduledTime: prayerDt,
        channelId: channelId,
        channelName: channelName,
        rawResourceName: rawResourceName,
      );
      if (success) scheduled++;
    }

    // ── BUG FIX #4: Schedule tomorrow's prayers if all today's have passed ───
    // Scenario: User's app is killed at 22:00 (after Isha). Next morning there
    // are NO scheduled notifications for Fajr. Fix: when scheduled == 0, also
    // schedule the same prayer times for TOMORROW as a close approximation
    // (prayer times change by only ~1-3 min each day).
    if (scheduled == 0) {
      developer.log(
        'All today\'s prayers have passed. Scheduling tomorrow\'s prayers as fallback.',
        name: 'NotificationService',
      );
      final tomorrowTimes =
          tomorrowPrayerTimes ??
          effectiveTodayPrayerTimes.withDate(tomorrowStr);
      final tomorrowPrayers = [
        (_fajrNextId, 'الفجر', 'Fajr', tomorrowTimes.fajr),
        (_dhuhrNextId, 'الظهر', 'Dhuhr', tomorrowTimes.dhuhr),
        (_asrNextId, 'العصر', 'Asr', tomorrowTimes.asr),
        (_maghribNextId, 'المغرب', 'Maghrib', tomorrowTimes.maghrib),
        (_ishaNextId, 'العشاء', 'Isha', tomorrowTimes.isha),
      ];
      int tScheduled = 0;
      for (final (id, arabic, english, timeStr) in tomorrowPrayers) {
        final prayerDt = tomorrowTimes.getDateTimeForPrayer(timeStr);
        if (prayerDt == null || !prayerDt.isAfter(now)) continue;
        final success = await _scheduleOne(
          id: id,
          arabic: arabic,
          english: english,
          scheduledTime: prayerDt,
          channelId: channelId,
          channelName: channelName,
          rawResourceName: rawResourceName,
        );
        if (success) tScheduled++;
      }
      developer.log(
        'Scheduled $tScheduled tomorrow prayer notification(s) '
        'for $tomorrowStr (approximate times from today).',
        name: 'NotificationService',
      );
    } else {
      developer.log(
        'Scheduled $scheduled prayer notification(s) for ${effectiveTodayPrayerTimes.date} '
        '(tz: ${tz.local.name}, sound: $rawResourceName).',
        name: 'NotificationService',
      );
    }
  }

  // ── SCHEDULE ONE ─────────────────────────────────────────────────────────────

  static Future<bool> _scheduleOne({
    required int id,
    required String arabic,
    required String english,
    required DateTime scheduledTime,
    required String channelId,
    required String channelName,
    required String rawResourceName,
  }) async {
    try {
      // tz.local is now correctly set to Africa/Cairo (or API timezone) before
      // this call, so TZDateTime.from() correctly converts local time to zoned.
      final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // BUG FIX #6: Use exact scheduling only if permission is granted,
      // otherwise fall back to inexact (alarmClock) with a warning.
      final scheduleMode = _exactAlarmPermissionGranted
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode
                .alarmClock; // alarmClock doesn't need SCHEDULE_EXACT_ALARM

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        sound: RawResourceAndroidNotificationSound(rawResourceName),
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        // BUG FIX #3: fullScreenIntent: true wakes the screen (like an alarm).
        // Previously false — screen stayed off, user never saw the notification.
        fullScreenIntent: true,
      );

      final iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$rawResourceName.mp3',
      );

      await _plugin.zonedSchedule(
        id,
        'حان وقت صلاة $arabic — الإسلاميك أوديو',
        'انقر للاستماع إلى الأذان كاملاً',
        tzTime,
        NotificationDetails(android: androidDetails, iOS: iOSDetails),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: english,
      );

      developer.log(
        'Scheduled: $english at $scheduledTime '
        '(TZ: ${tzTime.location.name}, mode: ${scheduleMode.name}, sound: $rawResourceName)',
        name: 'NotificationService',
      );
      return true;
    } catch (e) {
      developer.log(
        'Failed to schedule $english: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  // ── CANCEL ────────────────────────────────────────────────────────────────

  static Future<void> cancelAllPrayerNotifications() async {
    try {
      for (final id in [
        _fajrId,
        _dhuhrId,
        _asrId,
        _maghribId,
        _ishaId,
        _fajrNextId,
        _dhuhrNextId,
        _asrNextId,
        _maghribNextId,
        _ishaNextId,
      ]) {
        await _plugin.cancel(id);
      }
      developer.log(
        'All prayer notifications cancelled.',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log('Error cancelling: $e', name: 'NotificationService');
    }
  }

  // ── BATTERY OPTIMIZATION ─────────────────────────────────────────────────────

  static Future<void> checkAndRequestBatteryOptimization() async {
    if (!_isInitialized) return;
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
      developer.log(
        'Battery optimization bypass: ${status.name}',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Battery optimization error: $e',
        name: 'NotificationService',
      );
    }
  }
}
