import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/match.dart';
import '../repositories/match_repository.dart';
import '../repositories/opponent_repository.dart';
import '../utils/date_formatter.dart';
import 'court_edit_screen.dart';
import 'opponent_profile_screen.dart';

class MatchFormScreen extends StatefulWidget {
  final Match? match; // If provided, we're editing; otherwise, creating

  const MatchFormScreen({super.key, this.match});

  @override
  State<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends State<MatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MatchRepository _repository = MatchRepository();
  final OpponentRepository _opponentRepository = OpponentRepository();
  final Uuid _uuid = const Uuid();
  List<String> _savedOpponentNames = [];
  List<String> _savedCourtNames = [];
  Map<String, Map<String, String?>> _savedCourtDetails = {};

  late TextEditingController _opponentNameController;
  late TextEditingController _opponentName2Controller;
  late TextEditingController _partnerNameController;
  late TextEditingController _notesController;
  late TextEditingController _courtNameController;
  // Note: Balls and Crowd are now handled via _adjustments list
  DateTime? _selectedDate;
  int? _userScore;
  int? _opponentScore;
  List<Map<String, int?>> _sets = [{'user': null, 'opponent': null}];
  String? _matchType;
  String? _courtSurface;
  String? _courtSpeed;
  String? _courtCover;
  String? _altitude;
  String? _matchFormat;
  bool _noAds = false;
  bool _tiebreakSet = false;
  final List<Map<String, String?>> _adjustments = [];
  bool _isSaving = false;

  final List<String> _matchFormats = [
    'Full sets (best of 3, 6 games)',
    'Full sets (best of 5, 6 games)',
    'Short sets (best of 3, 4 games)',
    'Short sets (best of 5, 4 games)',
    'Pro set (7-9 games)',
    'Short set (4-6 games)',
    'Tiebreak (7 or 10 points)',
  ];

  final List<String> _matchTypes = [
    'Singles',
    'Doubles',
  ];

  final List<String> _adjustmentTypes = [
    'My',
    "Opponent's",
    'Conditions',
    'Balls',
    'Crowd',
  ];

  final Map<String, List<String>> _adjustmentValues = {
    'My': [
      'Injury',
      'Illness',
      'Fatigue',
      'Rest',
      'Easy loss',
      'Tough loss',
      'Easy win',
      'Tough win',
      'Demotivation',
      'Motivation',
    ],
    "Opponent's": [
      'Injury',
      'Illness',
      'Fatigue',
      'Rest',
      'Easy loss',
      'Tough loss',
      'Easy win',
      'Tough win',
      'Demotivation',
      'Motivation',
    ],
    'Conditions': [
      'Hot-dry',
      'Hot-humid',
      'Cold-dry',
      'Cold-humid',
      'Windy',
      'Rainy',
    ],
    'Crowd': [
      'Respectful',
      'Friendly',
      'Hostile',
      'Divided',
      'Disruptive',
    ],
  };

