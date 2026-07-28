class Message {
  final String id;
  final String conversationId;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isError;

  Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  // Check if message is from user
  bool get isUser => role == 'user';

  // Check if message is from assistant
  bool get isAssistant => role == 'assistant';

  // Serialize to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_error': isError ? 1 : 0,
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

  // Helper to parse boolean from either INTEGER (SQLite) or BOOLEAN (Supabase)
  static bool _parseBool(dynamic value) {
    if (value is bool) {
      // Supabase format: native boolean
      return value;
    } else if (value is int) {
      // SQLite format: 0 = false, 1 = true
      return value != 0;
    }
    return false;
  }

  // Deserialize from Map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      timestamp: _parseTimestamp(map['timestamp']),
      isError: _parseBool(map['is_error']),
    );
  }

  // Create a copy with updated fields
  Message copyWith({
    String? id,
    String? conversationId,
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isError,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }
}
