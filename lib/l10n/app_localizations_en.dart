// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KhaleekMomen';

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
      'Play the Adhan automatically at each prayer time.';

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
      'All data stays 100% offline on your device. Never shared.';

  @override
  String get privacySnackbar =>
      'Privacy Guard: All data is processed locally on your device.';

  @override
  String nextPrayer(String name) {
    return 'Next Prayer: $name';
  }

  @override
  String get liveDeviceScheduler => 'Device Time';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get exploreHub => 'Explore';

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
  String get relativeToBearing => 'Calculated relative to North';

  @override
  String qiblaDegrees(String degrees) {
    return 'Qibla: $degrees° E of N';
  }

  @override
  String region(String timezone) {
    return 'Region: $timezone';
  }

  @override
  String get updateCoordinates => 'Update Location';

  @override
  String get noConnectionOffline => 'No Internet Connection';

  @override
  String get cachedOfflineData => 'Cached Data';

  @override
  String get liveApiSynced => 'Live Synced';

  @override
  String get prayerTimesUnavailable => 'Prayer Times Unavailable';

  @override
  String get prayerTimesDefaultError =>
      'Please enable location permissions and connect to the internet to calculate prayer times.';

  @override
  String get retryFetching => 'Retry';

  @override
  String get coordsUnavailable =>
      'Location unavailable. Cannot calculate Qibla direction.';

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
      'Select a reciter, browse surahs, and add your favorites here.';

  @override
  String get searchRadioStations => 'Search Radio Stations...';

  @override
  String get refreshStations => 'Refresh Stations';

  @override
  String get noStationsMatch => 'No stations match your search.';

  @override
  String get unknownAudio => 'Unknown Audio';

  @override
  String get islamicAudioHub => 'KhaleekMomen';

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
      'This permission was denied. Please enable it from app settings.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get skip => 'Skip';

  @override
  String get onboardWelcomeTitle => 'Welcome to KhaleekMomen';

  @override
  String get onboardWelcomeSubtitle =>
      'Your companion for Quran, prayer times, and daily Azkar — all in one app.';

  @override
  String get onboardFeatureQuran => 'Listen to the Quran with top reciters';

  @override
  String get onboardFeaturePrayer => 'Accurate prayer times with auto Adhan';

  @override
  String get onboardFeatureRadio => 'Live Islamic radio stations';

  @override
  String get onboardFeatureAzkar => 'Morning, evening & sleep Azkar';

  @override
  String get onboardLocationTitle => 'Location for Prayer Times';

  @override
  String get onboardLocationSubtitle =>
      'We use your location only to calculate prayer times and show the Qibla direction. Never shared.';

  @override
  String get onboardWhyNeeded => 'Why we need this:';

  @override
  String get onboardLocationBullet1 =>
      'Calculate accurate prayer times for your city';

  @override
  String get onboardLocationBullet2 =>
      'Show the Qibla direction toward the Kaaba';

  @override
  String get onboardLocationBullet3 =>
      'Your location is processed locally — never uploaded';

  @override
  String get onboardGrantLocation => 'Allow Location Access';

  @override
  String get onboardAdhanTitle => 'Adhan Permissions';

  @override
  String get onboardAdhanSubtitle =>
      'Grant these so the Adhan always reaches you on time.';

  @override
  String get onboardNotifLabel => 'Prayer Notifications';

  @override
  String get onboardNotifTitle => 'Prayer Notifications';

  @override
  String get onboardNotifSubtitle => 'Get notified at each prayer time.';

  @override
  String get onboardNotifBullet1 =>
      'Receive a notification at each prayer time';

  @override
  String get onboardNotifBullet2 => 'Plays your selected Adhan automatically';

  @override
  String get onboardNotifBullet3 =>
      'Disable individual prayers anytime from Settings';

  @override
  String get onboardGrantNotif => 'Allow Notifications';

  @override
  String get onboardAlarmLabel => 'Precise Adhan Timing';

  @override
  String get onboardAlarmTitle => 'Precise Adhan Timing';

  @override
  String get onboardAlarmSubtitle =>
      'Ensures the Adhan fires at the exact prayer time.';

  @override
  String get onboardAlarmBullet1 => 'Adhan fires at the exact minute, not late';

  @override
  String get onboardAlarmBullet2 =>
      'Required for reliable prayer time delivery';

  @override
  String get onboardAlarmBullet3 =>
      'Without this, notifications may be delayed';

  @override
  String get onboardGrantAlarm => 'Allow Precise Alarms';

  @override
  String get onboardBatteryLabel => 'Background Activity';

  @override
  String get onboardBatteryTitle => 'Background Activity';

  @override
  String get onboardBatterySubtitle =>
      'Keep the Adhan working even when the screen is off.';

  @override
  String get onboardBatteryBullet1 => 'Ensures the Adhan plays even overnight';

  @override
  String get onboardBatteryBullet2 => 'Minimal battery impact';

  @override
  String get onboardBatteryBullet3 =>
      'Only removes the background delay restriction';

  @override
  String get onboardGrantBattery => 'Disable Battery Restrictions';

  @override
  String get onboardPermissionGranted => 'Enabled ✓';

  @override
  String get onboardDoneTitle => 'You\'re All Set!';

  @override
  String get onboardDoneSubtitle =>
      'KhaleekMomen is ready. May Allah accept your worship and keep you consistent in prayer.';

  @override
  String get onboardDoneNotif => 'Prayer Notifications';

  @override
  String get onboardDoneAlarm => 'Adhan Alarms';

  @override
  String get onboardDoneBattery => 'Background Adhan';

  @override
  String get onboardNext => 'Next';

  @override
  String get onboardFinish => 'Start the App';

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
  String get copyAyah => 'Copy Verse';

  @override
  String get ayahCopied => 'Verse copied';

  @override
  String get jumpToAyah => 'Jump to Verse';

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
