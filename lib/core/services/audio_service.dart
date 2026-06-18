import 'dart:async';
import 'dart:developer' as developer;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:islamic_audio_hub/data/models/audio_state.dart';

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
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
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
      final isCompleted =
          playerState.processingState == ProcessingState.completed;

      if (currentState.isPlaying != isPlaying) {
        _stateSubject.add(currentState.copyWith(isPlaying: isPlaying));
      }

      if (isCompleted && currentState.mode == AudioMode.adhan) {
        _handleAdhanComplete();
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
        mode: currentState.isLocked ? AudioMode.adhan : AudioMode.idle,
        currentSource: currentState.isLocked
            ? currentState.currentSource
            : null,
      ),
    );
  }

  // BUG FIX #3: Added optional [displayTitle] — used for MediaItem.title
  // (shown in the media notification / lock screen control).
  // [title] remains the stable currentSource identifier (e.g. surah number).
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
        displayTitle: displayTitle ?? title, // ← اسم السورة بالعربي
        subtitle: subtitle, // ← اسم القارئ
      ),
    );
    final startGen = _generation;

    try {
      // BUG FIX #3: Use displayTitle for what shows in the media notification.
      // Falls back to title if displayTitle is not provided.
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

  // BUG FIX #3: Added optional [displayTitle] for MediaItem.title.
  Future<void> _triggerAdhanNow(
    String url,
    String title,
    String subtitle, {
    String? displayTitle,
  }) async {
    if (!isAvailable) return;

    _generation++;
    _queue = Future.value();

    try {
      await _handler!.stop();
    } catch (_) {}

    _stateSubject.add(
      AudioState(
        mode: AudioMode.adhan,
        isPlaying: false,
        isLocked: true,
        previousSource: currentState.currentSource,
        currentSource: title,
        displayTitle: displayTitle ?? title, // ← اسم الأذان
        subtitle: subtitle, // ← اسم الصلاة
      ),
    );

    try {
      final mediaItem = MediaItem(
        id: url,
        album: subtitle,
        title: displayTitle ?? title, // BUG FIX #3
      );
      await _handler!.setSource(url, mediaItem);
      _handler!.play();
    } catch (e) {
      _stateSubject.add(
        const AudioState(
          mode: AudioMode.idle,
          isPlaying: false,
          isLocked: false,
          currentSource: null,
        ),
      );
      rethrow;
    }
  }

  // BUG FIX #3: Added optional [displayTitle] parameter.
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
    if (currentState.isLocked && targetMode != AudioMode.adhan) {
      return Future.error(Exception('Audio locked during Adhan.'));
    }
    if (targetMode == AudioMode.adhan) {
      return _triggerAdhanNow(url, title, subtitle, displayTitle: displayTitle);
    }

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
        displayTitle: displayTitle, // BUG FIX #3: pass through
      ),
      generation: gen,
    );
  }

  Future<void> pause() {
    if (!isAvailable) {
      return Future.error(AudioServiceException(AudioError.serviceUnavailable));
    }
    if (currentState.isLocked && currentState.mode != AudioMode.adhan) {
      return Future.value();
    }
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
    if (currentState.isLocked && currentState.mode != AudioMode.adhan) {
      return Future.value();
    }
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

  void _handleAdhanComplete() {
    if (!isAvailable) return;
    developer.log(
      'Diagnostic Log - [AudioServiceWrapper]: Adhan completion triggered.',
      name: 'AudioServiceWrapper',
    );
    try {
      _handler!.stop();
    } catch (_) {}
    _stateSubject.add(
      const AudioState(
        isLocked: false,
        mode: AudioMode.idle,
        isPlaying: false,
        currentSource: null,
        previousSource: null,
      ),
    );
  }

  void _handlePlaybackError() {
    if (!isAvailable) return;
    developer.log(
      '[AudioServiceWrapper] Playback error — mode: ${currentState.mode}, locked: ${currentState.isLocked}',
      name: 'AudioServiceWrapper',
    );
    try {
      _handler!.stop();
    } catch (_) {}

    if (currentState.isLocked) {
      _stateSubject.add(
        const AudioState(
          isLocked: false,
          mode: AudioMode.idle,
          isPlaying: false,
          currentSource: null,
          previousSource: null,
        ),
      );
    } else {
      _stateSubject.add(currentState.copyWith(isPlaying: false));
    }
  }

  void dispose() {
    _isDisposed = true;
    _stateSubject.close();
  }
}
