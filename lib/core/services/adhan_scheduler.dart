// lib/core/services/adhan_scheduler.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:islamic_audio_hub/core/services/adhan_player.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/notification_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';
import 'package:intl/intl.dart';

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

  // ✅ Map: prayer name → OS scheduled notification ID (101–105)
  static const Map<String, int> _prayerNotifIds = {
    'Fajr': 101,
    'Dhuhr': 102,
    'Asr': 103,
    'Maghrib': 104,
    'Isha': 105,
  };

  // Network fallback — only used if ALL local assets fail
  static const String _fallbackAdhanUrl =
      'https://download.quranicaudio.com/adhan/azan_makkah.mp3';

  AdhanScheduler(this._audioService, this._storageService) {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── PUBLIC API ─────────────────────────────────────────────────────────────

  Future<void> scheduleNextAdhan(PrayerTimes? prayerTimes) async {
    _cancelTimer();
    _hasBeenScheduled = true;

    if (prayerTimes == null || !prayerTimes.isValidChronologically()) {
      developer.log(
        'Cannot schedule Adhan: PrayerTimes is null or invalid.',
        name: 'AdhanScheduler',
      );
      NotificationService.cancelAllPrayerNotifications();
      notifyListeners();
      return;
    }

    // 1. In-process Timer (sync — sets _scheduledTime immediately)
    _scheduleInProcessTimer(prayerTimes);

    // 2. OS notifications (async — runs in background)
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

  DateTime? get scheduledTime => _scheduledTime;
  String? get scheduledPrayerName => _scheduledPrayerName;
  bool get hasBeenScheduled => _hasBeenScheduled;

  String? get scheduledPrayerNameArabic => _scheduledPrayerName != null
      ? _arabicNames[_scheduledPrayerName] ?? _scheduledPrayerName
      : null;

  void rescheduleFromCache() => _rescheduleAfterFired();

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

  // ── IN-PROCESS TIMER ──────────────────────────────────────────────────────

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
      'in ${duration.inSeconds}s',
      name: 'AdhanScheduler',
    );

    _prayerTimer = Timer(duration, () => _triggerAdhan(nextPrayerName!));
  }

  // ── ADHAN TRIGGER ──────────────────────────────────────────────────────────

  void _triggerAdhan(String prayerName) {
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

    // ── 1. ✅ إلغاء الإشعار المجدول لهذه الصلاة (لمنع تضارب الصوت) ──────
    // التطبيق حي = in-process timer يشغّل AdhanPlayer
    // لا داعي لصوت الـ OS notification → نلغيه قبل ما يطلع
    final notifId = _prayerNotifIds[prayerName];
    if (notifId != null) {
      NotificationService.cancelById(notifId);
      developer.log(
        'Cancelled OS scheduled notification $notifId for $prayerName',
        name: 'AdhanScheduler',
      );
    }

    // ── 2. إشعار فوري بدون صوت (banner فقط) ──────────────────────────────
    NotificationService.showImmediateAdhanNotification(arabicName);

    // ── 3. Lock AudioService (يوقف القرآن/الراديو) ────────────────────────
    _audioService.lockForAdhan(arabicName);

    // ── 4. Resolve adhan sound ─────────────────────────────────────────────
    final savedFile = _storageService.getSelectedAdhanSound();
    final selectedOption = AdhanSoundOption.fromFileName(
      savedFile.isEmpty ? null : savedFile,
    );

    // ── 5. onComplete: يُستدعى عند انتهاء الأذان (أو فشله) ───────────────
    void onComplete() {
      _audioService.unlockFromAdhan();
      NotificationService.cancelAdhanNotification(); // ID 200
      // ✅ إلغاء الإشعار المجدول لو لم يُلغَ بعد (احتياط)
      if (notifId != null) {
        NotificationService.cancelById(notifId);
      }
      _rescheduleAfterFired();
    }

    // ── 6. Play via AdhanPlayer ────────────────────────────────────────────
    AdhanPlayer.play(selectedOption.assetPath, onComplete: onComplete)
        .then((_) {
          developer.log(
            'AdhanPlayer: playing "${selectedOption.displayName}"',
            name: 'AdhanScheduler',
          );
        })
        .catchError((Object err) {
          developer.log(
            'AdhanPlayer failed: $err — trying network fallback.',
            name: 'AdhanScheduler',
          );
          // Network fallback — only if asset fails
          AdhanPlayer.play(
            _fallbackAdhanUrl,
            onComplete: onComplete,
          ).catchError((Object e) {
            developer.log(
              'Fallback also failed: $e — unlocking anyway.',
              name: 'AdhanScheduler',
            );
            // Even if everything fails, unlock and reschedule
            onComplete();
          });
        });
  }

  // ── RESCHEDULE ─────────────────────────────────────────────────────────────

  void _rescheduleAfterFired() {
    developer.log(
      'AdhanScheduler: rescheduling after adhan.',
      name: 'AdhanScheduler',
    );
    final cachedJson = _storageService.get('cached_prayer_times');
    if (cachedJson == null) return;
    try {
      final pt = PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
      unawaited(scheduleNextAdhan(pt));
    } catch (e) {
      developer.log('Error rescheduling: $e', name: 'AdhanScheduler');
    }
  }

  // ── TIMER CLEANUP ──────────────────────────────────────────────────────────

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
