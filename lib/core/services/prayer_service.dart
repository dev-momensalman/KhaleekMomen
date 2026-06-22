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
    // ✅ Dynamic method — يقرأ من الإعدادات، افتراضي 5 (الهيئة المصرية)
    final methodId = _storageService.getPrayerCalculationMethod();

    developer.log(
      'Requesting prayer times for $today '
      '(lat: $latitude, lng: $longitude, method: $methodId, force: $force)',
      name: 'PrayerService',
    );

    // 0. Pre-check: كاش صالح + موقع قريب + نفس الطريقة → استخدامه مباشرة
    if (!force) {
      final cachedJson = _storageService.get('cached_prayer_times');
      if (cachedJson != null) {
        try {
          final cachedTimes = PrayerTimes.fromJson(
            Map<String, dynamic>.from(cachedJson),
          );
          if (cachedTimes.date == today &&
              cachedTimes.isValidChronologically() &&
              cachedTimes.latitude != null &&
              cachedTimes.longitude != null) {
            final latDiff = (cachedTimes.latitude! - latitude).abs();
            final lngDiff = (cachedTimes.longitude! - longitude).abs();
            // نتحقق كمان إن الطريقة المحفوظة هي نفس الطريقة الحالية
            final cachedMethod = cachedTimes.calculationMethod ?? methodId;
            if (latDiff < 0.1 && lngDiff < 0.1 && cachedMethod == methodId) {
              developer.log(
                'Valid cache found for today, location & method match. Returning cache.',
                name: 'PrayerService',
              );
              return cachedTimes;
            }
          }
        } catch (e) {
          developer.log(
            'Error parsing cached prayer times during pre-check: $e',
            name: 'PrayerService',
          );
        }
      }
    }

    // 1. Fetch from network API
    try {
      final path =
          '/timings/$apiDateStr?latitude=$latitude&longitude=$longitude&method=$methodId';
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
          calculationMethod: methodId, // ✅ حفظ الطريقة مع البيانات
        );

        if (prayerTimes.fajr.isEmpty ||
            prayerTimes.dhuhr.isEmpty ||
            prayerTimes.asr.isEmpty ||
            prayerTimes.maghrib.isEmpty ||
            prayerTimes.isha.isEmpty) {
          throw Exception('Received incomplete prayer times data from API.');
        }

        if (!prayerTimes.isValidChronologically()) {
          throw Exception(
            'Received invalid prayer times from API (failed chronological order check).',
          );
        }

        await _storageService.put('cached_prayer_times', prayerTimes.toJson());
        await _storageService.put(
          'prayer_times_last_updated',
          DateTime.now().toIso8601String(),
        );

        developer.log(
          'Saved valid prayer times to cache (method=$methodId).',
          name: 'PrayerService',
        );
        return prayerTimes;
      } else {
        throw Exception('Response parsing error: Data block missing.');
      }
    } catch (e) {
      developer.log(
        'API call failed: $e. Checking cache fallback...',
        name: 'PrayerService',
      );

      // 2. Cache fallback
      final cachedJson = _storageService.get('cached_prayer_times');
      if (cachedJson != null) {
        try {
          final cachedTimes = PrayerTimes.fromJson(
            Map<String, dynamic>.from(cachedJson),
          );
          if (cachedTimes.date == today &&
              cachedTimes.isValidChronologically()) {
            developer.log(
              'Valid cache found. Using cache.',
              name: 'PrayerService',
            );
            return cachedTimes;
          } else {
            developer.log(
              'Cache outdated (cached: ${cachedTimes.date}, today: $today).',
              name: 'PrayerService',
            );
          }
        } catch (cacheErr) {
          developer.log(
            'Error parsing cached prayer times: $cacheErr',
            name: 'PrayerService',
          );
        }
      }

      throw Exception(
        'Prayer times unavailable: No network connectivity and no valid cached times.',
      );
    }
  }

  bool hasValidCacheForToday() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final cachedJson = _storageService.get('cached_prayer_times');
    if (cachedJson == null) return false;
    try {
      final cachedTimes = PrayerTimes.fromJson(
        Map<String, dynamic>.from(cachedJson),
      );
      return cachedTimes.date == today && cachedTimes.isValidChronologically();
    } catch (_) {
      return false;
    }
  }

  PrayerTimes? getCachedPrayerTimes() {
    final cachedJson = _storageService.get('cached_prayer_times');
    if (cachedJson == null) return null;
    try {
      return PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
    } catch (_) {
      return null;
    }
  }

  Future<PrayerTimes?> getTomorrowPrayerTimes({
    required double latitude,
    required double longitude,
  }) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);
    final apiDateStr = DateFormat('dd-MM-yyyy').format(tomorrow);
    final methodId = _storageService.getPrayerCalculationMethod(); // ✅

    // Return cached if still valid
    final cachedJson = _storageService.get('cached_prayer_times_tomorrow');
    if (cachedJson != null) {
      try {
        final cached = PrayerTimes.fromJson(
          Map<String, dynamic>.from(cachedJson),
        );
        final cachedMethod = cached.calculationMethod ?? methodId;
        if (cached.date == tomorrowStr &&
            cached.isValidChronologically() &&
            cachedMethod == methodId) {
          developer.log('Valid tomorrow cache found.', name: 'PrayerService');
          return cached;
        }
      } catch (_) {}
    }

    try {
      final path =
          '/timings/$apiDateStr?latitude=$latitude&longitude=$longitude&method=$methodId';
      final response = await _httpService.get(path);
      if (response != null && response['data'] != null) {
        final timings = response['data']['timings'] as Map<String, dynamic>;
        final meta = response['data']['meta'] as Map<String, dynamic>;
        final pt = PrayerTimes(
          date: tomorrowStr,
          fajr: timings['Fajr']?.toString() ?? '',
          sunrise: timings['Sunrise']?.toString() ?? '',
          dhuhr: timings['Dhuhr']?.toString() ?? '',
          asr: timings['Asr']?.toString() ?? '',
          maghrib: timings['Maghrib']?.toString() ?? '',
          isha: timings['Isha']?.toString() ?? '',
          latitude: latitude,
          longitude: longitude,
          timezone: meta['timezone']?.toString() ?? 'UTC',
          calculationMethod: methodId, // ✅
        );
        if (pt.isValidChronologically()) {
          await _storageService.put(
            'cached_prayer_times_tomorrow',
            pt.toJson(),
          );
          developer.log(
            'Tomorrow prayer times cached: $tomorrowStr (method=$methodId)',
            name: 'PrayerService',
          );
          return pt;
        }
      }
    } catch (e) {
      developer.log(
        'Failed to fetch tomorrow prayer times: $e',
        name: 'PrayerService',
      );
    }
    return null;
  }

  PrayerTimes? getCachedTomorrowPrayerTimes() {
    final tomorrowStr = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().add(const Duration(days: 1)));
    final cachedJson = _storageService.get('cached_prayer_times_tomorrow');
    if (cachedJson == null) return null;
    try {
      final pt = PrayerTimes.fromJson(Map<String, dynamic>.from(cachedJson));
      return (pt.date == tomorrowStr && pt.isValidChronologically())
          ? pt
          : null;
    } catch (_) {
      return null;
    }
  }
}
