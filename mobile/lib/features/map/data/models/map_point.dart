class MapPoint {
  final String id;
  final double latitude;
  final double longitude;
  final String status;

  MapPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory MapPoint.fromJson(Map<String, dynamic> json) {
    return MapPoint(
      id: json['id'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'REPORTED',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  MapPoint copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? status,
  }) {
    return MapPoint(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
    );
  }
}
