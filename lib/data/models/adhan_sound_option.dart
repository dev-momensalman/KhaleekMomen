/// Represents one selectable Adhan audio option.
///
/// [fileName]  — exact Arabic filename as declared in pubspec.yaml (e.g. "مشاري بن راشد العفاسي.mp3")
/// [assetPath] — full Flutter asset URI used by AudioServiceWrapper / just_audio
/// [displayName] — human-readable Arabic label shown in the UI
class AdhanSoundOption {
  final String displayName;
  final String fileName;
  final String assetPath;
  final String rawResourceName;

  const AdhanSoundOption({
    required this.displayName,
    required this.fileName,
    required this.assetPath,
    required this.rawResourceName,
  });

  /// All Adhan options bundled with the app.
  /// Filenames are identical to those declared in pubspec.yaml — do NOT rename.
  /// assetPath uses the `asset:///` URI scheme required by just_audio.
  static const List<AdhanSoundOption> all = [
    AdhanSoundOption(
      displayName: 'أذان الحرم المكي',
      fileName: 'أذان ,الحرم المكي ,مكة المكرمة ,السعودية.mp3',
      assetPath: 'asset:///assets/audio/adhan_makkah.mp3',
      rawResourceName: 'adhan_makkah',
    ),
    AdhanSoundOption(
      displayName: 'مشاري بن راشد العفاسي',
      fileName: 'مشاري بن راشد العفاسي.mp3',
      assetPath: 'asset:///assets/audio/adhan_alafasy.mp3',
      rawResourceName: 'adhan_alafasy',
    ),
    AdhanSoundOption(
      displayName: 'عبد الباسط عبد الصمد',
      fileName: 'عبد الباسط عبد الصمد.mp3',
      assetPath: 'asset:///assets/audio/adhan_abdulbasit.mp3',
      rawResourceName: 'adhan_abdulbasit',
    ),
    AdhanSoundOption(
      displayName: 'محمد رفعت',
      fileName: 'محمد رفعت.mp3',
      assetPath: 'asset:///assets/audio/adhan_refat.mp3',
      rawResourceName: 'adhan_refat',
    ),
    AdhanSoundOption(
      displayName: 'محمد صديق المنشاوي',
      fileName: 'محمد صديق المنشاوي.mp3',
      assetPath: 'asset:///assets/audio/adhan_minshawi.mp3',
      rawResourceName: 'adhan_minshawi',
    ),
    AdhanSoundOption(
      displayName: 'أحمد جلال يحيى',
      fileName: 'أحمد جلال يحيى.mp3',
      assetPath: 'asset:///assets/audio/adhan_ahmed_jalal.mp3',
      rawResourceName: 'adhan_ahmed_jalal',
    ),
    AdhanSoundOption(
      displayName: 'أبو العينين شعيشع',
      fileName: 'أبوالعينين شعيشع.mp3',
      assetPath: 'asset:///assets/audio/adhan_shaisha.mp3',
      rawResourceName: 'adhan_shaisha',
    ),
    AdhanSoundOption(
      displayName: 'بلبشير عبد القادر',
      fileName: 'بلبشير عبد القادر.mp3',
      assetPath: 'asset:///assets/audio/adhan_belbashir.mp3',
      rawResourceName: 'adhan_belbashir',
    ),
    AdhanSoundOption(
      displayName: 'حمزة المجالي',
      fileName: 'حمزة المجالي.mp3',
      assetPath: 'asset:///assets/audio/adhan_hamza_majali.mp3',
      rawResourceName: 'adhan_hamza_majali',
    ),
    AdhanSoundOption(
      displayName: 'مصطفى إسماعيل',
      fileName: 'مصطفى إسماعيل.mp3',
      assetPath: 'asset:///assets/audio/adhan_mustafa_ismail.mp3',
      rawResourceName: 'adhan_mustafa_ismail',
    ),
  ];

  /// Returns the option whose [fileName] matches [saved], or [all.first] as
  /// fallback when the saved value is absent or the file has been removed.
  static AdhanSoundOption fromFileName(String? saved) {
    if (saved == null || saved.isEmpty) return all.first;
    return all.firstWhere((o) => o.fileName == saved, orElse: () => all.first);
  }

  @override
  bool operator ==(Object other) =>
      other is AdhanSoundOption && other.fileName == fileName;

  @override
  int get hashCode => fileName.hashCode;
}
