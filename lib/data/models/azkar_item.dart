class AzkarItem {
  final String id;
  final String category;
  final String text;
  final String translation;
  final int count; // Target repetition count (e.g. 3, 33, 100)
  final String? audioUrl; // Optional audio play link

  AzkarItem({
    required this.id,
    required this.category,
    required this.text,
    required this.translation,
    required this.count,
    this.audioUrl,
  });

  factory AzkarItem.fromJson(Map<String, dynamic> json) {
    return AzkarItem(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
      count: json['count'] as int? ?? 1,
      audioUrl: json['audioUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'text': text,
      'translation': translation,
      'count': count,
      'audioUrl': audioUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AzkarItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AzkarItem(category: $category, count: $count)';
}
