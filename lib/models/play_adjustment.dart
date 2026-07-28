/// Represents a tactical advice item from AI response
class AdviceItem {
  final String shortName;
  final String description;

  AdviceItem({
    required this.shortName,
    required this.description,
  });

  factory AdviceItem.fromMap(Map<String, dynamic> map) {
    return AdviceItem(
      shortName: map['short_name'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'short_name': shortName,
      'description': description,
    };
  }
}

/// Represents a saved play adjustment/tactical advice
class PlayAdjustment {
  final String id;
  final String matchId;
  final String shortName;
  final String description;
  final String situation;
  final String momentum;
  final int gridPosition;
  final DateTime createdAt;
  final String? outcome; // null = no outcome, 'successful', 'unsuccessful'

  PlayAdjustment({
    required this.id,
    required this.matchId,
    required this.shortName,
    required this.description,
    required this.situation,
    required this.momentum,
    required this.gridPosition,
    required this.createdAt,
    this.outcome,
  });

  bool get isSuccessful => outcome == 'successful';
  bool get isUnsuccessful => outcome == 'unsuccessful';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'match_id': matchId,
      'short_name': shortName,
      'description': description,
      'situation': situation,
      'momentum': momentum,
      'grid_position': gridPosition,
      'created_at': createdAt.millisecondsSinceEpoch,
      'outcome': outcome,
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

  factory PlayAdjustment.fromMap(Map<String, dynamic> map) {
    return PlayAdjustment(
      id: map['id'] as String,
      matchId: map['match_id'] as String,
      shortName: map['short_name'] as String,
      description: map['description'] as String,
      situation: map['situation'] as String,
      momentum: map['momentum'] as String,
      gridPosition: map['grid_position'] as int,
      createdAt: _parseTimestamp(map['created_at']),
      outcome: map['outcome'] as String?,
    );
  }

  PlayAdjustment copyWith({
    String? id,
    String? matchId,
    String? shortName,
    String? description,
    String? situation,
    String? momentum,
    int? gridPosition,
    DateTime? createdAt,
    String? outcome,
  }) {
    return PlayAdjustment(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      shortName: shortName ?? this.shortName,
      description: description ?? this.description,
      situation: situation ?? this.situation,
      momentum: momentum ?? this.momentum,
      gridPosition: gridPosition ?? this.gridPosition,
      createdAt: createdAt ?? this.createdAt,
      outcome: outcome ?? this.outcome,
    );
  }
}
