class ProfileModel {
  // Actual database fields from Supabase profiles table
  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, userId: $userId, name: $name, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfileModel &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.avatarUrl == avatarUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        name.hashCode ^
        avatarUrl.hashCode ^
        createdAt.hashCode;
  }

  // Helper getters for UI compatibility
  bool get notificationsEnabled => true; // Managed locally via UserPreferencesService
  bool get darkModeEnabled => false; // Managed locally via UserPreferencesService
  DateTime? get updatedAt => null; // Not in schema
}
