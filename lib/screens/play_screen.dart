import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:tennis_tactics_agent/models/match.dart';
import 'package:tennis_tactics_agent/models/opponent.dart';
import 'package:tennis_tactics_agent/models/play_adjustment.dart';
import 'package:tennis_tactics_agent/models/user_profile.dart';
import 'package:tennis_tactics_agent/repositories/opponent_repository.dart';
import 'package:tennis_tactics_agent/repositories/play_adjustment_repository.dart';
import 'package:tennis_tactics_agent/repositories/user_profile_repository.dart';
import 'package:tennis_tactics_agent/services/gemini_service.dart';
import 'package:tennis_tactics_agent/widgets/flip_card.dart';

/// Custom slider thumb shape that draws an arrowhead pointing right
class ArrowheadSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;

  const ArrowheadSliderThumbShape({this.thumbRadius = 10.0});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    // Draw arrowhead pointing right
    final path = Path();
    final size = thumbRadius;

    // Arrow pointing right: left-top, tip-right, left-bottom
    path.moveTo(center.dx - size * 0.6, center.dy - size * 0.8);
    path.lineTo(center.dx + size * 0.8, center.dy);
    path.lineTo(center.dx - size * 0.6, center.dy + size * 0.8);
    path.close();

    canvas.drawPath(path, paint);
  }
}

class PlayScreen extends StatefulWidget {
  final bool embedded;
  final Match? match;

  const PlayScreen({super.key, this.embedded = false, this.match});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  int _situationIndex = 2; // Default: Dogfight
  int _momentumIndex = 2; // Default: middle (Trading holds for Dogfight)

  // AI advice state
  bool _isLoadingAdvice = false;
  List<AdviceItem> _adviceItems = [];
  final Set<int> _flippedCards = {};
  final Map<int, PlayAdjustment> _savedAdjustments = {}; // gridPosition -> full adjustment data

  // Services
  final PlayAdjustmentRepository _adjustmentRepository = PlayAdjustmentRepository();
  final OpponentRepository _opponentRepository = OpponentRepository();
  final UserProfileRepository _userProfileRepository = UserProfileRepository();
  GeminiService? _geminiService;

  // Context data
  Opponent? _linkedOpponent;
  Opponent? _linkedOpponent2;
  Opponent? _linkedPartner;
  UserProfile? _userProfile;
  PlayAdjustment? _activeAdjustment;

  // Long press timer
  Timer? _longPressTimer;
  int? _longPressPosition;

  final List<String> _situations = [
    'Crushed',
    'Down a break',
    'Dogfight',
    'Up a break',
    'Cruising',
  ];

  final Map<String, String> _situationDescriptions = {
    'Crushed':
        'A gap in level, struggling to find any foothold. The match isn\'t over, but something needs to change tactically, physically, or mentally.',
    'Down a break':
        'Behind but alive — one break back levels it up. Demands disciplined hold games and patience on return, waiting for the right moment rather than forcing low-percentage plays.',
    'Dogfight':
        'Neither can pull away — every game is a battle decided by fine margins and clutch points. Who manages energy better and owns the big points late will prevail.',
    'Up a break':
        'Having the lead but the match isn\'t won — priority is to consolidate serve and force the opponent to chase. One more break closes the set/match; losing resets everything.',
    'Cruising':
        'In complete control, holding comfortably, opponent has no reliable answers. Main danger is switching off and letting them back in through complacency.',
  };

  final Map<String, List<String>> _momentumOptions = {
    'Crushed': [
      'Capitulating',
      'Digging in',
      'Finding rhythm late',
      'Forcing a wobble',
      'Staging a comeback',
    ],
    'Down a break': [
      'Spiraling',
      'Chasing',
      'Consolidating',
      'Creeping',
      'Breaking back',
    ],
    'Dogfight': [
      'Opponent pulling away',
      'Momentum swinging',
      'Trading holds',
      'Tiebreak warfare',
      'You pulling away',
    ],
    'Up a break': [
      'Nerves creeping in',
      'Opponent pushing back',
      'Sitting on the lead',
      'Pressing',
      'Extending the lead',
    ],
    'Cruising': [
      'Opponent mounting a run',
      'Switching off',
      'Opponent adjusting',
      'On autopilot',
      'Imposing',
    ],
  };

