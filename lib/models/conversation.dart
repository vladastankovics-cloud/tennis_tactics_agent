class Conversation {
  final String id;
  final String? matchId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    this.matchId,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get display title (use title or generate from date)
  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    return 'Conversation ${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Check if conversation is linked to a match
  bool get isLinked => matchId != null;

  // Serialize to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'match_id': matchId,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Helper to parse timestamp from either BIGINT (SQLite) or ISO string (Supabase)
  static DateTime _parseTimestamp(dynamic value) {
    if (value is int) {
      // SQLite format: milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      // Supabase format: ISO 8601 string
      return DateTime.parse(value);
    }
    throw ArgumentError('Invalid timestamp format: $value');
  }

  // Deserialize from Map
  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      matchId: map['match_id'] as String?,
      title: map['title'] as String?,
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
    );
  }

  // Create a copy with updated fields
  Conversation copyWith({
    String? id,
    String? matchId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
