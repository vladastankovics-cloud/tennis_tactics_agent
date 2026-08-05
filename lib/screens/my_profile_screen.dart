import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';
import '../widgets/comparison_slider.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final UserProfileRepository _repository = UserProfileRepository();

  late Map<String, int> _attributes;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileId;

  // Profile fields
  int? _birthYear;
  int? _heightCm;
  double? _weightKg;
  int? _activeSinceYear;
  String? _hands;
  String? _backhandType;
  String? _level;

  // Level options
  static const List<String> _levelOptions = [
    'Developing',
    'Beginner',
    'Intermediate',
    'Advanced',
    'Pro',
  ];

  // Controllers for profile fields
  late TextEditingController _birthYearController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _activeSinceController;

  // Unit preferences
  bool _heightInFeet = false;
  bool _weightInLbs = false;

  // Define attribute groups
  final Map<String, List<String>> _groups = {
    'Thinking': ['Confidence', 'Clutchness', 'Calmness', 'Focus'],
    'Team': ['Sponsors', 'Crowd', 'Partners', 'Coaches', 'Family'],
    'Tactics': [
      'Big server',
      'Serve and volleyer',
      'Net rusher',
      'All-court player',
      'Aggressive baseliner',
      'Counterpuncher',
    ],
    'Technique': [
      'Specialty',
      'Net',
      'Transition',
      'Backhand',
      'Forehand',
      'Return',
      'Serve',
    ],
    'Toughness': [
      'Balance',
      'Coordination',
      'Reach',
      'Power',
      'Endurance',
      'Lean body',
      'Mobility',
      'Agility',
    ],
  };

  @override
  void initState() {
    super.initState();
    _birthYearController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _activeSinceController = TextEditingController();
    _initializeAttributes();
    _loadProfileData();
  }

  @override
  void dispose() {
    _birthYearController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _activeSinceController.dispose();
    super.dispose();
  }

  void _initializeAttributes() {
    _attributes = {
      'Confidence': 50,
      'Clutchness': 50,
      'Calmness': 50,
      'Focus': 50,
      'Sponsors': 50,
      'Crowd': 50,
      'Partners': 50,
      'Coaches': 50,
      'Family': 50,
      'Big server': 50,
      'Serve and volleyer': 50,
      'Net rusher': 50,
      'All-court player': 50,
      'Aggressive baseliner': 50,
      'Counterpuncher': 50,
      'Specialty': 50,
      'Net': 50,
      'Transition': 50,
      'Backhand': 50,
      'Forehand': 50,
      'Return': 50,
      'Serve': 50,
      'Balance': 50,
      'Coordination': 50,
      'Reach': 50,
      'Power': 50,
      'Endurance': 50,
      'Lean body': 50,
      'Mobility': 50,
      'Agility': 50,
    };
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await _repository.getOrCreateUserProfile();

      setState(() {
        _profileId = profile.id;
        // Load profile fields
        _birthYear = profile.birthYear;
        _heightCm = profile.heightCm;
        _weightKg = profile.weightKg;
        _activeSinceYear = profile.activeSinceYear != null ? int.tryParse(profile.activeSinceYear!) : null;
        _hands = profile.hands;
        _backhandType = profile.backhandType;
        _level = profile.level;

        // Update controllers
        _birthYearController.text = _birthYear?.toString() ?? '';
        _heightController.text = _heightCm?.toString() ?? '';
        _weightController.text = _weightKg?.toString() ?? '';
        _activeSinceController.text = _activeSinceYear?.toString() ?? '';

        _attributes = {
          'Confidence': profile.confidence,
          'Clutchness': profile.clutchness,
          'Calmness': profile.calmness,
          'Focus': profile.focus,
          'Sponsors': profile.sponsors,
          'Crowd': profile.crowd,
          'Partners': profile.partners,
          'Coaches': profile.coaches,
          'Family': profile.family,
          'Big server': profile.bigServer,
          'Serve and volleyer': profile.serveAndVolleyer,
          'Net rusher': profile.netRusher,
          'All-court player': profile.allCourtPlayer,
          'Aggressive baseliner': profile.aggressiveBaseliner,
          'Counterpuncher': profile.counterpuncher,
          'Specialty': profile.specialty,
          'Net': profile.net,
          'Transition': profile.transition,
          'Backhand': profile.backhand,
          'Forehand': profile.forehand,
          'Return': profile.returnServe,
          'Serve': profile.serve,
          'Balance': profile.balance,
          'Coordination': profile.coordination,
          'Reach': profile.reach,
          'Power': profile.power,
          'Endurance': profile.endurance,
          'Lean body': profile.leanBody,
          'Mobility': profile.mobility,
          'Agility': profile.agility,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  int _calculateGroupAverage(List<String> attributes) {
    if (attributes.isEmpty) return 50;
    final sum = attributes.fold<int>(0, (sum, attr) => sum + (_attributes[attr] ?? 50));
    return (sum / attributes.length).round();
  }

  // Calculate age from birth year
  int? _calculateAge() {
    if (_birthYear == null) return null;
    final now = DateTime.now();
    return now.year - _birthYear!;
  }

  // Calculate years active from active since year
  int? _calculateYearsActive() {
    if (_activeSinceYear == null) return null;
    final now = DateTime.now();
    return now.year - _activeSinceYear!;
  }

  // Convert height to feet and inches
  String _heightToFeetInches(int cm) {
    final totalInches = cm / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return "$feet'$inches\"";
  }

  // Parse feet/inches input to cm
  int? _parseFeetInchesToCm(String input) {
    final regex = RegExp(r'''(\d+)'(\d+)"?''');
    final match = regex.firstMatch(input.trim());
    if (match != null) {
      final feet = int.parse(match.group(1)!);
      final inches = int.parse(match.group(2)!);
      return ((feet * 12 + inches) * 2.54).round();
    }
    return null;
  }

  // Convert weight to lbs
  double _kgToLbs(double kg) => kg * 2.20462;

  // Convert lbs to kg
  double _lbsToKg(double lbs) => lbs / 2.20462;

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final profile = UserProfile(
        id: _profileId!,
        birthYear: _birthYear,
        heightCm: _heightCm,
        weightKg: _weightKg,
        activeSinceYear: _activeSinceYear?.toString(),
        hands: _hands,
        backhandType: _backhandType,
        level: _level,
        agility: _attributes['Agility']!,
        mobility: _attributes['Mobility']!,
        leanBody: _attributes['Lean body']!,
        endurance: _attributes['Endurance']!,
        power: _attributes['Power']!,
        reach: _attributes['Reach']!,
        coordination: _attributes['Coordination']!,
        balance: _attributes['Balance']!,
        serve: _attributes['Serve']!,
        returnServe: _attributes['Return']!,
        forehand: _attributes['Forehand']!,
        backhand: _attributes['Backhand']!,
        transition: _attributes['Transition']!,
        net: _attributes['Net']!,
        specialty: _attributes['Specialty']!,
        counterpuncher: _attributes['Counterpuncher']!,
        aggressiveBaseliner: _attributes['Aggressive baseliner']!,
        allCourtPlayer: _attributes['All-court player']!,
        netRusher: _attributes['Net rusher']!,
        serveAndVolleyer: _attributes['Serve and volleyer']!,
        bigServer: _attributes['Big server']!,
        family: _attributes['Family']!,
        coaches: _attributes['Coaches']!,
        partners: _attributes['Partners']!,
        crowd: _attributes['Crowd']!,
        sponsors: _attributes['Sponsors']!,
        focus: _attributes['Focus']!,
        calmness: _attributes['Calmness']!,
        clutchness: _attributes['Clutchness']!,
        confidence: _attributes['Confidence']!,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.saveUserProfile(profile);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Auto-save when navigating back
        if (!_isSaving) {
          await _saveProfile();
        }
        return false; // We handle navigation in _saveProfile
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveProfile,
              tooltip: 'Save',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Section
            _buildSectionHeader('PROFILE'),
            const SizedBox(height: 12),
            _buildProfileSection(),
            const SizedBox(height: 24),

            // Evaluation Section
            _buildSectionHeader('EVALUATION'),
            const SizedBox(height: 12),
            ..._buildEvaluationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildProfileSection() {
    final age = _calculateAge();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Age (Birth Year)
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('Birth Year', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _birthYearController,
                          decoration: const InputDecoration(
                            hintText: 'Year',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _birthYear = int.tryParse(value);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (age != null)
                        Text(
                          '$age years old',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Height
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('Height', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _heightController,
                          decoration: InputDecoration(
                            hintText: _heightInFeet ? "5'10\"" : 'cm',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                          onChanged: (value) {
                            setState(() {
                              if (_heightInFeet) {
                                _heightCm = _parseFeetInchesToCm(value);
                              } else {
                                _heightCm = int.tryParse(value);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ToggleButtons(
                        isSelected: [!_heightInFeet, _heightInFeet],
                        onPressed: (index) {
                          setState(() {
                            _heightInFeet = index == 1;
                            if (_heightCm != null) {
                              _heightController.text = _heightInFeet
                                  ? _heightToFeetInches(_heightCm!)
                                  : _heightCm.toString();
                            }
                          });
                        },
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
                        borderRadius: BorderRadius.circular(4),
                        children: const [Text('cm'), Text('ft')],
                      ),
                      const SizedBox(width: 12),
                      if (_heightCm != null)
                        Text(
                          _heightInFeet
                              ? '${_heightCm}cm'
                              : _heightToFeetInches(_heightCm!),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weight
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('Weight', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            hintText: _weightInLbs ? 'lbs' : 'kg',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            setState(() {
                              final parsed = double.tryParse(value);
                              if (parsed != null) {
                                _weightKg = _weightInLbs ? _lbsToKg(parsed) : parsed;
                              } else {
                                _weightKg = null;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ToggleButtons(
                        isSelected: [!_weightInLbs, _weightInLbs],
                        onPressed: (index) {
                          setState(() {
                            _weightInLbs = index == 1;
                            if (_weightKg != null) {
                              _weightController.text = _weightInLbs
                                  ? _kgToLbs(_weightKg!).toStringAsFixed(1)
                                  : _weightKg!.toStringAsFixed(1);
                            }
                          });
                        },
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
                        borderRadius: BorderRadius.circular(4),
                        children: const [Text('kg'), Text('lb')],
                      ),
                      const SizedBox(width: 12),
                      if (_weightKg != null)
                        Text(
                          _weightInLbs
                              ? '${_weightKg!.toStringAsFixed(1)}kg'
                              : '${_kgToLbs(_weightKg!).toStringAsFixed(1)}lbs',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Since (Years Active)
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('Active since', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _activeSinceController,
                          decoration: const InputDecoration(
                            hintText: 'Year',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _activeSinceYear = int.tryParse(value);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_calculateYearsActive() != null)
                        Text(
                          '${_calculateYearsActive()} years',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hands
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('Hands', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _hands,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select...'),
                    items: ['Right', 'Left', 'Both'].map((h) {
                      return DropdownMenuItem(value: h, child: Text(h));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _hands = value;
                        // Clear backhand if Both is selected
                        if (value == 'Both') {
                          _backhandType = null;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),

            // Backhand (only shown if hands is Right or Left)
            if (_hands != null && _hands != 'Both') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text('Backhand', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _backhandType,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select...'),
                      items: ['One-hander', 'Two-hander'].map((b) {
                        return DropdownMenuItem(value: b, child: Text(b));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _backhandType = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],

            // Level
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('Level', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _level,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select...'),
                    items: _levelOptions.map((l) {
                      return DropdownMenuItem(value: l, child: Text(l));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _level = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEvaluationSection() {
    final List<Widget> widgets = [];

    // Color for user profile - use strength blue
    const userColor = Color(0xFF3B82C4); // Court blue (strength color)

    for (var entry in _groups.entries) {
      final groupName = entry.key;
      final groupAttributes = entry.value;
      final average = _calculateGroupAverage(groupAttributes);

      // Group header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: ComparisonGroupHeader(
            label: groupName,
            value: average,
            valueColor: userColor,
          ),
        ),
      );

      // Group attributes
      for (var attribute in groupAttributes) {
        final value = _attributes[attribute]!;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ComparisonSlider(
              label: attribute,
              value: value,
              valueColor: userColor,
              onChanged: (newValue) {
                setState(() {
                  _attributes[attribute] = newValue;
                });
              },
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

