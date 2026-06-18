import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:islamic_audio_hub/core/services/http_service.dart';
import 'package:islamic_audio_hub/core/services/prayer_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/adhan_scheduler.dart';
import 'package:islamic_audio_hub/data/models/prayer_times.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';
import 'package:islamic_audio_hub/data/models/adhan_sound_option.dart';
import 'package:islamic_audio_hub/controllers/settings_controller.dart';

// Fake/Mock implementations to run tests in complete isolation without Flutter/Native dependencies

class FakeHttpService extends HttpService {
  final Map<String, dynamic>? mockResponse;
  final bool shouldThrow;

  FakeHttpService({
    this.mockResponse,
    this.shouldThrow = false,
  }) : super(baseUrl: 'https://api.aladhan.com/v1');

  @override
  Future<dynamic> get(String path, {Map<String, String>? headers}) async {
    if (shouldThrow) {
      throw NetworkException(message: 'Network connection failed');
    }
    return mockResponse;
  }
}

class FakeStorageService extends StorageService {
  final Map<String, dynamic> _data = {};

  @override
  dynamic get(String key, {dynamic defaultValue}) {
    return _data.containsKey(key) ? _data[key] : defaultValue;
  }

  @override
  Future<void> put(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

class FakeAudioServiceWrapper extends AudioServiceWrapper {
  AudioState _fakeState = const AudioState();
  final BehaviorSubject<AudioState> _fakeStateSubject =
      BehaviorSubject<AudioState>.seeded(const AudioState());

  @override
  AudioState get currentState => _fakeState;

  @override
  Stream<AudioState> get stateStream => _fakeStateSubject.stream;

  final List<String> playedUrls = [];
  bool stoppedCalled = false;

  @override
  Future<void> play(
    String url,
    AudioMode targetMode, {
    required String title,
    required String subtitle,
  }) async {
    playedUrls.add(url);
    _fakeState = AudioState(
      mode: targetMode,
      isPlaying: true,
      currentSource: title,
      isLocked: targetMode == AudioMode.adhan,
    );
    _fakeStateSubject.add(_fakeState);
  }

  @override
  Future<void> stop() async {
    stoppedCalled = true;
    _fakeState = const AudioState(
      mode: AudioMode.idle,
      isPlaying: false,
      currentSource: null,
      isLocked: false,
    );
    _fakeStateSubject.add(_fakeState);
  }
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PrayerTimes Model Tests', () {
    test('fromJson & toJson should serialize and deserialize correctly', () {
      final json = {
        'date': '2026-06-15',
        'fajr': '04:15',
        'sunrise': '05:45',
        'dhuhr': '12:20',
        'asr': '15:45',
        'maghrib': '19:10',
        'isha': '20:40',
        'latitude': 21.4225,
        'longitude': 39.8262,
        'timezone': 'Asia/Riyadh',
      };

      final prayerTimes = PrayerTimes.fromJson(json);

      expect(prayerTimes.date, '2026-06-15');
      expect(prayerTimes.fajr, '04:15');
      expect(prayerTimes.dhuhr, '12:20');
      expect(prayerTimes.latitude, 21.4225);

      final outputJson = prayerTimes.toJson();
      expect(outputJson['date'], '2026-06-15');
      expect(outputJson['asr'], '15:45');
    });

    test('getDateTimeForPrayer should parse HH:mm correctly', () {
      final prayerTimes = PrayerTimes(
        date: '2026-06-15',
        fajr: '04:15',
        sunrise: '05:45',
        dhuhr: '12:20',
        asr: '15:45',
        maghrib: '19:10',
        isha: '20:40',
        timezone: 'Asia/Riyadh',
      );

      final dateTime = prayerTimes.getDateTimeForPrayer(prayerTimes.fajr);
      expect(dateTime, isNotNull);
      expect(dateTime!.year, 2026);
      expect(dateTime.month, 6);
      expect(dateTime.day, 15);
      expect(dateTime.hour, 4);
      expect(dateTime.minute, 15);
    });
  });

