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
      developer.log('Error initializing Hive: \$e', name: 'StorageService');
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

  // Helper getters/setters for specific features

  // Favorites
  List<String> getFavoriteStations() {
    final list = get('fav_stations');
    return list != null ? List<String>.from(list) : [];
  }

  Future<void> setFavoriteStations(List<String> ids) async {
    await put('fav_stations', ids);
  }

  List<String> getFavoriteReciters() {
    final list = get('fav_reciters');
    return list != null ? List<String>.from(list) : [];
  }

  Future<void> setFavoriteReciters(List<String> ids) async {
    await put('fav_reciters', ids);
  }

  List<String> getFavoriteSurahs() {
    final list = get('fav_surahs');
    return list != null ? List<String>.from(list) : [];
  }

  Future<void> setFavoriteSurahs(List<String> ids) async {
    await put('fav_surahs', ids);
  }

  // Settings
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

  // Audio Auto-play Settings
  bool isAdhanAutoPlayEnabled() {
    return get('adhan_autoplay', defaultValue: true);
  }

  Future<void> setAdhanAutoPlay(bool enabled) async {
    await put('adhan_autoplay', enabled);
  }

  // Adhan Sound Selection
  String getSelectedAdhanSound() {
    return get('adhan_sound_file', defaultValue: '') as String;
  }

  Future<void> saveSelectedAdhanSound(String fileName) async {
    await put('adhan_sound_file', fileName);
  }

  // Last Played Audio State
  Map<String, dynamic>? getLastPlayedAudio() {
    final data = get('last_played_audio');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> setLastPlayedAudio(Map<String, dynamic> data) async {
    await put('last_played_audio', data);
  }

  // ── Onboarding ─────────────────────────────────────────────────────

  bool get isOnboardingCompleted {
    return get('onboarding_completed', defaultValue: false) as bool;
  }

  static Future<void> setOnboardingCompleted() async {
    final box = Hive.box(_boxName);
    await box.put('onboarding_completed', true);
  }

  // ── Reading Position (Resume Reading) ────────────────────────────────

  /// Returns the last saved reading position, or null if none saved.
  /// Map keys: 'surahNumber' (int), 'ayahNumber' (int),
  ///           'surahName' (String), 'timestamp' (String ISO-8601)
  Map<String, dynamic>? getLastReadingPosition() {
    final data = get('last_reading_position');
    if (data == null) return null;
    try {
      return Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return null;
    }
  }

  /// Persists the current reading position. Call on scroll/ayah change.
  Future<void> saveLastReadingPosition({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
    double scrollOffset = 0.0, // ← جديد
  }) async {
    await _box.put('last_reading_position', {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'scrollOffset': scrollOffset, // ← جديد
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Clears the saved reading position (e.g. user finishes a surah).
  Future<void> clearLastReadingPosition() async {
    await delete('last_reading_position');
  }
}
