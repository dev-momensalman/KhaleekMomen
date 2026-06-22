// lib/core/services/audio_service.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';
import 'package:islamic_audio_hub/core/services/adhan_player.dart';

class IslamicAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  IslamicAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  AudioPlayer get player => _player;

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setSource(String url, MediaItem mediaItem) async {
    this.mediaItem.add(mediaItem);
    final uri = Uri.parse(url);
    final isAsset = uri.scheme == 'asset';
    final timeoutDuration = isAsset
        ? const Duration(seconds: 5)
        : const Duration(seconds: 30);

    final duration =
        await (isAsset
                ? _player.setAudioSource(
                    AudioSource.asset(
                      uri.path.startsWith('/')
                          ? uri.path.substring(1)
                          : uri.path,
                    ),
                  )
                : _player.setAudioSource(
                    AudioSource.uri(
                      uri,
                      headers: const {
                        'User-Agent':
                            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
                            '(KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
                      },
                    ),
                  ))
            .timeout(timeoutDuration);

    this.mediaItem.add(mediaItem.copyWith(duration: duration));
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}

enum AudioError { serviceUnavailable }

class AudioServiceException implements Exception {
  final AudioError error;
  final String message;
  AudioServiceException(
    this.error, [
    this.message = 'Audio service is unavailable.',
  ]);
  @override
  String toString() => message;
}

class AudioServiceWrapper {
  static IslamicAudioHandler? _handler;
  static bool _isInitialized = false;
  static bool _initFailed = false;

  bool get isAvailable => _isInitialized && !_initFailed && _handler != null;
  bool get isInitialized => _isInitialized;
  bool get initFailed => _initFailed;

  final BehaviorSubject<AudioState> _stateSubject = BehaviorSubject.seeded(
    const AudioState(),
  );

  Stream<AudioState> get stateStream => _stateSubject.stream;
  AudioState get currentState => _stateSubject.value;

  Stream<Duration> get positionStream =>
      isAvailable ? _handler!.player.positionStream : const Stream.empty();
  Stream<Duration?> get durationStream =>
      isAvailable ? _handler!.player.durationStream : const Stream.empty();
  Stream<bool> get isPlayingStream =>
      isAvailable ? _handler!.player.playingStream : const Stream.empty();

  Future<void> _queue = Future.value();
  bool _isDisposed = false;
  int _generation = 0;

  String? _lastPlayUrl;
  DateTime? _lastPlayAt;
  static const Duration _dedupeWindow = Duration(milliseconds: 1000);

