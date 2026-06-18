import 'dart:developer' as developer;
import 'package:islamic_audio_hub/data/models/azkar_item.dart';

class AzkarService {
  final List<AzkarItem> _allAzkar = [
    // Morning Azkar
    AzkarItem(
      id: 'm1',
      category: 'morning',
      text: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      translation: 'We have reached the morning and at this very time all sovereignty belongs to Allah, and all praise is for Allah. None has the right to be worshipped except Allah, alone, without partner.',
      count: 1,
    ),
    AzkarItem(
      id: 'm2',
      category: 'morning',
      text: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.',
      translation: 'O Allah, by Your leave we have reached the morning and by Your leave we reach the evening, by Your leave we live and by Your leave we die, and unto You is our resurrection.',
      count: 1,
    ),
    AzkarItem(
      id: 'm3',
      category: 'morning',
      text: 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ.',
      translation: 'O Ever Living One, O Sustainer of all, by Your mercy I call upon You to set right all my affairs. Do not leave me to myself even for the blink of an eye.',
      count: 1,
    ),
    AzkarItem(
      id: 'm4',
      category: 'morning',
      text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ.',
      translation: 'How perfect Allah is and I praise Him.',
      count: 100,
    ),

    // Evening Azkar
    AzkarItem(
      id: 'e1',
      category: 'evening',
      text: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      translation: 'We have reached the evening and at this very time all sovereignty belongs to Allah, and all praise is for Allah. None has the right to be worshipped except Allah, alone, without partner.',
      count: 1,
    ),
    AzkarItem(
      id: 'e2',
      category: 'evening',
      text: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْهِ الْمَصِيرُ.',
      translation: 'O Allah, by Your leave we have reached the evening and by Your leave we reach the morning, by Your leave we live and by Your leave we die, and unto You is our return.',
      count: 1,
    ),
    AzkarItem(
      id: 'e3',
      category: 'evening',
      text: 'أَعُوذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ.',
      translation: 'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      count: 3,
    ),

    // Sleep Azkar
    AzkarItem(
      id: 's1',
      category: 'sleep',
      text: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ.',
      translation: 'In Your name my Lord, I lie down and in Your name I rise. If You take my soul then have mercy upon it, and if You release it then protect it as You protect Your righteous slaves.',
      count: 1,
    ),
    AzkarItem(
      id: 's2',
      category: 'sleep',
      text: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ.',
      translation: 'O Allah, protect me from Your punishment on the Day You resurrect Your slaves.',
      count: 3,
    ),
  ];

  /// Returns Azkar items filtering by category.
  List<AzkarItem> getAzkarByCategory(String category) {
    developer.log('Getting Azkar for category: $category', name: 'AzkarService');
    return _allAzkar.where((item) => item.category.toLowerCase() == category.toLowerCase()).toList();
  }

  /// Get list of all categories available
  List<String> getCategories() {
    return ['morning', 'evening', 'sleep'];
  }
}
