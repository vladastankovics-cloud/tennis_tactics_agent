import 'package:flutter/material.dart';
import '../models/match.dart';

class PlayBottomSheet extends StatefulWidget {
  final Match match;

  const PlayBottomSheet({super.key, required this.match});

  @override
  State<PlayBottomSheet> createState() => _PlayBottomSheetState();
}

class _PlayBottomSheetState extends State<PlayBottomSheet> {
  int _situationIndex = 2; // Default: Dogfight
  int _momentumIndex = 0;

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
        'Behind but very much alive — one break back levels it completely. Demands disciplined hold games and patience on return, waiting for the right moment rather than forcing low-percentage plays.',
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
      'Chasing',
      'Consolidating',
      'Creeping',
      'Breaking back',
      'Spiraling',
    ],
    'Dogfight': [
      'Trading holds',
      'Momentum swinging',
      'Tiebreak warfare',
      'You pulling away',
      'Opponent pulling away',
    ],
    'Up a break': [
      'Pressing',
      'Sitting on the lead',
      'Opponent pushing back',
      'Extending the lead',
      'Nerves creeping in',
    ],
    'Cruising': [
      'On autopilot',
      'Opponent adjusting',
      'Switching off',
      'Imposing',
      'Opponent mounting a run',
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
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.sports_tennis, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Play',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'vs ${widget.match.opponentName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Situation Section
                    _buildSectionHeader('Situation'),
                    const SizedBox(height: 12),
                    _buildSituationSlider(),
                    const SizedBox(height: 8),
                    _buildDescription(_situationDescriptions[_currentSituation] ?? ''),

                    const SizedBox(height: 24),

                    // Momentum Section
                    _buildSectionHeader('Momentum'),
                    const SizedBox(height: 12),
                    _buildMomentumSlider(),
                    const SizedBox(height: 8),
                    _buildDescription(
                      _momentumDescriptions[_currentSituation]?[_currentMomentum] ?? '',
                    ),

                    const SizedBox(height: 24),

                    // Adjustments Section
                    _buildSectionHeader('Adjustments'),
                    const SizedBox(height: 12),
                    _buildAdjustmentsGrid(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
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
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: _situationIndex.toDouble(),
            min: 0,
            max: 4,
            divisions: 4,
            onChanged: (value) {
              setState(() {
                _situationIndex = value.round();
                _momentumIndex = 0; // Reset momentum when situation changes
              });
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
                    setState(() {
                      _situationIndex = entry.key;
                      _momentumIndex = 0;
                    });
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
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: _momentumIndex.toDouble(),
            min: 0,
            max: 4,
            divisions: 4,
            onChanged: (value) {
              setState(() {
                _momentumIndex = value.round();
              });
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
                    setState(() {
                      _momentumIndex = entry.key;
                    });
                  },
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        description,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[800],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildAdjustmentsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Icon(
              Icons.add,
              color: Colors.grey[400],
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Color _getSituationColor(int index) {
    switch (index) {
      case 0: // Crushed
        return Colors.red[700]!;
      case 1: // Down a break
        return Colors.orange[600]!;
      case 2: // Dogfight
        return Colors.amber[600]!;
      case 3: // Up a break
        return Colors.lightGreen[600]!;
      case 4: // Cruising
        return Colors.green[600]!;
      default:
        return Colors.grey;
    }
  }
}
