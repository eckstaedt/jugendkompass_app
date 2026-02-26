class ProfileModel {
  // Actual database fields from Supabase profiles table
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, userId: $userId, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfileModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        createdAt.hashCode;
  }

  // Helper getters for UI compatibility
  // These are stored locally, not in Supabase
  String? get avatarUrl => null; // Managed locally or in storage
  bool get notificationsEnabled => true; // Managed locally via UserPreferencesService
  bool get darkModeEnabled => false; // Managed locally via UserPreferencesService
  DateTime? get updatedAt => null; // Not in schema
}
