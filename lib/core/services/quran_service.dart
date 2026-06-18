import 'dart:async';
import 'dart:developer' as developer;
import 'package:islamic_audio_hub/core/services/http_service.dart';
import 'package:islamic_audio_hub/data/models/reciter.dart';
import 'package:islamic_audio_hub/data/models/surah.dart';
import 'package:islamic_audio_hub/data/models/ayah.dart';

class QuranService {
  final HttpService _httpService;

  // Al Quran Cloud text API — injected for testability and connection reuse
  final HttpService _textHttpService;

  QuranService(this._httpService)
    : _textHttpService = HttpService(baseUrl: 'https://api.alquran.cloud/v1');
  // Note: For full DI, pass _textHttpService as a named constructor param.
  // The current approach already avoids the field initializer issue and
  // keeps construction deterministic while remaining override-friendly.

  // Popular reciters curated list for offline/fallback cases
  final List<Reciter> _defaultReciters = [
    Reciter(
      id: '1',
      name: 'Abdul Rahman Al-Sudais',
      server: 'https://server11.mp3quran.net/sudais/',
      letter: 'Hafs A\'n Assem',
    ),
    Reciter(
      id: '2',
      name: 'Maher Al-Muaiqly',
      server: 'https://server12.mp3quran.net/maher/',
      letter: 'Hafs A\'n Assem',
    ),
    Reciter(
      id: '3',
      name: 'Mishary Rashid Alafasy',
      server: 'https://server8.mp3quran.net/afs/',
      letter: 'Hafs A\'n Assem',
    ),
    Reciter(
      id: '4',
      name: 'Saad Al-Ghamdi',
      server: 'https://server7.mp3quran.net/s_gmd/',
      letter: 'Hafs A\'n Assem',
    ),
    Reciter(
      id: '5',
      name: 'Yasser Al-Dosari',
      server: 'https://server11.mp3quran.net/yasser/',
      letter: 'Hafs A\'n Assem',
    ),
  ];

