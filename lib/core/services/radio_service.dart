import 'dart:async';
import 'dart:developer' as developer;
import 'package:islamic_audio_hub/core/services/http_service.dart';
import 'package:islamic_audio_hub/data/models/station.dart';

class RadioService {
  final HttpService _httpService;

  RadioService(this._httpService);

  // High-quality, reliable default list of stations
  final List<Station> _defaultStations = [
    Station(
      id: 'cairo_quran',
      name: 'Quran Kareem Radio Cairo',
      country: 'Egypt',
      streamUrl: 'http://live.mp3quran.net:9722/;',
      type: 'quran',
    ),
    Station(
      id: 'makkah_haram',
      name: 'Makkah Live Stream',
      country: 'Saudi Arabia',
      streamUrl: 'http://live.mp3quran.net:9718/;',
      type: 'general',
    ),
    Station(
      id: 'edis_quran',
      name: 'Radio Ibrahim Al-Dossari',
      country: 'Saudi Arabia',
      streamUrl: 'http://live.mp3quran.net:9958/;',
      type: 'recitation',
    ),
    Station(
      id: 'sudais_quran',
      name: 'Radio Abdul Rahman Al-Sudais',
      country: 'Saudi Arabia',
      streamUrl: 'http://live.mp3quran.net:9988/;',
      type: 'recitation',
    ),
    Station(
      id: 'riyadh_radio',
      name: 'Riyadh Radio',
      country: 'Saudi Arabia',
      streamUrl: 'http://live.mp3quran.net:9938/;',
      type: 'general',
    ),
  ];

  /// Fetches radio stations from MP3Quran API, maps them, and returns them.
  /// Falls back to curated static stations if offline or if the request fails.
  Future<List<Station>> getStations() async {
    developer.log('Fetching radio stations...', name: 'RadioService');
    try {
      final response = await _httpService.get('/api/v3/radios');

      if (response != null && response['radios'] != null) {
        final radiosJson = response['radios'] as List<dynamic>;
        
        final apiStations = radiosJson.map((item) {
          final id = item['id']?.toString() ?? '';
          final name = item['name']?.toString() ?? '';
          final streamUrl = item['radio_url']?.toString() ?? '';
          
          return Station(
            id: 'api_$id',
            name: name,
            country: 'International',
            streamUrl: streamUrl,
            type: 'quran',
          );
        }).where((s) => s.name.isNotEmpty && s.streamUrl.isNotEmpty).toList();

        if (apiStations.isNotEmpty) {
          developer.log('Successfully fetched ${apiStations.length} radio stations from API.', name: 'RadioService');
          
          // Merge default stations at the top for premium user experience
          final Map<String, Station> merged = {};
          for (var station in _defaultStations) {
            merged[station.id] = station;
          }
          for (var station in apiStations) {
            merged[station.id] = station;
          }
          return merged.values.toList();
        }
      }
      throw Exception('Empty or invalid radios structure in response.');
    } catch (e) {
      developer.log('Failed to fetch radios online: $e. Returning fallback local stations list.', name: 'RadioService');
      // Graceful local fallback as per offline constraints
      return _defaultStations;
    }
  }
}