  @override
  void initState() {
    super.initState();
    final match = widget.match;

    // Initialize controllers immediately (synchronously)
    _opponentNameController = TextEditingController(text: match?.opponentName ?? '');
    _opponentName2Controller = TextEditingController(text: match?.opponentName2 ?? '');
    _partnerNameController = TextEditingController(text: match?.partnerName ?? '');
    _notesController = TextEditingController(text: match?.notes ?? '');
    _courtNameController = TextEditingController(text: match?.courtName ?? '');
    _selectedDate = match?.matchDate;
    _userScore = match?.matchScoreUser;
    _opponentScore = match?.matchScoreOpponent;
    _matchType = match?.matchType;
    _matchFormat = match?.matchFormat;
    _noAds = match?.noAds ?? false;
    _tiebreakSet = match?.tiebreakSet ?? false;
    _courtSurface = match?.courtSurface;
    // Handle legacy "Clay" value
    if (_courtSurface == 'Clay') {
      _courtSurface = 'Red clay';
    }
    _courtSpeed = match?.courtSpeed;
    _courtCover = match?.courtCover;
    _altitude = match?.altitude;

    // Initialize adjustments from existing match data
    if (match?.myAdjustment != null && match!.myAdjustment!.isNotEmpty) {
      _adjustments.add({'type': 'My', 'value': match.myAdjustment});
    }
    if (match?.opponentAdjustment != null && match!.opponentAdjustment!.isNotEmpty) {
      _adjustments.add({'type': "Opponent's", 'value': match.opponentAdjustment});
    }
    // Note: Conditions is now an adjustment, not a court detail
    var conditions = match?.courtConditions;
    // Handle legacy values
    if (conditions == 'High altitude') {
      conditions = null;
    } else if (conditions == 'Mild') {
      conditions = null;
    } else if (conditions == 'Rain') {
      conditions = 'Rainy';
    }
    if (conditions != null && conditions.isNotEmpty) {
      _adjustments.add({'type': 'Conditions', 'value': conditions});
    }
    if (match?.balls != null && match!.balls!.isNotEmpty) {
      _adjustments.add({'type': 'Balls', 'value': match.balls});
    }
    if (match?.crowd != null && match!.crowd!.isNotEmpty) {
      _adjustments.add({'type': 'Crowd', 'value': match.crowd});
    }

    // Parse set scores if editing
    if (match?.setScores != null && match!.setScores!.isNotEmpty) {
      final sets = match.setScores!.split(',');
      _sets = sets.map((setScore) {
        final parts = setScore.split('-');
        if (parts.length == 2) {
          return {
            'user': int.tryParse(parts[0]),
            'opponent': int.tryParse(parts[1]),
          };
        }
        return {'user': null, 'opponent': null};
      }).toList();
    }

    // If creating new match, load previous match data asynchronously
    if (match == null) {
      _loadPreviousMatchData();
    }

    // Load all saved opponent names for autocomplete
    _loadOpponentNames();

    // Load all saved court names for autocomplete
    _loadCourtNames();
  }

