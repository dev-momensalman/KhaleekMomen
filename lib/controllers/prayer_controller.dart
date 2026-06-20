// lib/controllers/prayer_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:islamic_audio_hub/core/services/adhan_scheduler.dart';
import 'package:islamic_audio_hub/core/services/location_service.dart';
import 'package:islamic_audio_hub/core/services/prayer_service.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';

class PrayerController extends ChangeNotifier with WidgetsBindingObserver {
  final PrayerService _prayerService;
  final LocationService _locationService;
  final AdhanScheduler _adhanScheduler;

  PrayerTimes? _todayTimes;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOfflineUsingCache = false;
  Timer? _dayChangeTimer;

  // ── City Name ──────────────────────────────────────────────────────────────

  String? _cityName;
  double? _lastLat;
  double? _lastLng;
  String _lastLocale = '';

  PrayerController(
    this._prayerService,
    this._locationService,
    this._adhanScheduler,
  ) {
    WidgetsBinding.instance.addObserver(this);

    _adhanScheduler.addListener(notifyListeners);

    _loadCachedTimes();
    _startDayChangeTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(fetchPrayerTimes());
    });
  }

  PrayerTimes? get todayTimes => _todayTimes;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get isOfflineUsingCache => _isOfflineUsingCache;

  String? get cityName => _cityName;

  bool get isValid =>
      _todayTimes != null && _todayTimes!.isValidChronologically();

  // ── INITIAL CACHE LOAD ─────────────────────────────────────────────────────

  void _loadCachedTimes() {
    final cache = _prayerService.getCachedPrayerTimes();

    if (cache != null && cache.isValidChronologically()) {
      _todayTimes = cache;
      _isOfflineUsingCache = !_prayerService.hasValidCacheForToday();

      final tomorrowCache = _prayerService.getCachedTomorrowPrayerTimes();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          _adhanScheduler.scheduleNextAdhan(
            cache,
            tomorrowPrayerTimes: tomorrowCache,
          ),
        );
      });

      notifyListeners();
    }
  }

  // ── DAY CHANGE CHECK ───────────────────────────────────────────────────────

  void _startDayChangeTimer() {
    _dayChangeTimer?.cancel();

    _dayChangeTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkDayChange(),
    );
  }

  void _checkDayChange() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (_todayTimes != null && _todayTimes!.date != todayStr) {
      developer.log(
        'Calendar day changed. Fetching new prayer times.',
        name: 'PrayerController',
      );

      unawaited(fetchPrayerTimes(force: true));
    }
  }

  // ── APP LIFECYCLE ──────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      developer.log(
        'App resumed - checking and fetching prayer times.',
        name: 'PrayerController',
      );

      _checkDayChange();

      if (!_prayerService.hasValidCacheForToday()) {
        unawaited(fetchPrayerTimes());
      } else {
        final todayCache = _prayerService.getCachedPrayerTimes();
        final tomorrowCache = _prayerService.getCachedTomorrowPrayerTimes();

        if (todayCache != null && todayCache.isValidChronologically()) {
          unawaited(
            _adhanScheduler.scheduleNextAdhan(
              todayCache,
              tomorrowPrayerTimes: tomorrowCache,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adhanScheduler.removeListener(notifyListeners);
    _dayChangeTimer?.cancel();
    super.dispose();
  }

  // ── FETCH PRAYER TIMES ─────────────────────────────────────────────────────

  Future<void> fetchPrayerTimes({bool force = false}) async {
    final hasValidCache = _prayerService.hasValidCacheForToday();

    if (force || !hasValidCache || _todayTimes == null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final position = await _locationService.getCurrentLocation();

      _isOfflineUsingCache = false;

      final times = await _prayerService.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        force: force,
      );

      _todayTimes = times;
      _errorMessage = null;

      // مهم جدًا:
      // لازم ننتظر أوقات صلاة بكرة قبل جدولة الأذان.
      // لو عملنا unawaited هنا، فجر بكرة ممكن يتجدول بتوقيت النهارده.
      final tomorrowTimes = await _prayerService.getTomorrowPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _adhanScheduler.scheduleNextAdhan(
        times,
        tomorrowPrayerTimes: tomorrowTimes,
      );

      // Fetch city name using last known locale, or default Arabic.
      unawaited(
        _fetchCityName(
          position.latitude,
          position.longitude,
          locale: _lastLocale.isNotEmpty ? _lastLocale : 'ar',
        ),
      );
    } on LocationServiceDisabledException catch (e) {
      _errorMessage = (force || _todayTimes == null) ? e.message : null;
      _handleOfflineOrFailedFetch();
    } on LocationPermissionDeniedException catch (e) {
      _errorMessage = (force || _todayTimes == null) ? e.message : null;
      _handleOfflineOrFailedFetch();
    } catch (e) {
      _errorMessage = (force || _todayTimes == null)
          ? e.toString().replaceAll('Exception:', '').trim()
          : null;

      developer.log(
        'Error fetching prayer times: $_errorMessage',
        name: 'PrayerController',
      );

      _handleOfflineOrFailedFetch();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── OFFLINE / FAILURE FALLBACK ─────────────────────────────────────────────

  void _handleOfflineOrFailedFetch() {
    final tomorrowCache = _prayerService.getCachedTomorrowPrayerTimes();

    if (_prayerService.hasValidCacheForToday()) {
      final todayCache = _prayerService.getCachedPrayerTimes();

      _todayTimes = todayCache;
      _isOfflineUsingCache = true;

      unawaited(
        _adhanScheduler.scheduleNextAdhan(
          todayCache,
          tomorrowPrayerTimes: tomorrowCache,
        ),
      );

      return;
    }

    final cache = _prayerService.getCachedPrayerTimes();

    if (cache != null && cache.isValidChronologically()) {
      _todayTimes = cache;
      _isOfflineUsingCache = true;

      unawaited(
        _adhanScheduler.scheduleNextAdhan(
          cache,
          tomorrowPrayerTimes: tomorrowCache,
        ),
      );
    } else {
      unawaited(_adhanScheduler.scheduleNextAdhan(null));
    }
  }

  // ── REFRESH CITY NAME WHEN LANGUAGE CHANGES ────────────────────────────────

  /// Call this from the View whenever the app locale changes.
  void refreshCityNameForLocale(String locale) {
    if (locale == _lastLocale) return;

    if (_lastLat == null || _lastLng == null) {
      _lastLocale = locale;
      return;
    }

    _cityName = null;
    notifyListeners();

    unawaited(_fetchCityName(_lastLat!, _lastLng!, locale: locale));
  }

  // ── REVERSE GEOCODING ──────────────────────────────────────────────────────
  // Nominatim — no API key required.

  Future<void> _fetchCityName(
    double lat,
    double lng, {
    String locale = 'ar',
  }) async {
    _lastLat = lat;
    _lastLng = lng;
    _lastLocale = locale;

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=$lat&lon=$lng&accept-language=$locale&zoom=10',
      );

      final response = await http
          .get(uri, headers: const {'User-Agent': 'KhaleekMomen/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final city =
              address['city'] as String? ??
              address['town'] as String? ??
              address['municipality'] as String? ??
              address['county'] as String? ??
              address['state'] as String?;

          if (city != null && city.isNotEmpty) {
            _cityName = city;

            developer.log(
              'City ($locale): $_cityName',
              name: 'PrayerController',
            );

            notifyListeners();
            return;
          }
        }
      }

      _fallbackCityFromTimezone();
    } catch (e) {
      developer.log('City name fetch failed: $e', name: 'PrayerController');

      _fallbackCityFromTimezone();
    }
  }

  void _fallbackCityFromTimezone() {
    if (_cityName != null) return;
    if (_todayTimes == null) return;

    final tz = _todayTimes!.timezone;

    if (tz.contains('/')) {
      _cityName = tz.split('/').last.replaceAll('_', ' ');
      notifyListeners();
    }
  }
}
