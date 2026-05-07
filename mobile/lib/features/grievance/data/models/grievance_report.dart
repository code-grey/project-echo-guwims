class GrievanceReport {
  final String id;
  final String reporterId;
  final String reporterUniversityId;
  final String status;
  final String? imageUrl;
  final String? afterImageUrl;
  final String? resolvedByUniversityId;
  final String aiDescription;
  final String aiDepartment;
  final DateTime createdAt;
  final double latitude;
  final double longitude;

  GrievanceReport({
    required this.id,
    required this.reporterId,
    this.reporterUniversityId = '',
    required this.status,
    this.imageUrl,
    this.afterImageUrl,
    this.resolvedByUniversityId,
    required this.aiDescription,
    required this.aiDepartment,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
  });

  factory GrievanceReport.fromJson(Map<String, dynamic> json) {
    // Defensive parsing for metadata as per engineering rules
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final aiDescription =
        metadata['ai_description'] as String? ?? 'Processing...';
    final aiDepartment = metadata['department'] as String? ?? 'UNKNOWN';
    final afterImageUrl = metadata['after_image_url'] as String?;
    final resolvedByUniversityId = metadata['resolved_by_university_id'] as String?;

    return GrievanceReport(
      id: json['id'] as String? ?? '',
      reporterId: json['reporter_id'] as String? ?? '',
      reporterUniversityId: json['reporter_university_id'] as String? ?? '',
      status: json['status'] as String? ?? 'REPORTED',
      imageUrl: json['image_url'] as String?,
      afterImageUrl: afterImageUrl,
      resolvedByUniversityId: resolvedByUniversityId,
      aiDescription: aiDescription,
      aiDepartment: aiDepartment,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reporter_university_id': reporterUniversityId,
      'status': status,
      'image_url': imageUrl,
      'metadata': {
        'ai_description': aiDescription,
        'department': aiDepartment,
        if (afterImageUrl != null) 'after_image_url': afterImageUrl,
        if (resolvedByUniversityId != null) 'resolved_by_university_id': resolvedByUniversityId,
      },
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  GrievanceReport copyWith({
    String? id,
    String? reporterId,
    String? reporterUniversityId,
    String? status,
    String? imageUrl,
    String? afterImageUrl,
    String? resolvedByUniversityId,
    String? aiDescription,
    String? aiDepartment,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) {
    return GrievanceReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterUniversityId: reporterUniversityId ?? this.reporterUniversityId,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      afterImageUrl: afterImageUrl ?? this.afterImageUrl,
      resolvedByUniversityId: resolvedByUniversityId ?? this.resolvedByUniversityId,
      aiDescription: aiDescription ?? this.aiDescription,
      aiDepartment: aiDepartment ?? this.aiDepartment,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
