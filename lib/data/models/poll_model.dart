class PollOptionModel {
  final String id;
  final String pollId;
  final String optionText;
  final int votes;
  final int sortOrder;
  final DateTime createdAt;

  PollOptionModel({
    required this.id,
    required this.pollId,
    required this.optionText,
    required this.votes,
    required this.sortOrder,
    required this.createdAt,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'].toString(),
      pollId: json['poll_id'].toString(),
      optionText: json['option_text'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poll_id': pollId,
      'option_text': optionText,
      'votes': votes,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PollOptionModel copyWith({
    String? id,
    String? pollId,
    String? optionText,
    int? votes,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return PollOptionModel(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      optionText: optionText ?? this.optionText,
      votes: votes ?? this.votes,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get percentage of total votes for this option
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return (votes / totalVotes) * 100;
  }
}

class PollModel {
  final String id;
  final String question;
  final String? contentId;
  final String? createdBy;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final List<PollOptionModel> options;

  PollModel({
    required this.id,
    required this.question,
    this.contentId,
    this.createdBy,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    this.options = const [],
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    // Parse options if they're included in the response
    List<PollOptionModel> options = [];
    if (json['poll_options'] != null) {
      final optionsData = json['poll_options'];
      if (optionsData is List) {
        options = optionsData
            .map((opt) => PollOptionModel.fromJson(opt as Map<String, dynamic>))
            .toList();
      }
    }

    return PollModel(
      id: json['id'].toString(),
      question: json['question'] as String? ?? '',
      contentId: json['content_id']?.toString(),
      createdBy: json['created_by']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      options: options,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'content_id': contentId,
      'created_by': createdBy,
      'is_active': isActive,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  PollModel copyWith({
    String? id,
    String? question,
    String? contentId,
    String? createdBy,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
    List<PollOptionModel>? options,
  }) {
    return PollModel(
      id: id ?? this.id,
      question: question ?? this.question,
      contentId: contentId ?? this.contentId,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      options: options ?? this.options,
    );
  }

  /// Total votes across all options
  int get totalVotes => options.fold(0, (sum, option) => sum + option.votes);

  /// Check if poll has expired
  bool get hasExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if poll is currently active and not expired
  bool get isActiveNow => isActive && !hasExpired;
}
