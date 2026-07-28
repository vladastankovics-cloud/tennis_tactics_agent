class PracticeDrill {
  final String id;
  final String tacticShortName; // Links to the tactic/adjustment
  final String title;
  final String description;
  final String? duration; // e.g., "10-15 minutes"
  final String? difficulty; // Developing, Beginner, Intermediate, Advanced, Pro
  final int orderIndex; // Order within the tactic
  final DateTime createdAt;
  final List<Map<String, dynamic>>? movements; // Court diagram movement data
  final List<Map<String, dynamic>>? positions; // Player position markers (P, O, P1, P2, etc.)

  PracticeDrill({
    required this.id,
    required this.tacticShortName,
    required this.title,
    required this.description,
    this.duration,
    this.difficulty,
    this.orderIndex = 0,
    required this.createdAt,
    this.movements,
    this.positions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tactic_short_name': tacticShortName,
      'title': title,
      'description': description,
      'duration': duration,
      'difficulty': difficulty,
      'order_index': orderIndex,
      'created_at': createdAt.millisecondsSinceEpoch,
      'movements': movements,
      'positions': positions,
    };
  }

  factory PracticeDrill.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>>? movements;
    if (map['movements'] != null) {
      movements = (map['movements'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    List<Map<String, dynamic>>? positions;
    if (map['positions'] != null) {
      positions = (map['positions'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return PracticeDrill(
      id: map['id'] as String,
      tacticShortName: map['tactic_short_name'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      duration: map['duration'] as String?,
      difficulty: map['difficulty'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      movements: movements,
      positions: positions,
    );
  }
}
