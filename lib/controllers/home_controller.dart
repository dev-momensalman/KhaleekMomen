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
      // FIX: Use Arabic text instead of English 'Unavailable'
      _countdownText = 'غير متاح';
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
    if (_previousRemainingSeconds != null) {
      final expected = _previousRemainingSeconds! - 1;
      final deviation = (actualRemaining - expected).abs();
      if (deviation > 30) {
        developer.log(
          'Clock drift detected (deviation: ${deviation}s) — rescheduling Adhan.',
          name: 'HomeController',
        );
        _previousRemainingSeconds = null;
        _adhanScheduler.rescheduleFromCache();
        return;
      }
    }
    _previousRemainingSeconds = actualRemaining;

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    _countdownText = '$hours:$minutes:$seconds';
    notifyListeners();

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

  // FIX: playLastPlayed now uses 'id' (surah number) as the title parameter
  // for quran audio, so that currentSource in AudioServiceWrapper matches the
  // value that isLastPlayedPlaying() compares against.
  // Previously it used 'title' (english name like "Al-Fatihah") while
  // isLastPlayedPlaying() compared against 'id' ("1") → mismatch → the play
  // button on home never reflected the playing state after resuming.
  Future<void> playLastPlayed() async {
    if (_lastPlayed == null) return;
    try {
      final type = _lastPlayed!['type'] as String;
      final url = _lastPlayed!['url'] as String;
      final subtitle = _lastPlayed!['subtitle'] as String;

      final mode = type == 'radio' ? AudioMode.radio : AudioMode.quran;

      // For quran: use 'id' (surah number) as the title so currentSource matches
      // what isLastPlayedPlaying() checks. For radio: 'title' is the station name.
      final String title;
      if (type == 'quran') {
        title = _lastPlayed!['id'] as String;
      } else {
        title = _lastPlayed!['title'] as String;
      }

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
      // Compare against 'id' (surah number) — matches currentSource set by playSurah()
      return state.currentSource == _lastPlayed!['id'];
    } else {
      // Radio: station.name matches currentSource
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
