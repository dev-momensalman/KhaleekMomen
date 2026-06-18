class Reciter {
  final String id;
  final String name;
  final String server; // Server base URL for audio playback
  final String letter; // Style / Riwayah

  Reciter({
    required this.id,
    required this.name,
    required this.server,
    required this.letter,
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      server: json['server']?.toString() ?? '',
      letter: json['letter']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'server': server,
      'letter': letter,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reciter && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Reciter(name: $name)';
}
