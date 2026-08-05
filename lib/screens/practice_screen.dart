import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../repositories/ai_tactic_repository.dart';
import '../repositories/play_adjustment_repository.dart';
import '../repositories/practice_hidden_repository.dart';
import '../widgets/tactic_bubble.dart';
import 'practice_drill_screen.dart';

class PracticeScreen extends StatefulWidget {
  final bool embedded;

  const PracticeScreen({super.key, this.embedded = false});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final AiTacticRepository _tacticRepository = AiTacticRepository();
  final PlayAdjustmentRepository _adjustmentRepository = PlayAdjustmentRepository();
  final PracticeHiddenRepository _hiddenRepository = PracticeHiddenRepository();

  List<TacticBubbleData> _allBubbles = [];
  Map<String, int> _hiddenItems = {};
  bool _isLoading = true;
  bool _showHidden = false; // Toggle state for showing hidden bubbles
  Timer? _snackBarTimer; // Track snackbar auto-hide timer

  @override
  void initState() {
    super.initState();
    _loadTactics();
  }

  Future<void> _loadTactics() async {
    setState(() => _isLoading = true);
    try {
      _hiddenItems = await _hiddenRepository.getHiddenItems();
      debugPrint('🙈 Hidden items: ${_hiddenItems.keys.join(', ')}');

      // Load AI tactics
      final successfulTactics = await _tacticRepository.getSuccessfulTacticsAggregated();
      final unsuccessfulTactics = await _tacticRepository.getUnsuccessfulTacticsAggregated();

      // Load play adjustments
      final successfulAdjustments = await _adjustmentRepository.getSuccessfulAdjustmentsAggregated();
      final unsuccessfulAdjustments = await _adjustmentRepository.getUnsuccessfulAdjustmentsAggregated();

      debugPrint('🎯 Successful tactics: ${successfulTactics.length}');
      debugPrint('🎯 Unsuccessful tactics: ${unsuccessfulTactics.length}');
      debugPrint('🔧 Successful adjustments: ${successfulAdjustments.length}');
      debugPrint('🔧 Unsuccessful adjustments: ${unsuccessfulAdjustments.length}');

      // Normalize tactic name for merging similar items
      String normalizeKey(String name) {
        var normalized = name.toLowerCase();
        // Expand common abbreviations
        normalized = normalized.replaceAll(RegExp(r'\bbh\b'), 'backhand');
        normalized = normalized.replaceAll(RegExp(r'\bfh\b'), 'forehand');
        // Remove filler words
        normalized = normalized.replaceAll(RegExp(r'\b(my|the|a|an)\b'), '');
        // Remove extra spaces and trim
        normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
        return normalized;
      }

      // Track strength/weakness counts separately for merging
      final strengthCounts = <String, int>{};
      final weaknessCounts = <String, int>{};
      final tacticData = <String, Map<String, dynamic>>{};

      void addToMap(Map<String, dynamic> m, bool isStrength) {
        final shortName = m['short_name'] as String;
        final normalizedKey = normalizeKey(shortName);
        final count = m['count'] as int;

        // Track counts by type
        if (isStrength) {
          strengthCounts[normalizedKey] = (strengthCounts[normalizedKey] ?? 0) + count;
        } else {
          weaknessCounts[normalizedKey] = (weaknessCounts[normalizedKey] ?? 0) + count;
        }

        // Keep the longest name and description
        if (!tacticData.containsKey(normalizedKey) ||
            shortName.length > (tacticData[normalizedKey]!['short_name'] as String).length) {
          tacticData[normalizedKey] = Map<String, dynamic>.from(m);
        }
      }

      // Build final map after collecting all data
      Map<String, TacticBubbleData> buildFinalMap() {
        final allMap = <String, TacticBubbleData>{};

        for (final normalizedKey in tacticData.keys) {
          final m = tacticData[normalizedKey]!;
          final shortName = m['short_name'] as String;
          final strengthCount = strengthCounts[normalizedKey] ?? 0;
          final weaknessCount = weaknessCounts[normalizedKey] ?? 0;
          final totalCount = strengthCount + weaknessCount;
          final isStrength = strengthCount >= weaknessCount;
          final latestAt = m['latest_at'] as int?;

          final isHidden = _hiddenItems.containsKey(shortName) ||
                           _hiddenItems.keys.any((k) => normalizeKey(k) == normalizedKey);
          final hiddenAt = _hiddenItems[shortName] ??
                           _hiddenItems.entries
                               .where((e) => normalizeKey(e.key) == normalizedKey)
                               .map((e) => e.value)
                               .fold<int?>(null, (a, b) => a == null ? b : (b > a ? b : a));
          final shouldBeHidden = isHidden && (latestAt == null || (hiddenAt != null && latestAt <= hiddenAt));

          allMap[normalizedKey] = TacticBubbleData(
            shortName: shortName,
            description: m['description'] as String,
            count: totalCount,
            latestAt: latestAt,
            isStrength: isStrength,
            isHidden: shouldBeHidden,
          );
        }

        return allMap;
      }

      // Add successful items (strengths - blue)
      for (var m in successfulTactics) {
        addToMap(m, true);
      }
      for (var m in successfulAdjustments) {
        addToMap(m, true);
      }

      // Add unsuccessful items (weaknesses - green)
      for (var m in unsuccessfulTactics) {
        addToMap(m, false);
      }
      for (var m in unsuccessfulAdjustments) {
        addToMap(m, false);
      }

      // Build final map and sort by count
      final allMap = buildFinalMap();
      final allBubbles = allMap.values.toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      for (var t in allBubbles) {
        final icon = t.isStrength ? '✓' : '✗';
        final hidden = t.isHidden ? ' (hidden)' : '';
        debugPrint('  $icon ${t.shortName} x${t.count}$hidden');
      }

      setState(() {
        _allBubbles = allBubbles;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading tactics: $e');
      debugPrint('$stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tactics: $e')),
        );
      }
    }
  }

  void _openDrillScreen(TacticBubbleData tactic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PracticeDrillScreen(tactic: tactic),
      ),
    );
  }

  Future<void> _dismissTactic(TacticBubbleData tactic) async {
    await _hiddenRepository.hide(tactic.shortName);
    _hiddenItems[tactic.shortName] = DateTime.now().millisecondsSinceEpoch;

    setState(() {
      // Update the bubble to be hidden instead of removing
      final index = _allBubbles.indexWhere((t) => t.shortName == tactic.shortName);
      if (index != -1) {
        _allBubbles[index] = _allBubbles[index].copyWith(isHidden: true);
      }
    });

    if (!mounted) return;
    _showAutoHideSnackBar('Hidden "${tactic.shortName}"', () async {
      await _hiddenRepository.unhide(tactic.shortName);
      _loadTactics();
    });
  }

  Future<void> _unhideTactic(TacticBubbleData tactic) async {
    await _hiddenRepository.unhide(tactic.shortName);
    _hiddenItems.remove(tactic.shortName);

    setState(() {
      // Update the bubble to not be hidden (smooth update like hiding)
      final index = _allBubbles.indexWhere((t) => t.shortName == tactic.shortName);
      if (index != -1) {
        _allBubbles[index] = _allBubbles[index].copyWith(isHidden: false);
      }
      // Auto-switch to non-hidden view if no hidden items remain
      if (_hiddenCount == 0) {
        _showHidden = false;
      }
    });

    if (!mounted) return;
    _showAutoHideSnackBar('Restored "${tactic.shortName}"', () async {
      await _hiddenRepository.hide(tactic.shortName);
      _loadTactics();
    });
  }

  void _showAutoHideSnackBar(String message, VoidCallback onUndo) {
    _snackBarTimer?.cancel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _snackBarTimer?.cancel();
            onUndo();
          },
        ),
      ),
    );

    // Manually hide after 5 seconds as fallback
    _snackBarTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        messenger.hideCurrentSnackBar();
      }
    });
  }

  List<TacticBubbleData> get _visibleBubbles {
    if (_showHidden) {
      return _allBubbles.where((b) => b.isHidden).toList();
    } else {
      return _allBubbles.where((b) => !b.isHidden).toList();
    }
  }

  int get _hiddenCount => _allBubbles.where((b) => b.isHidden).length;

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
            title: const Text('Practice'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadTactics,
                tooltip: 'Refresh',
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTactics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allBubbles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bubble_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tactics rated yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rate tactics as worked or didn\'t work\nduring your matches',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Toggle for showing hidden bubbles
        if (_hiddenCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _showHidden ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Show hidden ($_hiddenCount)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _showHidden,
                  onChanged: (value) {
                    setState(() {
                      _showHidden = value;
                    });
                  },
                ),
              ],
            ),
          ),
        // Bubble chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TacticBubbleChart(
              bubbles: _visibleBubbles,
              onTap: _openDrillScreen,
              onDismiss: _dismissTactic,
              onUnhide: _unhideTactic,
              emptyMessage: 'No tactics yet',
            ),
          ),
        ),
        // Legend bar at bottom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(TacticBubbleChart.strengthColor, 'Strengths'),
              const SizedBox(width: 32),
              _buildLegendItem(TacticBubbleChart.weaknessColor, 'Weaknesses'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
