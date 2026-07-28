class Match {
  final String id;
  final String opponentName;
  final String? opponentName2;
  final String? partnerName;
  final DateTime? matchDate;
  final String? matchResult;
  final int? matchScoreUser;
  final int? matchScoreOpponent;
  final String? setScores; // Format: "6-4,7-5,6-3" (user-opponent games per set)
  final String? matchType;
  final String? matchFormat;
  final bool noAds;
  final bool tiebreakSet;
  final String? courtName;
  final String? courtSurface;
  final String? courtSpeed;
  final String? courtCover;
  final String? courtConditions;
  final String? altitude;
  final String? myAdjustment;
  final String? opponentAdjustment;
  final String? balls;
  final String? crowd;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Match({
    required this.id,
    required this.opponentName,
    this.opponentName2,
    this.partnerName,
    this.matchDate,
    this.matchResult,
    this.matchScoreUser,
    this.matchScoreOpponent,
    this.setScores,
    this.matchType,
    this.matchFormat,
    this.noAds = false,
    this.tiebreakSet = false,
    this.courtName,
    this.courtSurface,
    this.courtSpeed,
    this.courtCover,
    this.courtConditions,
    this.altitude,
    this.myAdjustment,
    this.opponentAdjustment,
    this.balls,
    this.crowd,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Check if user won the match
  bool get isWin {
    if (matchScoreUser != null && matchScoreOpponent != null) {
      return matchScoreUser! > matchScoreOpponent!;
    }
    return false;
  }

  // Get formatted score string
  String get scoreDisplay {
    if (matchScoreUser != null && matchScoreOpponent != null) {
      return '$matchScoreUser-$matchScoreOpponent';
    }
    if (matchResult != null && matchResult!.isNotEmpty) {
      return matchResult!;
    }
    return 'No score';
  }

  // Serialize to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opponent_name': opponentName,
      'opponent_name_2': opponentName2,
      'partner_name': partnerName,
      'match_date': matchDate?.millisecondsSinceEpoch,
      'match_result': matchResult,
      'match_score_user': matchScoreUser,
      'match_score_opponent': matchScoreOpponent,
      'set_scores': setScores,
      'match_type': matchType,
      'match_format': matchFormat,
      'no_ads': noAds ? 1 : 0,
      'tiebreak_set': tiebreakSet ? 1 : 0,
      'court_name': courtName,
      'court_surface': courtSurface,
      'court_speed': courtSpeed,
      'court_cover': courtCover,
      'court_conditions': courtConditions,
      'altitude': altitude,
      'my_adjustment': myAdjustment,
      'opponent_adjustment': opponentAdjustment,
      'balls': balls,
      'crowd': crowd,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Helper to parse timestamp from either BIGINT (SQLite) or ISO string (Supabase)
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      // SQLite format: milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      // Supabase format: ISO 8601 string
      return DateTime.parse(value);
    }
    return null;
  }

  // Deserialize from Map
  factory Match.fromMap(Map<String, dynamic> map) {
    return Match(
      id: map['id'] as String,
      opponentName: map['opponent_name'] as String,
      opponentName2: map['opponent_name_2'] as String?,
      partnerName: map['partner_name'] as String?,
      matchDate: _parseTimestamp(map['match_date']),
      matchResult: map['match_result'] as String?,
      matchScoreUser: map['match_score_user'] as int?,
      matchScoreOpponent: map['match_score_opponent'] as int?,
      setScores: map['set_scores'] as String?,
      matchType: map['match_type'] as String?,
      matchFormat: map['match_format'] as String?,
      noAds: map['no_ads'] == 1 || map['no_ads'] == true,
      tiebreakSet: map['tiebreak_set'] == 1 || map['tiebreak_set'] == true,
      courtName: map['court_name'] as String?,
      courtSurface: map['court_surface'] as String?,
      courtSpeed: map['court_speed'] as String?,
      courtCover: map['court_cover'] as String?,
      courtConditions: map['court_conditions'] as String?,
      altitude: map['altitude'] as String?,
      myAdjustment: map['my_adjustment'] as String?,
      opponentAdjustment: map['opponent_adjustment'] as String?,
      balls: map['balls'] as String?,
      crowd: map['crowd'] as String?,
      notes: map['notes'] as String?,
      createdAt: _parseTimestamp(map['created_at'])!,
      updatedAt: _parseTimestamp(map['updated_at'])!,
    );
  }

  // Create a copy with updated fields
  Match copyWith({
    String? id,
    String? opponentName,
    String? opponentName2,
    String? partnerName,
    DateTime? matchDate,
    String? matchResult,
    int? matchScoreUser,
    int? matchScoreOpponent,
    String? setScores,
    String? matchType,
    String? matchFormat,
    bool? noAds,
    bool? tiebreakSet,
    String? courtName,
    String? courtSurface,
    String? courtSpeed,
    String? courtCover,
    String? courtConditions,
    String? altitude,
    String? myAdjustment,
    String? opponentAdjustment,
    String? balls,
    String? crowd,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      opponentName: opponentName ?? this.opponentName,
      opponentName2: opponentName2 ?? this.opponentName2,
      partnerName: partnerName ?? this.partnerName,
      matchDate: matchDate ?? this.matchDate,
      matchResult: matchResult ?? this.matchResult,
      matchScoreUser: matchScoreUser ?? this.matchScoreUser,
      matchScoreOpponent: matchScoreOpponent ?? this.matchScoreOpponent,
      setScores: setScores ?? this.setScores,
      matchType: matchType ?? this.matchType,
      matchFormat: matchFormat ?? this.matchFormat,
      noAds: noAds ?? this.noAds,
      tiebreakSet: tiebreakSet ?? this.tiebreakSet,
      courtName: courtName ?? this.courtName,
      courtSurface: courtSurface ?? this.courtSurface,
      courtSpeed: courtSpeed ?? this.courtSpeed,
      courtCover: courtCover ?? this.courtCover,
      courtConditions: courtConditions ?? this.courtConditions,
      altitude: altitude ?? this.altitude,
      myAdjustment: myAdjustment ?? this.myAdjustment,
      opponentAdjustment: opponentAdjustment ?? this.opponentAdjustment,
      balls: balls ?? this.balls,
      crowd: crowd ?? this.crowd,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
