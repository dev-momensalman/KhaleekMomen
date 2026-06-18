// lib/core/services/radio_service.dart

import 'package:islamic_audio_hub/data/models/station.dart';

class RadioService {
  // ────────────────────────────────────────────────────────────
  // ✅ جميع المحطات موثقة من qurango.net + radiojar.com
  // ────────────────────────────────────────────────────────────
  final List<Station> _curatedStations = [
    // ══════════════════════════════════════════════════════════
    // 📡 إذاعات رسمية (radiojar.com — موثقة 100%)
    // ══════════════════════════════════════════════════════════
    Station(
      id: 'egy_quran_cairo',
      name: 'إذاعة القرآن الكريم من القاهرة',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://stream.radiojar.com/8s5u5tpdtwzuv',
      type: 'quran',
    ),
    Station(
      id: 'sa_quran_official',
      name: 'إذاعة القرآن الكريم من المملكة',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://stream.radiojar.com/0tpy1h0kxtzuv',
      type: 'quran',
    ),
    Station(
      id: 'haram_makkah',
      name: 'إذاعة الحرم المكي',
      country: 'السعودية 🇸🇦',
      streamUrl: 'http://r7.tarat.com:8004/stream?type=http&nocache=114',
      type: 'quran',
    ),

    // ══════════════════════════════════════════════════════════
    // 📻 محطات متنوعة (qurango.net)
    // ══════════════════════════════════════════════════════════
    Station(
      id: 'qurango_mix',
      name: 'الإذاعة العامة — تلاوات متنوعة',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/mix',
      type: 'quran',
    ),
    Station(
      id: 'qurango_sakeenah',
      name: 'إذاعة آيات السكينة',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/sakeenah',
      type: 'quran',
    ),
    Station(
      id: 'qurango_salma',
      name: 'تلاوات خاشعة',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/salma',
      type: 'quran',
    ),
    Station(
      id: 'qurango_tarateel',
      name: 'تراتيل قصيرة متميزة',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/tarateel',
      type: 'quran',
    ),
    Station(
      id: 'qurango_albaqarah',
      name: 'سورة البقرة — قراء متعددون',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/albaqarah',
      type: 'quran',
    ),
    Station(
      id: 'qurango_roqiah',
      name: 'الرقية الشرعية',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/roqiah',
      type: 'quran',
    ),
    Station(
      id: 'qurango_tafseer',
      name: 'تفسير القرآن الكريم',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/tafseer',
      type: 'other',
    ),
    Station(
      id: 'qurango_athkar_sabah',
      name: 'أذكار الصباح',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/athkar_sabah',
      type: 'other',
    ),
    Station(
      id: 'qurango_athkar_masa',
      name: 'أذكار المساء',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/athkar_masa',
      type: 'other',
    ),
    Station(
      id: 'qurango_sahabah',
      name: 'إذاعة صور من حياة الصحابة',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/sahabah',
      type: 'other',
    ),
    Station(
      id: 'qurango_seerah',
      name: 'في ظلال السيرة النبوية',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/fi_zilal_alsiyra',
      type: 'other',
    ),

    // ══════════════════════════════════════════════════════════
    // 🎙️ قراء مشهورون (qurango.net — موثقة)
    // ══════════════════════════════════════════════════════════

    // مصريون
    Station(
      id: 'qurango_basit',
      name: 'عبد الباسط عبد الصمد',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://qurango.net/radio/abdulbasit_abdulsamad',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_basit_mojawwad',
      name: 'عبد الباسط — مجود',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://qurango.net/radio/abdulbasit_abdulsamad_mojawwad',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_minshawi',
      name: 'محمد صديق المنشاوي',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://qurango.net/radio/mohammed_siddiq_alminshawi',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_minshawi_moj',
      name: 'المنشاوي — مجود',
      country: 'مصر 🇪🇬',
      streamUrl:
          'https://qurango.net/radio/mohammed_siddiq_alminshawi_mojawwad',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_hussary',
      name: 'محمود خليل الحصري',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://qurango.net/radio/mahmoud_khalil_alhussary',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_hussary_moj',
      name: 'الحصري — مجود',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://qurango.net/radio/mahmoud_khalil_alhussary_mojawwad',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_tablawi',
      name: 'محمد الطبلاوي',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://qurango.net/radio/mohammad_altablaway',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_mustafa_ismail',
      name: 'مصطفى إسماعيل',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://qurango.net/radio/mustafa_ismail',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_albanna',
      name: 'محمود علي البنا',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://qurango.net/radio/mahmoud_ali__albanna',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_jibreel',
      name: 'محمد جبريل',
      country: 'مصر 🇪🇬',
      streamUrl: 'https://qurango.net/radio/mohammed_jibreel',
      type: 'recitation',
    ),

    // سعوديون
    Station(
      id: 'qurango_sudais',
      name: 'عبد الرحمن السديس',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/abdulrahman_alsudaes',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_shuraim',
      name: 'سعود الشريم',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/saud_alshuraim',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_maher',
      name: 'ماهر المعيقلي',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/maher_al_meaqli',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_ghamdi',
      name: 'سعد الغامدي',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/saad_alghamdi',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_huthaifi',
      name: 'علي الحذيفي',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/ali_alhuthaifi',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_salah_budair',
      name: 'صلاح البدير',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/salah_albudair',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_khalid_jaleel',
      name: 'خالد الجليل',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/khalid_aljileel',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_bandar',
      name: 'بندر بليلة',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/bandar_balilah',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_abu_bakr_shatri',
      name: 'أبو بكر الشاطري',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/shaik_abu_bakr_al_shatri',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_ibrahim_akdar',
      name: 'إبراهيم الأخضر',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/ibrahim_alakdar',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_yasser_dosari',
      name: 'ياسر الدوسري',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/yasser_aldosari',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_abdelbari',
      name: 'عبد الباري الثبيتي',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/abdelbari_altoubayti',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_aljohany',
      name: 'عبد الله الجهني',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/abdullah_aljohany',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_emad_hafez',
      name: 'عماد زهير حافظ',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/emad_hafez',
      type: 'recitation',
    ),

    // كويتيون
    Station(
      id: 'qurango_afasy',
      name: 'مشاري راشد العفاسي',
      country: 'الكويت 🇰🇼',
      streamUrl: 'https://qurango.net/radio/mishary_alafasi',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_alkandari',
      name: 'عبد الله الكندري',
      country: 'الكويت 🇰🇼',
      streamUrl: 'https://qurango.net/radio/abdullah_alkandari',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_adel_khalbany',
      name: 'عادل الكلباني',
      country: 'الكويت 🇰🇼',
      streamUrl: 'https://qurango.net/radio/adel_alkhalbany',
      type: 'recitation',
    ),

    // آخرون
    Station(
      id: 'qurango_nasser_qatami',
      name: 'ناصر القطامي',
      country: 'الكويت 🇰🇼',
      streamUrl: 'https://qurango.net/radio/nasser_alqatami',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_hani_rifai',
      name: 'هاني الرفاعي',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/hani_arrifai',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_mustafa_azawi',
      name: 'مصطفى رعد العزاوي',
      country: 'العراق 🇮🇶',
      streamUrl: 'https://qurango.net/radio/mustafa_raad_alazawy',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_moayyub',
      name: 'محمد أيوب',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/mohammed_ayyub',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_ali_jaber',
      name: 'علي جابر',
      country: 'السعودية 🇸🇦',
      streamUrl: 'https://qurango.net/radio/ali_jaber',
      type: 'recitation',
    ),
    Station(
      id: 'qurango_tawfeeq',
      name: 'توفيق الصايغ',
      country: 'دولي 🌍',
      streamUrl: 'https://qurango.net/radio/tawfeeq_assayegh',
      type: 'recitation',
    ),
  ];

  // ── Getters ──────────────────────────────────────────────────────
  List<Station> get allStations => List.unmodifiable(_curatedStations);

  List<Station> get quranStations =>
      _curatedStations.where((s) => s.type == 'quran').toList();

  List<Station> get recitationStations =>
      _curatedStations.where((s) => s.type == 'recitation').toList();

  List<Station> get otherStations =>
      _curatedStations.where((s) => s.type == 'other').toList();

  Station? findById(String id) {
    for (final s in _curatedStations) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Station> search(String query) {
    if (query.trim().isEmpty) return _curatedStations.toList();
    final q = query.trim().toLowerCase();
    return _curatedStations
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.country.toLowerCase().contains(q),
        )
        .toList();
  }

  // ✅ للتوافق مع RadioController
  Future<List<Station>> getStations() async => _curatedStations.toList();
}
