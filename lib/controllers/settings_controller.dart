import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:islamic_audio_hub/core/services/adhan_scheduler.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/notification_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';
import 'package:islamic_audio_hub/data/models/prayer_calculation_method.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';

class SettingsController extends ChangeNotifier {
  final StorageService _storageService;
  final AdhanScheduler _adhanScheduler;
  final AudioServiceWrapper _audioService;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ar');
  bool _adhanAutoPlay = true;
  bool _isTestingNativeAdhan = false;

  // ✅ طريقة حساب الأوقات
  PrayerCalculationMethod _calculationMethod = PrayerCalculationMethod.egyptian;

  // ✅ تأخير الأذان بالدقائق
  int _adhanOffsetMinutes = 0;

  Timer? _debounceTimer;

  AdhanSoundOption _selectedAdhan = AdhanSoundOption.all.first;
  bool _isPreviewing = false;
  AdhanSoundOption? _previewedAdhan;
  StreamSubscription<dynamic>? _audioSubscription;

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
      final isNowPreviewing =
          state.isPlaying &&
          state.mode == AudioMode.quran &&
          AdhanSoundOption.all.any(
            (option) => option.displayName == state.currentSource,
          );

      final playingAdhan = isNowPreviewing
          ? AdhanSoundOption.all.firstWhere(
              (option) => option.displayName == state.currentSource,
            )
          : null;

