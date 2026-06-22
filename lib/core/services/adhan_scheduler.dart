import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:islamic_audio_hub/core/services/adhan_player.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/notification_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';

class AdhanScheduler extends ChangeNotifier with WidgetsBindingObserver {
  final AudioServiceWrapper _audioService;
  final StorageService _storageService;

  Timer? _prayerTimer;
  DateTime? _scheduledTime;
  String? _scheduledPrayerName;
  bool _hasBeenScheduled = false;

  static const Map<String, String> _arabicNames = {
    'Fajr': 'الفجر',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };

  static const Map<String, int> _legacyPrayerNotifIds = {
    'Fajr': 101,
    'Dhuhr': 102,
    'Asr': 103,
    'Maghrib': 104,
    'Isha': 105,
  };

  static const String _fallbackAdhanUrl =
      'https://download.quranicaudio.com/adhan/azan_makkah.mp3';

  AdhanScheduler(this._audioService, this._storageService) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> scheduleNextAdhan(
    PrayerTimes? prayerTimes, {
    PrayerTimes? tomorrowPrayerTimes,
  }) async {
    _cancelTimer();
    _hasBeenScheduled = true;

    if (prayerTimes == null) {
      developer.log(
        'Cannot schedule Adhan: PrayerTimes is null.',
        name: 'AdhanScheduler',
      );

      await NotificationService.cancelAllPrayerNotifications();
      notifyListeners();
      return;
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final effectiveTodayPrayerTimes = prayerTimes.isForToday
        ? prayerTimes
        : prayerTimes.withDate(todayStr);

    if (!effectiveTodayPrayerTimes.isValidChronologically()) {
      developer.log(
        'Cannot schedule Adhan: PrayerTimes is invalid.',
        name: 'AdhanScheduler',
      );

      await NotificationService.cancelAllPrayerNotifications();
      notifyListeners();
      return;
    }

    final effectiveTomorrowPrayerTimes =
        tomorrowPrayerTimes ?? _getCachedTomorrowPrayerTimes();

    _scheduleInProcessTimer(
      effectiveTodayPrayerTimes,
      tomorrowPrayerTimes: effectiveTomorrowPrayerTimes,
    );

    if (_storageService.isAdhanAutoPlayEnabled()) {
      await NotificationService.schedulePrayerNotifications(
        effectiveTodayPrayerTimes,
        storage: _storageService,
        tomorrowPrayerTimes: effectiveTomorrowPrayerTimes,
      );
    } else {
      developer.log(
        'Adhan autoplay disabled — cancelling OS/native notification scheduling.',
        name: 'AdhanScheduler',
      );

      await NotificationService.cancelAllPrayerNotifications();
    }

    notifyListeners();
  }

  DateTime? get scheduledTime => _scheduledTime;

  String? get scheduledPrayerName => _scheduledPrayerName;

  bool get hasBeenScheduled => _hasBeenScheduled;

  String? get scheduledPrayerNameArabic => _scheduledPrayerName != null
      ? _arabicNames[_scheduledPrayerName] ?? _scheduledPrayerName
      : null;

  void rescheduleFromCache() {
    _rescheduleAfterFired();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      developer.log(
        'App resumed — recalculating Adhan schedule.',
        name: 'AdhanScheduler',
      );

      _rescheduleAfterFired();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    super.dispose();
  }

  PrayerTimes? _getCachedTodayPrayerTimes() {
    final cachedJson = _storageService.get('cached_prayer_times');
    if (cachedJson == null) return null;

    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final cached = PrayerTimes.fromJson(
        Map<String, dynamic>.from(cachedJson),
      );

      if (cached.date == todayStr && cached.isValidChronologically()) {
        return cached;
      }

      if (cached.isValidChronologically()) {
        return cached.withDate(todayStr);
      }

      return null;
    } catch (e) {
      developer.log(
        'Failed to parse cached today prayer times: $e',
        name: 'AdhanScheduler',
      );
      return null;
    }
  }