  group('PrayerService Isolated Tests', () {
    late FakeStorageService fakeStorage;

    setUp(() {
      fakeStorage = FakeStorageService();
    });

    test('getPrayerTimes returns valid timings from API and caches them', () async {
      final mockApiResponse = {
        'data': {
          'timings': {
            'Fajr': '04:12',
            'Sunrise': '05:40',
            'Dhuhr': '12:15',
            'Asr': '15:35',
            'Sunset': '19:05',
            'Maghrib': '19:07',
            'Isha': '20:37',
            'Imsak': '04:02',
            'Midnight': '00:15',
            'Firstthird': '22:45',
            'Lastthird': '01:45'
          },
          'meta': {
            'timezone': 'Asia/Riyadh',
          }
        }
      };

      final fakeHttp = FakeHttpService(mockResponse: mockApiResponse);
      final service = PrayerService(fakeHttp, fakeStorage);

      final result = await service.getPrayerTimes(latitude: 21.4, longitude: 39.8);

      expect(result.fajr, '04:12');
      expect(result.dhuhr, '12:15');
      expect(result.timezone, 'Asia/Riyadh');

      // Check if it got cached correctly
      final cachedJson = fakeStorage.get('cached_prayer_times');
      expect(cachedJson, isNotNull);
      expect(cachedJson['fajr'], '04:12');
    });

    test('getPrayerTimes falls back to valid today cache if API call fails', () async {
      // Force network error
      final fakeHttp = FakeHttpService(shouldThrow: true);
      final service = PrayerService(fakeHttp, fakeStorage);

      // We need to match today's date for fallback cache validation.
      // Since getDateTimeForPrayer / today date in service uses DateTime.now(),
      // let's dynamically write cache with today's date format.
      final now = DateTime.now();
      final nowFormatted = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final todayCachedTimes = PrayerTimes(
        date: nowFormatted,
        fajr: '04:10',
        sunrise: '05:40',
        dhuhr: '12:10',
        asr: '15:40',
        maghrib: '19:10',
        isha: '20:40',
        timezone: 'Asia/Riyadh',
      );
      await fakeStorage.put('cached_prayer_times', todayCachedTimes.toJson());

      final result = await service.getPrayerTimes(latitude: 21.4, longitude: 39.8);
      expect(result.fajr, '04:10');
      expect(result.date, nowFormatted);
    });

    test('getPrayerTimes throws exception if API fails and cache is invalid/missing', () async {
      final fakeHttp = FakeHttpService(shouldThrow: true);
      final service = PrayerService(fakeHttp, fakeStorage);

      expect(
        () async => await service.getPrayerTimes(latitude: 21.4, longitude: 39.8),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AdhanScheduler Tests', () {
    late FakeStorageService fakeStorage;
    late AudioServiceWrapper fakeAudio;
    late AdhanScheduler scheduler;

    setUp(() {
      fakeStorage = FakeStorageService();
      fakeAudio = AudioServiceWrapper();
      scheduler = AdhanScheduler(fakeAudio, fakeStorage);
    });

    tearDown(() {
      scheduler.dispose();
    });

    test('scheduleNextAdhan with valid future prayers should schedule the first future one', () {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final futureTime = now.add(const Duration(hours: 2));
      final futureTimeStr = '${futureTime.hour.toString().padLeft(2, '0')}:${futureTime.minute.toString().padLeft(2, '0')}';
      
      final prayerTimes = PrayerTimes(
        date: dateStr,
        fajr: '00:01', // past
        sunrise: '00:02', // past
        dhuhr: futureTimeStr, // future
        asr: '23:57', // future
        maghrib: '23:58', // future
        isha: '23:59', // future
        timezone: 'UTC',
      );

      scheduler.scheduleNextAdhan(prayerTimes);

      expect(scheduler.scheduledPrayerName, 'Dhuhr');
      expect(scheduler.scheduledTime, isNotNull);
      expect(scheduler.scheduledTime!.hour, futureTime.hour);
      expect(scheduler.scheduledTime!.minute, futureTime.minute);
    });

    test('scheduleNextAdhan when all today\'s prayers have passed should schedule tomorrow\'s Fajr', () {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final prayerTimes = PrayerTimes(
        date: dateStr,
        fajr: '00:01',
        sunrise: '00:02',
        dhuhr: '00:03',
        asr: '00:04',
        maghrib: '00:05',
        isha: '00:06',
        timezone: 'UTC',
      );

      scheduler.scheduleNextAdhan(prayerTimes);

      expect(scheduler.scheduledPrayerName, 'Fajr');
      expect(scheduler.scheduledTime, isNotNull);
      
      final tomorrow = now.add(const Duration(days: 1));
      expect(scheduler.scheduledTime!.day, tomorrow.day);
      expect(scheduler.scheduledTime!.hour, 0);
      expect(scheduler.scheduledTime!.minute, 1);
    });

    test('AdhanScheduler notifies listeners when scheduled time changes', () {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final futureTime = now.add(const Duration(hours: 1));
      final futureTimeStr = '${futureTime.hour.toString().padLeft(2, '0')}:${futureTime.minute.toString().padLeft(2, '0')}';

      final prayerTimes = PrayerTimes(
        date: dateStr,
        fajr: futureTimeStr,
        sunrise: '23:55',
        dhuhr: '23:56',
        asr: '23:57',
        maghrib: '23:58',
        isha: '23:59',
        timezone: 'UTC',
      );

      bool notified = false;
      scheduler.addListener(() {
        notified = true;
      });

      scheduler.scheduleNextAdhan(prayerTimes);

      expect(notified, isTrue);
    });
  });

  group('Adhan Sound Selection and Settings Tests', () {
    late FakeStorageService fakeStorage;
    late FakeAudioServiceWrapper fakeAudio;
    late AdhanScheduler scheduler;
    late SettingsController controller;

    setUp(() {
      fakeStorage = FakeStorageService();
      fakeAudio = FakeAudioServiceWrapper();
      scheduler = AdhanScheduler(fakeAudio, fakeStorage);
      controller = SettingsController(fakeStorage, scheduler, fakeAudio);
    });

    test('AdhanSoundOption.fromFileName matches options or defaults correctly', () {
      // Default fallback when null/empty
      expect(AdhanSoundOption.fromFileName(null), AdhanSoundOption.all.first);
      expect(AdhanSoundOption.fromFileName(''), AdhanSoundOption.all.first);
      expect(AdhanSoundOption.fromFileName('invalid_file.mp3'), AdhanSoundOption.all.first);

      // Matches valid options
      final secondOption = AdhanSoundOption.all[1];
      expect(AdhanSoundOption.fromFileName(secondOption.fileName), secondOption);

      // Validate all rawResourceName fields are ASCII-safe (lowercase alphanumeric + underscore)
      final asciiRegex = RegExp(r'^[a-z0-9_]+$');
      for (final option in AdhanSoundOption.all) {
        expect(asciiRegex.hasMatch(option.rawResourceName), isTrue,
            reason: '${option.rawResourceName} is not a valid Android resource name');
      }
    });

    test('SettingsController loads selected adhan sound correctly and updates it', () async {
      final targetOption = AdhanSoundOption.all[2];
      
      // Select adhan
      await controller.selectAdhan(targetOption);
      
      expect(controller.selectedAdhan, targetOption);
      expect(fakeStorage.getSelectedAdhanSound(), targetOption.fileName);
    });

    test('SettingsController preview adhan plays and stops audio correctly', () async {
      final targetOption = AdhanSoundOption.all[3];

      expect(controller.isPreviewing, isFalse);
      expect(controller.previewedAdhan, isNull);
      
      // Start preview
      await controller.previewAdhan(targetOption);
      await Future.delayed(Duration.zero);
      expect(fakeAudio.playedUrls.last, targetOption.assetPath);
      expect(fakeAudio.currentState.currentSource, targetOption.displayName);
      expect(controller.isPreviewing, isTrue);
      expect(controller.previewedAdhan, targetOption);

      // Stop preview
      controller.stopPreview();
      await Future.delayed(Duration.zero);
      expect(fakeAudio.stoppedCalled, isTrue);
      expect(controller.isPreviewing, isFalse);
      expect(controller.previewedAdhan, isNull);
    });

    test('SettingsController loads Arabic as default language, and respects saved English preference', () async {
      // 1. Fresh install scenario: storage is empty.
      final freshStorage = FakeStorageService();
      final controllerFresh = SettingsController(freshStorage, scheduler, fakeAudio);
      expect(controllerFresh.locale.languageCode, 'ar');

      // 2. Existing user scenario: user saved 'en'.
      final existingStorage = FakeStorageService();
      await existingStorage.put('language', 'en');
      final controllerExisting = SettingsController(existingStorage, scheduler, fakeAudio);
      expect(controllerExisting.locale.languageCode, 'en');

      // 3. Changing language dynamically updates locale and saves it.
      await controllerFresh.updateLanguage('en');
      expect(controllerFresh.locale.languageCode, 'en');
      expect(freshStorage.getLanguage(), 'en');
    });
  });
}
