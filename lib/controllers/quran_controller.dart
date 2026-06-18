import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/quran_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';
import 'package:islamic_audio_hub/data/models/reciter.dart';
import 'package:islamic_audio_hub/data/models/surah.dart';
import 'package:islamic_audio_hub/data/models/ayah.dart';

class QuranController extends ChangeNotifier {
  final QuranService _quranService;
  final StorageService _storageService;
  final AudioServiceWrapper _audioService;

  List<Reciter> _reciters = [];
  Reciter? _selectedReciter;
  List<Surah> _surahs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<String> _favoriteReciterIds = [];
  List<String> _favoriteSurahIds = [];
  StreamSubscription? _audioSubscription;

  // Reading position
  Map<String, dynamic>? _lastReadingPosition;

  QuranController(
    this._quranService,
    this._storageService,
    this._audioService,
  ) {
    _loadFavorites();
    _loadReadingPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _audioSubscription = _audioService.stateStream.listen((state) {
        notifyListeners();
      });
    });
  }

  // Getters
  List<Reciter> get reciters => _reciters;
  Reciter? get selectedReciter => _selectedReciter;
  List<Surah> get surahs => _surahs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get favoriteReciterIds => _favoriteReciterIds;
  List<String> get favoriteSurahIds => _favoriteSurahIds;

  /// Last saved reading position. Keys: surahNumber, ayahNumber, surahName, timestamp.
  Map<String, dynamic>? get lastReadingPosition => _lastReadingPosition;

  void _loadFavorites() {
    _favoriteReciterIds = _storageService.getFavoriteReciters();
    _favoriteSurahIds = _storageService.getFavoriteSurahs();
  }

  void _loadReadingPosition() {
    _lastReadingPosition = _storageService.getLastReadingPosition();
  }

  Future<void> saveReadingPosition({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
  }) async {
    await _storageService.saveLastReadingPosition(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
    );
    _lastReadingPosition = {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'surahName': surahName,
      'timestamp': DateTime.now().toIso8601String(),
    };
    notifyListeners();
  }

  Future<void> clearReadingPosition() async {
    await _storageService.clearLastReadingPosition();
    _lastReadingPosition = null;
    notifyListeners();
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reciters = await _quranService.getReciters();
      if (_reciters.isNotEmpty) {
        final lastReciterId = _storageService.get('last_reciter_id');
        final savedReciter = _reciters.firstWhere(
          (r) => r.id == lastReciterId,
          orElse: () =>
              _reciters.first, // safe: _reciters.isNotEmpty checked above
        );
        selectReciter(savedReciter);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      developer.log(
        'Error initializing QuranController: \$_errorMessage',
        name: 'QuranController',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectReciter(Reciter reciter) {
    _selectedReciter = reciter;
    _storageService.put('last_reciter_id', reciter.id);
    _surahs = _quranService.getSurahs(reciter);
    notifyListeners();
  }

  bool isReciterFavorite(Reciter reciter) =>
      _favoriteReciterIds.contains(reciter.id);

  Future<void> toggleReciterFavorite(Reciter reciter) async {
    if (isReciterFavorite(reciter)) {
      _favoriteReciterIds.remove(reciter.id);
    } else {
      _favoriteReciterIds.add(reciter.id);
    }
    await _storageService.setFavoriteReciters(_favoriteReciterIds);
    notifyListeners();
  }

  bool isSurahFavorite(Surah surah) =>
      _favoriteSurahIds.contains(surah.number.toString());

  Future<void> toggleSurahFavorite(Surah surah) async {
    final key = surah.number.toString();
    if (isSurahFavorite(surah)) {
      _favoriteSurahIds.remove(key);
    } else {
      _favoriteSurahIds.add(key);
    }
    await _storageService.setFavoriteSurahs(_favoriteSurahIds);
    notifyListeners();
  }

  bool isSurahPlaying(Surah surah) {
    final state = _audioService.currentState;
    return state.mode == AudioMode.quran &&
        state.currentSource == surah.number.toString() &&
        state.isPlaying;
  }

  bool isSurahActive(Surah surah) {
    final state = _audioService.currentState;
    return state.mode == AudioMode.quran &&
        state.currentSource == surah.number.toString();
  }

  Future<void> playSurah(Surah surah) async {
    if (_selectedReciter == null || surah.audioUrl == null) return;
    try {
      await _audioService.play(
        surah.audioUrl!,
        AudioMode.quran,
        title: surah.number.toString(), // use number as stable ID
        subtitle: _selectedReciter!.name,
      );
      await _storageService.setLastPlayedAudio({
        'type': 'quran',
        'id': surah.number.toString(), // ← أضف هذا السطر فقط
        'reciterId': _selectedReciter!.id,
        'title': surah.englishName,
        'subtitle': _selectedReciter!.name,
        'url': surah.audioUrl!,
      });
    } catch (e) {
      developer.log('Failed to play Surah: \$e', name: 'QuranController');
      rethrow;
    }
  }

  Future<List<Ayah>> getSurahVerses(int surahNumber) {
    return _quranService.getSurahVerses(surahNumber);
  }

  Future<List<Ayah>> getAyahTafsir(int surahNumber, int ayahNumber) {
    return _quranService.getAyahTafsir(surahNumber, ayahNumber);
  }

  Future<void> pauseSurah() async => _audioService.pause();
  Future<void> stopSurah() async => _audioService.stop();

  @override
  void dispose() {
    _audioSubscription?.cancel();
    super.dispose();
  }
}
