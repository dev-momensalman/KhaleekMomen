import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/core/services/azkar_service.dart';
import 'package:islamic_audio_hub/data/models/azkar_item.dart';

class AzkarController extends ChangeNotifier {
  final AzkarService _azkarService;

  // Cache loaded Azkar lists
  final Map<String, List<AzkarItem>> _azkarCache = {};
  
  // Track counts for each azkar item by id
  final Map<String, int> _counts = {};

  AzkarController(this._azkarService);

  List<AzkarItem> getAzkar(String category) {
    if (!_azkarCache.containsKey(category)) {
      _azkarCache[category] = _azkarService.getAzkarByCategory(category);
    }
    return _azkarCache[category] ?? [];
  }

  List<String> getCategories() {
    return _azkarService.getCategories();
  }

  int getCount(String id) {
    return _counts[id] ?? 0;
  }

  void incrementCount(AzkarItem item) {
    final current = _counts[item.id] ?? 0;
    if (current < item.count) {
      _counts[item.id] = current + 1;
      notifyListeners();
    }
  }

  void resetCount(String id) {
    _counts[id] = 0;
    notifyListeners();
  }

  void resetCategoryCounts(String category) {
    final items = getAzkar(category);
    for (var item in items) {
      _counts[item.id] = 0;
    }
    notifyListeners();
  }

  bool isCompleted(AzkarItem item) {
    return getCount(item.id) >= item.count;
  }
}
