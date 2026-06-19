import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'KhaleekMomen'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// No description provided for @radio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get radio;

  /// No description provided for @azkar.
  ///
  /// In en, this message translates to:
  /// **'Azkar'**
  String get azkar;

  /// No description provided for @prayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayer;

  /// No description provided for @nobleQuran.
  ///
  /// In en, this message translates to:
  /// **'Noble Quran'**
  String get nobleQuran;

  /// No description provided for @liveRadio.
  ///
  /// In en, this message translates to:
  /// **'Live Radio'**
  String get liveRadio;

  /// No description provided for @dailyAzkar.
  ///
  /// In en, this message translates to:
  /// **'Daily Azkar'**
  String get dailyAzkar;

  /// No description provided for @prayerAndQibla.
  ///
  /// In en, this message translates to:
  /// **'Prayer & Qibla'**
  String get prayerAndQibla;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @currentReciter.
  ///
  /// In en, this message translates to:
  /// **'Current Reciter'**
  String get currentReciter;

  /// No description provided for @changeReciter.
  ///
  /// In en, this message translates to:
  /// **'Change Reciter'**
  String get changeReciter;

  /// No description provided for @searchSurah.
  ///
  /// In en, this message translates to:
  /// **'Search Surah (e.g. Al-Fatihah, 18)...'**
  String get searchSurah;

  /// No description provided for @selectReciter.
  ///
  /// In en, this message translates to:
  /// **'Select Reciter'**
  String get selectReciter;

  /// No description provided for @noSurahsFound.
  ///
  /// In en, this message translates to:
  /// **'No Surahs match your search.'**
  String get noSurahsFound;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// No description provided for @verses.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get verses;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @adhanAutoplay.
  ///
  /// In en, this message translates to:
  /// **'Adhan Autoplay'**
  String get adhanAutoplay;

  /// No description provided for @myFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get myFavorites;

  /// No description provided for @audioScheduling.
  ///
  /// In en, this message translates to:
  /// **'Audio & Scheduling'**
  String get audioScheduling;

  /// No description provided for @adhanAutoplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play the Adhan automatically at each prayer time.'**
  String get adhanAutoplaySubtitle;

  /// No description provided for @personalization.
  ///
  /// In en, this message translates to:
  /// **'Personalization'**
  String get personalization;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @aboutApplication.
  ///
  /// In en, this message translates to:
  /// **'About Application'**
  String get aboutApplication;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// No description provided for @dataSafety.
  ///
  /// In en, this message translates to:
  /// **'Data Safety & Privacy'**
  String get dataSafety;

  /// No description provided for @dataSafetySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All data stays 100% offline on your device. Never shared.'**
  String get dataSafetySubtitle;

  /// No description provided for @privacySnackbar.
  ///
  /// In en, this message translates to:
  /// **'Privacy Guard: All data is processed locally on your device.'**
  String get privacySnackbar;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer: {name}'**
  String nextPrayer(String name);

  /// No description provided for @liveDeviceScheduler.
  ///
  /// In en, this message translates to:
  /// **'Device Time'**
  String get liveDeviceScheduler;

  /// No description provided for @recentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// No description provided for @exploreHub.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreHub;

  /// No description provided for @islamicRadio.
  ///
  /// In en, this message translates to:
  /// **'Islamic Radio'**
  String get islamicRadio;

  /// No description provided for @liveStations.
  ///
  /// In en, this message translates to:
  /// **'Live Stations'**
  String get liveStations;

  /// No description provided for @countersAndText.
  ///
  /// In en, this message translates to:
  /// **'Counters & Text'**
  String get countersAndText;

  /// No description provided for @adhanAndQibla.
  ///
  /// In en, this message translates to:
  /// **'Adhan & Qibla'**
  String get adhanAndQibla;

  /// No description provided for @listenToReciters.
  ///
  /// In en, this message translates to:
  /// **'Listen to Reciters'**
  String get listenToReciters;

  /// No description provided for @resetAllCategory.
  ///
  /// In en, this message translates to:
  /// **'Reset All Category'**
  String get resetAllCategory;

  /// No description provided for @resetCountersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Counters?'**
  String get resetCountersTitle;

  /// No description provided for @resetCountersMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reset all progress counters for {category} Azkar.'**
  String resetCountersMessage(String category);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @morningAzkar.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morningAzkar;

  /// No description provided for @eveningAzkar.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get eveningAzkar;

  /// No description provided for @sleepAzkar.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepAzkar;

  /// No description provided for @generalAzkar.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalAzkar;

  /// No description provided for @todaysTimings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Timings'**
  String get todaysTimings;

  /// No description provided for @qiblaDirection.
  ///
  /// In en, this message translates to:
  /// **'Qibla Direction'**
  String get qiblaDirection;

  /// No description provided for @kaabaDirAngle.
  ///
  /// In en, this message translates to:
  /// **'Kaaba Direction Angle'**
  String get kaabaDirAngle;

  /// No description provided for @relativeToBearing.
  ///
  /// In en, this message translates to:
  /// **'Calculated relative to North'**
  String get relativeToBearing;

  /// No description provided for @qiblaDegrees.
  ///
  /// In en, this message translates to:
  /// **'Qibla: {degrees}° E of N'**
  String qiblaDegrees(String degrees);

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region: {timezone}'**
  String region(String timezone);

  /// No description provided for @updateCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Update Location'**
  String get updateCoordinates;

  /// No description provided for @noConnectionOffline.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noConnectionOffline;

  /// No description provided for @cachedOfflineData.
  ///
  /// In en, this message translates to:
  /// **'Cached Data'**
  String get cachedOfflineData;

  /// No description provided for @liveApiSynced.
  ///
  /// In en, this message translates to:
  /// **'Live Synced'**
  String get liveApiSynced;

  /// No description provided for @prayerTimesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times Unavailable'**
  String get prayerTimesUnavailable;

  /// No description provided for @prayerTimesDefaultError.
  ///
  /// In en, this message translates to:
  /// **'Please enable location permissions and connect to the internet to calculate prayer times.'**
  String get prayerTimesDefaultError;

  /// No description provided for @retryFetching.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryFetching;

  /// No description provided for @coordsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. Cannot calculate Qibla direction.'**
  String get coordsUnavailable;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @radioStations.
  ///
  /// In en, this message translates to:
  /// **'Radio Stations'**
  String get radioStations;

  /// No description provided for @quranSurahs.
  ///
  /// In en, this message translates to:
  /// **'Quran Surahs'**
  String get quranSurahs;

  /// No description provided for @noRadioFavorites.
  ///
  /// In en, this message translates to:
  /// **'No Radio Favorites'**
  String get noRadioFavorites;

  /// No description provided for @noRadioFavoritesMsg.
  ///
  /// In en, this message translates to:
  /// **'Explore live radios and tap the heart icon to save stations here.'**
  String get noRadioFavoritesMsg;

  /// No description provided for @noSurahFavorites.
  ///
  /// In en, this message translates to:
  /// **'No Surah Favorites'**
  String get noSurahFavorites;

  /// No description provided for @noSurahFavoritesMsg.
  ///
  /// In en, this message translates to:
  /// **'Select a reciter, browse surahs, and add your favorites here.'**
  String get noSurahFavoritesMsg;

  /// No description provided for @searchRadioStations.
  ///
  /// In en, this message translates to:
  /// **'Search Radio Stations...'**
  String get searchRadioStations;

  /// No description provided for @refreshStations.
  ///
  /// In en, this message translates to:
  /// **'Refresh Stations'**
  String get refreshStations;

  /// No description provided for @noStationsMatch.
  ///
  /// In en, this message translates to:
  /// **'No stations match your search.'**
  String get noStationsMatch;

  /// No description provided for @unknownAudio.
  ///
  /// In en, this message translates to:
  /// **'Unknown Audio'**
  String get unknownAudio;

  /// No description provided for @islamicAudioHub.
  ///
  /// In en, this message translates to:
  /// **'KhaleekMomen'**
  String get islamicAudioHub;

  /// No description provided for @noVersesFound.
  ///
  /// In en, this message translates to:
  /// **'No verses found.'**
  String get noVersesFound;

  /// No description provided for @adhanPrioritySystem.
  ///
  /// In en, this message translates to:
  /// **'Adhan Priority System'**
  String get adhanPrioritySystem;

  /// No description provided for @quranRecitation.
  ///
  /// In en, this message translates to:
  /// **'Quran Recitation'**
  String get quranRecitation;

  /// No description provided for @islamicRadioStation.
  ///
  /// In en, this message translates to:
  /// **'Islamic Radio Station'**
  String get islamicRadioStation;

  /// No description provided for @adhanBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Adhan Broadcast'**
  String get adhanBroadcast;

  /// No description provided for @audioPlayer.
  ///
  /// In en, this message translates to:
  /// **'Audio Player'**
  String get audioPlayer;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'This permission was denied. Please enable it from app settings.'**
  String get permissionDeniedBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @onboardWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to KhaleekMomen'**
  String get onboardWelcomeTitle;

  /// No description provided for @onboardWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your companion for Quran, prayer times, and daily Azkar — all in one app.'**
  String get onboardWelcomeSubtitle;

  /// No description provided for @onboardFeatureQuran.
  ///
  /// In en, this message translates to:
  /// **'Listen to the Quran with top reciters'**
  String get onboardFeatureQuran;

  /// No description provided for @onboardFeaturePrayer.
  ///
  /// In en, this message translates to:
  /// **'Accurate prayer times with auto Adhan'**
  String get onboardFeaturePrayer;

  /// No description provided for @onboardFeatureRadio.
  ///
  /// In en, this message translates to:
  /// **'Live Islamic radio stations'**
  String get onboardFeatureRadio;

  /// No description provided for @onboardFeatureAzkar.
  ///
  /// In en, this message translates to:
  /// **'Morning, evening & sleep Azkar'**
  String get onboardFeatureAzkar;

  /// No description provided for @onboardLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location for Prayer Times'**
  String get onboardLocationTitle;

  /// No description provided for @onboardLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use your location only to calculate prayer times and show the Qibla direction. Never shared.'**
  String get onboardLocationSubtitle;

  /// No description provided for @onboardWhyNeeded.
  ///
  /// In en, this message translates to:
  /// **'Why we need this:'**
  String get onboardWhyNeeded;

  /// No description provided for @onboardLocationBullet1.
  ///
  /// In en, this message translates to:
  /// **'Calculate accurate prayer times for your city'**
  String get onboardLocationBullet1;

  /// No description provided for @onboardLocationBullet2.
  ///
  /// In en, this message translates to:
  /// **'Show the Qibla direction toward the Kaaba'**
  String get onboardLocationBullet2;

  /// No description provided for @onboardLocationBullet3.
  ///
  /// In en, this message translates to:
  /// **'Your location is processed locally — never uploaded'**
  String get onboardLocationBullet3;

  /// No description provided for @onboardGrantLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow Location Access'**
  String get onboardGrantLocation;

  /// No description provided for @onboardAdhanTitle.
  ///
  /// In en, this message translates to:
  /// **'Adhan Permissions'**
  String get onboardAdhanTitle;

  /// No description provided for @onboardAdhanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grant these so the Adhan always reaches you on time.'**
  String get onboardAdhanSubtitle;

  /// No description provided for @onboardNotifLabel.
  ///
  /// In en, this message translates to:
  /// **'Prayer Notifications'**
  String get onboardNotifLabel;

  /// No description provided for @onboardNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Notifications'**
  String get onboardNotifTitle;

  /// No description provided for @onboardNotifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified at each prayer time.'**
  String get onboardNotifSubtitle;

  /// No description provided for @onboardNotifBullet1.
  ///
  /// In en, this message translates to:
  /// **'Receive a notification at each prayer time'**
  String get onboardNotifBullet1;

  /// No description provided for @onboardNotifBullet2.
  ///
  /// In en, this message translates to:
  /// **'Plays your selected Adhan automatically'**
  String get onboardNotifBullet2;

  /// No description provided for @onboardNotifBullet3.
  ///
  /// In en, this message translates to:
  /// **'Disable individual prayers anytime from Settings'**
  String get onboardNotifBullet3;

  /// No description provided for @onboardGrantNotif.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get onboardGrantNotif;

  /// No description provided for @onboardAlarmLabel.
  ///
  /// In en, this message translates to:
  /// **'Precise Adhan Timing'**
  String get onboardAlarmLabel;

  /// No description provided for @onboardAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Precise Adhan Timing'**
  String get onboardAlarmTitle;

  /// No description provided for @onboardAlarmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ensures the Adhan fires at the exact prayer time.'**
  String get onboardAlarmSubtitle;

  /// No description provided for @onboardAlarmBullet1.
  ///
  /// In en, this message translates to:
  /// **'Adhan fires at the exact minute, not late'**
  String get onboardAlarmBullet1;

  /// No description provided for @onboardAlarmBullet2.
  ///
  /// In en, this message translates to:
  /// **'Required for reliable prayer time delivery'**
  String get onboardAlarmBullet2;

  /// No description provided for @onboardAlarmBullet3.
  ///
  /// In en, this message translates to:
  /// **'Without this, notifications may be delayed'**
  String get onboardAlarmBullet3;

  /// No description provided for @onboardGrantAlarm.
  ///
  /// In en, this message translates to:
  /// **'Allow Precise Alarms'**
  String get onboardGrantAlarm;

  /// No description provided for @onboardBatteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Background Activity'**
  String get onboardBatteryLabel;

  /// No description provided for @onboardBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Background Activity'**
  String get onboardBatteryTitle;

  /// No description provided for @onboardBatterySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the Adhan working even when the screen is off.'**
  String get onboardBatterySubtitle;

  /// No description provided for @onboardBatteryBullet1.
  ///
  /// In en, this message translates to:
  /// **'Ensures the Adhan plays even overnight'**
  String get onboardBatteryBullet1;

  /// No description provided for @onboardBatteryBullet2.
  ///
  /// In en, this message translates to:
  /// **'Minimal battery impact'**
  String get onboardBatteryBullet2;

  /// No description provided for @onboardBatteryBullet3.
  ///
  /// In en, this message translates to:
  /// **'Only removes the background delay restriction'**
  String get onboardBatteryBullet3;

  /// No description provided for @onboardGrantBattery.
  ///
  /// In en, this message translates to:
  /// **'Disable Battery Restrictions'**
  String get onboardGrantBattery;

  /// No description provided for @onboardPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Enabled ✓'**
  String get onboardPermissionGranted;

  /// No description provided for @onboardDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get onboardDoneTitle;

  /// No description provided for @onboardDoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'KhaleekMomen is ready. May Allah accept your worship and keep you consistent in prayer.'**
  String get onboardDoneSubtitle;

  /// No description provided for @onboardDoneNotif.
  ///
  /// In en, this message translates to:
  /// **'Prayer Notifications'**
  String get onboardDoneNotif;

  /// No description provided for @onboardDoneAlarm.
  ///
  /// In en, this message translates to:
  /// **'Adhan Alarms'**
  String get onboardDoneAlarm;

  /// No description provided for @onboardDoneBattery.
  ///
  /// In en, this message translates to:
  /// **'Background Adhan'**
  String get onboardDoneBattery;

  /// No description provided for @onboardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardNext;

  /// No description provided for @onboardFinish.
  ///
  /// In en, this message translates to:
  /// **'Start the App'**
  String get onboardFinish;

  /// No description provided for @tafsirTitle.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsirTitle;

  /// No description provided for @tafsirLabel.
  ///
  /// In en, this message translates to:
  /// **'Tafsir (Simplified)'**
  String get tafsirLabel;

  /// No description provided for @tafsirUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tafsir is not available for this verse while offline.'**
  String get tafsirUnavailable;

  /// No description provided for @translationLabel.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translationLabel;

  /// No description provided for @copyAyah.
  ///
  /// In en, this message translates to:
  /// **'Copy Verse'**
  String get copyAyah;

  /// No description provided for @ayahCopied.
  ///
  /// In en, this message translates to:
  /// **'Verse copied'**
  String get ayahCopied;

  /// No description provided for @jumpToAyah.
  ///
  /// In en, this message translates to:
  /// **'Jump to Verse'**
  String get jumpToAyah;

  /// No description provided for @ayahNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Verse number'**
  String get ayahNumberHint;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @lastReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Last read'**
  String get lastReadLabel;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @ayahLabel.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get ayahLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
