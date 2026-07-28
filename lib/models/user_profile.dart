class UserProfile {
  final String id;

  // Profile information
  final int? birthYear;
  final int? heightCm;
  final double? weightKg;
  final String? activeSinceYear;
  final String? hands; // Right, Left, Both
  final String? backhandType; // One-hander, Two-hander (only for Right/Left hands)
  final String? level; // Developing, Beginner, Intermediate, Advanced, Pro

  // Physical attributes (0-100)
  final int agility;
  final int mobility;
  final int leanBody;
  final int endurance;
  final int power;
  final int reach;
  final int coordination;
  final int balance;

  // Technical skills (0-100)
  final int serve;
  final int returnServe;
  final int forehand;
  final int backhand;
  final int transition;
  final int net;
  final int specialty;

  // Playing styles (0-100)
  final int counterpuncher;
  final int aggressiveBaseliner;
  final int allCourtPlayer;
  final int netRusher;
  final int serveAndVolleyer;
  final int bigServer;

  // Support system (0-100)
  final int family;
  final int coaches;
  final int partners;
  final int crowd;
  final int sponsors;

  // Mental attributes (0-100)
  final int focus;
  final int calmness;
  final int clutchness;
  final int confidence;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.birthYear,
    this.heightCm,
    this.weightKg,
    this.activeSinceYear,
    this.hands,
    this.backhandType,
    this.level,
    this.agility = 50,
    this.mobility = 50,
    this.leanBody = 50,
    this.endurance = 50,
    this.power = 50,
    this.reach = 50,
    this.coordination = 50,
    this.balance = 50,
    this.serve = 50,
    this.returnServe = 50,
    this.forehand = 50,
    this.backhand = 50,
    this.transition = 50,
    this.net = 50,
    this.specialty = 50,
    this.counterpuncher = 50,
    this.aggressiveBaseliner = 50,
    this.allCourtPlayer = 50,
    this.netRusher = 50,
    this.serveAndVolleyer = 50,
    this.bigServer = 50,
    this.family = 50,
    this.coaches = 50,
    this.partners = 50,
    this.crowd = 50,
    this.sponsors = 50,
    this.focus = 50,
    this.calmness = 50,
    this.clutchness = 50,
    this.confidence = 50,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'birth_year': birthYear,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'active_since_year': activeSinceYear,
      'hands': hands,
      'backhand_type': backhandType,
      'level': level,
      'agility': agility,
      'mobility': mobility,
      'lean_body': leanBody,
      'endurance': endurance,
      'power': power,
      'reach': reach,
      'coordination': coordination,
      'balance': balance,
      'serve': serve,
      'return_serve': returnServe,
      'forehand': forehand,
      'backhand': backhand,
      'transition': transition,
      'net': net,
      'specialty': specialty,
      'counterpuncher': counterpuncher,
      'aggressive_baseliner': aggressiveBaseliner,
      'all_court_player': allCourtPlayer,
      'net_rusher': netRusher,
      'serve_and_volleyer': serveAndVolleyer,
      'big_server': bigServer,
      'family': family,
      'coaches': coaches,
      'partners': partners,
      'crowd': crowd,
      'sponsors': sponsors,
      'focus': focus,
      'calmness': calmness,
      'clutchness': clutchness,
      'confidence': confidence,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
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

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      birthYear: map['birth_year'] as int?,
      heightCm: map['height_cm'] as int?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      activeSinceYear: map['active_since_year'] as String?,
      hands: map['hands'] as String?,
      backhandType: map['backhand_type'] as String?,
      level: map['level'] as String?,
      agility: map['agility'] as int? ?? 50,
      mobility: map['mobility'] as int? ?? 50,
      leanBody: map['lean_body'] as int? ?? 50,
      endurance: map['endurance'] as int? ?? 50,
      power: map['power'] as int? ?? 50,
      reach: map['reach'] as int? ?? 50,
      coordination: map['coordination'] as int? ?? 50,
      balance: map['balance'] as int? ?? 50,
      serve: map['serve'] as int? ?? 50,
      returnServe: map['return_serve'] as int? ?? 50,
      forehand: map['forehand'] as int? ?? 50,
      backhand: map['backhand'] as int? ?? 50,
      transition: map['transition'] as int? ?? 50,
      net: map['net'] as int? ?? 50,
      specialty: map['specialty'] as int? ?? 50,
      counterpuncher: map['counterpuncher'] as int? ?? 50,
      aggressiveBaseliner: map['aggressive_baseliner'] as int? ?? 50,
      allCourtPlayer: map['all_court_player'] as int? ?? 50,
      netRusher: map['net_rusher'] as int? ?? 50,
      serveAndVolleyer: map['serve_and_volleyer'] as int? ?? 50,
      bigServer: map['big_server'] as int? ?? 50,
      family: map['family'] as int? ?? 50,
      coaches: map['coaches'] as int? ?? 50,
      partners: map['partners'] as int? ?? 50,
      crowd: map['crowd'] as int? ?? 50,
      sponsors: map['sponsors'] as int? ?? 50,
      focus: map['focus'] as int? ?? 50,
      calmness: map['calmness'] as int? ?? 50,
      clutchness: map['clutchness'] as int? ?? 50,
      confidence: map['confidence'] as int? ?? 50,
      createdAt: _parseTimestamp(map['created_at']),
      updatedAt: _parseTimestamp(map['updated_at']),
    );
  }

  UserProfile copyWith({
    String? id,
    int? birthYear,
    int? heightCm,
    double? weightKg,
    String? activeSinceYear,
    String? hands,
    String? backhandType,
    String? level,
    int? agility,
    int? mobility,
    int? leanBody,
    int? endurance,
    int? power,
    int? reach,
    int? coordination,
    int? balance,
    int? serve,
    int? returnServe,
    int? forehand,
    int? backhand,
    int? transition,
    int? net,
    int? specialty,
    int? counterpuncher,
    int? aggressiveBaseliner,
    int? allCourtPlayer,
    int? netRusher,
    int? serveAndVolleyer,
    int? bigServer,
    int? family,
    int? coaches,
    int? partners,
    int? crowd,
    int? sponsors,
    int? focus,
    int? calmness,
    int? clutchness,
    int? confidence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      birthYear: birthYear ?? this.birthYear,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activeSinceYear: activeSinceYear ?? this.activeSinceYear,
      hands: hands ?? this.hands,
      backhandType: backhandType ?? this.backhandType,
      level: level ?? this.level,
      agility: agility ?? this.agility,
      mobility: mobility ?? this.mobility,
      leanBody: leanBody ?? this.leanBody,
      endurance: endurance ?? this.endurance,
      power: power ?? this.power,
      reach: reach ?? this.reach,
      coordination: coordination ?? this.coordination,
      balance: balance ?? this.balance,
      serve: serve ?? this.serve,
      returnServe: returnServe ?? this.returnServe,
      forehand: forehand ?? this.forehand,
      backhand: backhand ?? this.backhand,
      transition: transition ?? this.transition,
      net: net ?? this.net,
      specialty: specialty ?? this.specialty,
      counterpuncher: counterpuncher ?? this.counterpuncher,
      aggressiveBaseliner: aggressiveBaseliner ?? this.aggressiveBaseliner,
      allCourtPlayer: allCourtPlayer ?? this.allCourtPlayer,
      netRusher: netRusher ?? this.netRusher,
      serveAndVolleyer: serveAndVolleyer ?? this.serveAndVolleyer,
      bigServer: bigServer ?? this.bigServer,
      family: family ?? this.family,
      coaches: coaches ?? this.coaches,
      partners: partners ?? this.partners,
      crowd: crowd ?? this.crowd,
      sponsors: sponsors ?? this.sponsors,
      focus: focus ?? this.focus,
      calmness: calmness ?? this.calmness,
      clutchness: clutchness ?? this.clutchness,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
