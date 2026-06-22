// lib/data/models/prayer_calculation_method.dart

enum PrayerCalculationMethod {
  egyptian(5, 'الهيئة المصرية للمساحة', 'Egyptian General Authority'),
  mwl(3, 'رابطة العالم الإسلامي', 'Muslim World League'),
  isna(2, 'الجمعية الإسلامية لأمريكا الشمالية', 'ISNA (North America)'),
  umAlQura(4, 'أم القرى - مكة المكرمة', 'Umm Al-Qura (Makkah)'),
  karachi(
    1,
    'جامعة العلوم الإسلامية - كراتشي',
    'Univ. of Islamic Sciences, Karachi',
  ),
  kuwait(9, 'الكويت', 'Kuwait'),
  qatar(10, 'قطر', 'Qatar'),
  gulf(8, 'منطقة الخليج', 'Gulf Region'),
  turkey(13, 'ديانت - تركيا', 'Diyanet, Turkey'),
  tehran(7, 'جامعة طهران', 'Univ. of Tehran'),
  singapore(11, 'سنغافورة', 'Singapore MUIS'),
  france(12, 'اتحاد إسلامي فرنسا', 'Union Islamique de France'),
  russia(14, 'روسيا', 'Muslims of Russia'),
  moonsighting(
    15,
    'لجنة رؤية الهلال العالمية',
    'Moonsighting Committee Worldwide',
  );

  final int id;
  final String nameAr;
  final String nameEn;

  const PrayerCalculationMethod(this.id, this.nameAr, this.nameEn);

  String displayName(bool isArabic) => isArabic ? nameAr : nameEn;

  static PrayerCalculationMethod fromId(int id) {
    return PrayerCalculationMethod.values.firstWhere(
      (m) => m.id == id,
      orElse: () => PrayerCalculationMethod.egyptian,
    );
  }
}
