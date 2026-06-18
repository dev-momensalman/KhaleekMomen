import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/notification_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';

class AdhanScheduler extends ChangeNotifier with WidgetsBindingObserver {
  final AudioServiceWrapper _audioService;
  final StorageService _storageService;

  Timer? _prayerTimer;
  DateTime? _scheduledTime;
  String? _scheduledPrayerName;

  // Fallback remote URL used only when no local asset is selected.
  static const String _fallbackAdhanUrl =
      'https://download.quranicaudio.com/adhan/azan_makkah.mp3';

  AdhanScheduler(this._audioService, this._storageService) {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── PUBLIC API ────────────────────────────────────────────────────────────

  /// Schedules both:
  ///   1. An in-process Dart [Timer] → fires when the app is in foreground/background.
  ///   2. OS-level local notifications → fire even when the app is fully killed.
  ///
  /// Passing [null] or invalid times cancels all existing schedules.
  // BUG FIX #4 (continued): Changed to async because the body now contains
  // "await NotificationService.schedulePrayerNotifications(...)"
  Future<void> scheduleNextAdhan(PrayerTimes? prayerTimes) async {
    _cancelTimer();

    if (prayerTimes == null || !prayerTimes.isValidChronologically()) {
      developer.log(
        'Cannot schedule Adhan: PrayerTimes is null or invalid.',
        name: 'AdhanScheduler',
      );
      // Cancel OS notifications too so nothing stale fires
      NotificationService.cancelAllPrayerNotifications();
      notifyListeners();
      return;
    }

    // ── 1. In-process Timer (foreground/background) ───────────────────────
    // Always schedule the in-process timer so the countdown UI stays accurate.
    _scheduleInProcessTimer(prayerTimes);

    // ── 2. OS notifications (works even when app is killed) ───────────────
    // Only register OS notifications if the user has autoplay enabled.
    if (_storageService.isAdhanAutoPlayEnabled()) {
      // BUG FIX #4: Added missing "storage: _storageService" required parameter
      // (caused compile error after Round-2 DI fix) and added "await" so
      // scheduling errors are not silently swallowed.
      await NotificationService.schedulePrayerNotifications(
        prayerTimes,
        storage: _storageService,
      );
    } else {
      developer.log(
        'Adhan autoplay disabled — skipping OS notification scheduling.',
        name: 'AdhanScheduler',
      );
    }

    notifyListeners();
  }

  /// Exposed for countdown widgets on the home screen.
  DateTime? get scheduledTime      => _scheduledTime;
  String?   get scheduledPrayerName => _scheduledPrayerName;

  /// Called by [HomeController] when foreground clock drift is detected
  /// (manual time change or DST flip while the app is active).
  /// Re-reads the cache and re-arms the monotonic timer against the new
  /// wall-clock position.  No-op if no cache is available.
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
      // Strip any extra text (like timezone names: "19:00 (EET)")
      final hour = int.parse(timeParts[0].trim().split(' ')[0]);
      final minute = int.parse(timeParts[1].trim().split(' ')[0]);
      return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  void _scheduleInProcessTimer(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final today = now;
    final tomorrow = now.add(const Duration(days: 1));

    final prayers = [
      // Today's prayers
      _PrayerTimeEntry('Fajr', _parseTimeOnDate(today, prayerTimes.fajr)),
      _PrayerTimeEntry('Dhuhr', _parseTimeOnDate(today, prayerTimes.dhuhr)),
      _PrayerTimeEntry('Asr', _parseTimeOnDate(today, prayerTimes.asr)),
      _PrayerTimeEntry('Maghrib', _parseTimeOnDate(today, prayerTimes.maghrib)),
      _PrayerTimeEntry('Isha', _parseTimeOnDate(today, prayerTimes.isha)),
      
      // Tomorrow's prayers
      _PrayerTimeEntry('Fajr', _parseTimeOnDate(tomorrow, prayerTimes.fajr)),
      _PrayerTimeEntry('Dhuhr', _parseTimeOnDate(tomorrow, prayerTimes.dhuhr)),
      _PrayerTimeEntry('Asr', _parseTimeOnDate(tomorrow, prayerTimes.asr)),
      _PrayerTimeEntry('Maghrib', _parseTimeOnDate(tomorrow, prayerTimes.maghrib)),
      _PrayerTimeEntry('Isha', _parseTimeOnDate(tomorrow, prayerTimes.isha)),
    ];

    DateTime? nextPrayerTime;
    String?   nextPrayerName;

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

    _scheduledTime      = nextPrayerTime;
    _scheduledPrayerName = nextPrayerName;
    final duration = nextPrayerTime.difference(now);

    developer.log(
      'Diagnostic Log - [AdhanScheduler]:\n'
      '  - Current Time: $now\n'
      '  - Next Prayer: $nextPrayerName\n'
      '  - Next Prayer Time: $nextPrayerTime\n'
      '  - Countdown Duration: $duration (${duration.inSeconds} seconds)\n'
      '  - Cache Date: ${prayerTimes.date}',
      name: 'AdhanScheduler',
    );

    _prayerTimer = Timer(duration, () => _triggerAdhan(nextPrayerName!));
  }

  // ── ADHAN PLAYBACK ────────────────────────────────────────────────────────

  void _triggerAdhan(String prayerName) {
    developer.log('Adhan timer fired for: $prayerName', name: 'AdhanScheduler');

    final autoPlayEnabled = _storageService.isAdhanAutoPlayEnabled();
    if (!autoPlayEnabled) {
      developer.log(
        'Adhan autoplay disabled — skipping audio.',
        name: 'AdhanScheduler',
      );
      _rescheduleAfterFired();
      return;
    }

    // Resolve user-selected sound; fall back to remote URL when none saved.
    final savedFile = _storageService.getSelectedAdhanSound();
    final selectedOption = AdhanSoundOption.fromFileName(
      savedFile.isEmpty ? null : savedFile,
    );
    // Use the local asset path so playback works offline.
    final adhanUrl = selectedOption.assetPath;

    _audioService.play(
      adhanUrl,
      AudioMode.adhan,
      title: 'Adhan ($prayerName)',
      subtitle: 'Islamic Audio Hub',
    ).then((_) {
      developer.log('Adhan playing: ${selectedOption.displayName}', name: 'AdhanScheduler');
    }).catchError((err) {
      developer.log('Adhan play failed: $err — retrying with fallback.', name: 'AdhanScheduler');
      // Fallback to remote stream if local asset fails
      _audioService.play(
        _fallbackAdhanUrl,
        AudioMode.adhan,
        title: 'Adhan ($prayerName)',
        subtitle: 'Islamic Audio Hub',
      ).catchError((e) {
        developer.log('Fallback adhan also failed: $e', name: 'AdhanScheduler');
      });
    }).whenComplete(_rescheduleAfterFired);
  }

  void _rescheduleAfterFired() {
    developer.log('Diagnostic Log - [AdhanScheduler]: Rescheduling after adhan completed or fired.', name: 'AdhanScheduler');
    final cachedJson = _storageService.get('cached_prayer_times');
    if (cachedJson == null) return;
    try {
      final pt = PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
      unawaited(scheduleNextAdhan(pt));
    } catch (e) {
      developer.log('Error rescheduling after fire: $e', name: 'AdhanScheduler');
    }
  }

  // ── TIMER CLEANUP ─────────────────────────────────────────────────────────

  void _cancelTimer() {
    _prayerTimer?.cancel();
    _prayerTimer       = null;
    _scheduledTime     = null;
    _scheduledPrayerName = null;
  }
}

class _PrayerTimeEntry {
  final String name;
  final DateTime? time;
  _PrayerTimeEntry(this.name, this.time);
}

