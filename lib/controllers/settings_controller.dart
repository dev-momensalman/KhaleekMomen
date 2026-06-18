import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/core/services/adhan_scheduler.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/notification_service.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';

class SettingsController extends ChangeNotifier {
  final StorageService _storageService;
  final AdhanScheduler _adhanScheduler;
  final AudioServiceWrapper _audioService;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar');
  bool _adhanAutoPlay = true;
  Timer? _debounceTimer;

  // ── Adhan Sound ───────────────────────────────────────────────────────────
  AdhanSoundOption _selectedAdhan = AdhanSoundOption.all.first;
  bool _isPreviewing = false;
  AdhanSoundOption? _previewedAdhan;
  StreamSubscription<AudioState>? _audioSubscription;

  SettingsController(
    this._storageService,
    this._adhanScheduler,
    this._audioService,
  ) {
    _loadSettings();
    _listenToAudioState();
  }

  void _listenToAudioState() {
    _audioSubscription = _audioService.stateStream.listen((state) {
      final isNowPreviewing = state.isPlaying &&
          state.mode == AudioMode.quran &&
          AdhanSoundOption.all.any((o) => o.displayName == state.currentSource);

      final playingAdhan = isNowPreviewing
          ? AdhanSoundOption.all.firstWhere((o) => o.displayName == state.currentSource)
          : null;

      if (_isPreviewing != isNowPreviewing || _previewedAdhan != playingAdhan) {
        _isPreviewing = isNowPreviewing;
        _previewedAdhan = playingAdhan;
        notifyListeners();
      }
    });
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get adhanAutoPlay => _adhanAutoPlay;

  List<AdhanSoundOption> get availableAdhans => AdhanSoundOption.all;
  AdhanSoundOption get selectedAdhan => _selectedAdhan;
  bool get isPreviewing => _isPreviewing;
  AdhanSoundOption? get previewedAdhan => _previewedAdhan;

  void _loadSettings() {
    final themeStr = _storageService.getThemeMode();
    _themeMode = _parseThemeMode(themeStr);

    final langStr = _storageService.getLanguage();
    _locale = Locale(langStr);

    _adhanAutoPlay = _storageService.isAdhanAutoPlayEnabled();

    final savedFile = _storageService.getSelectedAdhanSound();
    _selectedAdhan = AdhanSoundOption.fromFileName(savedFile.isEmpty ? null : savedFile);
  }

  ThemeMode _parseThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    
    await _storageService.setThemeMode(modeStr);
    notifyListeners();
  }

  Future<void> updateLanguage(String langCode) async {
    _locale = Locale(langCode);
    await _storageService.setLanguage(langCode);
    notifyListeners();
  }

  Future<void> updateAdhanAutoPlay(bool enabled) async {
    _adhanAutoPlay = enabled;
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _storageService.setAdhanAutoPlay(enabled);
      if (enabled) {
        final cachedJson = _storageService.get('cached_prayer_times');
        if (cachedJson != null) {
          try {
            final pt = PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
            unawaited(_adhanScheduler.scheduleNextAdhan(pt));
          } catch (e) {
            developer.log('Error parsing cached prayer times on toggle enable: $e', name: 'SettingsController');
          }
        }
      } else {
        await NotificationService.cancelAllPrayerNotifications();
        stopPreview();
        if (_audioService.currentState.mode == AudioMode.adhan) {
          await _audioService.stop();
        }
      }
    });
  }

  // ── Adhan Sound Methods ───────────────────────────────────────────────────

  Future<void> selectAdhan(AdhanSoundOption option) async {
    stopPreview();
    _selectedAdhan = option;
    await _storageService.saveSelectedAdhanSound(option.fileName);
    notifyListeners();

    // Reschedule notifications with the new channel/sound settings
    final cachedJson = _storageService.get('cached_prayer_times');
    if (cachedJson != null) {
      try {
        final pt = PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
        await NotificationService.schedulePrayerNotifications(pt, storage: _storageService);
      } catch (e) {
        developer.log('Error rescheduling notifications on sound change: $e', name: 'SettingsController');
      }
    }
  }

  Future<void> previewAdhan(AdhanSoundOption option) async {
    // Do not start a preview while a real Adhan is locked
    if (_audioService.currentState.isLocked) {
      developer.log('Preview blocked — real Adhan is active.', name: 'SettingsController');
      return;
    }
    stopPreview();
    try {
      await _audioService.play(
        option.assetPath,
        AudioMode.quran, // quran mode = interruptible, not locked
        title: option.displayName,
        subtitle: 'معاينة الأذان',
      );
    } catch (e) {
      developer.log('Preview failed: $e', name: 'SettingsController');
    }
  }

  void stopPreview() {
    _audioService.stop();
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    stopPreview();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
