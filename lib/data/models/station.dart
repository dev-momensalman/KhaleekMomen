class Station {
  final String id;
  final String name;
  final String country;
  final String streamUrl;
  final String type; // quran, azkar, nasheed, etc.

  Station({
    required this.id,
    required this.name,
    required this.country,
    required this.streamUrl,
    required this.type,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      streamUrl: json['streamUrl']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'streamUrl': streamUrl,
      'type': type,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Station && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Station(name: $name, type: $type)';
}