  final Map<String, Map<String, String>> _momentumDescriptions = {
    'Crushed': {
      'Capitulating':
          'Errors mounting, body language gone, just playing out the match.',
      'Digging in':
          'Fighting for games but no real threat to the scoreline.',
      'Finding rhythm late':
          'Starting to play better but too little too late.',
      'Forcing a wobble':
          'Opponent gets tight, you sneak a win or two but deficit too large.',
      'Staging a comeback':
          'Genuine reversal, crowd involved, opponent feeling it.',
    },
    'Down a break': {
      'Chasing': 'One break down, trying to immediately break back.',
      'Consolidating': 'Holding your own serve first, staying in it.',
      'Creeping': 'Opponent starts missing, you sense the door opening.',
      'Breaking back': 'You level it up, momentum fully shifts.',
      'Spiraling': 'Opponent breaks again, one break becomes two.',
    },
    'Dogfight': {
      'Trading holds': 'Both players locked in, neither blinks.',
      'Momentum swinging': 'Mini-runs either way, match on a knife\'s edge.',
      'Tiebreak warfare':
          'Set decided in breakers, nerves and clutch points decide.',
      'You pulling away':
          'Your consistency or fitness starts to tip the balance.',
      'Opponent pulling away':
          'They start owning big points, you\'re on the back foot.',
    },
    'Up a break': {
      'Pressing': 'Trying to convert the advantage into a break.',
      'Sitting on the lead': 'Playing conservatively, not forcing.',
      'Opponent pushing back': 'Lead feels fragile, pressure building.',
      'Extending the lead':
          'Converting a break, turning slight edge into control.',
      'Nerves creeping in':
          'Serving for the set or match, tightening up.',
    },
    'Cruising': {
      'On autopilot': 'Everything clicking, minimal effort required.',
      'Opponent adjusting': 'They change tactics, you need to adapt.',
      'Switching off': 'Mentally relaxing too early, opponent creeps back.',
      'Imposing': 'Actively accelerating, putting the match to bed.',
      'Opponent mounting a run':
          'Suddenly a dogfight despite the scoreline.',
    },
  };