  static Future<void> init() async {
    if (_isInitialized || _initFailed) return;
    try {
      _handler = await AudioService.init(
        builder: () => IslamicAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.islamicaudiohub.channel.audio',
          androidNotificationChannelName: 'Islamic Audio Hub Playback',

          // ✅ FIX: كان true → بيخلي إشعار دايم في الـ status bar حتى لما مفيش موسيقى
          // ده كان السبب إن المستخدم يشوف التطبيق عند غلق الشاشة.
          // false → الإشعار بيظهر بس لما في صوت شغال فعلاً.
          androidNotificationOngoing: false,

          // ✅ FIX: إخفاء الـ badge لما مفيش شيء شغال
          androidShowNotificationBadge: false,
          androidStopForegroundOnPause: true,
        ),
      );
      _isInitialized = true;
    } catch (e, st) {
      _initFailed = true;
      assert(() {
        debugPrint(
          '[AudioService] INIT FAILED — audio features disabled.\n$e\n$st',
        );
        return true;
      }());
    }
  }

  AudioServiceWrapper() {
    if (!isAvailable) return;
    _attachListeners();
  }

  void _attachListeners() {
    _handler!.player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      if (currentState.isPlaying != isPlaying) {
        _stateSubject.add(currentState.copyWith(isPlaying: isPlaying));
      }
    });

    _handler!.player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        _handlePlaybackError();
      },
    );
  }

  Future<void> _enqueue(Future<void> Function() op, {required int generation}) {
    _queue = _queue.then((_) async {
      if (_isDisposed || _generation != generation) return;
      if (!isAvailable) return;
      try {
        await op();
      } catch (e) {
        assert(() {
          debugPrint('[AudioService] Queued op error: $e');
          return true;
        }());
      }
    });
    return _queue;
  }

  Future<void> _stopNow() async {
    if (!isAvailable) return;
    try {
      await _handler!.stop();
    } catch (_) {}
    _stateSubject.add(
      currentState.copyWith(
        isPlaying: false,
        mode: AudioMode.idle,
        currentSource: null,
      ),
    );
  }

  Future<void> _playNow(
    String url,
    AudioMode targetMode, {
    required String title,
    required String subtitle,
    String? displayTitle,
  }) async {
    if (!isAvailable) return;

    if (currentState.isPlaying) {
      await _stopNow();
    }

    _stateSubject.add(
      AudioState(
        mode: targetMode,
        isPlaying: false,
        currentSource: title,
        previousSource: currentState.currentSource,
        isLocked: false,
        displayTitle: displayTitle ?? title,
        subtitle: subtitle,
      ),
    );
    final startGen = _generation;

    try {
      final mediaItem = MediaItem(
        id: url,
        album: subtitle,
        title: displayTitle ?? title,
      );
      await _handler!.setSource(url, mediaItem);

      if (_generation != startGen || _isDisposed) return;

      _handler!.play();
    } catch (e) {
      developer.log(
        '[AudioServiceWrapper] _playNow error: $e',
        name: 'AudioServiceWrapper',
      );
      if (!currentState.isLocked && _generation == startGen) {
        _stateSubject.add(
          const AudioState(
            mode: AudioMode.idle,
            isPlaying: false,
            currentSource: null,
            isLocked: false,
          ),
        );
      }
      rethrow;
    }
  }

  void lockForAdhan(String arabicPrayerName) {
    _generation++;
    _queue = Future.value();

    if (isAvailable && currentState.isPlaying) {
      try {
        _handler!.stop();
      } catch (_) {}
    }

    _stateSubject.add(
      AudioState(
        mode: AudioMode.adhan,
        isPlaying: true,
        isLocked: true,
        currentSource: arabicPrayerName,
        displayTitle: arabicPrayerName,
        subtitle: 'خليك مؤمن',
      ),
    );

    developer.log(
      'AudioServiceWrapper: locked for adhan — $arabicPrayerName',
      name: 'AudioServiceWrapper',
    );
  }

  void unlockFromAdhan() {
    _stateSubject.add(
      const AudioState(
        mode: AudioMode.idle,
        isPlaying: false,
        isLocked: false,
        currentSource: null,
      ),
    );

    developer.log(
      'AudioServiceWrapper: unlocked from adhan.',
      name: 'AudioServiceWrapper',
    );
  }

  Future<void> play(
    String url,
    AudioMode targetMode, {
    required String title,
    required String subtitle,
    String? displayTitle,
  }) {
    if (!isAvailable) {
      return Future.error(AudioServiceException(AudioError.serviceUnavailable));
    }
    if (currentState.isLocked) {
      return Future.error(Exception('Audio locked during Adhan.'));
    }
    assert(
      targetMode != AudioMode.adhan,
      'Use lockForAdhan() + AdhanPlayer.play() for adhan mode.',
    );

    final now = DateTime.now();
    if (url == _lastPlayUrl &&
        _lastPlayAt != null &&
        now.difference(_lastPlayAt!) < _dedupeWindow) {
      return Future.value();
    }
    _lastPlayUrl = url;
    _lastPlayAt = now;

    final gen = _generation;
    return _enqueue(
      () => _playNow(
        url,
        targetMode,
        title: title,
        subtitle: subtitle,
        displayTitle: displayTitle,
      ),
      generation: gen,
    );
  }

  Future<void> pause() {
    if (!isAvailable) {
      return Future.error(AudioServiceException(AudioError.serviceUnavailable));
    }
    if (currentState.isLocked) return Future.value();
    final gen = _generation;
    return _enqueue(() async {
      if (!isAvailable) return;
      try {
        await _handler!.pause();
      } catch (_) {}
    }, generation: gen);
  }

  Future<void> resume() {
    if (!isAvailable) {
      return Future.error(AudioServiceException(AudioError.serviceUnavailable));
    }
    if (currentState.isLocked) return Future.value();
    final gen = _generation;
    return _enqueue(() async {
      if (!isAvailable) return;
      try {
        await _handler!.play();
      } catch (_) {}
    }, generation: gen);
  }

  Future<void> stop() async {
    if (!isAvailable) return;
    _generation++;
    _queue = Future.value();

    if (currentState.mode == AudioMode.adhan) {
      await AdhanPlayer.stop();
    }

    await _stopNow();
  }

  Future<void> switchSource(
    String url,
    AudioMode targetMode, {
    required String title,
    required String subtitle,
    String? displayTitle,
  }) {
    if (!isAvailable) {
      return Future.error(AudioServiceException(AudioError.serviceUnavailable));
    }
    return play(
      url,
      targetMode,
      title: title,
      subtitle: subtitle,
      displayTitle: displayTitle,
    );
  }

  void _handlePlaybackError() {
    if (!isAvailable) return;
    developer.log(
      '[AudioServiceWrapper] Playback error — mode: ${currentState.mode}',
      name: 'AudioServiceWrapper',
    );
    try {
      _handler!.stop();
    } catch (_) {}

    _stateSubject.add(currentState.copyWith(isPlaying: false));
  }

  void dispose() {
    _isDisposed = true;
    _stateSubject.close();
  }
}
