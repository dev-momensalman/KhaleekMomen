enum AudioMode { idle, quran, radio, adhan }

class AudioState {
  final AudioMode mode;
  final bool isPlaying;
  final dynamic currentSource; // stable ID (surah number / station id)
  final dynamic previousSource;
  final bool isLocked;
  final String? displayTitle; // ← جديد: اسم السورة أو المحطة للعرض
  final String? subtitle; // ← جديد: اسم القارئ أو وصف المحطة

  const AudioState({
    this.mode = AudioMode.idle,
    this.isPlaying = false,
    this.currentSource,
    this.previousSource,
    this.isLocked = false,
    this.displayTitle,
    this.subtitle,
  });

  static const Object _unset = Object();

  AudioState copyWith({
    AudioMode? mode,
    bool? isPlaying,
    Object? currentSource = _unset,
    Object? previousSource = _unset,
    bool? isLocked,
    Object? displayTitle = _unset,
    Object? subtitle = _unset,
  }) {
    return AudioState(
      mode: mode ?? this.mode,
      isPlaying: isPlaying ?? this.isPlaying,
      currentSource: currentSource == _unset
          ? this.currentSource
          : currentSource,
      previousSource: previousSource == _unset
          ? this.previousSource
          : previousSource,
      isLocked: isLocked ?? this.isLocked,
      displayTitle: displayTitle == _unset
          ? this.displayTitle
          : displayTitle as String?,
      subtitle: subtitle == _unset ? this.subtitle : subtitle as String?,
    );
  }

  @override
  String toString() {
    return 'AudioState(mode: $mode, isPlaying: $isPlaying, '
        'currentSource: $currentSource, displayTitle: $displayTitle, '
        'subtitle: $subtitle, isLocked: $isLocked)';
  }
}
