// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services
import 'package:islamic_audio_hub/core/services/http_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/core/services/location_service.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/prayer_service.dart';
import 'package:islamic_audio_hub/core/services/radio_service.dart';
import 'package:islamic_audio_hub/core/services/quran_service.dart';
import 'package:islamic_audio_hub/core/services/azkar_service.dart';
import 'package:islamic_audio_hub/core/services/adhan_scheduler.dart';
import 'package:islamic_audio_hub/core/services/notification_service.dart';
import 'package:islamic_audio_hub/core/services/adhan_work_manager.dart';

// Controllers
import 'package:islamic_audio_hub/controllers/settings_controller.dart';
import 'package:islamic_audio_hub/controllers/prayer_controller.dart';
import 'package:islamic_audio_hub/controllers/radio_controller.dart';
import 'package:islamic_audio_hub/controllers/quran_controller.dart';
import 'package:islamic_audio_hub/controllers/azkar_controller.dart';
import 'package:islamic_audio_hub/controllers/home_controller.dart';

// Views & Theme
import 'package:islamic_audio_hub/views/main_navigation_scaffold.dart';
import 'package:islamic_audio_hub/views/onboarding/onboarding_view.dart';
import 'package:islamic_audio_hub/core/theme/app_theme.dart';
import 'package:islamic_audio_hub/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  HttpService? _httpService;
  LocationService? _locationService;
  StorageService? _storageService;
  AudioServiceWrapper? _audioService;
  PrayerService? _prayerService;
  RadioService? _radioService;
  QuranService? _quranService;
  AzkarService? _azkarService;
  AdhanScheduler? _adhanScheduler;

  bool _isBootstrapping = true;
  bool _showOnboarding = false;
  bool _deferredStartupStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    // ── 1. Minimal required startup only ──────────────────────────────────
    // Keep the first app launch light. Do not initialize notifications,
    // WorkManager, AudioService, location, or adhan scheduling here.
    try {
      await StorageService.init();
    } catch (e) {
      debugPrint('[Boot] Storage init failed: $e');
    }

    // ── 2. Create lightweight services ───────────────────────────────────
    _httpService = HttpService(baseUrl: 'https://mp3quran.net');
    _locationService = LocationService();
    _storageService = StorageService();

    // AudioServiceWrapper object is lightweight. The heavy native
    // AudioService.init() is delayed in _runDeferredStartupTasks().
    _audioService = AudioServiceWrapper();

    _prayerService = PrayerService(
      HttpService(baseUrl: 'https://api.aladhan.com/v1'),
      _storageService!,
    );

    _radioService = RadioService();
    _quranService = QuranService(_httpService!);
    _azkarService = AzkarService();
    _adhanScheduler = AdhanScheduler(_audioService!, _storageService!);

    if (!mounted) return;

    final showOnboarding = !(_storageService?.isOnboardingCompleted ?? false);

    setState(() {
      _isBootstrapping = false;
      _showOnboarding = showOnboarding;
    });

    // ── 3. Start heavy services after the UI is visible ───────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runDeferredStartupTasks();
    });
  }

  void _runDeferredStartupTasks() {
    if (_deferredStartupStarted) return;
    _deferredStartupStarted = true;

    // 1) Re-schedule from cached prayer times after the first screen appears.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      try {
        _adhanScheduler?.rescheduleFromCache();
      } catch (e) {
        debugPrint('[Boot] Adhan cache reschedule failed: $e');
      }
    });

    // 2) Initialize notification plugin later to avoid startup jank.
    Future.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;

      try {
        await NotificationService.init();
      } catch (e) {
        debugPrint('[Boot] Notification init failed: $e');
      }
    });

    // 3) Register WorkManager later. It does not need to block app launch.
    Future.delayed(const Duration(seconds: 7), () async {
      if (!mounted) return;

      try {
        await registerAdhanWorker();
      } catch (e) {
        debugPrint('[Boot] WorkManager registration failed: $e');
      }
    });

    // 4) Warm up background audio last. Quran/Radio playback will still work
    // once the user interacts, but this avoids blocking the first screen.
    Future.delayed(const Duration(seconds: 10), () async {
      if (!mounted) return;

      try {
        await AudioServiceWrapper.init();
      } catch (e) {
        debugPrint('[Boot] Audio init failed: $e');
      }
    });
  }

  @override
  void dispose() {
    _audioService?.dispose();
    _adhanScheduler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) return _buildSplash();

    final audio = _audioService!;
    final storage = _storageService!;
    final location = _locationService!;
    final scheduler = _adhanScheduler!;
    final prayer = _prayerService!;
    final radio = _radioService!;
    final quran = _quranService!;
    final azkar = _azkarService!;

    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<AudioServiceWrapper>.value(value: audio),
        ChangeNotifierProvider<AdhanScheduler>.value(value: scheduler),

        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(storage, scheduler, audio),
        ),

        // Keep PrayerController lazy. It will be created when a screen
        // actually needs it, instead of forcing Geolocator at startup.
        ChangeNotifierProvider<PrayerController>(
          create: (_) => PrayerController(prayer, location, scheduler),
        ),

        ChangeNotifierProvider<RadioController>(
          create: (_) {
            final ctrl = RadioController(radio, storage, audio);

            // Delay station fetching so it does not compete with first render.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(seconds: 5), () {
                unawaited(ctrl.fetchStations());
              });
            });

            return ctrl;
          },
        ),

        ChangeNotifierProvider<QuranController>(
          create: (_) => QuranController(quran, storage, audio),
        ),

        ChangeNotifierProvider<AzkarController>(
          create: (_) => AzkarController(azkar),
        ),

        ChangeNotifierProvider<HomeController>(
          create: (_) => HomeController(storage, scheduler, audio),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'خليك مؤمن',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              final isRtl = settings.locale.languageCode == 'ar';

              return Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },
            home: _showOnboarding
                ? OnboardingView(
                    onComplete: () => setState(() => _showOnboarding = false),
                  )
                : const MainNavigationScaffold(),
          );
        },
      ),
    );
  }

  Widget _buildSplash() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        backgroundColor: AppTheme.primaryEmerald,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset('assets/icon/icon.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'خليك مؤمن',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'استمع • تعلم • تذكر',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
