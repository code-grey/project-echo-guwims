class User {
  final String id;
  final String
      universityId; // Maps to generic username backend field as per project context
  final String role;

  User({
    required this.id,
    required this.universityId,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      universityId:
          json['university_id'] as String? ?? json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'STUDENT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'university_id': universityId,
      'role': role,
    };
  }

  User copyWith({
    String? id,
    String? universityId,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      universityId: universityId ?? this.universityId,
      role: role ?? this.role,
    );
  }
}
