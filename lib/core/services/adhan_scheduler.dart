import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/notification_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';
import 'package:intl/intl.dart';

class AdhanScheduler extends ChangeNotifier with WidgetsBindingObserver {
  final AudioServiceWrapper _audioService;
  final StorageService _storageService;

  Timer? _prayerTimer;
  DateTime? _scheduledTime;
  String? _scheduledPrayerName; // English key — internal use only

  // BUG FIX #2: Arabic prayer names map for UI display & notification titles.
  static const Map<String, String> _arabicNames = {
    'Fajr': 'الفجر',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };

  static const String _fallbackAdhanUrl =
      'https://download.quranicaudio.com/adhan/azan_makkah.mp3';

  AdhanScheduler(this._audioService, this._storageService) {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── PUBLIC API ────────────────────────────────────────────────────────────

  Future<void> scheduleNextAdhan(PrayerTimes? prayerTimes) async {
    _cancelTimer();

    if (prayerTimes == null || !prayerTimes.isValidChronologically()) {
      developer.log(
        'Cannot schedule Adhan: PrayerTimes is null or invalid.',
        name: 'AdhanScheduler',
      );
      NotificationService.cancelAllPrayerNotifications();
      notifyListeners();
      return;
    }

    // 1. In-process Timer (foreground/background)
    _scheduleInProcessTimer(prayerTimes);

    // 2. OS notifications (works even when app is killed)
    if (_storageService.isAdhanAutoPlayEnabled()) {
      PrayerTimes? tomorrowPt;
      final tomorrowJson = _storageService.get('cached_prayer_times_tomorrow');
      if (tomorrowJson != null) {
        try {
          final tomorrowStr = DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 1)));
          final cached = PrayerTimes.fromJson(
            Map<String, dynamic>.from(tomorrowJson),
          );
          if (cached.date == tomorrowStr && cached.isValidChronologically()) {
            tomorrowPt = cached;
          }
        } catch (_) {}
      }

