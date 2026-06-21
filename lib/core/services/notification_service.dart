import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _nativeAdhanChannel = MethodChannel(
    'khaleek_momen/adhan_alarm',
  );

  static bool _isInitialized = false;
  static bool _initFailed = false;
  static bool _exactAlarmPermissionGranted = false;

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

  static const int _nativeBaseId = 7000;

  static const String _channelId = 'prayer_times_channel';
  static const String _channelName = 'Prayer Times';
  static const String _channelDesc =
      'Azan notifications for daily prayer times';

  static bool get isInitialized => _isInitialized;
  static bool get initFailed => _initFailed;
  static bool get exactAlarmPermissionGranted => _exactAlarmPermissionGranted;

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

      // مهم جدًا:
      // لا تطلب صلاحية الإشعارات أو exact alarm هنا.
      // init يجب أن يكون خفيفًا حتى لا يسبب تهنيج عند بداية التطبيق.
      if (Platform.isAndroid) {
        _exactAlarmPermissionGranted = await canScheduleNativeExactAlarms();
      } else {
        _exactAlarmPermissionGranted = true;
      }

      _isInitialized = true;

      developer.log(
        'NotificationService initialized silently. Exact alarm: $_exactAlarmPermissionGranted',
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

  /// اطلب الصلاحيات المهمة يدويًا من شاشة الإعدادات أو زر فحص الأذان.
  ///
  /// لا تستدعي هذه الدالة عند بداية التطبيق حتى لا تسبب تهنيج أو نوافذ مفاجئة.
  static Future<void> requestCriticalPermissions() async {
    if (!_isInitialized) {
      await init();
    }

    if (!_isInitialized) return;

    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidPlugin?.requestNotificationsPermission();

      final exactResult = await androidPlugin?.requestExactAlarmsPermission();
      _exactAlarmPermissionGranted = exactResult ?? false;

      if (Platform.isAndroid) {
        final nativeCanSchedule = await canScheduleNativeExactAlarms();
        _exactAlarmPermissionGranted =
            _exactAlarmPermissionGranted || nativeCanSchedule;
      }

      developer.log(
        'Critical notification permissions requested. Exact alarm: $_exactAlarmPermissionGranted',
        name: 'NotificationService',
      );
    } catch (e, st) {
      developer.log(
        'Request critical permissions failed.\n$e\n$st',
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

  static Future<bool> canScheduleNativeExactAlarms() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await _nativeAdhanChannel.invokeMethod<bool>(
        'canScheduleExactAlarms',
      );

      return result ?? false;
    } catch (e) {
      developer.log(
        'Native canScheduleExactAlarms failed: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  static Future<void> openNativeExactAlarmSettings() async {
    if (!Platform.isAndroid) return;

    try {
      await _nativeAdhanChannel.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      developer.log(
        'Opening native exact alarm settings failed: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<bool> isIgnoringBatteryOptimizationsNative() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await _nativeAdhanChannel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );

      return result ?? false;
    } catch (e) {
      developer.log(
        'Native battery optimization check failed: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  static Future<void> openNativeBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;

    try {
      await _nativeAdhanChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      developer.log(
        'Opening native battery settings failed: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<void> playNativeTestAdhan({
    required String rawResourceName,
    String prayerAr = 'اختبار الأذان',
  }) async {
    if (!Platform.isAndroid) return;

    try {
      await _nativeAdhanChannel.invokeMethod('playTestAdhan', {
        'resourceName': rawResourceName,
        'prayerAr': prayerAr,
      });

      developer.log(
        'Native test adhan requested: $rawResourceName',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Native test adhan failed: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<void> stopNativeAdhan() async {
    if (!Platform.isAndroid) return;

    try {
      await _nativeAdhanChannel.invokeMethod('stopAdhan');
    } catch (e) {
      developer.log(
        'Stop native adhan failed: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<void> _cancelNativeAdhanAlarms() async {
    if (!Platform.isAndroid) return;

    try {
      await _nativeAdhanChannel.invokeMethod('cancelAdhanAlarms');

      developer.log(
        'Native Android Adhan alarms cancelled.',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Cancel native Adhan alarms failed: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<bool> _scheduleNativeAdhanAlarms(
    List<Map<String, dynamic>> alarms,
  ) async {
    if (!Platform.isAndroid) return false;
    if (alarms.isEmpty) return false;

    try {
      final scheduledCount = await _nativeAdhanChannel.invokeMethod<int>(
        'scheduleAdhanAlarms',
        {'alarms': alarms},
      );

      final ok = (scheduledCount ?? 0) > 0;

      developer.log(
        'Native Android Adhan scheduling result: count=$scheduledCount / requested=${alarms.length}',
        name: 'NotificationService',
      );

      return ok;
    } catch (e, st) {
      developer.log(
        'Native Android Adhan scheduling failed. Falling back to local notifications.\n$e\n$st',
        name: 'NotificationService',
      );

      return false;
    }
  }

  static Future<void> schedulePrayerNotifications(
    PrayerTimes prayerTimes, {
    required StorageService storage,
    PrayerTimes? tomorrowPrayerTimes,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    if (!_isInitialized) {
      developer.log(
        'NotificationService not ready — skipping schedule.',
        name: 'NotificationService',
      );
      return;
    }

    final timezoneStr = prayerTimes.timezone.isNotEmpty
        ? prayerTimes.timezone
        : 'Africa/Cairo';

    try {
      tz.setLocalLocation(tz.getLocation(timezoneStr));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      } catch (_) {}
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tomorrowStr = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(const Duration(days: 1)));

    final effectiveTodayPrayerTimes = prayerTimes.isForToday
        ? prayerTimes
        : prayerTimes.withDate(todayStr);

    if (!effectiveTodayPrayerTimes.isValidChronologically()) {
      developer.log(
        'Invalid prayer times — cancelling existing schedules.',
        name: 'NotificationService',
      );

      await cancelAllPrayerNotifications();
      return;
    }

    final savedSound = storage.getSelectedAdhanSound();

    final selectedOption = AdhanSoundOption.fromFileName(
      savedSound.isEmpty ? null : savedSound,
    );

    final rawResourceName = selectedOption.rawResourceName;

    final nativeAlarms = _buildNativeAdhanAlarms(
      todayPrayerTimes: effectiveTodayPrayerTimes,
      tomorrowPrayerTimes: tomorrowPrayerTimes,
      tomorrowStr: tomorrowStr,
      rawResourceName: rawResourceName,
    );

    // مهم جدًا:
    // على Android لا نلغي الأذانات قبل الجدولة.
    // NativeAdhanScheduler هو المسؤول عن مقارنة التوقيع
    // وتحديد هل يحتاج إعادة جدولة أم لا.
    if (Platform.isAndroid && nativeAlarms.isNotEmpty) {
      final nativeScheduled = await _scheduleNativeAdhanAlarms(nativeAlarms);

      if (nativeScheduled) {
        developer.log(
          'Native Android Adhan schedule handled without pre-cancel.',
          name: 'NotificationService',
        );
        return;
      }
    }

    // لو Native فشل فقط، نلغي القديم ونستخدم Flutter fallback.
    await cancelAllPrayerNotifications();

    await _scheduleFlutterLocalNotificationsFallback(
      effectiveTodayPrayerTimes,
      tomorrowPrayerTimes: tomorrowPrayerTimes,
      tomorrowStr: tomorrowStr,
      rawResourceName: rawResourceName,
    );
  }

  static List<Map<String, dynamic>> _buildNativeAdhanAlarms({
    required PrayerTimes todayPrayerTimes,
    required PrayerTimes? tomorrowPrayerTimes,
    required String tomorrowStr,
    required String rawResourceName,
  }) {
    final now = DateTime.now();

    final alarms = <Map<String, dynamic>>[];

    final todayPrayers = [
      (_nativeBaseId + 1, 'الفجر', 'Fajr', todayPrayerTimes.fajr),
      (_nativeBaseId + 2, 'الظهر', 'Dhuhr', todayPrayerTimes.dhuhr),
      (_nativeBaseId + 3, 'العصر', 'Asr', todayPrayerTimes.asr),
      (_nativeBaseId + 4, 'المغرب', 'Maghrib', todayPrayerTimes.maghrib),
      (_nativeBaseId + 5, 'العشاء', 'Isha', todayPrayerTimes.isha),
    ];

    for (final (id, arabic, english, timeStr) in todayPrayers) {
      final prayerDt = todayPrayerTimes.getDateTimeForPrayer(timeStr);

      if (prayerDt == null || !prayerDt.isAfter(now)) continue;

      alarms.add(
        _nativeAlarmMap(
          id: id,
          arabic: arabic,
          english: english,
          prayerDt: prayerDt,
          rawResourceName: rawResourceName,
        ),
      );
    }

    final effectiveTomorrowPrayerTimes =
        tomorrowPrayerTimes ?? todayPrayerTimes.withDate(tomorrowStr);

    if (effectiveTomorrowPrayerTimes.isValidChronologically()) {
      final tomorrowPrayers = [
        (
          _nativeBaseId + 11,
          'الفجر',
          'Fajr',
          effectiveTomorrowPrayerTimes.fajr,
        ),
        (
          _nativeBaseId + 12,
          'الظهر',
          'Dhuhr',
          effectiveTomorrowPrayerTimes.dhuhr,
        ),
        (_nativeBaseId + 13, 'العصر', 'Asr', effectiveTomorrowPrayerTimes.asr),
        (
          _nativeBaseId + 14,
          'المغرب',
          'Maghrib',
          effectiveTomorrowPrayerTimes.maghrib,
        ),
        (
          _nativeBaseId + 15,
          'العشاء',
          'Isha',
          effectiveTomorrowPrayerTimes.isha,
        ),
      ];

      for (final (id, arabic, english, timeStr) in tomorrowPrayers) {
        final prayerDt = effectiveTomorrowPrayerTimes.getDateTimeForPrayer(
          timeStr,
        );

        if (prayerDt == null || !prayerDt.isAfter(now)) continue;

        alarms.add(
          _nativeAlarmMap(
            id: id,
            arabic: arabic,
            english: english,
            prayerDt: prayerDt,
            rawResourceName: rawResourceName,
          ),
        );
      }
    }

    return alarms;
  }

  static Map<String, dynamic> _nativeAlarmMap({
    required int id,
    required String arabic,
    required String english,
    required DateTime prayerDt,
    required String rawResourceName,
  }) {
    return {
      'id': id,
      'triggerAtMillis': prayerDt.millisecondsSinceEpoch,
      'prayerEn': english,
      'prayerAr': arabic,
      'resourceName': rawResourceName,
      'title': 'حان وقت صلاة $arabic — خليك مؤمن',
      'body':
          'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا',
    };
  }

  static Future<void> _scheduleFlutterLocalNotificationsFallback(
    PrayerTimes effectiveTodayPrayerTimes, {
    required PrayerTimes? tomorrowPrayerTimes,
    required String tomorrowStr,
    required String rawResourceName,
  }) async {
    final channelId = 'prayer_times_channel_$rawResourceName';
    final channelName = 'Prayer Times ($rawResourceName)';

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

    try {
      final canSchedule =
          await androidPlugin?.canScheduleExactNotifications() ?? false;

      _exactAlarmPermissionGranted = canSchedule;
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

    final effectiveTomorrowPrayerTimes =
        tomorrowPrayerTimes ?? effectiveTodayPrayerTimes.withDate(tomorrowStr);

    if (scheduled == 0 &&
        effectiveTomorrowPrayerTimes.isValidChronologically()) {
      final tomorrowPrayers = [
        (_fajrNextId, 'الفجر', 'Fajr', effectiveTomorrowPrayerTimes.fajr),
        (_dhuhrNextId, 'الظهر', 'Dhuhr', effectiveTomorrowPrayerTimes.dhuhr),
        (_asrNextId, 'العصر', 'Asr', effectiveTomorrowPrayerTimes.asr),
        (
          _maghribNextId,
          'المغرب',
          'Maghrib',
          effectiveTomorrowPrayerTimes.maghrib,
        ),
        (_ishaNextId, 'العشاء', 'Isha', effectiveTomorrowPrayerTimes.isha),
      ];

      for (final (id, arabic, english, timeStr) in tomorrowPrayers) {
        final prayerDt = effectiveTomorrowPrayerTimes.getDateTimeForPrayer(
          timeStr,
        );

        if (prayerDt == null || !prayerDt.isAfter(now)) continue;

        await _scheduleOne(
          id: id,
          arabic: arabic,
          english: english,
          scheduledTime: prayerDt,
          channelId: channelId,
          channelName: channelName,
          rawResourceName: rawResourceName,
        );
      }
    }
  }

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

      final scheduleMode = _exactAlarmPermissionGranted
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexact;

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

      return true;
    } catch (e) {
      developer.log(
        'Failed to schedule $english: $e',
        name: 'NotificationService',
      );

      return false;
    }
  }

  static Future<void> showImmediateAdhanNotification(String arabicName) async {
    if (!_isInitialized) return;

    try {
      const channelId = 'adhan_immediate_channel';

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      try {
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            'إشعار الأذان الفوري',
            description: 'يظهر عند حلول وقت الصلاة',
            importance: Importance.max,
            playSound: false,
            enableVibration: true,
            enableLights: true,
          ),
        );
      } catch (_) {}

      await _plugin.show(
        200,
        '🕌 حان وقت صلاة $arabicName',
        'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'إشعار الأذان الفوري',
            channelDescription: 'يظهر عند حلول وقت الصلاة',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            playSound: false,
            enableVibration: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            fullScreenIntent: true,
          ),
        ),
      );
    } catch (e) {
      developer.log(
        'Failed to show immediate notification: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<void> cancelAdhanNotification() async {
    if (!_isInitialized) return;

    try {
      await _plugin.cancel(200);
    } catch (e) {
      developer.log(
        'cancelAdhanNotification error: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<void> cancelById(int id) async {
    if (!_isInitialized) return;

    try {
      await _plugin.cancel(id);
    } catch (e) {
      developer.log('cancelById($id) error: $e', name: 'NotificationService');
    }
  }

  static Future<void> cancelAllPrayerNotifications() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _cancelNativeAdhanAlarms();

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
        200,
      ]) {
        await _plugin.cancel(id);
      }

      developer.log(
        'All prayer notifications cancelled.',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error cancelling notifications: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<void> checkAndRequestBatteryOptimization() async {
    if (!_isInitialized) {
      await init();
    }

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
