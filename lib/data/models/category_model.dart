class CategoryModel {
  // Actual database fields from Supabase
  final String id;
  final String name;

  CategoryModel({
    required this.id,
    required this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Helper getters for UI compatibility
  // These can be hard-coded or determined from the name
  String? get color {
    // Map category names to colors
    switch (name.toLowerCase()) {
      case 'glaube':
        return '#6B4FA0'; // Purple
      case 'deep dive':
        return '#4A90E2'; // Blue
      case 'lifestyle':
        return '#E8A87C'; // Orange
      case 'news':
        return '#4CAF50'; // Green
      default:
        return '#6B4FA0'; // Default purple
    }
  }

  String? get iconUrl => null; // Icons handled in UI
  String? get description => null; // Not stored in DB
  int get sortOrder => 0; // Not stored in DB
}