      if (_isPreviewing != isNowPreviewing || _previewedAdhan != playingAdhan) {
        _isPreviewing = isNowPreviewing;
        _previewedAdhan = playingAdhan;
        notifyListeners();
      }
    });
  }

  // ── Getters ────────────────────────────────────────────────────────────

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get adhanAutoPlay => _adhanAutoPlay;
  List<AdhanSoundOption> get availableAdhans => AdhanSoundOption.all;
  AdhanSoundOption get selectedAdhan => _selectedAdhan;
  bool get isPreviewing => _isPreviewing;
  AdhanSoundOption? get previewedAdhan => _previewedAdhan;
  bool get isTestingNativeAdhan => _isTestingNativeAdhan;

  // ✅ getters جديدة
  PrayerCalculationMethod get calculationMethod => _calculationMethod;
  List<PrayerCalculationMethod> get availableMethods =>
      PrayerCalculationMethod.values;
  int get adhanOffsetMinutes => _adhanOffsetMinutes;

  // ── Load Settings ──────────────────────────────────────────────────────

  void _loadSettings() {
    final themeStr = _storageService.getThemeMode();
    _themeMode = _parseThemeMode(themeStr);

    final langStr = _storageService.getLanguage();
    _locale = Locale(langStr);

    _adhanAutoPlay = _storageService.isAdhanAutoPlayEnabled();

    final savedFile = _storageService.getSelectedAdhanSound();
    _selectedAdhan = AdhanSoundOption.fromFileName(
      savedFile.isEmpty ? null : savedFile,
    );

    // ✅ تحميل طريقة الحساب
    final methodId = _storageService.getPrayerCalculationMethod();
    _calculationMethod = PrayerCalculationMethod.fromId(methodId);

    // ✅ تحميل التأخير
    _adhanOffsetMinutes = _storageService.getAdhanOffsetMinutes();
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

  // ── Update Methods ─────────────────────────────────────────────────────

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
        await _rescheduleAdhanFromCache(reason: 'adhan autoplay enabled');
      } else {
        await NotificationService.cancelAllPrayerNotifications();
        await NotificationService.stopNativeAdhan();
        stopPreview();
        if (_audioService.currentState.mode == AudioMode.adhan) {
          await _audioService.stop();
        }
        developer.log(
          'Adhan autoplay disabled — all notifications/native alarms cancelled.',
          name: 'SettingsController',
        );
      }
    });
  }

  /// ✅ تغيير طريقة حساب الأوقات — يمسح الكاش ويعيد الجدولة
  Future<void> updateCalculationMethod(PrayerCalculationMethod method) async {
    if (_calculationMethod == method) return;
    _calculationMethod = method;
    await _storageService.setPrayerCalculationMethod(method.id);

    // مسح الكاش القديم عشان يجيب أوقات جديدة بالطريقة الجديدة
    await _storageService.delete('cached_prayer_times');
    await _storageService.delete('cached_prayer_times_tomorrow');

    notifyListeners();

    developer.log(
      'Calculation method changed to: ${method.nameEn} (id=${method.id}). Cache cleared.',
      name: 'SettingsController',
    );

    // ملاحظة: الأوقات الجديدة ستُجلب تلقائياً في المرة القادمة التي
    // يفتح فيها المستخدم التطبيق أو عند استئناف التطبيق من الخلفية.
    // لو عندك PrayerController accessible هنا ممكن تعمل force fetch.
  }

  /// ✅ تغيير تأخير الأذان — يحفظ ويعيد الجدولة فوراً
  Future<void> updateAdhanOffsetMinutes(int minutes) async {
    _adhanOffsetMinutes = minutes;
    await _storageService.setAdhanOffsetMinutes(minutes);
    notifyListeners();

    await _rescheduleAdhanFromCache(
      reason: 'adhan offset changed to ${minutes}min',
    );

    developer.log(
      'Adhan offset set to $minutes minutes.',
      name: 'SettingsController',
    );
  }

  Future<void> selectAdhan(AdhanSoundOption option) async {
    stopPreview();
    _selectedAdhan = option;
    await _storageService.saveSelectedAdhanSound(option.fileName);
    notifyListeners();
    await _rescheduleAdhanFromCache(
      reason: 'adhan sound changed to ${option.displayName}',
    );
  }

  Future<void> previewAdhan(AdhanSoundOption option) async {
    if (_audioService.currentState.isLocked) {
      developer.log(
        'Preview blocked — real Adhan is active.',
        name: 'SettingsController',
      );
      return;
    }
    stopPreview();
    try {
      await _audioService.play(
        option.assetPath,
        AudioMode.quran,
        title: option.displayName,
        subtitle: 'معاينة الأذان',
      );
    } catch (e) {
      developer.log('Preview failed: $e', name: 'SettingsController');
    }
  }

  Future<void> testNativeAdhan() async {
    if (_isTestingNativeAdhan) return;
    _isTestingNativeAdhan = true;
    notifyListeners();
    try {
      stopPreview();
      if (_audioService.currentState.mode == AudioMode.adhan ||
          _audioService.currentState.isPlaying) {
        await _audioService.stop();
      }
      await NotificationService.playNativeTestAdhan(
        rawResourceName: _selectedAdhan.rawResourceName,
        prayerAr: 'اختبار الأذان',
      );
      developer.log(
        'Native Adhan test started: ${_selectedAdhan.displayName}',
        name: 'SettingsController',
      );
    } catch (e, st) {
      developer.log(
        'Native Adhan test failed: $e\n$st',
        name: 'SettingsController',
      );
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      _isTestingNativeAdhan = false;
      notifyListeners();
    }
  }

  Future<void> stopNativeAdhan() async {
    await NotificationService.stopNativeAdhan();
  }

  Future<void> openExactAlarmSettings() async {
    await NotificationService.openNativeExactAlarmSettings();
  }

  Future<void> openBatteryOptimizationSettings() async {
    await NotificationService.openNativeBatteryOptimizationSettings();
  }

  void stopPreview() {
    unawaited(_audioService.stop());
  }

  // ── Reschedule ─────────────────────────────────────────────────────────

  Future<void> _rescheduleAdhanFromCache({required String reason}) async {
    final todayPrayerTimes = _getCachedTodayPrayerTimes();
    final tomorrowPrayerTimes = _getCachedTomorrowPrayerTimes();

    if (todayPrayerTimes == null) {
      developer.log(
        'Cannot reschedule Adhan after $reason: no valid cached prayer times.',
        name: 'SettingsController',
      );
      return;
    }

    try {
      await _adhanScheduler.scheduleNextAdhan(
        todayPrayerTimes,
        tomorrowPrayerTimes: tomorrowPrayerTimes,
      );
      developer.log(
        'Adhan rescheduled successfully after $reason.',
        name: 'SettingsController',
      );
    } catch (e, st) {
      developer.log(
        'Error rescheduling Adhan after $reason: $e\n$st',
        name: 'SettingsController',
      );
    }
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
        'Error parsing cached today prayer times: $e',
        name: 'SettingsController',
      );
      return null;
    }
  }

  PrayerTimes? _getCachedTomorrowPrayerTimes() {
    final tomorrowJson = _storageService.get('cached_prayer_times_tomorrow');
    if (tomorrowJson == null) return null;
    try {
      final tomorrowStr = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 1)));
      final cached = PrayerTimes.fromJson(
        Map<String, dynamic>.from(tomorrowJson),
      );
      if (cached.date == tomorrowStr && cached.isValidChronologically()) {
        return cached;
      }
      return null;
    } catch (e) {
      developer.log(
        'Error parsing cached tomorrow prayer times: $e',
        name: 'SettingsController',
      );
      return null;
    }
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    stopPreview();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
