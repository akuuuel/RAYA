/// Titik koordinat posisi pengguna sesuai FR-26 dan FR-28.
class LocationPoint {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime updatedAt;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.updatedAt,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

