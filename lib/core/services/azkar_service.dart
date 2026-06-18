// lib/core/services/azkar_service.dart

import 'package:islamic_audio_hub/data/models/azkar_item.dart';

class AzkarService {
  final List<AzkarItem> _allAzkar = [
    // ══════════════════════════════════════════════════
    // 🌅 أذكار الصباح
    // ══════════════════════════════════════════════════
    AzkarItem(
      id: 'm1',
      category: 'morning',
      text:
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ.',
      translation:
          'We have reached the morning and at this very time all sovereignty belongs to Allah. O Lord, I ask You for the good of this day and the good of what follows it.',
      count: 1,
      source: 'صحيح مسلم',
    ),
    AzkarItem(
      id: 'm2',
      category: 'morning',
      text:
          'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.',
      translation:
          'O Allah, by Your leave we have reached the morning and by Your leave we reach the evening, by Your leave we live and die, and unto You is our resurrection.',
      count: 1,
      source: 'سنن الترمذي',
    ),
    AzkarItem(
      id: 'm3',
      category: 'morning',
      text:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.',
      translation:
          'O Allah, You are my Lord, none has the right to be worshipped except You. You created me and I am Your servant. I abide by Your covenant and promise as best I can.',
      count: 1,
      source: 'صحيح البخاري — سيد الاستغفار',
    ),
    AzkarItem(
      id: 'm4',
      category: 'morning',
      text:
          'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.',
      translation:
          'O Ever Living One, O Sustainer of all, by Your mercy I call upon You to set right all my affairs. Do not leave me to myself even for the blink of an eye.',
      count: 1,
      source: 'المستدرك للحاكم',
    ),
    AzkarItem(
      id: 'm5',
      category: 'morning',
      text:
          'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ.',
      translation:
          'O Allah, grant me health in my body. O Allah, grant me health in my hearing. O Allah, grant me health in my sight. None has the right to be worshipped except You.',
      count: 3,
      source: 'سنن أبي داود',
    ),
    AzkarItem(
      id: 'm6',
      category: 'morning',
      text:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي.',
      translation:
          'O Allah, I ask You for pardon and well-being in this life and the next. O Allah, I ask You for pardon and well-being in my religious and worldly affairs.',
      count: 1,
      source: 'سنن ابن ماجه',
    ),
    AzkarItem(
      id: 'm7',
      category: 'morning',
      text:
          'بِسْمِ اللهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.',
      translation:
          'In the name of Allah with Whose name nothing can harm on earth or in heaven, and He is the All-Hearing, All-Knowing.',
      count: 3,
      source: 'سنن أبي داود — سنن الترمذي',
    ),
    AzkarItem(
      id: 'm8',
      category: 'morning',
      text:
          'رَضِيتُ بِاللهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا وَرَسُولًا.',
      translation:
          'I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet and Messenger.',
      count: 3,
      source: 'سنن أبي داود',
    ),
    AzkarItem(
      id: 'm9',
      category: 'morning',
      text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ.',
      translation: 'How perfect Allah is and I praise Him.',
      count: 100,
      source: 'صحيح البخاري — صحيح مسلم',
    ),
    AzkarItem(
      id: 'm10',
      category: 'morning',
      text:
          'لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      translation:
          'None has the right to be worshipped except Allah, alone, without partner. To Him belongs all sovereignty and praise, and He is over all things omnipotent.',
      count: 10,
      source: 'صحيح مسلم',
    ),

    // ══════════════════════════════════════════════════
    // 🌙 أذكار المساء
    // ══════════════════════════════════════════════════
    AzkarItem(
      id: 'e1',
      category: 'evening',
      text:
          'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا.',
      translation:
          'We have reached the evening and at this very time all sovereignty belongs to Allah. O Lord, I ask You for the good of this night and the good of what follows.',
      count: 1,
      source: 'صحيح مسلم',
    ),
    AzkarItem(
      id: 'e2',
      category: 'evening',
      text:
          'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ.',
      translation:
          'O Allah, by Your leave we have reached the evening and by Your leave we reach the morning, by Your leave we live and die, and unto You is our return.',
      count: 1,
      source: 'سنن الترمذي',
    ),
    AzkarItem(
      id: 'e3',
      category: 'evening',
      text:
          'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.',
      translation:
          'O Allah, You are my Lord, none has the right to be worshipped except You. You created me and I am Your servant.',
      count: 1,
      source: 'صحيح البخاري — سيد الاستغفار',
    ),
    AzkarItem(
      id: 'e4',
      category: 'evening',
      text: 'أَعُوذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',
      translation:
          'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      count: 3,
      source: 'صحيح مسلم',
    ),
    AzkarItem(
      id: 'e5',
      category: 'evening',
      text:
          'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ.',
      translation:
          'O Allah, grant me health in my body, my hearing, and my sight. None has the right to be worshipped except You.',
      count: 3,
      source: 'سنن أبي داود',
    ),
    AzkarItem(
      id: 'e6',
      category: 'evening',
      text:
          'بِسْمِ اللهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ.',
      translation:
          'In the name of Allah with Whose name nothing can harm on earth or in heaven, and He is the All-Hearing, All-Knowing.',
      count: 3,
      source: 'سنن أبي داود',
    ),
    AzkarItem(
      id: 'e7',
      category: 'evening',
      text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ.',
      translation: 'How perfect Allah is and I praise Him.',
      count: 100,
      source: 'صحيح البخاري — صحيح مسلم',
    ),
    AzkarItem(
      id: 'e8',
      category: 'evening',
      text:
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ.',
      translation:
          'O Allah, I ask You for pardon and well-being in this life and the next.',
      count: 1,
      source: 'سنن ابن ماجه',
    ),

    // ══════════════════════════════════════════════════
    // 😴 أذكار النوم
    // ══════════════════════════════════════════════════
    AzkarItem(
      id: 's1',
      category: 'sleep',
      text:
          'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ.',
      translation:
          'In Your name my Lord, I lie down and in Your name I rise. If You take my soul then have mercy upon it, and if You release it then protect it.',
      count: 1,
      source: 'صحيح البخاري',
    ),
    AzkarItem(
      id: 's2',
      category: 'sleep',
      text: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.',
      translation:
          'O Allah, protect me from Your punishment on the Day You resurrect Your slaves.',
      count: 3,
      source: 'سنن أبي داود',
    ),
    AzkarItem(
      id: 's3',
      category: 'sleep',
      text:
          'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، لَا مَلْجَأَ وَلَا مَنْجَا مِنْكَ إِلَّا إِلَيْكَ.',
      translation:
          'O Allah, I submit myself to You, entrust my affairs to You, and rely on You. There is no refuge or escape from You except to You.',
      count: 1,
      source: 'صحيح البخاري',
    ),
    AzkarItem(
      id: 's4',
      category: 'sleep',
      text: 'سُبْحَانَ اللهِ.',
      translation: 'How perfect Allah is.',
      count: 33,
      source: 'صحيح البخاري — تسبيح فاطمة',
    ),
    AzkarItem(
      id: 's5',
      category: 'sleep',
      text: 'الْحَمْدُ لِلَّهِ.',
      translation: 'All praise is for Allah.',
      count: 33,
      source: 'صحيح البخاري — تسبيح فاطمة',
    ),
    AzkarItem(
      id: 's6',
      category: 'sleep',
      text: 'اللهُ أَكْبَرُ.',
      translation: 'Allah is the Greatest.',
      count: 34,
      source: 'صحيح البخاري — تسبيح فاطمة',
    ),

    // ══════════════════════════════════════════════════
    // 📿 أذكار عامة
    // ══════════════════════════════════════════════════
    AzkarItem(
      id: 'g1',
      category: 'general',
      text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ، سُبْحَانَ اللهِ الْعَظِيمِ.',
      translation:
          'How perfect Allah is and I praise Him. How perfect Allah is, the Supreme.',
      count: 100,
      source: 'صحيح البخاري — صحيح مسلم',
    ),
    AzkarItem(
      id: 'g2',
      category: 'general',
      text:
          'لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      translation:
          'None has the right to be worshipped except Allah, alone, without partner. To Him belongs all sovereignty and praise.',
      count: 100,
      source: 'صحيح البخاري',
    ),
    AzkarItem(
      id: 'g3',
      category: 'general',
      text: 'أَسْتَغْفِرُ اللهَ وَأَتُوبُ إِلَيْهِ.',
      translation: 'I seek Allah\'s forgiveness and repent to Him.',
      count: 100,
      source: 'صحيح البخاري — صحيح مسلم',
    ),
    AzkarItem(
      id: 'g4',
      category: 'general',
      text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ.',
      translation: 'O Allah, send prayers and peace upon our Prophet Muhammad.',
      count: 100,
      source: 'السنة النبوية',
    ),
    AzkarItem(
      id: 'g5',
      category: 'general',
      text: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ.',
      translation: 'There is no power or might except with Allah.',
      count: 100,
      source: 'صحيح البخاري — كنز من كنوز الجنة',
    ),
  ];

  List<AzkarItem> getAzkarByCategory(String category) {
    return _allAzkar
        .where((item) => item.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  List<String> getCategories() {
    return ['morning', 'evening', 'sleep', 'general'];
  }
}
