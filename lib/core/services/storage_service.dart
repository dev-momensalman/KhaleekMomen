import 'dart:developer' as developer;
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _boxName = 'islamic_audio_hub_cache';
  static late Box _box;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;
      developer.log(
        'Storage Service (Hive) initialized.',
        name: 'StorageService',
      );
    } catch (e) {
      developer.log('Error initializing Hive: $e', name: 'StorageService');
      rethrow;
    }
  }

  // Core API Methods
  dynamic get(String key, {dynamic defaultValue}) {
    return _box.get(key, defaultValue: defaultValue);
  }

  Future<void> put(String key, dynamic value) async {
    await _box.put(key, value);
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  // ── Favorites ────────────────────────────────────────────────────────

  List<dynamic> getFavoriteStations() {
    final list = get('fav_stations');
    return list != null ? List.from(list) : [];
  }

  Future<void> setFavoriteStations(List<dynamic> ids) async {
    await put('fav_stations', ids);
  }

  List<dynamic> getFavoriteReciters() {
    final list = get('fav_reciters');
    return list != null ? List.from(list) : [];
  }

  Future<void> setFavoriteReciters(List<dynamic> ids) async {
    await put('fav_reciters', ids);
  }

  List<dynamic> getFavoriteSurahs() {
    final list = get('fav_surahs');
    return list != null ? List.from(list) : [];
  }

  Future<void> setFavoriteSurahs(List<dynamic> ids) async {
    await put('fav_surahs', ids);
  }

  // ── Settings ─────────────────────────────────────────────────────────

  String getThemeMode() {
    return get('theme_mode', defaultValue: 'system');
  }

  Future<void> setThemeMode(String mode) async {
    await put('theme_mode', mode);
  }

  String getLanguage() {
    return get('language', defaultValue: 'ar');
  }

  Future<void> setLanguage(String lang) async {
    await put('language', lang);
  }

  // ── Adhan Auto-play ───────────────────────────────────────────────────

  bool isAdhanAutoPlayEnabled() {
    return get('adhan_autoplay', defaultValue: true);
  }

  Future<void> setAdhanAutoPlay(bool enabled) async {
    await put('adhan_autoplay', enabled);
  }

  // ── Adhan Sound Selection ─────────────────────────────────────────────

  String getSelectedAdhanSound() {
    return get('adhan_sound_file', defaultValue: '') as String;
  }

  Future<void> saveSelectedAdhanSound(String fileName) async {
    await put('adhan_sound_file', fileName);
  }

  // ── Prayer Calculation Method ─────────────────────────────────────────
  // AlAdhan API method ID — default 5 (Egyptian General Authority)

  int getPrayerCalculationMethod() {
    return get('prayer_calc_method', defaultValue: 5) as int;
  }

  Future<void> setPrayerCalculationMethod(int methodId) async {
    await put('prayer_calc_method', methodId);
  }

  // ── Adhan Offset (minutes to add after calculated time) ───────────────

  int getAdhanOffsetMinutes() {
    return get('adhan_offset_minutes', defaultValue: 0) as int;
  }

  Future<void> setAdhanOffsetMinutes(int minutes) async {
    await put('adhan_offset_minutes', minutes);
  }

  // ── Last Played Audio State ───────────────────────────────────────────

  Map<String, dynamic>? getLastPlayedAudio() {
    final data = get('last_played_audio');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> setLastPlayedAudio(Map<String, dynamic> data) async {
    await put('last_played_audio', data);
  }

  // ── Onboarding ────────────────────────────────────────────────────────

  bool get isOnboardingCompleted {
    return get('onboarding_completed', defaultValue: false) as bool;
  }

  static Future<void> setOnboardingCompleted() async {
    final box = Hive.box(_boxName);
    await box.put('onboarding_completed', true);
  }

  // ── Reading Position (Resume Reading) ────────────────────────────────

  Map<String, dynamic>? getLastReadingPosition() {
    final data = get('last_reading_position');
    if (data == null) return null;
    try {
      return Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastReadingPosition({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
    double scrollOffset = 0.0,
  }) async {
    await _box.put('last_reading_position', {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'scrollOffset': scrollOffset,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearLastReadingPosition() async {
    await delete('last_reading_position');
  }
}