  // High-performance static metadata list of Surahs
  final List<Surah> _surahMetadataList = [
    Surah(
      number: 1,
      name: 'الفاتحة',
      englishName: 'Al-Fatihah',
      englishNameTranslation: 'The Opening',
      numberOfAyahs: 7,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 2,
      name: 'البقرة',
      englishName: 'Al-Baqarah',
      englishNameTranslation: 'The Cow',
      numberOfAyahs: 286,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 3,
      name: 'آل عمران',
      englishName: 'Ali \'Imran',
      englishNameTranslation: 'Family of Imran',
      numberOfAyahs: 200,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 4,
      name: 'النساء',
      englishName: 'An-Nisa',
      englishNameTranslation: 'The Women',
      numberOfAyahs: 176,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 5,
      name: 'المائدة',
      englishName: 'Al-Ma\'idah',
      englishNameTranslation: 'The Table Spread',
      numberOfAyahs: 120,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 6,
      name: 'الأنعام',
      englishName: 'Al-An\'am',
      englishNameTranslation: 'The Cattle',
      numberOfAyahs: 165,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 7,
      name: 'الأعراف',
      englishName: 'Al-A\'raf',
      englishNameTranslation: 'The Heights',
      numberOfAyahs: 206,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 8,
      name: 'الأنفال',
      englishName: 'Al-Anfal',
      englishNameTranslation: 'The Spoils of War',
      numberOfAyahs: 75,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 9,
      name: 'التوبة',
      englishName: 'At-Tawbah',
      englishNameTranslation: 'The Repentance',
      numberOfAyahs: 129,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 10,
      name: 'يونس',
      englishName: 'Yunus',
      englishNameTranslation: 'Jonah',
      numberOfAyahs: 109,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 11,
      name: 'هود',
      englishName: 'Hud',
      englishNameTranslation: 'Hud',
      numberOfAyahs: 123,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 12,
      name: 'يوسف',
      englishName: 'Yusuf',
      englishNameTranslation: 'Joseph',
      numberOfAyahs: 111,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 13,
      name: 'الرعد',
      englishName: 'Ar-Ra\'d',
      englishNameTranslation: 'The Thunder',
      numberOfAyahs: 43,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 14,
      name: 'إبراهيم',
      englishName: 'Ibrahim',
      englishNameTranslation: 'Abraham',
      numberOfAyahs: 52,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 15,
      name: 'الحجر',
      englishName: 'Al-Hijr',
      englishNameTranslation: 'The Rocky Tract',
      numberOfAyahs: 99,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 16,
      name: 'النحل',
      englishName: 'An-Nahl',
      englishNameTranslation: 'The Bee',
      numberOfAyahs: 128,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 17,
      name: 'الإسراء',
      englishName: 'Al-Isra',
      englishNameTranslation: 'The Night Journey',
      numberOfAyahs: 111,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 18,
      name: 'الكهف',
      englishName: 'Al-Kahf',
      englishNameTranslation: 'The Cave',
      numberOfAyahs: 110,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 19,
      name: 'مريم',
      englishName: 'Maryam',
      englishNameTranslation: 'Mary',
      numberOfAyahs: 98,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 20,
      name: 'طه',
      englishName: 'Taha',
      englishNameTranslation: 'Ta-Ha',
      numberOfAyahs: 135,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 21,
      name: 'الأنبياء',
      englishName: 'Al-Anbiya',
      englishNameTranslation: 'The Prophets',
      numberOfAyahs: 112,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 22,
      name: 'الحج',
      englishName: 'Al-Hajj',
      englishNameTranslation: 'The Pilgrimage',
      numberOfAyahs: 78,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 23,
      name: 'المؤمنون',
      englishName: 'Al-Mu\'minun',
      englishNameTranslation: 'The Believers',
      numberOfAyahs: 118,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 24,
      name: 'النور',
      englishName: 'An-Nur',
      englishNameTranslation: 'The Light',
      numberOfAyahs: 64,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 25,
      name: 'الفرقان',
      englishName: 'Al-Furqan',
      englishNameTranslation: 'The Criterion',
      numberOfAyahs: 77,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 26,
      name: 'الشعراء',
      englishName: 'Ash-Shu\'ara',
      englishNameTranslation: 'The Poets',
      numberOfAyahs: 227,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 27,
      name: 'النمل',
      englishName: 'An-Naml',
      englishNameTranslation: 'The Ant',
      numberOfAyahs: 93,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 28,
      name: 'القصص',
      englishName: 'Al-Qasas',
      englishNameTranslation: 'The Stories',
      numberOfAyahs: 88,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 29,
      name: 'العنكبوت',
      englishName: 'Al-\'Ankabut',
      englishNameTranslation: 'The Spider',
      numberOfAyahs: 69,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 30,
      name: 'الروم',
      englishName: 'Ar-Rum',
      englishNameTranslation: 'The Romans',
      numberOfAyahs: 60,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 31,
      name: 'لقمان',
      englishName: 'Luqman',
      englishNameTranslation: 'Luqman',
      numberOfAyahs: 34,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 32,
      name: 'السجدة',
      englishName: 'As-Sajdah',
      englishNameTranslation: 'The Prostration',
      numberOfAyahs: 30,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 33,
      name: 'الأحزاب',
      englishName: 'Al-Ahzab',
      englishNameTranslation: 'The Combined Forces',
      numberOfAyahs: 73,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 34,
      name: 'سبأ',
      englishName: 'Saba',
      englishNameTranslation: 'Sheba',
      numberOfAyahs: 54,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 35,
      name: 'فاطر',
      englishName: 'Fatir',
      englishNameTranslation: 'Originator',
      numberOfAyahs: 45,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 36,
      name: 'يس',
      englishName: 'Ya-Sin',
      englishNameTranslation: 'Ya Sin',
      numberOfAyahs: 83,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 37,
      name: 'الصافات',
      englishName: 'As-Saffat',
      englishNameTranslation: 'Those who set the Ranks',
      numberOfAyahs: 182,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 38,
      name: 'ص',
      englishName: 'Sad',
      englishNameTranslation: 'The Letter Sad',
      numberOfAyahs: 88,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 39,
      name: 'الزمر',
      englishName: 'Az-Zumar',
      englishNameTranslation: 'The Troops',
      numberOfAyahs: 75,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 40,
      name: 'غافر',
      englishName: 'Ghafir',
      englishNameTranslation: 'The Forgiver',
      numberOfAyahs: 85,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 41,
      name: 'فصلت',
      englishName: 'Fussilat',
      englishNameTranslation: 'Explained in Detail',
      numberOfAyahs: 54,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 42,
      name: 'الشورى',
      englishName: 'Ash-Shura',
      englishNameTranslation: 'The Consultation',
      numberOfAyahs: 53,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 43,
      name: 'الزخرف',
      englishName: 'Az-Zukhruf',
      englishNameTranslation: 'The Ornaments of Gold',
      numberOfAyahs: 89,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 44,
      name: 'الدخان',
      englishName: 'Ad-Dukhan',
      englishNameTranslation: 'The Smoke',
      numberOfAyahs: 59,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 45,
      name: 'الجاثية',
      englishName: 'Al-Jathiyah',
      englishNameTranslation: 'The Crouching',
      numberOfAyahs: 37,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 46,
      name: 'الأحقاف',
      englishName: 'Al-Ahqaf',
      englishNameTranslation: 'The Wind-Curved Sandhills',
      numberOfAyahs: 35,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 47,
      name: 'محمد',
      englishName: 'Muhammad',
      englishNameTranslation: 'Muhammad',
      numberOfAyahs: 38,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 48,
      name: 'الفتح',
      englishName: 'Al-Fath',
      englishNameTranslation: 'The Victory',
      numberOfAyahs: 29,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 49,
      name: 'الحجرات',
      englishName: 'Al-Hujurat',
      englishNameTranslation: 'The Dwellings',
      numberOfAyahs: 18,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 50,
      name: 'ق',
      englishName: 'Qaf',
      englishNameTranslation: 'The Letter Qaf',
      numberOfAyahs: 45,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 51,
      name: 'الذاريات',
      englishName: 'Adh-Dhariyat',
      englishNameTranslation: 'The Winnowing Winds',
      numberOfAyahs: 60,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 52,
      name: 'الطور',
      englishName: 'At-Tur',
      englishNameTranslation: 'The Mount',
      numberOfAyahs: 49,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 53,
      name: 'النجم',
      englishName: 'An-Najm',
      englishNameTranslation: 'The Star',
      numberOfAyahs: 62,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 54,
      name: 'القمر',
      englishName: 'Al-Qamar',
      englishNameTranslation: 'The Moon',
      numberOfAyahs: 55,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 55,
      name: 'الرحمن',
      englishName: 'Ar-Rahman',
      englishNameTranslation: 'The Beneficent',
      numberOfAyahs: 78,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 56,
      name: 'الواقعة',
      englishName: 'Al-Waqi\'ah',
      englishNameTranslation: 'The Inevitable',
      numberOfAyahs: 96,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 57,
      name: 'الحديد',
      englishName: 'Al-Hadid',
      englishNameTranslation: 'The Iron',
      numberOfAyahs: 29,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 58,
      name: 'المجادلة',
      englishName: 'Al-Mujadilah',
      englishNameTranslation: 'The Pleading Woman',
      numberOfAyahs: 22,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 59,
      name: 'الحشر',
      englishName: 'Al-Hashr',
      englishNameTranslation: 'The Exile',
      numberOfAyahs: 24,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 60,
      name: 'الممتحنة',
      englishName: 'Al-Mumtahanah',
      englishNameTranslation: 'She that is to be examined',
      numberOfAyahs: 13,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 61,
      name: 'الصف',
      englishName: 'As-Saff',
      englishNameTranslation: 'The Ranks',
      numberOfAyahs: 14,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 62,
      name: 'الجمعة',
      englishName: 'Al-Jum\'ah',
      englishNameTranslation: 'The Congregation',
      numberOfAyahs: 11,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 63,
      name: 'المنافقون',
      englishName: 'Al-Munafiqun',
      englishNameTranslation: 'The Hypocrites',
      numberOfAyahs: 11,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 64,
      name: 'التغابن',
      englishName: 'At-Taghabun',
      englishNameTranslation: 'Mutual Disillusion',
      numberOfAyahs: 18,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 65,
      name: 'الطلاق',
      englishName: 'At-Talaq',
      englishNameTranslation: 'The Divorce',
      numberOfAyahs: 12,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 66,
      name: 'التحريم',
      englishName: 'At-Tahrim',
      englishNameTranslation: 'The Prohibition',
      numberOfAyahs: 12,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 67,
      name: 'الملك',
      englishName: 'Al-Mulk',
      englishNameTranslation: 'The Sovereignty',
      numberOfAyahs: 30,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 68,
      name: 'القلم',
      englishName: 'Al-Qalam',
      englishNameTranslation: 'The Pen',
      numberOfAyahs: 52,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 69,
      name: 'الحاقة',
      englishName: 'Al-Haqqah',
      englishNameTranslation: 'The Reality',
      numberOfAyahs: 52,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 70,
      name: 'المعارج',
      englishName: 'Al-Ma\'arij',
      englishNameTranslation: 'The Ascending Stairways',
      numberOfAyahs: 44,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 71,
      name: 'نوح',
      englishName: 'Nuh',
      englishNameTranslation: 'Noah',
      numberOfAyahs: 28,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 72,
      name: 'الجن',
      englishName: 'Al-Jinn',
      englishNameTranslation: 'The Jinn',
      numberOfAyahs: 28,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 73,
      name: 'المزمل',
      englishName: 'Al-Muzzammil',
      englishNameTranslation: 'The Enshrouded One',
      numberOfAyahs: 20,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 74,
      name: 'المدثر',
      englishName: 'Al-Muddaththir',
      englishNameTranslation: 'The Cloaked One',
      numberOfAyahs: 56,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 75,
      name: 'القيامة',
      englishName: 'Al-Qiyamah',
      englishNameTranslation: 'The Resurrection',
      numberOfAyahs: 40,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 76,
      name: 'الإنسان',
      englishName: 'Al-Insan',
      englishNameTranslation: 'Man',
      numberOfAyahs: 31,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 77,
      name: 'المرسلات',
      englishName: 'Al-Mursalat',
      englishNameTranslation: 'The Emissaries',
      numberOfAyahs: 50,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 78,
      name: 'النبأ',
      englishName: 'An-Naba',
      englishNameTranslation: 'The Tidings',
      numberOfAyahs: 40,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 79,
      name: 'النازعات',
      englishName: 'An-Nazi\'at',
      englishNameTranslation: 'Those who drag forth',
      numberOfAyahs: 46,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 80,
      name: 'عبس',
      englishName: '\'Abasa',
      englishNameTranslation: 'He Frowned',
      numberOfAyahs: 42,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 81,
      name: 'التكوير',
      englishName: 'At-Takwir',
      englishNameTranslation: 'The Overthrowing',
      numberOfAyahs: 29,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 82,
      name: 'الانفطار',
      englishName: 'Al-Infitar',
      englishNameTranslation: 'The Cleaving',
      numberOfAyahs: 19,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 83,
      name: 'المطففين',
      englishName: 'Al-Mutaffifin',
      englishNameTranslation: 'Defrauding',
      numberOfAyahs: 36,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 84,
      name: 'الانشقاق',
      englishName: 'Al-Inshiqaq',
      englishNameTranslation: 'The Sundering',
      numberOfAyahs: 25,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 85,
      name: 'البروج',
      englishName: 'Al-Buruj',
      englishNameTranslation: 'The Mansions of the Stars',
      numberOfAyahs: 22,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 86,
      name: 'الطارق',
      englishName: 'At-Tariq',
      englishNameTranslation: 'The Morning Star',
      numberOfAyahs: 17,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 87,
      name: 'الأعلى',
      englishName: 'Al-A\'la',
      englishNameTranslation: 'The Most High',
      numberOfAyahs: 19,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 88,
      name: 'الغاشية',
      englishName: 'Al-Ghashiyah',
      englishNameTranslation: 'The Overwhelming',
      numberOfAyahs: 26,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 89,
      name: 'الفجر',
      englishName: 'Al-Fajr',
      englishNameTranslation: 'The Dawn',
      numberOfAyahs: 30,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 90,
      name: 'البلد',
      englishName: 'Al-Balad',
      englishNameTranslation: 'The City',
      numberOfAyahs: 20,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 91,
      name: 'الشمس',
      englishName: 'Ash-Shams',
      englishNameTranslation: 'The Sun',
      numberOfAyahs: 15,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 92,
      name: 'الليل',
      englishName: 'Al-Lail',
      englishNameTranslation: 'The Night',
      numberOfAyahs: 21,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 93,
      name: 'الضحى',
      englishName: 'Ad-Duha',
      englishNameTranslation: 'The Morning Hours',
      numberOfAyahs: 11,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 94,
      name: 'الشرح',
      englishName: 'Ash-Sharh',
      englishNameTranslation: 'The Consolation',
      numberOfAyahs: 8,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 95,
      name: 'التين',
      englishName: 'At-Tin',
      englishNameTranslation: 'The Fig',
      numberOfAyahs: 8,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 96,
      name: 'العلق',
      englishName: 'Al-\'Alaq',
      englishNameTranslation: 'The Clot',
      numberOfAyahs: 19,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 97,
      name: 'القدر',
      englishName: 'Al-Qadr',
      englishNameTranslation: 'The Power',
      numberOfAyahs: 5,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 98,
      name: 'البينة',
      englishName: 'Al-Bayyinah',
      englishNameTranslation: 'The Clear Proof',
      numberOfAyahs: 8,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 99,
      name: 'الزلزلة',
      englishName: 'Az-Zalzalah',
      englishNameTranslation: 'The Earthquake',
      numberOfAyahs: 8,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 100,
      name: 'العاديات',
      englishName: 'Al-\'Adiyat',
      englishNameTranslation: 'The Courser',
      numberOfAyahs: 11,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 101,
      name: 'القارعة',
      englishName: 'Al-Qari\'ah',
      englishNameTranslation: 'The Calamity',
      numberOfAyahs: 11,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 102,
      name: 'التكاثر',
      englishName: 'At-Takathur',
      englishNameTranslation: 'Competition',
      numberOfAyahs: 8,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 103,
      name: 'العصر',
      englishName: 'Al-\'Asr',
      englishNameTranslation: 'The Declining Day',
      numberOfAyahs: 3,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 104,
      name: 'الهمزة',
      englishName: 'Al-Humazah',
      englishNameTranslation: 'The Traducer',
      numberOfAyahs: 9,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 105,
      name: 'الفيل',
      englishName: 'Al-Fil',
      englishNameTranslation: 'The Elephant',
      numberOfAyahs: 5,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 106,
      name: 'قريش',
      englishName: 'Quraish',
      englishNameTranslation: 'Quraish',
      numberOfAyahs: 4,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 107,
      name: 'الماعون',
      englishName: 'Al-Ma\'un',
      englishNameTranslation: 'Almsgiving',
      numberOfAyahs: 7,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 108,
      name: 'الكوثر',
      englishName: 'Al-Kauthar',
      englishNameTranslation: 'Abundance',
      numberOfAyahs: 3,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 109,
      name: 'الكافرون',
      englishName: 'Al-Kafirun',
      englishNameTranslation: 'The Disbelievers',
      numberOfAyahs: 6,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 110,
      name: 'النصر',
      englishName: 'An-Nasr',
      englishNameTranslation: 'Divine Support',
      numberOfAyahs: 3,
      revelationType: 'Medinan',
    ),
    Surah(
      number: 111,
      name: 'المسد',
      englishName: 'Al-Masad',
      englishNameTranslation: 'The Palm Fibre',
      numberOfAyahs: 5,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 112,
      name: 'الإخلاص',
      englishName: 'Al-Ikhlas',
      englishNameTranslation: 'Sincerity',
      numberOfAyahs: 4,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 113,
      name: 'الفلق',
      englishName: 'Al-Falaq',
      englishNameTranslation: 'The Daybreak',
      numberOfAyahs: 5,
      revelationType: 'Meccan',
    ),
    Surah(
      number: 114,
      name: 'الناس',
      englishName: 'An-Nas',
      englishNameTranslation: 'Mankind',
      numberOfAyahs: 6,
      revelationType: 'Meccan',
    ),
  ];

