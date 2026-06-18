class Ayah {
  final int number;
  final String text;
  final String translation;
  /// Arabic Muyassar simplified tafsir (optional, loaded on demand).
  final String tafsir;

  Ayah({
    required this.number,
    required this.text,
    required this.translation,
    this.tafsir = '',
  });

  factory Ayah.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> translationJson, {
    Map<String, dynamic>? tafsirJson,
  }) {
    return Ayah(
      number: json['numberInSurah'] as int? ?? json['number'] as int? ?? 0,
      text: json['text']?.toString() ?? '',
      translation: translationJson['text']?.toString() ?? '',
      tafsir: tafsirJson?['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      'translation': translation,
      'tafsir': tafsir,
    };
  }
}
