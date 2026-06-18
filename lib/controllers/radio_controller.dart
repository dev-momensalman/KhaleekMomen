import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:islamic_audio_hub/core/services/audio_service.dart';
import 'package:islamic_audio_hub/core/services/radio_service.dart';
import 'package:islamic_audio_hub/core/services/storage_service.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';
import 'package:islamic_audio_hub/data/models/station.dart';

class RadioController extends ChangeNotifier {
  final RadioService _radioService;
  final StorageService _storageService;
  final AudioServiceWrapper _audioService;

  List<Station> _stations = [];
  List<String> _favoriteStationIds = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _audioSubscription;

  RadioController(
    this._radioService,
    this._storageService,
    this._audioService,
  ) {
    _loadFavorites();
    _audioSubscription = _audioService.stateStream.listen((state) {
      notifyListeners();
    });
  }

  // Getters
  List<Station> get stations => _stations;
  List<String> get favoriteStationIds => _favoriteStationIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Station> get favoriteStations =>
      _stations.where((s) => _favoriteStationIds.contains(s.id)).toList();

  void _loadFavorites() {
    _favoriteStationIds = _storageService.getFavoriteStations();
    notifyListeners();
  }

  Future<void> fetchStations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stations = await _radioService.getStations();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      developer.log('Error fetching radio stations: $_errorMessage', name: 'RadioController');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(Station station) {
    return _favoriteStationIds.contains(station.id);
  }

  Future<void> toggleFavorite(Station station) async {
    if (isFavorite(station)) {
      _favoriteStationIds.remove(station.id);
    } else {
      _favoriteStationIds.add(station.id);
    }
    await _storageService.setFavoriteStations(_favoriteStationIds);
    notifyListeners();
  }

  // Audio Playback Actions
  bool isStationPlaying(Station station) {
    final state = _audioService.currentState;
    return state.mode == AudioMode.radio &&
        state.currentSource == station.name &&
        state.isPlaying;
  }

  bool isStationActive(Station station) {
    final state = _audioService.currentState;
    return state.mode == AudioMode.radio && state.currentSource == station.name;
  }

  Future<void> playStation(Station station) async {
    try {
      await _audioService.play(
        station.streamUrl,
        AudioMode.radio,
        title: station.name,
        subtitle: station.country,
      );
      
      // Save last played state
      await _storageService.setLastPlayedAudio({
        'type': 'radio',
        'id': station.id,
        'title': station.name,
        'subtitle': station.country,
        'url': station.streamUrl,
      });
    } catch (e) {
      developer.log('Failed to play radio station: $e', name: 'RadioController');
      rethrow;
    }
  }

  Future<void> stopStation() async {
    await _audioService.stop();
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    super.dispose();
  }
}
