class ReadingPlanModel {
  final String id;
  final int currentWeek;
  final List<ReadingDay> days;
  final DateTime startDate;
  final DateTime? lastUpdatedAt;

  const ReadingPlanModel({
    required this.id,
    required this.currentWeek,
    required this.days,
    required this.startDate,
    this.lastUpdatedAt,
  });

  factory ReadingPlanModel.fromJson(Map<String, dynamic> json) {
    return ReadingPlanModel(
      id: json['id'] as String,
      currentWeek: json['current_week'] as int? ?? 1,
      days: (json['days'] as List<dynamic>?)
              ?.map((day) => ReadingDay.fromJson(day as Map<String, dynamic>))
              .toList() ??
          _generateDefaultDays(),
      startDate: DateTime.parse(json['start_date'] as String),
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.parse(json['last_updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'current_week': currentWeek,
      'days': days.map((day) => day.toJson()).toList(),
      'start_date': startDate.toIso8601String(),
      'last_updated_at': lastUpdatedAt?.toIso8601String(),
    };
  }

  ReadingPlanModel copyWith({
    String? id,
    int? currentWeek,
    List<ReadingDay>? days,
    DateTime? startDate,
    DateTime? lastUpdatedAt,
  }) {
    return ReadingPlanModel(
      id: id ?? this.id,
      currentWeek: currentWeek ?? this.currentWeek,
      days: days ?? this.days,
      startDate: startDate ?? this.startDate,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  int get completedDaysCount {
    return days.where((day) => day.isCompleted).length;
  }

  static List<ReadingDay> _generateDefaultDays() {
    return List.generate(
      7,
      (index) => ReadingDay(
        dayNumber: index + 1,
        isCompleted: false,
      ),
    );
  }

  @override
  String toString() {
    return 'ReadingPlanModel(id: $id, currentWeek: $currentWeek, completedDays: $completedDaysCount/7)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReadingPlanModel &&
        other.id == id &&
        other.currentWeek == currentWeek &&
        other.startDate == startDate &&
        other.lastUpdatedAt == lastUpdatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        currentWeek.hashCode ^
        startDate.hashCode ^
        lastUpdatedAt.hashCode;
  }
}

class ReadingDay {
  final int dayNumber;
  final bool isCompleted;
  final DateTime? completedAt;

  const ReadingDay({
    required this.dayNumber,
    required this.isCompleted,
    this.completedAt,
  });

  factory ReadingDay.fromJson(Map<String, dynamic> json) {
    return ReadingDay(
      dayNumber: json['day_number'] as int,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_number': dayNumber,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  ReadingDay copyWith({
    int? dayNumber,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return ReadingDay(
      dayNumber: dayNumber ?? this.dayNumber,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'ReadingDay(dayNumber: $dayNumber, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReadingDay &&
        other.dayNumber == dayNumber &&
        other.isCompleted == isCompleted &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return dayNumber.hashCode ^ isCompleted.hashCode ^ completedAt.hashCode;
  }
}