      await NotificationService.schedulePrayerNotifications(
        prayerTimes,
        storage: _storageService,
        tomorrowPrayerTimes: tomorrowPt,
      );
    } else {
      developer.log(
        'Adhan autoplay disabled — skipping OS notification scheduling.',
        name: 'AdhanScheduler',
      );
    }

    notifyListeners();
  }

  /// English key — used internally by timers and logs.
  DateTime? get scheduledTime => _scheduledTime;
  String? get scheduledPrayerName => _scheduledPrayerName;

  /// BUG FIX #2: Arabic name — used by HomeController for UI display.
  String? get scheduledPrayerNameArabic => _scheduledPrayerName != null
      ? _arabicNames[_scheduledPrayerName] ?? _scheduledPrayerName
      : null;

  void rescheduleFromCache() => _rescheduleAfterFired();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      developer.log(
        'App resumed — checking and recalculating Adhan schedule.',
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

  // ── IN-PROCESS TIMER ─────────────────────────────────────────────────────

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

  void _scheduleInProcessTimer(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final today = now;
    final tomorrow = now.add(const Duration(days: 1));

    PrayerTimes tomorrowTimes = prayerTimes;
    final tomorrowCachedJson = _storageService.get(
      'cached_prayer_times_tomorrow',
    );
    if (tomorrowCachedJson != null) {
      try {
        final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);
        final cached = PrayerTimes.fromJson(
          Map<String, dynamic>.from(tomorrowCachedJson),
        );
        if (cached.date == tomorrowStr && cached.isValidChronologically()) {
          tomorrowTimes = cached;
          developer.log(
            'Using actual tomorrow times for timer.',
            name: 'AdhanScheduler',
          );
        }
      } catch (_) {}
    }

    final prayers = [
      _PrayerTimeEntry('Fajr', _parseTimeOnDate(today, prayerTimes.fajr)),
      _PrayerTimeEntry('Dhuhr', _parseTimeOnDate(today, prayerTimes.dhuhr)),
      _PrayerTimeEntry('Asr', _parseTimeOnDate(today, prayerTimes.asr)),
      _PrayerTimeEntry('Maghrib', _parseTimeOnDate(today, prayerTimes.maghrib)),
      _PrayerTimeEntry('Isha', _parseTimeOnDate(today, prayerTimes.isha)),
      _PrayerTimeEntry('Fajr', _parseTimeOnDate(tomorrow, tomorrowTimes.fajr)),
      _PrayerTimeEntry(
        'Dhuhr',
        _parseTimeOnDate(tomorrow, tomorrowTimes.dhuhr),
      ),
      _PrayerTimeEntry('Asr', _parseTimeOnDate(tomorrow, tomorrowTimes.asr)),
      _PrayerTimeEntry(
        'Maghrib',
        _parseTimeOnDate(tomorrow, tomorrowTimes.maghrib),
      ),
      _PrayerTimeEntry('Isha', _parseTimeOnDate(tomorrow, tomorrowTimes.isha)),
    ];

    DateTime? nextPrayerTime;
    String? nextPrayerName;

    for (final entry in prayers) {
      final t = entry.time;
      if (t != null && t.isAfter(now)) {
        if (nextPrayerTime == null || t.isBefore(nextPrayerTime)) {
          nextPrayerTime = t;
          nextPrayerName = entry.name;
        }
      }
    }

    if (nextPrayerTime == null) {
      developer.log(
        'Diagnostic Log - [AdhanScheduler]: No upcoming prayers found today or tomorrow.',
        name: 'AdhanScheduler',
      );
      return;
    }

    _scheduledTime = nextPrayerTime;
    _scheduledPrayerName = nextPrayerName;
    final duration = nextPrayerTime.difference(now);

    // BUG FIX #2: Log shows Arabic name alongside English key
    final arabicForLog = _arabicNames[nextPrayerName] ?? nextPrayerName!;
    developer.log(
      'Diagnostic Log - [AdhanScheduler]:\n'
      ' - Current Time: $now\n'
      ' - Next Prayer: $arabicForLog ($nextPrayerName)\n'
      ' - Next Prayer Time: $nextPrayerTime\n'
      ' - Countdown Duration: $duration (${duration.inSeconds} seconds)\n'
      ' - Cache Date: ${prayerTimes.date}',
      name: 'AdhanScheduler',
    );

    _prayerTimer = Timer(duration, () => _triggerAdhan(nextPrayerName!));
  }

  // ── ADHAN PLAYBACK ────────────────────────────────────────────────────────

  void _triggerAdhan(String prayerName) {
    // BUG FIX #2: Resolve Arabic name for display purposes
    final arabicName = _arabicNames[prayerName] ?? prayerName;

    developer.log(
      'Adhan timer fired for: $arabicName ($prayerName)',
      name: 'AdhanScheduler',
    );

    final autoPlayEnabled = _storageService.isAdhanAutoPlayEnabled();
    if (!autoPlayEnabled) {
      developer.log(
        'Adhan autoplay disabled — skipping audio.',
        name: 'AdhanScheduler',
      );
      _rescheduleAfterFired();
      return;
    }

    // BUG FIX #1: Show immediate visible notification when adhan fires.
    // This guarantees a banner even when the app is in the foreground,
    // since the pre-scheduled OS alarm may be suppressed in that state.
    NotificationService.showImmediateAdhanNotification(arabicName);

    final savedFile = _storageService.getSelectedAdhanSound();
    final selectedOption = AdhanSoundOption.fromFileName(
      savedFile.isEmpty ? null : savedFile,
    );
    final adhanUrl = selectedOption.assetPath;

    _audioService
        .play(
          adhanUrl,
          AudioMode.adhan,
          title: arabicName, // BUG FIX #2: Arabic name in media control title
          subtitle: 'خليك مؤمن',
        )
        .then((_) {
          developer.log(
            'Adhan playing: ${selectedOption.displayName}',
            name: 'AdhanScheduler',
          );
        })
        .catchError((err) {
          developer.log(
            'Adhan play failed: $err — retrying with fallback.',
            name: 'AdhanScheduler',
          );
          _audioService
              .play(
                _fallbackAdhanUrl,
                AudioMode.adhan,
                title: arabicName,
                subtitle: 'خليك مؤمن',
              )
              .catchError((e) {
                developer.log(
                  'Fallback adhan also failed: $e',
                  name: 'AdhanScheduler',
                );
              });
        })
        .whenComplete(_rescheduleAfterFired);
  }

  void _rescheduleAfterFired() {
    developer.log(
      'Diagnostic Log - [AdhanScheduler]: Rescheduling after adhan completed or fired.',
      name: 'AdhanScheduler',
    );
    final cachedJson = _storageService.get('cached_prayer_times');
    if (cachedJson == null) return;
    try {
      final pt = PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
      unawaited(scheduleNextAdhan(pt));
    } catch (e) {
      developer.log(
        'Error rescheduling after fire: $e',
        name: 'AdhanScheduler',
      );
    }
  }

  // ── TIMER CLEANUP ─────────────────────────────────────────────────────────

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
  _PrayerTimeEntry(this.name, this.time);
}
