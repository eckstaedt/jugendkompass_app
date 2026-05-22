class PollVoteModel {
  final String id;
  final String pollId;
  final String optionId;
  final String? userId;
  final DateTime createdAt;

  PollVoteModel({
    required this.id,
    required this.pollId,
    required this.optionId,
    this.userId,
    required this.createdAt,
  });

  factory PollVoteModel.fromJson(Map<String, dynamic> json) {
    return PollVoteModel(
      id: json['id'].toString(),
      pollId: json['poll_id'].toString(),
      optionId: json['option_id'].toString(),
      userId: json['user_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poll_id': pollId,
      'option_id': optionId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PollVoteModel copyWith({
    String? id,
    String? pollId,
    String? optionId,
    String? userId,
    DateTime? createdAt,
  }) {
    return PollVoteModel(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      optionId: optionId ?? this.optionId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
