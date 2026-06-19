// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'خليك مؤمن';

  @override
  String get home => 'الرئيسية';

  @override
  String get quran => 'القرآن';

  @override
  String get radio => 'الإذاعة';

  @override
  String get azkar => 'الأذكار';

  @override
  String get prayer => 'الصلاة';

  @override
  String get nobleQuran => 'القرآن الكريم';

  @override
  String get liveRadio => 'الإذاعة المباشرة';

  @override
  String get dailyAzkar => 'الأذكار اليومية';

  @override
  String get prayerAndQibla => 'الصلاة والقبلة';

  @override
  String get favorites => 'المفضلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get currentReciter => 'القارئ الحالي';

  @override
  String get changeReciter => 'تغيير القارئ';

  @override
  String get searchSurah => 'ابحث عن سورة (مثال: الفاتحة، 18)...';

  @override
  String get selectReciter => 'اختر القارئ';

  @override
  String get noSurahsFound => 'لم يتم العثور على سور مطابقة لبحثك.';

  @override
  String get tryAgain => 'أعد المحاولة';

  @override
  String get networkError => 'خطأ في الشبكة';

  @override
  String get connectionError => 'خطأ في الاتصال';

  @override
  String get verses => 'آيات';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'المظهر الفاتح';

  @override
  String get themeDark => 'المظهر الداكن';

  @override
  String get themeSystem => 'تلقائي حسب النظام';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English (الإنجليزية)';

  @override
  String get arabic => 'العربية';

  @override
  String get adhanAutoplay => 'تشغيل الأذان تلقائيًا';

  @override
  String get myFavorites => 'مفضلتي';

  @override
  String get audioScheduling => 'الصوتيات والجدولة';

  @override
  String get adhanAutoplaySubtitle =>
      'تشغيل أذان الصلاة تلقائيًا فور دخول وقت الصلاة.';

  @override
  String get personalization => 'التخصيص والواجهة';

  @override
  String get themeMode => 'نمط المظهر';

  @override
  String get appLanguage => 'لغة التطبيق';

  @override
  String get aboutApplication => 'حول التطبيق';

  @override
  String get appVersion => 'الإصدار 1.0.0';

  @override
  String get dataSafety => 'سلامة البيانات والخصوصية';

  @override
  String get dataSafetySubtitle =>
      'جميع إحداثيات الموقع وملفات التهيئة تعمل محليًا 100% دون مغادرة جهازك.';

  @override
  String get privacySnackbar =>
      'حماية الخصوصية: معالجة إحداثيات الموقع تتم محليًا بالكامل.';

  @override
  String nextPrayer(String name) {
    return 'الصلاة القادمة: $name';
  }

  @override
  String get liveDeviceScheduler => 'جدولة وقت الجهاز المباشر';

  @override
  String get recentlyPlayed => 'تم تشغيله مؤخرًا';

  @override
  String get exploreHub => 'استكشف المحتوى';

  @override
  String get islamicRadio => 'الإذاعة الإسلامية';

  @override
  String get liveStations => 'محطات مباشرة';

  @override
  String get countersAndText => 'العدادات والنصوص';

  @override
  String get adhanAndQibla => 'الأذان والقبلة';

  @override
  String get listenToReciters => 'استمع إلى القراء';

  @override
  String get resetAllCategory => 'إعادة تعيين الفئة كلها';

  @override
  String get resetCountersTitle => 'إعادة تعيين العدادات؟';

  @override
  String resetCountersMessage(String category) {
    return 'سيتم إعادة تعيين عدادات تقدم $category الأذكار.';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get morningAzkar => 'الصباح';

  @override
  String get eveningAzkar => 'المساء';

  @override
  String get sleepAzkar => 'النوم';

  @override
  String get generalAzkar => 'عام';

  @override
  String get todaysTimings => 'مواقيت اليوم';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String get kaabaDirAngle => 'زاوية اتجاه الكعبة';

  @override
  String get relativeToBearing => 'محسوبة نسبةً إلى الشمال';

  @override
  String qiblaDegrees(String degrees) {
    return 'القبلة: $degrees° شرق الشمال';
  }

  @override
  String region(String timezone) {
    return 'المنطقة: $timezone';
  }

  @override
  String get updateCoordinates => 'تحديث الإحداثيات';

  @override
  String get noConnectionOffline => 'لا يوجد اتصال / غير متصل';

  @override
  String get cachedOfflineData => 'بيانات مخزنة مؤقتًا';

  @override
  String get liveApiSynced => 'متزامن مع الخادم';

  @override
  String get prayerTimesUnavailable => 'مواقيت الصلاة غير متوفرة';

  @override
  String get prayerTimesDefaultError =>
      'يرجى تفعيل أذونات الموقع والاتصال بالإنترنت لحساب مواقيت الصلاة.';

  @override
  String get retryFetching => 'إعادة المحاولة';

  @override
  String get coordsUnavailable =>
      'الإحداثيات غير متوفرة. لا يمكن حساب اتجاه القبلة.';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrise => 'الشروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get radioStations => 'محطات الراديو';

  @override
  String get quranSurahs => 'سور القرآن';

  @override
  String get noRadioFavorites => 'لا توجد محطات مفضلة';

  @override
  String get noRadioFavoritesMsg =>
      'استكشف المحطات المباشرة واضغط على القلب لحفظ محطاتك المفضلة.';

  @override
  String get noSurahFavorites => 'لا توجد سور مفضلة';

  @override
  String get noSurahFavoritesMsg =>
      'اختر قارئًا واستعرض السور وأضف فصولك المفضلة هنا.';

  @override
  String get searchRadioStations => 'ابحث عن محطات الراديو...';

  @override
  String get refreshStations => 'تحديث المحطات';

  @override
  String get noStationsMatch => 'لا توجد محطات مطابقة لبحثك.';

  @override
  String get unknownAudio => 'صوت غير معروف';

  @override
  String get islamicAudioHub => 'خليك مؤمن';

  @override
  String get noVersesFound => 'لا توجد آيات.';

  @override
  String get adhanPrioritySystem => 'نظام أولوية الأذان';

  @override
  String get quranRecitation => 'تلاوة قرآنية';

  @override
  String get islamicRadioStation => 'إذاعة إسلامية';

  @override
  String get adhanBroadcast => 'بث الأذان';

  @override
  String get audioPlayer => 'مشغّل الصوت';

  @override
  String get permissionDeniedTitle => 'الإذن مطلوب';

  @override
  String get permissionDeniedBody =>
      'تم رفض هذا الإذن بشكل دائم. يرجى تفعيله من إعدادات التطبيق لاستخدام هذه الميزة.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get skip => 'تخطي';

  @override
  String get onboardWelcomeTitle => 'أهلاً بك في خليك مؤمن';

  @override
  String get onboardWelcomeSubtitle =>
      'رفيقك الإسلامي الشامل: قرآن كريم، أوقات صلاة دقيقة، إذاعات مباشرة وأذكار يومية — كل هذا في تطبيق واحد رائع.';

  @override
  String get onboardFeatureQuran =>
      'استمع إلى القرآن الكريم بأصوات أفضل القراء في العالم';

  @override
  String get onboardFeaturePrayer => 'أوقات صلاة دقيقة مع أذان تلقائي';

  @override
  String get onboardFeatureRadio =>
      'إذاعات إسلامية مباشرة من جميع أنحاء العالم';

  @override
  String get onboardFeatureAzkar => 'تذكيرات أذكار الصباح والمساء والنوم';

  @override
  String get onboardLocationTitle => 'إذن الموقع';

  @override
  String get onboardLocationSubtitle =>
      'نحتاج إلى موقعك لحساب أوقات الصلاة بدقة وإظهار اتجاه القبلة الصحيح لمدينتك.';

  @override
  String get onboardWhyNeeded => 'لماذا نحتاجه هذا:';

  @override
  String get onboardLocationBullet1 =>
      'حساب أوقات الصلوات الخمس بناءً على إحداثياتك الجغرافية الدقيقة';

  @override
  String get onboardLocationBullet2 =>
      'عرض اتجاه بوصلة القبلة بدقة نحو الكعبة المشرفة';

  @override
  String get onboardLocationBullet3 =>
      'موقعك يُعالج محلياً 100٪ ولا يُرسَل إلى أي خادم خارجي';

  @override
  String get onboardGrantLocation => 'السماح بالوصول إلى الموقع';

  @override
  String get onboardAdhanTitle => 'أذونات الأذان';

  @override
  String get onboardAdhanSubtitle =>
      'فعّل هذه الأذونات لضمان وصول الأذان إليك في وقته دائماً.';

  @override
  String get onboardNotifLabel => 'إشعارات الصلاة';

  @override
  String get onboardNotifTitle => 'إشعارات الصلاة';

  @override
  String get onboardNotifSubtitle =>
      'اسمح بالإشعارات حتى ينبهك التطبيق عند دخول وقت كل صلاة، حتى حين يكون الشاشة مطفأة.';

  @override
  String get onboardNotifBullet1 =>
      'استقبال إشعار عند دخول وقت كل صلاة من الصلوات الخمس';

  @override
  String get onboardNotifBullet2 =>
      'الإشعارات تشغل صوت الأذان المختار تلقائياً';

  @override
  String get onboardNotifBullet3 =>
      'يمكنك تعطيل كل صلاة بشكل منفرد من الإعدادات';

  @override
  String get onboardGrantNotif => 'السماح بالإشعارات';

  @override
  String get onboardAlarmLabel => 'دقة توقيت الأذان';

  @override
  String get onboardAlarmTitle => 'دقة توقيت الأذان';

  @override
  String get onboardAlarmSubtitle =>
      'يضمن رفع الأذان في وقت الصلاة بالدقيقة الدقيقة.';

  @override
  String get onboardAlarmBullet1 => 'الأذان يُرفع في الدقيقة المحددة بالضبط';

  @override
  String get onboardAlarmBullet2 => 'ضروري لضمان موثوقية مواعيد الصلاة';

  @override
  String get onboardAlarmBullet3 =>
      'بدونه قد يتأخر النظام في تشغيل إشعارات الصلاة';

  @override
  String get onboardGrantAlarm => 'السماح بالتنبيه الدقيق';

  @override
  String get onboardBatteryLabel => 'نشاط الخلفية';

  @override
  String get onboardBatteryTitle => 'نشاط الخلفية';

  @override
  String get onboardBatterySubtitle =>
      'يبقي الأذان يعمل حتى حين تكون الشاشة مطفأة.';

  @override
  String get onboardBatteryBullet1 => 'يضمن تشغيل الأذان حتى طوال الليل';

  @override
  String get onboardBatteryBullet2 => 'استهلاك بطارية ضئيل جداً';

  @override
  String get onboardBatteryBullet3 => 'يزيل فقط قيد التأخير في الخلفية';

  @override
  String get onboardGrantBattery => 'إلغاء قيود البطارية';

  @override
  String get onboardPermissionGranted => 'تم التفعيل ✓';

  @override
  String get onboardDoneTitle => 'كل شيء جاهز!';

  @override
  String get onboardDoneSubtitle =>
      'خليك مؤمن جاهز. تقبل الله طاعتك وثبّتك على الصلاة.';

  @override
  String get onboardDoneNotif => 'إشعارات الصلاة';

  @override
  String get onboardDoneAlarm => 'تنبيهات الأذان';

  @override
  String get onboardDoneBattery => 'أذان الخلفية';

  @override
  String get onboardNext => 'التالي';

  @override
  String get onboardFinish => 'ابدأ التطبيق';

  @override
  String get tafsirTitle => 'التفسير';

  @override
  String get tafsirLabel => 'التفسير الميسر';

  @override
  String get tafsirUnavailable =>
      'التفسير غير متاح لهذه الآية في وضع عدم الاتصال.';

  @override
  String get translationLabel => 'الترجمة';

  @override
  String get copyAyah => 'نسخ الآية';

  @override
  String get ayahCopied => 'تم نسخ الآية';

  @override
  String get jumpToAyah => 'الانتقال إلى آية';

  @override
  String get ayahNumberHint => 'رقم الآية';

  @override
  String get go => 'انتقال';

  @override
  String get lastReadLabel => 'آخر قراءة';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String get ayahLabel => 'الآية';

  @override
  String get playerStationLabel => 'المحطة: ';

  @override
  String get playerSurahLabel => 'سورة: ';

  @override
  String get playerReciterLabel => 'القارئ: ';

  @override
  String get playerCountryLabel => 'الدولة: ';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterFavorites => 'المفضلة';

  @override
  String get nowPlaying => 'يُشغَّل الآن';

  @override
  String get noFavoriteStationsYet => 'لا توجد محطات مفضلة بعد';

  @override
  String resultCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get adhanSound => 'صوت الأذان';

  @override
  String get selectAdhanSound => 'اختر صوت الأذان';

  @override
  String get searchReciter => 'ابحث عن قارئ...';

  @override
  String get noResultsFound => 'لا توجد نتائج';

  @override
  String get appDeveloper => 'مطور البرنامج';

  @override
  String get connect => 'تواصل';

  @override
  String reciterCount(int count) {
    return '$count قارئ';
  }

  @override
  String get noReciterFound => 'لا يوجد قارئ بهذا الاسم';

  @override
  String get azkarCompleted => 'اكتمل بحمد الله 🎉';

  @override
  String azkarProgress(int done, int total) {
    return '$done / $total مكتمل';
  }

  @override
  String get noAzkarFound => 'لا توجد أذكار';
}
