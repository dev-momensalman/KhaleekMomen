import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:islamic_audio_hub/core/services/location_service.dart';
import 'package:islamic_audio_hub/core/services/prayer_service.dart';
import 'package:islamic_audio_hub/core/services/adhan_scheduler.dart';
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

  PrayerController(
    this._prayerService,
    this._locationService,
    this._adhanScheduler,
  ) {
    WidgetsBinding.instance.addObserver(this);
    // Listen to scheduler changes to notify our UI immediately
    _adhanScheduler.addListener(notifyListeners);
    // Attempt to load cached prayer times immediately on startup
    _loadCachedTimes();
    // Start periodic day change checking
    _startDayChangeTimer();
    // Always fetch fresh prayer times on startup (schedules notifications too)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPrayerTimes();
    });
  }

  // Getters
  PrayerTimes? get todayTimes => _todayTimes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOfflineUsingCache => _isOfflineUsingCache;
  bool get isValid =>
      _todayTimes != null && _todayTimes!.isValidChronologically();

  void _loadCachedTimes() {
    final cache = _prayerService.getCachedPrayerTimes();
    if (cache != null && cache.isValidChronologically()) {
      _todayTimes = cache;
      _isOfflineUsingCache = !_prayerService.hasValidCacheForToday();
      unawaited(_adhanScheduler.scheduleNextAdhan(cache));
      notifyListeners();
    }
  }

  void _startDayChangeTimer() {
    _dayChangeTimer?.cancel();
    _dayChangeTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkDayChange();
    });
  }

  void _checkDayChange() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_todayTimes != null && _todayTimes!.date != todayStr) {
      developer.log(
        'Calendar day changed. Fetching new prayer times.',
        name: 'PrayerController',
      );
      fetchPrayerTimes();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      developer.log(
        'App resumed - checking and fetching prayer times.',
        name: 'PrayerController',
      );
      _checkDayChange();
      if (!_prayerService.hasValidCacheForToday()) {
        fetchPrayerTimes();
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

  /// Fetches prayer times from API using the user's location.
  /// If location is unavailable, it shows an error and attempts cached fallback only if the cache is for today.
  Future<void> fetchPrayerTimes({bool force = false}) async {
    final hasValidCache = _prayerService.hasValidCacheForToday();

    if (force || !hasValidCache || _todayTimes == null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // 1. Get Coordinates (throws specific LocationService exceptions if denied/disabled)
      final position = await _locationService.getCurrentLocation();

      _isOfflineUsingCache = false;

      // 2. Fetch times (PrayerService handles API -> local cache fallback)
      final times = await _prayerService.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        force: force,
      );

      _todayTimes = times;
      _errorMessage = null;

      // Update scheduler
      unawaited(_adhanScheduler.scheduleNextAdhan(times));
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

  void _handleOfflineOrFailedFetch() {
    // If we have a valid cache specifically for TODAY, use it.
    if (_prayerService.hasValidCacheForToday()) {
      _todayTimes = _prayerService.getCachedPrayerTimes();
      _isOfflineUsingCache = true;
      unawaited(_adhanScheduler.scheduleNextAdhan(_todayTimes));
    } else {
      // If we have a cache from any day, use it as fallback rather than cancelling the countdown/Adhans
      final cache = _prayerService.getCachedPrayerTimes();
      if (cache != null) {
        _todayTimes = cache;
        _isOfflineUsingCache = true;
        unawaited(_adhanScheduler.scheduleNextAdhan(cache));
      } else {
        // Cancel adhan scheduling only if we don't have any cached times at all
        unawaited(_adhanScheduler.scheduleNextAdhan(null));
      }
    }
  }
}
