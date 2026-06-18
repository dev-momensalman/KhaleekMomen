import 'dart:async';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import 'package:islamic_audio_hub/core/services/http_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';

class PrayerService {
  final HttpService _httpService;
  final StorageService _storageService;

  PrayerService(this._httpService, this._storageService);

  /// Fetches prayer times from API, validates them chronologically, caches them, 
  /// or returns valid cache on failure.
  /// Throws [Exception] if API fails and no valid cache is available.
  Future<PrayerTimes> getPrayerTimes({
    required double latitude,
    required double longitude,
    bool force = false,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final apiDateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());

    developer.log('Requesting prayer times for $today (lat: $latitude, lng: $longitude, force: $force)', name: 'PrayerService');

    // 0. Pre-check: If we already have a valid cache for today and coordinates are close, use it (unless forced)
    if (!force) {
      final cachedJson = _storageService.get('cached_prayer_times');
      if (cachedJson != null) {
        try {
          final cachedTimes = PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
          if (cachedTimes.date == today &&
              cachedTimes.isValidChronologically() &&
              cachedTimes.latitude != null &&
              cachedTimes.longitude != null) {
            final latDiff = (cachedTimes.latitude! - latitude).abs();
            final lngDiff = (cachedTimes.longitude! - longitude).abs();
            if (latDiff < 0.1 && lngDiff < 0.1) {
              developer.log('Valid today\'s cache for matching location found. Returning cache.', name: 'PrayerService');
              return cachedTimes;
            }
          }
        } catch (e) {
          developer.log('Error parsing cached prayer times during pre-check: $e', name: 'PrayerService');
        }
      }
    }

    // 1. Try fetching from network API
    try {
      // Method 5 = Egyptian General Survey Authority (الهيئة المصرية العامة للمساحة)
      final path = '/timings/$apiDateStr?latitude=$latitude&longitude=$longitude&method=5';
      final response = await _httpService.get(path);

      if (response != null && response['data'] != null) {
        final timings = response['data']['timings'] as Map<String, dynamic>;
        final meta = response['data']['meta'] as Map<String, dynamic>;

        final prayerTimes = PrayerTimes(
          date: today,
          fajr: timings['Fajr']?.toString() ?? '',
          sunrise: timings['Sunrise']?.toString() ?? '',
          dhuhr: timings['Dhuhr']?.toString() ?? '',
          asr: timings['Asr']?.toString() ?? '',
          maghrib: timings['Maghrib']?.toString() ?? '',
          isha: timings['Isha']?.toString() ?? '',
          latitude: latitude,
          longitude: longitude,
          timezone: meta['timezone']?.toString() ?? 'UTC',
        );

        // Validation check (non-empty)
        if (prayerTimes.fajr.isEmpty || prayerTimes.dhuhr.isEmpty || prayerTimes.asr.isEmpty ||
            prayerTimes.maghrib.isEmpty || prayerTimes.isha.isEmpty) {
          throw Exception('Received incomplete prayer times data from API.');
        }

        // Strict Chronological Validation check
        if (!prayerTimes.isValidChronologically()) {
          throw Exception('Received invalid prayer times from API (failed chronological order check).');
        }

        // Cache the valid response
        await _storageService.put('cached_prayer_times', prayerTimes.toJson());
        await _storageService.put('prayer_times_last_updated', DateTime.now().toIso8601String());

        developer.log('Saved valid prayer times to cache successfully.', name: 'PrayerService');
        return prayerTimes;
      } else {
        throw Exception('Response parsing error: Data block missing.');
      }
    } catch (e) {
      developer.log('API call failed or was invalid: $e. Checking cache fallback...', name: 'PrayerService');
      
      // 2. Fetch from cache fallback
      final cachedJson = _storageService.get('cached_prayer_times');
      if (cachedJson != null) {
        try {
          final cachedTimes = PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
          // Strict validation: must be for TODAY and should match the chronologically check
          if (cachedTimes.date == today && cachedTimes.isValidChronologically()) {
            developer.log('Valid today\'s cache found. Using cache.', name: 'PrayerService');
            return cachedTimes;
          } else {
            developer.log('Cache is outdated or invalid (cached for: ${cachedTimes.date}, today is: $today).', name: 'PrayerService');
          }
        } catch (cacheErr) {
          developer.log('Error parsing cached prayer times: $cacheErr', name: 'PrayerService');
        }
      }
      
      // 3. No valid cache found, propagate the error as requested by rules
      throw Exception('Prayer times unavailable: No network connectivity and no valid cached times.');
    }
  }

  /// Check if cached data exists, is valid for today, and is chronologically valid.
  bool hasValidCacheForToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cachedJson = _storageService.get('cached_prayer_times');
    if (cachedJson == null) return false;
    try {
      final cachedTimes = PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
      return cachedTimes.date == today && cachedTimes.isValidChronologically();
    } catch (_) {
      return false;
    }
  }

  /// Retrieve the current cached prayer times, even if outdated/offline.
  PrayerTimes? getCachedPrayerTimes() {
    final cachedJson = _storageService.get('cached_prayer_times');
    if (cachedJson == null) return null;
    try {
      return PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
    } catch (_) {
      return null;
    }
  }
}