  PrayerTimes? _getCachedTomorrowPrayerTimes() {
    final tomorrowCachedJson = _storageService.get(
      'cached_prayer_times_tomorrow',
    );

    if (tomorrowCachedJson == null) return null;

    try {
      final tomorrowStr = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 1)));

      final cached = PrayerTimes.fromJson(
        Map<String, dynamic>.from(tomorrowCachedJson),
      );

      if (cached.date == tomorrowStr && cached.isValidChronologically()) {
        return cached;
      }

      return null;
    } catch (e) {
      developer.log(
        'Failed to parse cached tomorrow prayer times: $e',
        name: 'AdhanScheduler',
      );
      return null;
    }
  }

  DateTime? _parseTimeOnDate(DateTime targetDate, String timeStr) {
    try {
      final timeParts = timeStr.split(':');
      if (timeParts.length != 2) return null;

      final hour = int.parse(timeParts[0].trim().split(' ')[0]);
      final minute = int.parse(timeParts[1].trim().split(' ')[0]);

      return DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      );
    } catch (_) {
      return null;
    }
  }

  void _scheduleInProcessTimer(
    PrayerTimes prayerTimes, {
    PrayerTimes? tomorrowPrayerTimes,
  }) {

    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final effectiveTomorrowPrayerTimes =
        tomorrowPrayerTimes ??
        prayerTimes.withDate(DateFormat('yyyy-MM-dd').format(tomorrow));

    final prayers = [
      _PrayerTimeEntry('Fajr', _parseTimeOnDate(today, prayerTimes.fajr)),
      _PrayerTimeEntry('Dhuhr', _parseTimeOnDate(today, prayerTimes.dhuhr)),
      _PrayerTimeEntry('Asr', _parseTimeOnDate(today, prayerTimes.asr)),
      _PrayerTimeEntry('Maghrib', _parseTimeOnDate(today, prayerTimes.maghrib)),
      _PrayerTimeEntry('Isha', _parseTimeOnDate(today, prayerTimes.isha)),
      _PrayerTimeEntry(
        'Fajr',
        _parseTimeOnDate(tomorrow, effectiveTomorrowPrayerTimes.fajr),
      ),
      _PrayerTimeEntry(
        'Dhuhr',
        _parseTimeOnDate(tomorrow, effectiveTomorrowPrayerTimes.dhuhr),
      ),
      _PrayerTimeEntry(
        'Asr',
        _parseTimeOnDate(tomorrow, effectiveTomorrowPrayerTimes.asr),
      ),
      _PrayerTimeEntry(
        'Maghrib',
        _parseTimeOnDate(tomorrow, effectiveTomorrowPrayerTimes.maghrib),
      ),
      _PrayerTimeEntry(
        'Isha',
        _parseTimeOnDate(tomorrow, effectiveTomorrowPrayerTimes.isha),
      ),
    ];

    DateTime? nextPrayerTime;
    String? nextPrayerName;

    for (final entry in prayers) {
      final time = entry.time;

      if (time != null && time.isAfter(now)) {
        if (nextPrayerTime == null || time.isBefore(nextPrayerTime)) {
          nextPrayerTime = time;
          nextPrayerName = entry.name;
        }
      }
    }

    if (nextPrayerTime == null || nextPrayerName == null) {
      developer.log(
        'AdhanScheduler: No upcoming prayers found.',
        name: 'AdhanScheduler',
      );
      return;
    }

    _scheduledTime = nextPrayerTime;
    _scheduledPrayerName = nextPrayerName;

    final duration = nextPrayerTime.difference(now);

    developer.log(
      'AdhanScheduler: next prayer = '
      '${_arabicNames[nextPrayerName] ?? nextPrayerName} '
      'in ${duration.inSeconds}s at $nextPrayerTime',
      name: 'AdhanScheduler',
    );

    _prayerTimer = Timer(duration, () => _triggerAdhan(nextPrayerName!));
  }

  Future<void> _triggerAdhan(String prayerName) async {
    final arabicName = _arabicNames[prayerName] ?? prayerName;

    developer.log(
      'Adhan timer fired — $arabicName ($prayerName)',
      name: 'AdhanScheduler',
    );

    if (!_storageService.isAdhanAutoPlayEnabled()) {
      developer.log(
        'Adhan autoplay disabled — skipping audio.',
        name: 'AdhanScheduler',
      );

      _rescheduleAfterFired();
      return;
    }

    if (Platform.isAndroid) {
      developer.log(
        'Android foreground timer fired. Native alarm/service is responsible for full adhan audio.',
        name: 'AdhanScheduler',
      );

      _scheduledTime = null;
      _scheduledPrayerName = null;

      Future.delayed(const Duration(minutes: 2), _rescheduleAfterFired);
      notifyListeners();
      return;
    }

    final legacyNotifId = _legacyPrayerNotifIds[prayerName];

    if (legacyNotifId != null) {
      await NotificationService.cancelById(legacyNotifId);
    }

    await NotificationService.showImmediateAdhanNotification(arabicName);

    _audioService.lockForAdhan(arabicName);

    final savedFile = _storageService.getSelectedAdhanSound();

    final selectedOption = AdhanSoundOption.fromFileName(
      savedFile.isEmpty ? null : savedFile,
    );

    var completed = false;

    Future<void> onComplete() async {
      if (completed) return;
      completed = true;

      _audioService.unlockFromAdhan();

      await NotificationService.cancelAdhanNotification();

      if (legacyNotifId != null) {
        await NotificationService.cancelById(legacyNotifId);
      }

      _rescheduleAfterFired();
    }

    try {
      await AdhanPlayer.play(
        selectedOption.assetPath,
        onComplete: () {
          unawaited(onComplete());
        },
      );
    } catch (err) {
      developer.log(
        'AdhanPlayer failed: $err — trying network fallback.',
        name: 'AdhanScheduler',
      );

      try {
        await AdhanPlayer.play(
          _fallbackAdhanUrl,
          onComplete: () {
            unawaited(onComplete());
          },
        );
      } catch (e) {
        developer.log(
          'Fallback also failed: $e — unlocking anyway.',
          name: 'AdhanScheduler',
        );

        await onComplete();
      }
    }
  }

  void _rescheduleAfterFired() {
    developer.log(
      'AdhanScheduler: rescheduling after adhan.',
      name: 'AdhanScheduler',
    );

    final todayPrayerTimes = _getCachedTodayPrayerTimes();
    final tomorrowPrayerTimes = _getCachedTomorrowPrayerTimes();

    if (todayPrayerTimes == null) {
      developer.log(
        'Cannot reschedule: no valid cached prayer times.',
        name: 'AdhanScheduler',
      );
      return;
    }

    unawaited(
      scheduleNextAdhan(
        todayPrayerTimes,
        tomorrowPrayerTimes: tomorrowPrayerTimes,
      ),
    );
  }

  void _cancelTimer() {
    _prayerTimer?.cancel();
    _prayerTimer = null;
    _scheduledTime = null;
    _scheduledPrayerName = null;
  }
}

class _PrayerTimeEntry {
  final String name;
  final DateTime? time;

  const _PrayerTimeEntry(this.name, this.time);
}
