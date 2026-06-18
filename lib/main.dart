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

// ─── BOOT RULE: main() must ONLY contain ensureInitialized + runApp ──────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // All services are null until _bootstrap() completes.
  // This ensures they are created AFTER Hive and AudioService are ready.
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

  @override
  void initState() {
    super.initState();
    // Defer ALL heavy work to after the first frame — no IO in initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    // ── 1. Hive storage (crash-safe) ─────────────────────────────────────────
    try {
      await StorageService.init();
    } catch (e) {
      assert(() {
        debugPrint('[Boot] Storage init failed: $e');
        return true;
      }());
      // Storage failed → app continues, features that need storage will degrade.
    }

    // ── 2. OS Prayer Notifications (crash-safe) ───────────────────────────────
    try {
      await NotificationService.init();
      await NotificationService.checkAndRequestBatteryOptimization();
    } catch (e) {
      assert(() {
        debugPrint('[Boot] Notification service init failed: $e');
        return true;
      }());
      // Notification failure is non-fatal — prayer times still show in UI.
    }

    // ── 3. Background audio engine (crash-safe) ───────────────────────────────
    try {
      await AudioServiceWrapper.init();
    } catch (e) {
      assert(() {
        debugPrint('[Boot] Audio init failed: $e');
        return true;
      }());
      // Audio failed → AudioServiceWrapper.isAvailable will be false.
      // All audio features degrade gracefully; app does NOT crash.
    }

    // ── 4. Create services AFTER init() has run ───────────────────────────────
    //    AudioServiceWrapper() must be constructed AFTER AudioServiceWrapper.init()
    //    so that _attachListeners() runs when _handler is already assigned.
    _httpService = HttpService(baseUrl: 'https://mp3quran.net');
    _locationService = LocationService();
    _storageService = StorageService();
    _audioService = AudioServiceWrapper(); // Listeners attach here ✓
    _prayerService = PrayerService(
      HttpService(baseUrl: 'https://api.aladhan.com/v1'),
      _storageService!,
    );
    _radioService = RadioService(_httpService!);
    _quranService = QuranService(_httpService!);
    _azkarService = AzkarService();
    _adhanScheduler = AdhanScheduler(_audioService!, _storageService!);

    if (mounted) {
      final showOnboarding = !(_storageService?.isOnboardingCompleted ?? false);
      setState(() {
        _isBootstrapping = false;
        _showOnboarding = showOnboarding;
      });
    }
  }

  @override
  void dispose() {
    _audioService?.dispose();
    _adhanScheduler?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Show a Material 3 splash while services initialise.
    if (_isBootstrapping) return _buildSplash();

    // All services are non-null beyond this point.
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
        // ── Services ──────────────────────────────────────────────────────
        Provider<StorageService>.value(value: storage),
        Provider<AudioServiceWrapper>.value(value: audio),
        ChangeNotifierProvider<AdhanScheduler>.value(value: scheduler),

        // ── Controllers ───────────────────────────────────────────────────
        // Using plain ChangeNotifierProvider for all controllers.
        // Services are captured via closure — no ProxyProvider type-lookup risk.
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(storage, scheduler, audio),
        ),
        ChangeNotifierProvider<PrayerController>(
          create: (_) {
            final ctrl = PrayerController(prayer, location, scheduler);
            // Initial fetch deferred to avoid doing IO inside provider create.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ctrl.fetchPrayerTimes();
            });
            return ctrl;
          },
        ),
        ChangeNotifierProvider<RadioController>(
          create: (_) {
            final ctrl = RadioController(radio, storage, audio);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ctrl.fetchStations();
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

  // ── Splash shown while bootstrap runs (Material 3, theme-aware) ────────────
  Widget _buildSplash() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryEmerald),
              SizedBox(height: 28),
              Text(
                'Islamic Audio Hub',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryEmerald,
                ),
              ),
              SizedBox(height: 8),
              Text('Starting up…', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