  /// Fetches the list of reciters from MP3Quran API.
  /// Falls back to our curated list of 5 premium reciters if network fails.
  Future<List<Reciter>> getReciters() async {
    developer.log('Fetching reciters list...', name: 'QuranService');
    try {
      final response = await _httpService.get('/api/v3/reciters');
      if (response != null && response['reciters'] != null) {
        final recitersJson = response['reciters'] as List<dynamic>;
        final apiReciters = recitersJson
            .map((item) {
              final id = item['id']?.toString() ?? '';
              final name = item['name']?.toString() ?? '';

              // Locate the Hafs Riwayah (moshaf) to get correct audio server
              String server = '';
              String styleName = 'Hafs A\'n Assem';

              if (item['moshaf'] != null && item['moshaf'] is List) {
                final moshafs = item['moshaf'] as List;
                if (moshafs.isNotEmpty) {
                  server = moshafs[0]['server']?.toString() ?? '';
                  styleName =
                      moshafs[0]['name']?.toString() ?? 'Hafs A\'n Assem';
                }
              }

              return Reciter(
                id: id,
                name: name,
                server: server,
                letter: styleName,
              );
            })
            .where((r) => r.name.isNotEmpty && r.server.isNotEmpty)
            .toList();

        if (apiReciters.isNotEmpty) {
          developer.log(
            'Successfully fetched ${apiReciters.length} reciters from API.',
            name: 'QuranService',
          );
          return apiReciters;
        }
      }
      throw Exception('Empty or invalid reciters response.');
    } catch (e) {
      developer.log(
        'Failed to fetch reciters online: $e. Returning fallback default reciters.',
        name: 'QuranService',
      );
      return _defaultReciters;
    }
  }

