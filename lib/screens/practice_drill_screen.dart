import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/practice_drill.dart';
import '../models/user_profile.dart';
import '../repositories/practice_drill_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../services/gemini_service.dart';
import '../widgets/tactic_bubble.dart';
import '../widgets/tennis_court_diagram.dart';

class PracticeDrillScreen extends StatefulWidget {
  final TacticBubbleData tactic;

  const PracticeDrillScreen({
    super.key,
    required this.tactic,
  });

  @override
  State<PracticeDrillScreen> createState() => _PracticeDrillScreenState();
}

class _PracticeDrillScreenState extends State<PracticeDrillScreen> {
  final PracticeDrillRepository _drillRepository = PracticeDrillRepository();
  final UserProfileRepository _userProfileRepository = UserProfileRepository();

  List<PracticeDrill> _drills = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isGeneratingMore = false;
  String? _error;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load user profile for level
      _userProfile = await _userProfileRepository.getUserProfile();

      // Check if drills exist
      final drills = await _drillRepository.getDrillsForTactic(widget.tactic.shortName);

      if (drills.isEmpty) {
        // Generate drills via AI
        await _generateDrills();
      } else {
        if (!mounted) return;
        setState(() {
          _drills = drills;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateDrills() async {
    if (!mounted) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      debugPrint('Starting drill generation for tactic: ${widget.tactic.shortName}');
      final geminiService = await GeminiService.fromConfig();
      if (geminiService == null) {
        debugPrint('Gemini service not configured');
        throw Exception('AI service not configured. Please set up your API key in Settings.');
      }

      final level = _userProfile?.level ?? 'Intermediate';
      final systemPrompt = _buildDrillSystemPrompt(level);

      debugPrint('Sending request to Gemini API...');
      final response = await geminiService.sendMessageWithSystem(
        message: 'Generate 3-5 practice drills for this tactic.',
        systemPrompt: systemPrompt,
        maxTokens: 1024,
        temperature: 0.7,
        addToHistory: false,
      );

      if (response['success'] == true) {
        final message = response['message'] as String;
        debugPrint('Gemini response received, parsing drills...');
        final drills = _parseDrillsResponse(message);

        if (drills.isEmpty) {
          debugPrint('Warning: No drills parsed from response');
          debugPrint('Response: $message');
        }

        // Save to database
        await _drillRepository.saveDrills(widget.tactic.shortName, drills);
        debugPrint('Saved ${drills.length} drills to database');

        if (!mounted) return;
        setState(() {
          _drills = drills;
          _isLoading = false;
          _isGenerating = false;
        });
      } else {
        debugPrint('Gemini API error: ${response['error']}');
        throw Exception(response['error'] ?? 'Failed to generate drills');
      }
    } catch (e) {
      debugPrint('Drill generation failed: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isGenerating = false;
      });
    }
  }

  String _buildDrillSystemPrompt(String level) {
    return '''You are an expert tennis coach creating practice drills with visual court diagrams.

## Player Level
$level

## Tactic to Practice
**${widget.tactic.shortName}**: ${widget.tactic.description}

## Instructions

Create 3-5 practice drills that help a $level level player improve at "${widget.tactic.shortName}".

Each drill should:
- Be appropriate for $level skill level
- Be specific and actionable
- Include clear setup and execution steps
- Have a reasonable duration (5-20 minutes each)

Format your response as ONLY a JSON array with no other text:
[
  {
    "title": "Drill name (2-4 words)",
    "description": "Clear step-by-step instructions for the drill. Include setup, execution, and what to focus on. 2-4 sentences.",
    "duration": "X-Y minutes",
    "difficulty": "$level",
    "positions": [
      {"x": 0.5, "y": 0.82, "label": "P"},
      {"x": 0.5, "y": 0.18, "label": "O"}
    ],
    "movements": [
      {"from": {"x": 0.5, "y": 0.82}, "to": {"x": 0.25, "y": 0.7}, "type": "player"},
      {"from": {"x": 0.5, "y": 0.18}, "to": {"x": 0.25, "y": 0.7}, "type": "opponent"},
      {"from": {"x": 0.5, "y": 0.82}, "to": {"x": 0.7, "y": 0.25}, "type": "ball", "shot": "FHCC"}
    ]
  }
]

## Court Layout (coordinates 0.0 to 1.0)
The diagram shows full court with green surround area:
- Court boundaries: x=0.12 to x=0.88 (left to right), y=0.12 to y=0.88 (opponent to player baseline)
- Net: y=0.5
- Player baseline: y=0.88, Opponent baseline: y=0.12
- Surround area (green): 0.0-0.12 and 0.88-1.0 on all sides

Key positions for RALLYING:
- Player at baseline center: x=0.5, y=0.82
- Opponent at baseline center: x=0.5, y=0.18
- Deuce court: x=0.25-0.5, Ad court: x=0.5-0.75
- Net approach: y=0.55-0.6 (player side), y=0.4-0.45 (opponent side)

Key positions for SERVING (player serves):
- Server deuce court: x=0.45, y=0.88 (right of center mark)
- Server ad court: x=0.55, y=0.88 (left of center mark)
- Returner vs deuce serve: x=0.30, y=0.15 (diagonal, ready for wide/body/T)
- Returner vs ad serve: x=0.70, y=0.15 (diagonal, ready for wide/body/T)

Key positions for RETURNING (opponent serves):
- Opponent server deuce: x=0.45, y=0.12
- Opponent server ad: x=0.55, y=0.12
- Player returner deuce: x=0.30, y=0.85 (behind baseline, diagonal)
- Player returner ad: x=0.70, y=0.85 (behind baseline, diagonal)

## Positions
Mark starting positions with labels:
- Singles: "P" (player, white circle), "O" (opponent, black circle)
- Doubles: "P1", "P2" (player team), "O1", "O2" (opponent team)

## Movements (depict the drill accurately!)
Movement types:
- "player" = white solid arrow (player movement to the ball)
- "opponent" = black solid arrow (opponent movement to the ball)
- "ball" = yellow dashed arrow (ball trajectory, include "shot" label)

IMPORTANT movement rules:
1. After EVERY ball shot, show the receiver moving to intercept it
2. Pattern: ball → receiver moves to ball → receiver hits ball → hitter moves to that ball → repeat
3. Example sequence for a rally:
   - Ball from P to deuce side → O moves to deuce side
   - Ball from O cross-court → P moves to ad side
   - Ball from P down-the-line → O moves to cover
4. Both player AND opponent must move realistically to each incoming ball

Shot abbreviations for "shot" field:
- FH = Forehand, BH = Backhand
- TS = Topspin, SL = Slice, FL = Flat
- CC = Cross-court, DL = Down-the-line, IO = Inside-out
- Examples: "FHTS" (forehand topspin), "BHCC" (backhand cross-court), "FHDL" (forehand down-the-line), "SV" (serve), "VOL" (volley), "DROP" (drop shot), "LOB" (lob)

Include 4-8 movements showing realistic rally sequence with both players moving to each ball.
''';
  }

  List<PracticeDrill> _parseDrillsResponse(String response) {
    final drills = <PracticeDrill>[];
    final uuid = const Uuid();
    final now = DateTime.now();

    try {
      // Find JSON array in response
      final startIndex = response.indexOf('[');
      final endIndex = response.lastIndexOf(']');

      if (startIndex == -1 || endIndex == -1) {
        throw Exception('No JSON array found in response');
      }

      final jsonStr = response.substring(startIndex, endIndex + 1);
      final List<dynamic> parsed = json.decode(jsonStr);

      for (var i = 0; i < parsed.length; i++) {
        final item = parsed[i] as Map<String, dynamic>;
        List<Map<String, dynamic>>? movements;
        if (item['movements'] != null) {
          movements = (item['movements'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        List<Map<String, dynamic>>? positions;
        if (item['positions'] != null) {
          positions = (item['positions'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        drills.add(PracticeDrill(
          id: uuid.v4(),
          tacticShortName: widget.tactic.shortName,
          title: item['title'] as String? ?? 'Drill ${i + 1}',
          description: item['description'] as String? ?? '',
          duration: item['duration'] as String?,
          difficulty: item['difficulty'] as String?,
          orderIndex: i,
          createdAt: now,
          movements: movements,
          positions: positions,
        ));
      }
    } catch (e) {
      debugPrint('Error parsing drills: $e');
      debugPrint('Response: $response');
    }

    return drills;
  }

  Future<void> _regenerateDrills() async {
    // Delete existing and regenerate
    await _drillRepository.deleteDrillsForTactic(widget.tactic.shortName);
    if (!mounted) return;
    setState(() {
      _drills = [];
      _isLoading = true;
    });
    await _generateDrills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tactic.shortName),
        actions: [
          if (!_isLoading && !_isGenerating)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _regenerateDrills,
              tooltip: 'Regenerate drills',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isGenerating ? 'Generating practice drills...' : 'Loading...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_isGenerating) ...[
              const SizedBox(height: 8),
              Text(
                'Based on your ${_userProfile?.level ?? "Intermediate"} level',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_drills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_tennis, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No drills available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateDrills,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Drills'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tactic description card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tactic',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.tactic.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (_userProfile?.level != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(_userProfile!.level!),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Drills header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Practice Drills',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_drills.length} drills',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Drill cards
        ..._drills.asMap().entries.map((entry) {
          final index = entry.key;
          final drill = entry.value;
          return _buildDrillCard(drill, index + 1);
        }),

        // Suggest more button
        const SizedBox(height: 8),
        _buildSuggestMoreButton(),
      ],
    );
  }

  Widget _buildSuggestMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _isGeneratingMore ? null : _generateMoreDrills,
        icon: _isGeneratingMore
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(_isGeneratingMore ? 'Generating...' : 'Suggest more drills'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Future<void> _generateMoreDrills() async {
    if (!mounted) return;
    setState(() {
      _isGeneratingMore = true;
    });

    try {
      final geminiService = await GeminiService.fromConfig();
      if (geminiService == null) {
        throw Exception('AI service not configured. Please set up your API key in Settings.');
      }

      final level = _userProfile?.level ?? 'Intermediate';
      final existingTitles = _drills.map((d) => d.title).join(', ');
      final systemPrompt = _buildMoreDrillsSystemPrompt(level, existingTitles);

      final response = await geminiService.sendMessageWithSystem(
        message: 'Generate 2-3 more practice drills for this tactic.',
        systemPrompt: systemPrompt,
        maxTokens: 1024,
        temperature: 0.7,
        addToHistory: false,
      );

      if (response['success'] == true) {
        final message = response['message'] as String;
        final newDrills = _parseMoreDrillsResponse(message);

        // Add to existing drills in database (don't delete existing)
        await _drillRepository.addDrills(widget.tactic.shortName, newDrills);

        if (!mounted) return;
        setState(() {
          _drills.addAll(newDrills);
          _isGeneratingMore = false;
        });
      } else {
        throw Exception(response['error'] ?? 'Failed to generate drills');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeneratingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _buildMoreDrillsSystemPrompt(String level, String existingTitles) {
    return '''You are an expert tennis coach creating practice drills with visual court diagrams.

## Player Level
$level

## Tactic to Practice
**${widget.tactic.shortName}**: ${widget.tactic.description}

## Existing Drills (do NOT repeat these)
$existingTitles

## Instructions

Create 2-3 NEW practice drills that help a $level level player improve at "${widget.tactic.shortName}".
These must be DIFFERENT from the existing drills listed above.

Each drill should:
- Be appropriate for $level skill level
- Be specific and actionable
- Include clear setup and execution steps
- Have a reasonable duration (5-20 minutes each)

Format your response as ONLY a JSON array with no other text:
[
  {
    "title": "Drill name (2-4 words)",
    "description": "Clear step-by-step instructions for the drill. Include setup, execution, and what to focus on. 2-4 sentences.",
    "duration": "X-Y minutes",
    "difficulty": "$level",
    "positions": [
      {"x": 0.5, "y": 0.82, "label": "P"},
      {"x": 0.5, "y": 0.18, "label": "O"}
    ],
    "movements": [
      {"from": {"x": 0.5, "y": 0.82}, "to": {"x": 0.25, "y": 0.7}, "type": "player"},
      {"from": {"x": 0.5, "y": 0.18}, "to": {"x": 0.25, "y": 0.7}, "type": "opponent"},
      {"from": {"x": 0.5, "y": 0.82}, "to": {"x": 0.7, "y": 0.25}, "type": "ball", "shot": "FHCC"}
    ]
  }
]

## Court Layout (coordinates 0.0 to 1.0)
The diagram shows full court with green surround area:
- Court boundaries: x=0.12 to x=0.88 (left to right), y=0.12 to y=0.88 (opponent to player baseline)
- Net: y=0.5
- Player baseline: y=0.88, Opponent baseline: y=0.12
- Surround area (green): 0.0-0.12 and 0.88-1.0 on all sides

Key positions for RALLYING:
- Player at baseline center: x=0.5, y=0.82
- Opponent at baseline center: x=0.5, y=0.18
- Deuce court: x=0.25-0.5, Ad court: x=0.5-0.75
- Net approach: y=0.55-0.6 (player side), y=0.4-0.45 (opponent side)

Key positions for SERVING (player serves):
- Server deuce court: x=0.45, y=0.88 (right of center mark)
- Server ad court: x=0.55, y=0.88 (left of center mark)
- Returner vs deuce serve: x=0.30, y=0.15 (diagonal, ready for wide/body/T)
- Returner vs ad serve: x=0.70, y=0.15 (diagonal, ready for wide/body/T)

Key positions for RETURNING (opponent serves):
- Opponent server deuce: x=0.45, y=0.12
- Opponent server ad: x=0.55, y=0.12
- Player returner deuce: x=0.30, y=0.85 (behind baseline, diagonal)
- Player returner ad: x=0.70, y=0.85 (behind baseline, diagonal)

## Positions
Mark starting positions with labels:
- Singles: "P" (player, white circle), "O" (opponent, black circle)
- Doubles: "P1", "P2" (player team), "O1", "O2" (opponent team)

## Movements (depict the drill accurately!)
Movement types:
- "player" = white solid arrow (player movement to the ball)
- "opponent" = black solid arrow (opponent movement to the ball)
- "ball" = yellow dashed arrow (ball trajectory, include "shot" label)

IMPORTANT movement rules:
1. After EVERY ball shot, show the receiver moving to intercept it
2. Pattern: ball → receiver moves to ball → receiver hits ball → hitter moves to that ball → repeat
3. Example sequence for a rally:
   - Ball from P to deuce side → O moves to deuce side
   - Ball from O cross-court → P moves to ad side
   - Ball from P down-the-line → O moves to cover
4. Both player AND opponent must move realistically to each incoming ball

Shot abbreviations for "shot" field:
- FH = Forehand, BH = Backhand
- TS = Topspin, SL = Slice, FL = Flat
- CC = Cross-court, DL = Down-the-line, IO = Inside-out
- Examples: "FHTS" (forehand topspin), "BHCC" (backhand cross-court), "FHDL" (forehand down-the-line), "SV" (serve), "VOL" (volley), "DROP" (drop shot), "LOB" (lob)

Include 4-8 movements showing realistic rally sequence with both players moving to each ball.
''';
  }

  List<PracticeDrill> _parseMoreDrillsResponse(String response) {
    final drills = <PracticeDrill>[];
    final uuid = const Uuid();
    final now = DateTime.now();
    final startIndex = _drills.length;

    try {
      final jsonStartIndex = response.indexOf('[');
      final jsonEndIndex = response.lastIndexOf(']');

      if (jsonStartIndex == -1 || jsonEndIndex == -1) {
        throw Exception('No JSON array found in response');
      }

      final jsonStr = response.substring(jsonStartIndex, jsonEndIndex + 1);
      final List<dynamic> parsed = json.decode(jsonStr);

      for (var i = 0; i < parsed.length; i++) {
        final item = parsed[i] as Map<String, dynamic>;
        List<Map<String, dynamic>>? movements;
        if (item['movements'] != null) {
          movements = (item['movements'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        List<Map<String, dynamic>>? positions;
        if (item['positions'] != null) {
          positions = (item['positions'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        drills.add(PracticeDrill(
          id: uuid.v4(),
          tacticShortName: widget.tactic.shortName,
          title: item['title'] as String? ?? 'Drill ${startIndex + i + 1}',
          description: item['description'] as String? ?? '',
          duration: item['duration'] as String?,
          difficulty: item['difficulty'] as String?,
          orderIndex: startIndex + i,
          createdAt: now,
          movements: movements,
          positions: positions,
        ));
      }
    } catch (e) {
      debugPrint('Error parsing more drills: $e');
      debugPrint('Response: $response');
    }

    return drills;
  }

  Widget _buildDrillCard(PracticeDrill drill, int number) {
    // Convert movements to CourtMovement objects
    final movements = drill.movements
        ?.map((m) => CourtMovement.fromMap(m))
        .toList() ?? [];

    // Convert positions to CourtPosition objects
    final positions = drill.positions
        ?.map((p) => CourtPosition.fromMap(p))
        .toList() ?? [];

    // Use green for weakness drills, blue for strength drills
    final numberColor = widget.tactic.isStrength
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF6B8F55); // Green for weaknesses (same as weakness bubble)

    // Show diagram only if we have ball movements (showing actual shot patterns)
    final hasBallMovements = movements.any((m) => m.type == 'ball');
    final hasDiagram = hasBallMovements;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: numberColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (drill.duration != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              drill.duration!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Court diagram with positions and movements
            if (hasDiagram) ...[
              const SizedBox(height: 16),
              TennisCourtDiagram(
                movements: movements,
                positions: positions,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              drill.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