  String get _currentSituation => _situations[_situationIndex];
  List<String> get _currentMomentumOptions =>
      _momentumOptions[_currentSituation] ?? [];
  String get _currentMomentum =>
      _currentMomentumOptions.isNotEmpty
          ? _currentMomentumOptions[_momentumIndex]
          : '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadSavedAdjustments();
  }

  @override
  void didUpdateWidget(PlayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when match changes
    if (widget.match?.id != oldWidget.match?.id) {
      _initializeServices();
      _loadSavedAdjustments();
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _geminiService = await GeminiService.fromConfig();

    // Load user profile
    _userProfile = await _userProfileRepository.getUserProfile();

    // Load opponent data if match is provided
    if (widget.match != null) {
      _linkedOpponent = await _opponentRepository.getOpponentByName(widget.match!.opponentName);

      // Load partner and opponent 2 for doubles matches
      if (widget.match!.matchType == 'Doubles') {
        if (widget.match!.partnerName != null && widget.match!.partnerName!.isNotEmpty) {
          _linkedPartner = await _opponentRepository.getOpponentByName(widget.match!.partnerName!);
        }
        if (widget.match!.opponentName2 != null && widget.match!.opponentName2!.isNotEmpty) {
          _linkedOpponent2 = await _opponentRepository.getOpponentByName(widget.match!.opponentName2!);
        }
      }

      // Load active (accepted or latest) adjustment
      _activeAdjustment = await _adjustmentRepository.getActiveAdjustment(widget.match!.id);
    }
  }

  Future<void> _loadSavedAdjustments() async {
    if (widget.match == null) return;

    // Load ALL adjustments for the match (not context-specific)
    final adjustments = await _adjustmentRepository.getAdjustmentsForMatch(widget.match!.id);

    setState(() {
      _savedAdjustments.clear();
      for (final adj in adjustments) {
        _savedAdjustments[adj.gridPosition] = adj;
      }
    });
  }

  /// Build system prompt with full match context for AI advice
  String _buildPlaySystemPrompt() {
    final match = widget.match!;
    final situationDesc = _situationDescriptions[_currentSituation] ?? '';
    final momentumDesc = _momentumDescriptions[_currentSituation]?[_currentMomentum] ?? '';
    final buffer = StringBuffer();

    buffer.write('''You are an expert tennis tactics advisor providing real-time match adjustments.

## Current Match Situation

**Situation:** $_currentSituation
$situationDesc

**Momentum:** $_currentMomentum
$momentumDesc

## Match Details
''');

    buffer.write('- Opponent: ${match.opponentName}\n');
    if (match.matchType == 'Doubles') {
      if (match.opponentName2 != null && match.opponentName2!.isNotEmpty) {
        buffer.write('- Opponent 2: ${match.opponentName2}\n');
      }
      if (match.partnerName != null && match.partnerName!.isNotEmpty) {
        buffer.write('- Partner: ${match.partnerName}\n');
      }
    }
    if (match.matchType != null) {
      buffer.write('- Match Type: ${match.matchType}\n');
    }
    if (match.courtSurface != null) {
      buffer.write('- Surface: ${match.courtSurface}');
      if (match.courtSpeed != null) {
        buffer.write(' (${match.courtSpeed})');
      }
      buffer.write('\n');
    }
    if (match.courtCover != null) {
      buffer.write('- Cover: ${match.courtCover}\n');
    }

    // Opponent 1 analytics
    if (_linkedOpponent != null) {
      final opp = _linkedOpponent!;
      buffer.write('\n## Opponent Analysis (${match.opponentName})\n');

      if (opp.level != null) {
        buffer.write('**Level:** ${opp.level}\n');
      }

      if (opp.hands != null || opp.backhandType != null) {
        buffer.write('**Style:** ');
        if (opp.hands != null) buffer.write('${opp.hands}');
        if (opp.backhandType != null) buffer.write(', ${opp.backhandType} backhand');
        buffer.write('\n');
      }

      buffer.write('\n**Physical (0-100):** ');
      buffer.write('Agility ${opp.agility}, Mobility ${opp.mobility}, Endurance ${opp.endurance}, Power ${opp.power}\n');

      buffer.write('**Technical (0-100):** ');
      buffer.write('Serve ${opp.serve}, Return ${opp.returnServe}, FH ${opp.forehand}, BH ${opp.backhand}, Net ${opp.net}\n');

      buffer.write('**Playing Style (0-100):** ');
      buffer.write('Counterpuncher ${opp.counterpuncher}, Aggressive BL ${opp.aggressiveBaseliner}, All-Court ${opp.allCourtPlayer}, S&V ${opp.serveAndVolleyer}\n');

      buffer.write('**Mental (0-100):** ');
      buffer.write('Focus ${opp.focus}, Calmness ${opp.calmness}, Clutch ${opp.clutchness}, Confidence ${opp.confidence}\n');
    }

    // Opponent 2 analytics (doubles)
    if (_linkedOpponent2 != null) {
      final opp = _linkedOpponent2!;
      buffer.write('\n## Opponent 2 Analysis (${match.opponentName2})\n');

      if (opp.level != null) {
        buffer.write('**Level:** ${opp.level}\n');
      }

      buffer.write('**Physical (0-100):** ');
      buffer.write('Agility ${opp.agility}, Mobility ${opp.mobility}, Endurance ${opp.endurance}, Power ${opp.power}\n');

      buffer.write('**Technical (0-100):** ');
      buffer.write('Serve ${opp.serve}, Return ${opp.returnServe}, FH ${opp.forehand}, BH ${opp.backhand}, Net ${opp.net}\n');

      buffer.write('**Mental (0-100):** ');
      buffer.write('Focus ${opp.focus}, Calmness ${opp.calmness}, Clutch ${opp.clutchness}, Confidence ${opp.confidence}\n');
    }

    // User's own profile
    if (_userProfile != null) {
      final me = _userProfile!;
      buffer.write('\n## Your Profile\n');

      if (me.level != null) {
        buffer.write('**Level:** ${me.level}\n');
      }

      if (me.hands != null || me.backhandType != null) {
        buffer.write('**Style:** ');
        if (me.hands != null) buffer.write('${me.hands}');
        if (me.backhandType != null) buffer.write(', ${me.backhandType} backhand');
        buffer.write('\n');
      }

      buffer.write('**Physical (0-100):** ');
      buffer.write('Agility ${me.agility}, Mobility ${me.mobility}, Endurance ${me.endurance}, Power ${me.power}\n');

      buffer.write('**Technical (0-100):** ');
      buffer.write('Serve ${me.serve}, Return ${me.returnServe}, FH ${me.forehand}, BH ${me.backhand}, Net ${me.net}\n');

      buffer.write('**Playing Style (0-100):** ');
      buffer.write('Counterpuncher ${me.counterpuncher}, Aggressive BL ${me.aggressiveBaseliner}, All-Court ${me.allCourtPlayer}, S&V ${me.serveAndVolleyer}\n');

      buffer.write('**Mental (0-100):** ');
      buffer.write('Focus ${me.focus}, Calmness ${me.calmness}, Clutch ${me.clutchness}, Confidence ${me.confidence}\n');
    }

    // Include current tactic if available
    if (_activeAdjustment != null) {
      final adj = _activeAdjustment!;
      String outcomeLabel = '';
      if (adj.isSuccessful) {
        outcomeLabel = ' (Successful)';
      } else if (adj.isUnsuccessful) outcomeLabel = ' (Unsuccessful)';
      buffer.write('\n## Recent Tactic$outcomeLabel\n');
      buffer.write('**${adj.shortName}**: ${adj.description}\n');
      buffer.write('(From: ${adj.situation} / ${adj.momentum})\n');
      buffer.write('\nConsider whether this tactic is still relevant or needs adjustment based on the current situation.\n');
    }

    buffer.write('''

## Instructions

Based on the current situation, momentum, and player profiles, provide exactly 8 tactical changes/adjustments the player should make RIGHT NOW to improve their position in the match.

Consider:
- The specific situation ($_currentSituation) and momentum ($_currentMomentum)
- Exploit opponent weaknesses based on their ratings
- Play to your strengths based on your ratings
- Court surface and conditions

Format your response as ONLY a JSON array with no other text:
[
  {"short_name": "1-3 words", "description": "One brief sentence max 10 words"},
  {"short_name": "1-3 words", "description": "One brief sentence max 10 words"},
  ...8 items total
]

CRITICAL: Keep short_name to 1-3 words and description to ONE short sentence (max 10 words) for small tile display.
''');

    return buffer.toString();
  }

  // Set to true for free testing without API costs
  static const bool _useMockAdvice = false;

  Future<void> _getAdvice() async {
    if (widget.match == null) return;

    setState(() {
      _isLoadingAdvice = true;
      _adviceItems = [];
      _flippedCards.clear();
    });

    try {
      // Use mock data for testing (free, no API cost)
      if (_useMockAdvice) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
        _loadMockAdvice();
        return;
      }

      if (_geminiService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please configure API key in settings')),
        );
        return;
      }

      final systemPrompt = _buildPlaySystemPrompt();

      final response = await _geminiService!.sendMessageWithSystem(
        message: 'Give me 8 tactical adjustments for this situation.',
        systemPrompt: systemPrompt,
        maxTokens: 1024,
        temperature: 0.7,
        addToHistory: false,
      );

      if (response['success'] == true) {
        final message = response['message'] as String;
        _parseAdviceResponse(message);
      } else {
        throw Exception(response['error'] ?? 'Failed to get advice');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAdvice = false;
        });
      }
    }
  }

  void _loadMockAdvice() {
    // Context-aware mock advice based on situation
    final mockAdviceByContext = {
      'Crushed': [
        AdviceItem(shortName: 'Shorten Points', description: 'Hit earlier, move forward when possible.'),
        AdviceItem(shortName: 'High & Deep', description: 'Heavy topspin deep to reset rallies.'),
        AdviceItem(shortName: 'Target Weakness', description: 'Build patterns around their weaker side.'),
        AdviceItem(shortName: 'Serve + 1', description: 'Strong serve plus aggressive first shot.'),
        AdviceItem(shortName: 'Change Pace', description: 'Mix slices, dropshots, and moonballs.'),
        AdviceItem(shortName: 'Body Language', description: 'Walk tall, project confidence always.'),
        AdviceItem(shortName: 'First Serves', description: 'Get more first serves in play.'),
        AdviceItem(shortName: 'Small Goals', description: 'Focus on winning just this point.'),
      ],
      'Down a break': [
        AdviceItem(shortName: 'Hold First', description: 'Consolidate serve before breaking back.'),
        AdviceItem(shortName: 'Stay Patient', description: 'Wait for opportunities, avoid forcing.'),
        AdviceItem(shortName: 'Return Deep', description: 'Deep returns pressure their serve.'),
        AdviceItem(shortName: 'Energy Mgmt', description: 'Save energy, invest on your serve.'),
        AdviceItem(shortName: 'Ad Court Focus', description: 'Have clear plan for ad side.'),
        AdviceItem(shortName: 'Chip & Charge', description: 'Mix approaches to disrupt rhythm.'),
        AdviceItem(shortName: 'Deuce Points', description: 'Stay aggressive on deuce points.'),
        AdviceItem(shortName: 'Rally Length', description: 'Extend rallies to test consistency.'),
      ],
      'Dogfight': [
        AdviceItem(shortName: 'Win First 4', description: 'Start each game strong and focused.'),
        AdviceItem(shortName: 'Clutch Patterns', description: 'Use go-to plays on big points.'),
        AdviceItem(shortName: 'Physical Edge', description: 'Push fitness, show you\'re fresh.'),
        AdviceItem(shortName: 'First Strike', description: 'Attack early in rallies when possible.'),
        AdviceItem(shortName: 'Net Presence', description: 'Come forward, pressure passing shots.'),
        AdviceItem(shortName: 'Breaker Ready', description: 'Have tiebreak strategy prepared.'),
        AdviceItem(shortName: 'Serve Variety', description: 'Vary placement and spin on serve.'),
        AdviceItem(shortName: 'Stay Present', description: 'Focus only on this point now.'),
      ],
      'Up a break': [
        AdviceItem(shortName: 'Consolidate', description: 'Hold serve, don\'t get broken back.'),
        AdviceItem(shortName: 'Play Solid', description: 'Reduce errors, make them earn it.'),
        AdviceItem(shortName: 'No Let Up', description: 'Keep intensity high throughout.'),
        AdviceItem(shortName: 'High First %', description: 'Get first serves in consistently.'),
        AdviceItem(shortName: 'Control Tempo', description: 'Dictate pace, use your lead.'),
        AdviceItem(shortName: 'Safe Targets', description: 'Aim for larger margins safely.'),
        AdviceItem(shortName: 'Close It Out', description: 'Clear game plan when serving out.'),
        AdviceItem(shortName: 'Stay Hungry', description: 'Play like you\'re still behind.'),
      ],
      'Cruising': [
        AdviceItem(shortName: 'Stay Focused', description: 'Maintain concentration, don\'t switch off.'),
        AdviceItem(shortName: 'Experiment', description: 'Try new tactics for future matches.'),
        AdviceItem(shortName: 'Keep Routine', description: 'Maintain between-point rituals.'),
        AdviceItem(shortName: 'Fast Close', description: 'End it quickly and decisively.'),
        AdviceItem(shortName: 'Energy Save', description: 'Win efficiently for later rounds.'),
        AdviceItem(shortName: 'Killer Mode', description: 'Respond immediately if they rally.'),
        AdviceItem(shortName: 'Serve It Out', description: 'Stick to what\'s been working.'),
        AdviceItem(shortName: 'No Mercy', description: 'Finish strong, build momentum.'),
      ],
    };

    final advice = mockAdviceByContext[_currentSituation] ?? mockAdviceByContext['Dogfight']!;

    setState(() {
      _adviceItems = advice;
      _isLoadingAdvice = false;
    });

    _loadSavedAdjustments();
  }

  void _parseAdviceResponse(String message) {
    try {
      // Find JSON array in the response
      final startIndex = message.indexOf('[');
      final endIndex = message.lastIndexOf(']');

      if (startIndex == -1 || endIndex == -1 || endIndex <= startIndex) {
        throw Exception('No JSON array found in response');
      }

      final jsonStr = message.substring(startIndex, endIndex + 1);
      final List<dynamic> parsed = jsonDecode(jsonStr);

      final items = parsed
          .take(8)
          .map((item) => AdviceItem.fromMap(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _adviceItems = items;
      });

      // Load saved adjustments after getting new advice
      _loadSavedAdjustments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse advice: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleFlip(int index) {
    setState(() {
      if (_flippedCards.contains(index)) {
        _flippedCards.remove(index);
      } else {
        _flippedCards.add(index);
      }
    });
  }

  void _startLongPress(int gridPosition) {
    // Directly save the adjustment without showing a dialog
    if (widget.match == null) return;

    final saved = _savedAdjustments[gridPosition];

    if (saved != null) {
      // If already saved, delete it
      _deleteAdjustment(gridPosition, saved.id);
    } else {
      // Need advice to save - check if we have AI advice for this position
      final adviceIndex = gridPosition < 4 ? gridPosition : gridPosition - 1;
      if (adviceIndex < 0 || adviceIndex >= _adviceItems.length) return;

      final advice = _adviceItems[adviceIndex];
      // Save the adjustment
      _saveAdjustment(gridPosition, advice);
    }
  }

  void _cancelLongPress() {
    // No longer needed but kept for compatibility
  }

  void _handleDoubleTap(int gridPosition) {
    // Double-tap to mark as successful/clear successful
    if (widget.match == null) return;

    final saved = _savedAdjustments[gridPosition];
    if (saved == null) return; // Must be saved first

    if (saved.isSuccessful) {
      // Already successful, clear it
      _clearOutcome(gridPosition, saved.id);
    } else {
      // Mark as successful
      _markSuccessful(gridPosition, saved.id);
    }
  }

  void _handleTripleTap(int gridPosition) {
    // Triple-tap to mark as unsuccessful/clear unsuccessful
    if (widget.match == null) return;

    final saved = _savedAdjustments[gridPosition];
    if (saved == null) return; // Must be saved first

    if (saved.isUnsuccessful) {
      // Already unsuccessful, clear it
      _clearOutcome(gridPosition, saved.id);
    } else {
      // Mark as unsuccessful
      _markUnsuccessful(gridPosition, saved.id);
    }
  }

  void _cycleStatus(int gridPosition) {
    // Cycle through: pending (?) → successful (✓) → unsuccessful (✗) → pending
    if (widget.match == null) return;

    final saved = _savedAdjustments[gridPosition];
    if (saved == null) return;

    if (saved.isSuccessful) {
      // successful → unsuccessful
      _markUnsuccessful(gridPosition, saved.id);
    } else if (saved.isUnsuccessful) {
      // unsuccessful → pending
      _clearOutcome(gridPosition, saved.id);
    } else {
      // pending → successful
      _markSuccessful(gridPosition, saved.id);
    }
  }

  Future<void> _saveAdjustment(int gridPosition, AdviceItem advice) async {
    final adjustment = PlayAdjustment(
      id: const Uuid().v4(),
      matchId: widget.match!.id,
      shortName: advice.shortName,
      description: advice.description,
      situation: _currentSituation,
      momentum: _currentMomentum,
      gridPosition: gridPosition,
      createdAt: DateTime.now(),
    );

    await _adjustmentRepository.createAdjustment(adjustment);

    setState(() {
      _savedAdjustments[gridPosition] = adjustment;
    });
  }

  Future<void> _markSuccessful(int gridPosition, String adjustmentId) async {
    await _adjustmentRepository.markSuccessful(adjustmentId);
    setState(() {
      final current = _savedAdjustments[gridPosition];
      if (current != null) {
        _savedAdjustments[gridPosition] = current.copyWith(outcome: 'successful');
      }
    });
  }

  Future<void> _markUnsuccessful(int gridPosition, String adjustmentId) async {
    await _adjustmentRepository.markUnsuccessful(adjustmentId);
    setState(() {
      final current = _savedAdjustments[gridPosition];
      if (current != null) {
        _savedAdjustments[gridPosition] = current.copyWith(outcome: 'unsuccessful');
      }
    });
  }

  Future<void> _clearOutcome(int gridPosition, String adjustmentId) async {
    await _adjustmentRepository.clearOutcome(adjustmentId);
    setState(() {
      final current = _savedAdjustments[gridPosition];
      if (current != null) {
        // Create new instance with null outcome
        _savedAdjustments[gridPosition] = PlayAdjustment(
          id: current.id,
          matchId: current.matchId,
          shortName: current.shortName,
          description: current.description,
          situation: current.situation,
          momentum: current.momentum,
          gridPosition: current.gridPosition,
          createdAt: current.createdAt,
          outcome: null,
        );
      }
    });
  }

  Future<void> _deleteAdjustment(int gridPosition, String adjustmentId) async {
    await _adjustmentRepository.deleteAdjustment(adjustmentId);
    setState(() {
      _savedAdjustments.remove(gridPosition);
    });
  }

  void _onSituationChanged(int newIndex) {
    setState(() {
      _situationIndex = newIndex;
      _momentumIndex = 2; // Default to middle position
      _adviceItems = [];
      _flippedCards.clear();
      // Don't clear _savedAdjustments - they persist across context changes
    });
  }

  void _onMomentumChanged(int newIndex) {
    setState(() {
      _momentumIndex = newIndex;
      _adviceItems = [];
      _flippedCards.clear();
      // Don't clear _savedAdjustments - they persist across context changes
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        children: [
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Menu',
            ),
            title: Text(widget.match != null
                ? 'Play vs ${widget.match!.opponentName}'
                : 'Play'),
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }

    // Standalone mode
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.match != null
            ? 'Play vs ${widget.match!.opponentName}'
            : 'Play'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.match == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No match selected',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long-press a match from Plan to start',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Situation Section
          _buildSectionHeader('Situation'),
          const SizedBox(height: 4),
          _buildSituationSlider(),
          const SizedBox(height: 4),
          _buildDescription(_situationDescriptions[_currentSituation] ?? ''),

          const SizedBox(height: 12),

          // Momentum Section
          _buildSectionHeader('Momentum'),
          const SizedBox(height: 4),
          _buildMomentumSlider(),
          const SizedBox(height: 4),
          _buildDescription(
            _momentumDescriptions[_currentSituation]?[_currentMomentum] ?? '',
          ),

          const SizedBox(height: 12),

          // Adjustments Section
          _buildSectionHeader('Adjustments'),
          const SizedBox(height: 6),
          Expanded(child: _buildAdjustmentsGrid()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSituationSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getSituationColor(_situationIndex),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: _getSituationColor(_situationIndex),
            overlayColor: _getSituationColor(_situationIndex).withOpacity(0.2),
            trackHeight: 6,
            thumbShape: const ArrowheadSliderThumbShape(thumbRadius: 10),
          ),
          child: Slider(
            value: _situationIndex.toDouble(),
            min: 0,
            max: 4,
            divisions: 4,
            onChanged: (value) {
              _onSituationChanged(value.round());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _situations.asMap().entries.map((entry) {
              final isSelected = entry.key == _situationIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    _onSituationChanged(entry.key);
                  },
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? _getSituationColor(entry.key)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMomentumSlider() {
    final options = _currentMomentumOptions;
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getMomentumColor(_momentumIndex),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: _getMomentumColor(_momentumIndex),
            overlayColor: _getMomentumColor(_momentumIndex).withOpacity(0.2),
            trackHeight: 6,
            thumbShape: const ArrowheadSliderThumbShape(thumbRadius: 10),
          ),
          child: Slider(
            value: _momentumIndex.toDouble(),
            min: 0,
            max: 4,
            divisions: 4,
            onChanged: (value) {
              _onMomentumChanged(value.round());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: options.asMap().entries.map((entry) {
              final isSelected = entry.key == _momentumIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    _onMomentumChanged(entry.key);
                  },
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? _getMomentumColor(entry.key)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[800],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildAdjustmentsGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        // Center card (index 4) is the "Get Advice" button
        if (index == 4) {
          return _buildGetAdviceButton();
        }

        // Check if there's a saved adjustment at this position
        final hasSaved = _savedAdjustments.containsKey(index);

        // Get advice index (accounting for center button)
        final adviceIndex = index < 4 ? index : index - 1;
        final hasAdvice = adviceIndex < _adviceItems.length;

        // Show card if either saved or has AI advice
        if (hasSaved || hasAdvice) {
          return _buildAdviceCard(index, adviceIndex);
        }

        return _buildEmptyCard();
      },
    );
  }

  Widget _buildGetAdviceButton() {
    return GestureDetector(
      onTap: _isLoadingAdvice ? null : _getAdvice,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _isLoadingAdvice
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get AI Advice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          color: Colors.grey[400],
          size: 24,
        ),
      ),
    );
  }

  Widget _buildAdviceCard(int gridPosition, int adviceIndex) {
    final isFlipped = _flippedCards.contains(gridPosition);
    final saved = _savedAdjustments[gridPosition];
    final isSaved = saved != null;

    // Use saved adjustment content if available, otherwise use AI advice
    String shortName;
    String description;
    if (isSaved) {
      shortName = saved.shortName;
      description = saved.description;
    } else if (adviceIndex >= 0 && adviceIndex < _adviceItems.length) {
      final advice = _adviceItems[adviceIndex];
      shortName = advice.shortName;
      description = advice.description;
    } else {
      // Fallback (shouldn't happen, but safety check)
      shortName = '';
      description = '';
    }

    final isSuccessful = saved?.isSuccessful ?? false;
    final isUnsuccessful = saved?.isUnsuccessful ?? false;

    // Different colors for saved vs successful vs unsuccessful
    Color? backgroundColor;
    Color? borderColor;
    if (isSuccessful) {
      backgroundColor = Colors.green[50];
      borderColor = Colors.green[600];
    } else if (isUnsuccessful) {
      backgroundColor = Colors.red[50];
      borderColor = Colors.red[600];
    } else if (isSaved) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      borderColor = Theme.of(context).colorScheme.primary;
    }

    final isPending = isSaved && !isSuccessful && !isUnsuccessful;

    return FlipCard(
      isFlipped: isFlipped,
      isHighlighted: isSaved,
      borderColor: borderColor,
      onTap: () => _toggleFlip(gridPosition),
      onDoubleTap: () => _handleDoubleTap(gridPosition),
      onTripleTap: () => _handleTripleTap(gridPosition),
      onLongPress: () => _startLongPress(gridPosition),
      onLongPressEnd: _cancelLongPress,
      front: FlipCardContent(
        text: shortName,
        isBack: false,
        backgroundColor: backgroundColor,
        showSuccessfulBadge: isSuccessful,
        showUnsuccessfulBadge: isUnsuccessful,
        showPendingBadge: isPending,
        onStatusTap: isSaved ? () => _cycleStatus(gridPosition) : null,
      ),
      back: FlipCardContent(
        text: description,
        isBack: true,
        backgroundColor: backgroundColor,
        showSuccessfulBadge: isSuccessful,
        showUnsuccessfulBadge: isUnsuccessful,
        showPendingBadge: isPending,
        onStatusTap: isSaved ? () => _cycleStatus(gridPosition) : null,
      ),
    );
  }

  Color _getProgressColor(int index) {
    switch (index) {
      case 0: // Worst
        return Colors.red[600]!;
      case 1: // Bad
        return Colors.orange[600]!;
      case 2: // Neutral
        return Colors.amber[600]!;
      case 3: // Good
        return Colors.lime[600]!;
      case 4: // Best
        return Colors.green[600]!;
      default:
        return Colors.grey;
    }
  }

  Color _getSituationColor(int index) => _getProgressColor(index);
  Color _getMomentumColor(int index) => _getProgressColor(index);
}
