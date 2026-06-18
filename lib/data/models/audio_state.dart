enum AudioMode { idle, quran, radio, adhan }

class AudioState {
  final AudioMode mode;
  final bool isPlaying;
  final dynamic currentSource; // Station or Surah model
  final dynamic previousSource;
  final bool isLocked; // Locked when Adhan is playing

  const AudioState({
    this.mode = AudioMode.idle,
    this.isPlaying = false,
    this.currentSource,
    this.previousSource,
    this.isLocked = false,
  });

  // Sentinel object to distinguish "not passed" from explicit null.
  // This allows copyWith(currentSource: null) to actually clear the value.
  static const Object _unset = Object();

  AudioState copyWith({
    AudioMode? mode,
    bool? isPlaying,
    Object? currentSource = _unset,
    Object? previousSource = _unset,
    bool? isLocked,
  }) {
    return AudioState(
      mode: mode ?? this.mode,
      isPlaying: isPlaying ?? this.isPlaying,
      currentSource:
          currentSource == _unset ? this.currentSource : currentSource,
      previousSource:
          previousSource == _unset ? this.previousSource : previousSource,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  String toString() {
    return 'AudioState(mode: $mode, isPlaying: $isPlaying, currentSource: $currentSource, isLocked: $isLocked)';
  }
}
