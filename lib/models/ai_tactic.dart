/// Represents an AI-generated tactical suggestion extracted from conversation
class AiTactic {
  final String id;
  final String conversationId;
  final String matchId;
  final String shortName;
  final String description;
  final String? outcome; // null = pending (?), 'successful' (✓), 'unsuccessful' (✗)
  final DateTime createdAt;

  AiTactic({
    required this.id,
    required this.conversationId,
    required this.matchId,
    required this.shortName,
    required this.description,
    this.outcome,
    required this.createdAt,
  });

  bool get isSuccessful => outcome == 'successful';
  bool get isUnsuccessful => outcome == 'unsuccessful';
  bool get isPending => outcome == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'match_id': matchId,
      'short_name': shortName,
      'description': description,
      'outcome': outcome,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('Invalid timestamp format: $value');
  }

  factory AiTactic.fromMap(Map<String, dynamic> map) {
    return AiTactic(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      matchId: map['match_id'] as String,
      shortName: map['short_name'] as String,
      description: map['description'] as String,
      outcome: map['outcome'] as String?,
      createdAt: _parseTimestamp(map['created_at']),
    );
  }

  AiTactic copyWith({
    String? id,
    String? conversationId,
    String? matchId,
    String? shortName,
    String? description,
    String? outcome,
    DateTime? createdAt,
  }) {
    return AiTactic(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      matchId: matchId ?? this.matchId,
      shortName: shortName ?? this.shortName,
      description: description ?? this.description,
      outcome: outcome,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
