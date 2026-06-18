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
// ─────────────────────────────────────────────────────────────────────────────
// BUG FIXES APPLIED:
// #1 tz.setLocalLocation() called with API timezone (e.g. Africa/Cairo)
//    → Fixes 2-3 hour delay for Egyptian users
// #2 Channel delete+recreate before each schedule
//    → Fixes Adhan sound not updating after Settings change
// #3 fullScreenIntent: true
//    → Wakes screen like an alarm
// #4 Next-day scheduling when all today's prayers have passed
//    → Fixes "no Fajr notification" when app killed after Isha
// #5 Stale cache date correction
//    → Fixes 0 notifications when cache is from yesterday
// #6 (Round 2 + Round 3) Exact alarm fallback: alarmClock → inexact
//    → alarmClock (AlarmManager.setAlarmClock) ALSO needs SCHEDULE_EXACT_ALARM
//    → inexact (AlarmManager.set) needs NO special permission
//    → Fixes silent failure when SCHEDULE_EXACT_ALARM is denied on Android 12+
// #7 Notification tap handler
//    → Opens/resumes app when notification is tapped
// #8 (Round 4) Missing VIBRATE + USE_FULL_SCREEN_INTENT handled at channel level
//    → Declared in AndroidManifest.xml (see that file fix)
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool _initFailed = false;
  static bool _exactAlarmPermissionGranted = false;

  // IDs 101-105 = today, 111-115 = tomorrow fallback
  static const int _fajrId = 101;
  static const int _dhuhrId = 102;
  static const int _asrId = 103;
  static const int _maghribId = 104;
  static const int _ishaId = 105;
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
      tz_data.initializeTimeZones();

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

      await androidPlugin?.requestNotificationsPermission();

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

  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    developer.log(
      'Notification tapped: id=${response.id} payload=${response.payload}',
      name: 'NotificationService',
    );
  }

  @pragma('vm:entry-point')
  static void _onNotificationTappedBackground(NotificationResponse response) {
    developer.log(
      'Background notification tapped: id=${response.id} payload=${response.payload}',
      name: 'NotificationService',
    );
  }

  // ── SCHEDULE ──────────────────────────────────────────────────────────────

  static Future<void> schedulePrayerNotifications(
    PrayerTimes prayerTimes, {
    required StorageService storage,
    PrayerTimes? tomorrowPrayerTimes,
  }) async {
    if (!_isInitialized) {
      developer.log(
        'NotificationService not ready — skipping.',
        name: 'NotificationService',
      );
      return;
    }

    // BUG FIX #1: Set correct local timezone
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

    // BUG FIX #5: Stale cache date correction
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tomorrowStr = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(const Duration(days: 1)));
    final effectiveTodayPrayerTimes = prayerTimes.isForToday
        ? prayerTimes
        : prayerTimes.withDate(todayStr);

    if (!effectiveTodayPrayerTimes.isValidChronologically()) {
      developer.log(
        'Invalid prayer times — skipping.',
        name: 'NotificationService',
      );
      return;
    }

    await cancelAllPrayerNotifications();

    final savedSound = storage.getSelectedAdhanSound();
    final selectedOption = AdhanSoundOption.fromFileName(
      savedSound.isEmpty ? null : savedSound,
    );
    final rawResourceName = selectedOption.rawResourceName;
    final channelId = 'prayer_times_channel_$rawResourceName';
    final channelName = 'Prayer Times ($rawResourceName)';

    // BUG FIX #2: Delete + recreate channel for sound change to take effect
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

    // BUG FIX #6: Re-check exact alarm permission
    try {
      final canSchedule =
          await androidPlugin?.canScheduleExactNotifications() ?? false;
      _exactAlarmPermissionGranted = canSchedule;
      if (!canSchedule) {
        developer.log(
          'WARNING: SCHEDULE_EXACT_ALARM not granted — using inexact timing.',
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

    // BUG FIX #4: Schedule tomorrow if all today's prayers have passed
    if (scheduled == 0) {
      developer.log(
        'All today\'s prayers have passed. Scheduling tomorrow as fallback.',
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
        'Scheduled $tScheduled tomorrow prayer notification(s) for $tomorrowStr.',
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

  // ── SCHEDULE ONE ──────────────────────────────────────────────────────────

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
      final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // ── BUG FIX #6 (Round 2 + Round 3 — CRITICAL):
      // AndroidScheduleMode.alarmClock uses AlarmManager.setAlarmClock()
      // which ALSO requires SCHEDULE_EXACT_ALARM on Android 12+.
      // AndroidScheduleMode.inexact uses AlarmManager.set() which requires
      // NO special permission and fires within a system-controlled window.
      // Using alarmClock as fallback caused the same silent PlatformException
      // that the fallback was meant to prevent.
      final scheduleMode = _exactAlarmPermissionGranted
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexact; // ← FIXED: was alarmClock (WRONG)

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
        // BUG FIX #3: wakes screen. Requires USE_FULL_SCREEN_INTENT in manifest.
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
        'حان وقت صلاة $arabic — خليك مؤمن',
        'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا',
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

  // ── BATTERY OPTIMIZATION ──────────────────────────────────────────────────

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
