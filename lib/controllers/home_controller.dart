import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/adhan_scheduler.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';

class HomeController extends ChangeNotifier {
  final StorageService _storageService;
  final AdhanScheduler _adhanScheduler;
  final AudioServiceWrapper _audioService;

  Timer? _ticker;
  String _countdownText = '--:--:--';
  Map<String, dynamic>? _lastPlayed;
  StreamSubscription? _audioSubscription;

  // Clock-drift detection: tracks the last measured remaining seconds so that
  // the ticker can notice when the wall-clock jumps (manual change / DST).
  int? _previousRemainingSeconds;

  HomeController(
    this._storageService,
    this._adhanScheduler,
    this._audioService,
  ) {
    _adhanScheduler.addListener(_updateCountdown);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastPlayed();
      _startCountdownTicker();

      // Listen to changes in audio playback to update last played item on home
      _audioSubscription = _audioService.stateStream.listen((state) {
        if (state.isPlaying) {
          _loadLastPlayed();
        }
        notifyListeners();
      });
    });
  }

  // Getters
  AudioServiceWrapper get audioService => _audioService;
  String get countdownText => _countdownText;
  String? get nextPrayerName => _adhanScheduler.scheduledPrayerName;
  DateTime? get nextPrayerTime => _adhanScheduler.scheduledTime;
  Map<String, dynamic>? get lastPlayed => _lastPlayed;

  void _loadLastPlayed() {
    _lastPlayed = _storageService.getLastPlayedAudio();
    notifyListeners();
  }

  void _startCountdownTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
    _updateCountdown();
  }

  void _updateCountdown() {
    final target = _adhanScheduler.scheduledTime;
    if (target == null) {
      _previousRemainingSeconds = null;
      _countdownText = 'Unavailable';
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    if (now.isAfter(target)) {
      _previousRemainingSeconds = null;
      _countdownText = '00:00:00';
      notifyListeners();
      return;
    }

    final diff = target.difference(now);
    final actualRemaining = diff.inSeconds;

    // ── Clock-drift detection ───────────────────────────────────────────────
    // Under normal operation the ticker fires every ~1 s, so the remaining
    // count should decrease by exactly 1.  A deviation > 30 s means the
    // wall-clock jumped (manual change or DST flip) while the app was in the
    // foreground.  Re-arm the scheduler so the Dart Timer realigns to the
    // new wall-clock position.
    if (_previousRemainingSeconds != null) {
      final expected = _previousRemainingSeconds! - 1;
      final deviation = (actualRemaining - expected).abs();
      if (deviation > 30) {
        developer.log(
          'Clock drift detected (deviation: ${deviation}s) — rescheduling Adhan.',
          name: 'HomeController',
        );
        _previousRemainingSeconds = null; // reset before reschedule
        _adhanScheduler.rescheduleFromCache();
        return; // reschedule triggers notifyListeners via listener
      }
    }
    _previousRemainingSeconds = actualRemaining;
    // ───────────────────────────────────────────────────────────────────────

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    _countdownText = '$hours:$minutes:$seconds';
    notifyListeners();

    // Occasional diagnostic log to avoid console spam (e.g. every 30 seconds)
    if (actualRemaining % 30 == 0) {
      developer.log(
        'Diagnostic Log - [HomeController]:\n'
        '  - Current Time: $now\n'
        '  - Next Prayer: ${_adhanScheduler.scheduledPrayerName}\n'
        '  - Next Prayer Time: $target\n'
        '  - Countdown Text: $_countdownText',
        name: 'HomeController',
      );
    }
  }

  // Quick actions
  Future<void> playLastPlayed() async {
    if (_lastPlayed == null) return;
    try {
      final type = _lastPlayed!['type'] as String;
      final url = _lastPlayed!['url'] as String;
      final title = _lastPlayed!['title'] as String;
      final subtitle = _lastPlayed!['subtitle'] as String;

      final mode = type == 'radio' ? AudioMode.radio : AudioMode.quran;
      await _audioService.play(url, mode, title: title, subtitle: subtitle);
    } catch (e) {
      developer.log(
        'Failed to resume last played audio: $e',
        name: 'HomeController',
      );
    }
  }

  bool isLastPlayedPlaying() {
    if (_lastPlayed == null) return false;
    final state = _audioService.currentState;
    if (!state.isPlaying) return false;

    final type = _lastPlayed!['type'] as String? ?? '';

    if (type == 'quran') {
      // مقارنة بالـ id (رقم السورة) — متطابق مع currentSource
      return state.currentSource == _lastPlayed!['id'];
    } else {
      // الراديو: station.name متطابق مع currentSource
      return state.currentSource == _lastPlayed!['title'];
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _audioSubscription?.cancel();
    _adhanScheduler.removeListener(_updateCountdown);
    super.dispose();
  }
}
