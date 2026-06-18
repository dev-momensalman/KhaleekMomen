// lib/data/models/azkar_item.dart

class AzkarItem {
  final String id;
  final String category;
  final String text;
  final String translation;
  final int count;
  final String? source;
  final String? audioUrl;

  AzkarItem({
    required this.id,
    required this.category,
    required this.text,
    required this.translation,
    required this.count,
    this.source,
    this.audioUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AzkarItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AzkarItem(category: $category, count: $count)';
}