  /// Returns the static 114 Surahs list.
  /// This is offline-first, avoiding unnecessary server calls.
  List<Surah> getSurahs(Reciter reciter) {
    developer.log(
      'Getting surahs list for reciter: ${reciter.name}',
      name: 'QuranService',
    );
    // Map each surah to its audio stream url based on reciter's base server URL
    return _surahMetadataList.map((surah) {
      // Audio URLs are formatted as [server][paddedNumber].mp3
      // e.g. https://server11.mp3quran.net/sudais/001.mp3
      final baseUrl = reciter.server.endsWith('/')
          ? reciter.server
          : '${reciter.server}/';
      final fileUrl = '$baseUrl${surah.paddedNumber}.mp3';

      return surah.copyWith(audioUrl: fileUrl);
    }).toList();
  }

  /// Returns individual Surah by number
  Surah? getSurahByNumber(int number, Reciter reciter) {
    if (number < 1 || number > 114) return null;
    final surah = _surahMetadataList.firstWhere((s) => s.number == number);
    final baseUrl = reciter.server.endsWith('/')
        ? reciter.server
        : '${reciter.server}/';
    return surah.copyWith(audioUrl: '$baseUrl${surah.paddedNumber}.mp3');
  }

  /// Fetches the verses (Arabic Uthmani text + English translation) of a Surah.
  /// First tries from the API. Falls back to a small static set of sample ayat if offline/error.
  Future<List<Ayah>> getSurahVerses(int surahNumber) async {
    developer.log(
      'Fetching verses for surah: $surahNumber',
      name: 'QuranService',
    );
    try {
      final path = '/surah/$surahNumber/editions/quran-uthmanic,en.asad';
      final response = await _textHttpService.get(path);

      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        final editions = response['data'] as List<dynamic>;
        if (editions.length >= 2) {
          final arabicEdition = editions[0];
          final englishEdition = editions[1];

          final arabicAyahs = arabicEdition['ayahs'] as List<dynamic>;
          final englishAyahs = englishEdition['ayahs'] as List<dynamic>;

          final List<Ayah> ayahs = [];
          for (int i = 0; i < arabicAyahs.length; i++) {
            ayahs.add(
              Ayah.fromJson(
                arabicAyahs[i] as Map<String, dynamic>,
                englishAyahs[i] as Map<String, dynamic>,
              ),
            );
          }
          return ayahs;
        }
      }
      throw Exception('Failed to parse editions from Al Quran Cloud API.');
    } catch (e) {
      developer.log('Failed to fetch surah verses: $e', name: 'QuranService');
      // Return cached sample verses for known surahs (Al-Fatihah, Al-Ikhlas)
      if (_sampleVerses.containsKey(surahNumber)) {
        developer.log(
          'Returning cached sample verses for surah $surahNumber',
          name: 'QuranService',
        );
        return _sampleVerses[surahNumber]!;
      }
      // Re-throw so the UI can show a proper error message instead of fake data
      rethrow;
    }
  }

  // Pre-configured high quality sample verses for offline fallback (Surah Al-Fatihah & Al-Ikhlas)
  static final Map<int, List<Ayah>> _sampleVerses = {
    1: [
      Ayah(
        number: 1,
        text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        translation:
            'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
      ),
      Ayah(
        number: 2,
        text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        translation: '[All] praise is [due] to Allah, Lord of the worlds -',
      ),
      Ayah(
        number: 3,
        text: 'الرَّحْمَٰنِ الرَّحِيمِ',
        translation: 'The Entirely Merciful, the Especially Merciful,',
      ),
      Ayah(
        number: 4,
        text: 'مَالِكِ يَوْمِ الدِّينِ',
        translation: 'Sovereign of the Day of Recompense.',
      ),
      Ayah(
        number: 5,
        text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
        translation: 'It is You we worship and You we ask for help.',
      ),
      Ayah(
        number: 6,
        text: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
        translation: 'Guide us to the straight path -',
      ),
      Ayah(
        number: 7,
        text:
            'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
        translation:
            'The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray.',
      ),
    ],
    112: [
      Ayah(
        number: 1,
        text: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
        translation: 'Say, "He is Allah, [who is] One,',
      ),
      Ayah(
        number: 2,
        text: 'اللَّهُ الصَّمَدُ',
        translation: 'Allah, the Eternal Refuge.',
      ),
      Ayah(
        number: 3,
        text: 'لَمْ يَلِدْ وَلَمْ يُولَدْ',
        translation: 'He neither begets nor is born,',
      ),
      Ayah(
        number: 4,
        text: 'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
        translation: 'And there is none co-equal or comparable unto Him."',
      ),
    ],
  };

  /// Fetches Arabic Muyassar tafsir for a single ayah.
  /// Returns a list with one Ayah; the [translation] field holds the tafsir text.
  Future<List<Ayah>> getAyahTafsir(int surahNumber, int ayahNumber) async {
    developer.log(
      'Fetching tafsir for $surahNumber:$ayahNumber',
      name: 'QuranService',
    );
    try {
      final path =
          '/ayah/$surahNumber:$ayahNumber/editions/quran-uthmanic,en.asad,ar.muyassar';
      final response = await _textHttpService.get(path);

      if (response != null &&
          response['data'] != null &&
          response['data'] is List) {
        final editions = response['data'] as List<dynamic>;
        // editions[0] = Arabic Uthmani, editions[1] = English Asad, editions[2] = Arabic Muyassar
        if (editions.length >= 3) {
          final arabicAyah = editions[0] as Map<String, dynamic>;
          final englishAyah = editions[1] as Map<String, dynamic>;
          final tafsirAyah = editions[2] as Map<String, dynamic>;

          return [
            Ayah(
              number: arabicAyah['numberInSurah'] as int? ?? ayahNumber,
              text: arabicAyah['text']?.toString() ?? '',
              translation: englishAyah['text']?.toString() ?? '',
              tafsir: tafsirAyah['text']?.toString() ?? '',
            ),
          ];
        }
      }
      throw Exception('Failed to parse tafsir response.');
    } catch (e) {
      developer.log('Failed to fetch tafsir: $e', name: 'QuranService');
      return [Ayah(number: ayahNumber, text: '', translation: '', tafsir: '')];
    }
  }
}
