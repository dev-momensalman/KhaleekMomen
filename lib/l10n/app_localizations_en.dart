// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Islamic Audio Hub';

  @override
  String get home => 'Home';

  @override
  String get quran => 'Quran';

  @override
  String get radio => 'Radio';

  @override
  String get azkar => 'Azkar';

  @override
  String get prayer => 'Prayer';

  @override
  String get nobleQuran => 'Noble Quran';

  @override
  String get liveRadio => 'Live Radio';

  @override
  String get dailyAzkar => 'Daily Azkar';

  @override
  String get prayerAndQibla => 'Prayer & Qibla';

  @override
  String get favorites => 'Favorites';

  @override
  String get settings => 'Settings';

  @override
  String get currentReciter => 'Current Reciter';

  @override
  String get changeReciter => 'Change Reciter';

  @override
  String get searchSurah => 'Search Surah (e.g. Al-Fatihah, 18)...';

  @override
  String get selectReciter => 'Select Reciter';

  @override
  String get noSurahsFound => 'No Surahs match your search.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get networkError => 'Network Error';

  @override
  String get connectionError => 'Connection Error';

  @override
  String get verses => 'Verses';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light Theme';

  @override
  String get themeDark => 'Dark Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get adhanAutoplay => 'Adhan Autoplay';

  @override
  String get myFavorites => 'My Favorites';

  @override
  String get audioScheduling => 'Audio & Scheduling';

  @override
  String get adhanAutoplaySubtitle =>
      'Play the Adhan notification audio automatically at prayer times.';

  @override
  String get personalization => 'Personalization';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get appLanguage => 'App Language';

  @override
  String get aboutApplication => 'About Application';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get dataSafety => 'Data Safety & Privacy';

  @override
  String get dataSafetySubtitle =>
      'All calculation coordinates and storage parameters stay 100% offline on your device.';

  @override
  String get privacySnackbar =>
      'Privacy Guard: Coordinates are processed locally on your device.';

  @override
  String nextPrayer(String name) {
    return 'Next Prayer: $name';
  }

  @override
  String get liveDeviceScheduler => 'Live Device Time Scheduler';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get exploreHub => 'Explore Hub';

  @override
  String get islamicRadio => 'Islamic Radio';

  @override
  String get liveStations => 'Live Stations';

  @override
  String get countersAndText => 'Counters & Text';

  @override
  String get adhanAndQibla => 'Adhan & Qibla';

  @override
  String get listenToReciters => 'Listen to Reciters';

  @override
  String get resetAllCategory => 'Reset All Category';

  @override
  String get resetCountersTitle => 'Reset Counters?';

  @override
  String resetCountersMessage(String category) {
    return 'This will reset all progress counters for $category Azkar.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get morningAzkar => 'Morning';

  @override
  String get eveningAzkar => 'Evening';

  @override
  String get sleepAzkar => 'Sleep';

  @override
  String get generalAzkar => 'General';

  @override
  String get todaysTimings => 'Today\'s Timings';

  @override
  String get qiblaDirection => 'Qibla Direction';

  @override
  String get kaabaDirAngle => 'Kaaba Direction Angle';

  @override
  String get relativeToBearing => 'Calculated relative to North bearing';

  @override
  String qiblaDegrees(String degrees) {
    return 'Qibla: $degrees° E of N';
  }

  @override
  String region(String timezone) {
    return 'Region: $timezone';
  }

  @override
  String get updateCoordinates => 'Update coordinates';

  @override
  String get noConnectionOffline => 'No Connection / Offline';

  @override
  String get cachedOfflineData => 'Cached Offline Data';

  @override
  String get liveApiSynced => 'Live API Synchronized';

  @override
  String get prayerTimesUnavailable => 'Prayer Times Unavailable';

  @override
  String get prayerTimesDefaultError =>
      'Please enable location permissions and connect to the internet to calculate prayer schedules.';

  @override
  String get retryFetching => 'Retry Fetching';

  @override
  String get coordsUnavailable =>
      'Coordinates unavailable. Cannot calculate Qibla direction.';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get radioStations => 'Radio Stations';

  @override
  String get quranSurahs => 'Quran Surahs';

  @override
  String get noRadioFavorites => 'No Radio Favorites';

  @override
  String get noRadioFavoritesMsg =>
      'Explore live radios and tap the heart icon to save stations here.';

  @override
  String get noSurahFavorites => 'No Surah Favorites';

  @override
  String get noSurahFavoritesMsg =>
      'Select a reciter, browse surahs, and add your favorite chapters here.';

  @override
  String get searchRadioStations => 'Search Radio Stations...';

  @override
  String get refreshStations => 'Refresh Stations';

  @override
  String get noStationsMatch => 'No stations match your search.';

  @override
  String get unknownAudio => 'Unknown Audio';

  @override
  String get islamicAudioHub => 'Islamic Audio Hub';

  @override
  String get noVersesFound => 'No verses found.';

  @override
  String get adhanPrioritySystem => 'Adhan Priority System';

  @override
  String get quranRecitation => 'Quran Recitation';

  @override
  String get islamicRadioStation => 'Islamic Radio Station';

  @override
  String get adhanBroadcast => 'Adhan Broadcast';

  @override
  String get audioPlayer => 'Audio Player';

  @override
  String get permissionDeniedTitle => 'Permission Required';

  @override
  String get permissionDeniedBody =>
      'This permission was permanently denied. Please enable it from app settings to use this feature.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get skip => 'Skip';

  @override
  String get onboardWelcomeTitle => 'Welcome to Islamic Audio Hub';

  @override
  String get onboardWelcomeSubtitle =>
      'Your complete Islamic companion for Quran, prayer times, live radio, and daily Azkar — all in one beautiful app.';

  @override
  String get onboardFeatureQuran =>
      'Listen to the Holy Quran with world-class reciters';

  @override
  String get onboardFeaturePrayer =>
      'Accurate prayer times with automatic Adhan';

  @override
  String get onboardFeatureRadio =>
      'Live Islamic radio stations from around the world';

  @override
  String get onboardFeatureAzkar =>
      'Morning, evening and sleep Azkar reminders';

  @override
  String get onboardLocationTitle => 'Location Permission';

  @override
  String get onboardLocationSubtitle =>
      'We need your location to calculate precise prayer times and Qibla direction for your city.';

  @override
  String get onboardWhyNeeded => 'Why we need this:';

  @override
  String get onboardLocationBullet1 =>
      'Calculate the 5 daily prayer times based on your exact coordinates';

  @override
  String get onboardLocationBullet2 =>
      'Show the precise Qibla compass direction toward the Kaaba';

  @override
  String get onboardLocationBullet3 =>
      'Your location is processed 100% locally — never uploaded to any server';

  @override
  String get onboardGrantLocation => 'Allow Location Access';

  @override
  String get onboardNotifTitle => 'Prayer Notifications';

  @override
  String get onboardNotifSubtitle =>
      'Allow notifications so the app can alert you when each prayer time arrives, even when the screen is off.';

  @override
  String get onboardNotifBullet1 =>
      'Receive a notification at each of the 5 daily prayer times';

  @override
  String get onboardNotifBullet2 =>
      'Notifications play your selected Adhan sound automatically';

  @override
  String get onboardNotifBullet3 =>
      'You can disable individual prayers anytime from Settings';

  @override
  String get onboardGrantNotif => 'Allow Notifications';

  @override
  String get onboardAlarmTitle => 'Exact Alarm Permission';

  @override
  String get onboardAlarmSubtitle =>
      'Android requires special permission to schedule alarms at exact times — essential for prayers that cannot be late.';

  @override
  String get onboardAlarmBullet1 =>
      'Ensures Adhan fires at the precise prayer time, not minutes late';

  @override
  String get onboardAlarmBullet2 =>
      'Required by Android for exact-time scheduling (API 31+)';

  @override
  String get onboardAlarmBullet3 =>
      'Without this, prayer notifications may be delayed by the OS';

  @override
  String get onboardGrantAlarm => 'Allow Exact Alarms';

  @override
  String get onboardBatteryTitle => 'Battery Optimization';

  @override
  String get onboardBatterySubtitle =>
      'Disable battery optimization for this app so the Adhan continues to work reliably when your phone is idle or the screen is off.';

  @override
  String get onboardBatteryBullet1 =>
      'Prevents Android from killing the Adhan scheduler in Doze mode';

  @override
  String get onboardBatteryBullet2 =>
      'Ensures prayer alarms fire even overnight or during long screen-off periods';

  @override
  String get onboardBatteryBullet3 =>
      'The app uses minimal battery — this only removes the delay restriction';

  @override
  String get onboardGrantBattery => 'Disable Battery Restriction';

  @override
  String get onboardPermissionGranted => 'Permission granted';

  @override
  String get onboardDoneTitle => 'You\'re All Set!';

  @override
  String get onboardDoneSubtitle =>
      'Islamic Audio Hub is ready. May Allah accept your worship and keep you consistent in prayer.';

  @override
  String get onboardDoneNotif => 'Prayer notifications enabled';

  @override
  String get onboardDoneAlarm => 'Exact Adhan alarms configured';

  @override
  String get onboardDoneBattery => 'Reliable background delivery';

  @override
  String get onboardNext => 'Next';

  @override
  String get onboardFinish => 'Start Using App';

  @override
  String get tafsirTitle => 'Tafsir';

  @override
  String get tafsirLabel => 'Tafsir (Simplified)';

  @override
  String get tafsirUnavailable =>
      'Tafsir is not available for this verse while offline.';

  @override
  String get translationLabel => 'Translation';

  @override
  String get copyAyah => 'Copy verse';

  @override
  String get ayahCopied => 'Verse copied to clipboard';

  @override
  String get jumpToAyah => 'Jump to verse';

  @override
  String get ayahNumberHint => 'Verse number';

  @override
  String get go => 'Go';

  @override
  String get lastReadLabel => 'Last read';

  @override
  String get continueReading => 'Continue reading';

  @override
  String get ayahLabel => 'Verse';
}