  Future<void> _loadPreviousMatchData() async {
    try {
      debugPrint('=== Loading previous match data ===');
      final previousMatch = await _repository.getMostRecentMatch();

      if (previousMatch != null) {
        debugPrint('Found previous match:');
        debugPrint('  Opponent: ${previousMatch.opponentName}');
        debugPrint('  Match Date: ${previousMatch.matchDate != null ? DateFormatter.formatDate(previousMatch.matchDate!) : "No date"}');
        debugPrint('  Match ID: ${previousMatch.id}');
        debugPrint('  Court Surface: ${previousMatch.courtSurface ?? "(empty)"}');
        debugPrint('  Court Speed: ${previousMatch.courtSpeed ?? "(empty)"}');
        debugPrint('  Court Cover: ${previousMatch.courtCover ?? "(empty)"}');
        debugPrint('  Court Conditions: ${previousMatch.courtConditions ?? "(empty)"}');
        debugPrint('  Altitude: ${previousMatch.altitude ?? "(empty)"}');
        debugPrint('  Balls: ${previousMatch.balls ?? "(empty)"}');
        debugPrint('  Crowd: ${previousMatch.crowd ?? "(empty)"}');

        if (mounted) {
          // No longer prefilling any data from previous match
          debugPrint('✓ Previous match found but not prefilling data');
        } else {
          debugPrint('✗ Widget not mounted, skipping state update');
        }
      } else {
        debugPrint('No previous match found (no matches with dates in database)');
      }
      debugPrint('=================================');
    } catch (e) {
      debugPrint('ERROR loading previous match data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _loadOpponentNames() async {
    try {
      // Load from opponent profiles
      final opponents = await _opponentRepository.getAllOpponents();
      final Set<String> names = opponents.map((o) => o.name).toSet();

      // Also load opponent names from existing matches
      final matches = await _repository.getAllMatches();
      for (var match in matches) {
        if (match.opponentName.isNotEmpty) {
          names.add(match.opponentName);
        }
        if (match.opponentName2 != null && match.opponentName2!.isNotEmpty) {
          names.add(match.opponentName2!);
        }
        if (match.partnerName != null && match.partnerName!.isNotEmpty) {
          names.add(match.partnerName!);
        }
      }

      if (mounted) {
        final sortedNames = names.toList()..sort();
        setState(() {
          _savedOpponentNames = sortedNames;
        });
      }
    } catch (e) {
      debugPrint('ERROR loading opponent names: $e');
    }
  }

  Future<void> _loadCourtNames() async {
    try {
      final matches = await _repository.getAllMatches();
      if (mounted) {
        // Extract unique court names and their details (use most recent match for each court)
        final Map<String, Map<String, String?>> courtDetails = {};
        final List<String> courtNames = [];

        // Sort matches by updatedAt descending to get most recently updated first
        final sortedMatches = matches.where((m) => m.courtName != null && m.courtName!.isNotEmpty).toList();
        sortedMatches.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        for (var match in sortedMatches) {
          final courtName = match.courtName!;
          if (!courtDetails.containsKey(courtName)) {
            courtNames.add(courtName);
            courtDetails[courtName] = {
              'surface': match.courtSurface,
              'speed': match.courtSpeed,
              'cover': match.courtCover,
              'altitude': match.altitude,
            };
          }
        }

        courtNames.sort();
        setState(() {
          _savedCourtNames = courtNames;
          _savedCourtDetails = courtDetails;
        });
      }
    } catch (e) {
      debugPrint('ERROR loading court names: $e');
    }
  }

  @override
  void dispose() {
    _opponentNameController.dispose();
    _opponentName2Controller.dispose();
    _partnerNameController.dispose();
    _notesController.dispose();
    _courtNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    final threeMonthsLater = DateTime(now.year, now.month + 3, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: threeMonthsAgo,
      lastDate: threeMonthsLater,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
  }

  /// Returns max sets allowed based on format
  int _getMaxSets() {
    if (_matchFormat == null) return 5; // Default
    if (_matchFormat!.contains('best of 5')) return 5;
    if (_matchFormat!.contains('best of 3')) return 3;
    // Pro set, Short set, Tiebreak - only 1 field
    return 1;
  }

  /// Check if format is tiebreak (points instead of games)
  bool _isTiebreakFormat() {
    return _matchFormat != null && _matchFormat!.contains('Tiebreak');
  }

  /// Check if format is single-score (Pro set, Short set, or Tiebreak)
  bool _isSingleScoreFormat() {
    if (_matchFormat == null) return false;
    return _matchFormat!.contains('Pro set') ||
           _matchFormat == 'Short set (4-6 games)' ||
           _matchFormat!.contains('Tiebreak');
  }

  void _addSet() {
    final maxSets = _getMaxSets();
    if (_sets.length < maxSets) {
      setState(() {
        _sets.add({'user': null, 'opponent': null});
      });
    }
  }

  void _removeSet(int index) {
    if (index > 0 && _sets.length > 1) {
      setState(() {
        _sets.removeAt(index);
      });
    }
  }

  Future<void> _openOpponentProfile() async {
    final opponentName = _opponentNameController.text.trim();
    if (opponentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter opponent name first')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpponentProfileScreen(
          opponentName: opponentName,
        ),
      ),
    );
  }

  Future<void> _openOpponent2Profile() async {
    final opponentName = _opponentName2Controller.text.trim();
    if (opponentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter opponent 2 name first')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpponentProfileScreen(
          opponentName: opponentName,
        ),
      ),
    );
  }

  Future<void> _openPartnerProfile() async {
    final partnerName = _partnerNameController.text.trim();
    if (partnerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter partner name first')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpponentProfileScreen(
          opponentName: partnerName,
        ),
      ),
    );
  }

  Future<void> _openCourtDetails() async {
    final result = await Navigator.push<CourtDetails>(
      context,
      MaterialPageRoute(
        builder: (context) => CourtEditScreen(
          initialDetails: CourtDetails(
            surface: _courtSurface,
            speed: _courtSpeed,
            cover: _courtCover,
            altitude: _altitude,
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _courtSurface = result.surface;
        _courtSpeed = result.speed;
        _courtCover = result.cover;
        _altitude = result.altitude;
      });
    }
  }

  void _addAdjustment() {
    // Find which types are not yet used
    final usedTypes = _adjustments.map((a) => a['type']).toSet();
    final availableTypes = _adjustmentTypes.where((t) => !usedTypes.contains(t)).toList();

    if (availableTypes.isNotEmpty) {
      setState(() {
        _adjustments.add({'type': availableTypes.first, 'value': null});
      });
    }
  }

  void _removeAdjustment(int index) {
    setState(() {
      _adjustments.removeAt(index);
    });
  }

  List<String> _getAvailableAdjustmentTypes(int currentIndex) {
    final currentType = _adjustments[currentIndex]['type'];
    final usedTypes = _adjustments
        .asMap()
        .entries
        .where((e) => e.key != currentIndex)
        .map((e) => e.value['type'])
        .toSet();
    return _adjustmentTypes.where((t) => !usedTypes.contains(t) || t == currentType).toList();
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Calculate total sets won from individual set scores and build set scores string
      int userSetsWon = 0;
      int opponentSetsWon = 0;
      List<String> setScoresList = [];

      for (var set in _sets) {
        final userGames = set['user'];
        final opponentGames = set['opponent'];
        if (userGames != null && opponentGames != null) {
          setScoresList.add('$userGames-$opponentGames');
          if (userGames > opponentGames) {
            userSetsWon++;
          } else if (opponentGames > userGames) {
            opponentSetsWon++;
          }
        }
      }

      final setScores = setScoresList.isNotEmpty ? setScoresList.join(',') : null;

      // Extract adjustments values
      String? myAdjustment;
      String? opponentAdjustment;
      String? conditions;
      String? balls;
      String? crowd;
      for (var adj in _adjustments) {
        if (adj['type'] == 'My' && adj['value'] != null) {
          myAdjustment = adj['value'];
        } else if (adj['type'] == "Opponent's" && adj['value'] != null) {
          opponentAdjustment = adj['value'];
        } else if (adj['type'] == 'Conditions' && adj['value'] != null) {
          conditions = adj['value'];
        } else if (adj['type'] == 'Balls' && adj['value'] != null) {
          balls = adj['value'];
        } else if (adj['type'] == 'Crowd' && adj['value'] != null) {
          crowd = adj['value'];
        }
      }

      final now = DateTime.now();
      final match = Match(
        id: widget.match?.id ?? _uuid.v4(),
        opponentName: _opponentNameController.text.trim(),
        opponentName2: _opponentName2Controller.text.trim().isEmpty
            ? null
            : _opponentName2Controller.text.trim(),
        partnerName: _partnerNameController.text.trim().isEmpty
            ? null
            : _partnerNameController.text.trim(),
        matchDate: _selectedDate,
        matchScoreUser: setScoresList.isNotEmpty ? userSetsWon : null,
        matchScoreOpponent: setScoresList.isNotEmpty ? opponentSetsWon : null,
        setScores: setScores,
        matchType: _matchType,
        matchFormat: _matchFormat,
        noAds: _noAds,
        tiebreakSet: _tiebreakSet,
        courtName: _courtNameController.text.trim().isEmpty
            ? null
            : _courtNameController.text.trim(),
        courtSurface: _courtSurface,
        courtSpeed: _courtSpeed,
        courtCover: _courtCover,
        courtConditions: conditions,
        altitude: _altitude,
        myAdjustment: myAdjustment,
        opponentAdjustment: opponentAdjustment,
        balls: balls,
        crowd: crowd,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.match?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.match == null) {
        await _repository.createMatch(match);
      } else {
        await _repository.updateMatch(match);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving match: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.match != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Match' : 'Add Match'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Match Type
            DropdownButtonFormField<String>(
              initialValue: _matchType,
              decoration: const InputDecoration(
                labelText: 'Match Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people_outline),
              ),
              items: _matchTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _matchType = value;
                  // Clear partner and second opponent when switching to Singles
                  if (value == 'Singles') {
                    _partnerNameController.clear();
                    _opponentName2Controller.clear();
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Match type is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Partner Name (only for Doubles) with autocomplete
            if (_matchType == 'Doubles') ...[
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _partnerNameController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  // Show both saved opponent names and partner names
                  return _savedOpponentNames.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _partnerNameController.text = selection;
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  // Sync the autocomplete controller with our main controller
                  if (fieldTextEditingController.text != _partnerNameController.text) {
                    fieldTextEditingController.text = _partnerNameController.text;
                  }
                  fieldTextEditingController.addListener(() {
                    _partnerNameController.text = fieldTextEditingController.text;
                  });

                  return TextFormField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Partner Name',
                      hintText: 'Enter partner name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.analytics_outlined),
                        onPressed: _openPartnerProfile,
                        tooltip: 'View partner profile',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Opponent Name (required) with autocomplete
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _opponentNameController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _savedOpponentNames.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _opponentNameController.text = selection;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                // Sync the autocomplete controller with our main controller
                if (fieldTextEditingController.text != _opponentNameController.text) {
                  fieldTextEditingController.text = _opponentNameController.text;
                }
                fieldTextEditingController.addListener(() {
                  _opponentNameController.text = fieldTextEditingController.text;
                });

                return TextFormField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Opponent Name *',
                    hintText: 'Enter opponent name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person, color: Colors.black),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.analytics_outlined),
                      onPressed: _openOpponentProfile,
                      tooltip: 'View opponent profile',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Opponent name is required';
                    }
                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Opponent Name 2 (only for Doubles) with autocomplete
            if (_matchType == 'Doubles') ...[
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _opponentName2Controller.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _savedOpponentNames.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _opponentName2Controller.text = selection;
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  // Sync the autocomplete controller with our main controller
                  if (fieldTextEditingController.text != _opponentName2Controller.text) {
                    fieldTextEditingController.text = _opponentName2Controller.text;
                  }
                  fieldTextEditingController.addListener(() {
                    _opponentName2Controller.text = fieldTextEditingController.text;
                  });

                  return TextFormField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Opponent Name 2',
                      hintText: 'Enter second opponent name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person, color: Colors.black),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.analytics_outlined),
                        onPressed: _openOpponent2Profile,
                        tooltip: 'View opponent 2 profile',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Match Date (optional)
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: _selectedDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearDate,
                          tooltip: 'Clear date',
                        )
                      : null,
                ),
                child: Text(
                  _selectedDate != null
                      ? DateFormatter.formatDate(_selectedDate!)
                      : 'Not set',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Court Name with autocomplete
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _courtNameController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _savedCourtNames.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _courtNameController.text = selection;
                // Populate court details from saved data
                if (_savedCourtDetails.containsKey(selection)) {
                  final details = _savedCourtDetails[selection]!;
                  setState(() {
                    _courtSurface = details['surface'];
                    _courtSpeed = details['speed'];
                    _courtCover = details['cover'];
                    _altitude = details['altitude'];
                  });
                }
              },
              fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                // Sync the autocomplete controller with our main controller
                if (fieldTextEditingController.text != _courtNameController.text) {
                  fieldTextEditingController.text = _courtNameController.text;
                }
                fieldTextEditingController.addListener(() {
                  _courtNameController.text = fieldTextEditingController.text;
                });

                return TextFormField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Court Name',
                    hintText: 'Enter court name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _openCourtDetails,
                      tooltip: 'Edit court details',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Calibration Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calibration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_adjustments.length < _adjustmentTypes.length)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addAdjustment,
                    tooltip: 'Add adjustment',
                  ),
              ],
            ),
            if (_adjustments.isNotEmpty) const SizedBox(height: 8),
            ...List.generate(_adjustments.length, (index) {
              final adjustment = _adjustments[index];
              final availableTypes = _getAvailableAdjustmentTypes(index);
              final currentType = adjustment['type'];
              final currentValue = adjustment['value'];
              final isBalls = currentType == 'Balls';
              final isMultiSelect = currentType == 'My' || currentType == "Opponent's";
              var valueOptions = currentType != null ? List<String>.from(_adjustmentValues[currentType] ?? []) : <String>[];

              // Add current value to options if it's not already in the list (for legacy/custom values)
              if (!isBalls && !isMultiSelect && currentValue != null && !valueOptions.contains(currentValue)) {
                valueOptions.insert(0, currentValue);
              }

              // Parse selected values for multi-select
              final selectedValues = isMultiSelect && currentValue != null
                  ? currentValue.split(',').where((v) => v.isNotEmpty).toSet()
                  : <String>{};

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type dropdown
                        SizedBox(
                          width: 120,
                          child: DropdownButtonFormField<String>(
                            initialValue: currentType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: availableTypes.map((type) {
                              return DropdownMenuItem(value: type, child: Text(type));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _adjustments[index]['type'] = value;
                                _adjustments[index]['value'] = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Value input - varies by type
                        if (!isMultiSelect)
                          Expanded(
                            child: isBalls
                                ? TextFormField(
                                    initialValue: currentValue ?? '',
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      hintText: 'Enter ball type',
                                    ),
                                    onChanged: (value) {
                                      _adjustments[index]['value'] = value.isEmpty ? null : value;
                                    },
                                  )
                                : DropdownButtonFormField<String>(
                                    initialValue: currentValue,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Select...', style: TextStyle(fontStyle: FontStyle.italic)),
                                      ),
                                      ...valueOptions.map((val) {
                                        return DropdownMenuItem(value: val, child: Text(val));
                                      }),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _adjustments[index]['value'] = value;
                                      });
                                    },
                                  ),
                          ),
                        if (isMultiSelect) const Spacer(),
                        const SizedBox(width: 8),
                        // Remove button
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => _removeAdjustment(index),
                          tooltip: 'Remove',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    // Multi-select chips for My and Opponent's
                    if (isMultiSelect) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: valueOptions.map((val) {
                          final isSelected = selectedValues.contains(val);
                          return FilterChip(
                            label: Text(val, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                final newSet = Set<String>.from(selectedValues);
                                if (selected) {
                                  newSet.add(val);
                                } else {
                                  newSet.remove(val);
                                }
                                _adjustments[index]['value'] = newSet.isEmpty ? null : newSet.join(',');
                              });
                            },
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Add relevant details to adjustments or anything else.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 24),

            // Format Section
            Text(
              'Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _matchFormat,
              decoration: const InputDecoration(
                labelText: 'Match Format',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Select format...', style: TextStyle(fontStyle: FontStyle.italic)),
                ),
                ..._matchFormats.map((format) {
                  return DropdownMenuItem(value: format, child: Text(format));
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _matchFormat = value;
                  // Clear tiebreakSet if not a sets format
                  if (value != null && !value.contains('sets')) {
                    _tiebreakSet = false;
                  }
                  // Reset sets to 1 when switching to single-score format
                  if (value != null && (value.contains('Pro set') ||
                      value == 'Short set (4-6 games)' ||
                      value.contains('Tiebreak'))) {
                    if (_sets.length > 1) {
                      _sets = [_sets[0]];
                    }
                  }
                  // Trim sets if exceeds max for best of 3
                  if (value != null && value.contains('best of 3') && _sets.length > 3) {
                    _sets = _sets.sublist(0, 3);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            // No ads checkbox - always visible
            CheckboxListTile(
              title: const Text('No ads (sudden death)'),
              value: _noAds,
              onChanged: (value) {
                setState(() {
                  _noAds = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            // Tiebreak set checkbox - only for Full sets and Short sets
            if (_matchFormat != null && _matchFormat!.contains('sets'))
              CheckboxListTile(
                title: const Text('Tiebreak set (at 1:1, 2:2)'),
                value: _tiebreakSet,
                onChanged: (value) {
                  setState(() {
                    _tiebreakSet = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

            const SizedBox(height: 24),

            // Score Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_sets.length < _getMaxSets() && !_isSingleScoreFormat())
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addSet,
                    tooltip: 'Add set',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_sets.length > _getMaxSets() ? _getMaxSets() : _sets.length, (index) {
              final isTiebreak = _isTiebreakFormat();
              final isSingleScore = _isSingleScoreFormat();
              final userLabel = isTiebreak
                  ? 'Your points'
                  : (isSingleScore
                      ? 'Your games'
                      : (index == 0 ? 'Your games' : 'Set ${index + 1} - Your games'));
              final oppLabel = isTiebreak
                  ? 'Opponent points'
                  : (isSingleScore
                      ? 'Opponent games'
                      : (index == 0 ? 'Opponent games' : 'Set ${index + 1} - Opp games'));

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _sets[index]['user']?.toString() ?? '',
                        decoration: InputDecoration(
                          labelText: userLabel,
                          hintText: '0',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _sets[index]['user'] = int.tryParse(value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _sets[index]['opponent']?.toString() ?? '',
                        decoration: InputDecoration(
                          labelText: oppLabel,
                          hintText: '0',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _sets[index]['opponent'] = int.tryParse(value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (index > 0 && !_isSingleScoreFormat())
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => _removeSet(index),
                        tooltip: 'Remove set',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    else
                      const SizedBox(width: 32),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMatch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update Match' : 'Save Match'),
            ),

            const SizedBox(height: 8),

            // Cancel Button
            OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel'),
            ),

            const SizedBox(height: 8),

            // Required fields note
            const Text(
              '* Required fields',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
