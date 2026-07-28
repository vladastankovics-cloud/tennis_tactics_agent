import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/ai_tactic.dart';
import '../models/match.dart';
import '../models/conversation.dart';
import '../models/play_adjustment.dart';
import '../repositories/ai_tactic_repository.dart';
import '../repositories/match_repository.dart';
import '../repositories/play_adjustment_repository.dart';
import '../repositories/practice_hidden_repository.dart';
import '../services/conversation_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/conversation_list_item.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/tennis_ball_icon.dart';
import 'match_form_screen.dart';
import 'tactics_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final MatchRepository _matchRepository = MatchRepository();
  final ConversationService _conversationService = ConversationService();
  final PlayAdjustmentRepository _adjustmentRepository = PlayAdjustmentRepository();
  final AiTacticRepository _aiTacticRepository = AiTacticRepository();
  final PracticeHiddenRepository _hiddenRepository = PracticeHiddenRepository();

  Match? _match;
  List<Conversation> _conversations = [];
  List<PlayAdjustment> _adjustments = [];
  List<AiTactic> _aiTactics = [];
  Map<String, int> _messageCounts = {};
  Map<String, int> _hiddenItems = {}; // shortName -> hidden_at timestamp
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final match = await _matchRepository.getMatchById(widget.matchId);
      final conversations =
          await _conversationService.getConversationsForMatch(widget.matchId);
      final adjustments =
          await _adjustmentRepository.getAdjustmentsForMatch(widget.matchId);
      final aiTactics =
          await _aiTacticRepository.getTacticsForMatch(widget.matchId);
      final hiddenItems = await _hiddenRepository.getHiddenItems();

      // Load message counts for each conversation
      final Map<String, int> counts = {};
      for (var conv in conversations) {
        counts[conv.id] = await _conversationService.getMessageCount(conv.id);
      }

      setState(() {
        _match = match;
        _conversations = conversations;
        _adjustments = adjustments;
        _aiTactics = aiTactics;
        _messageCounts = counts;
        _hiddenItems = hiddenItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading match details: $e')),
        );
      }
    }
  }

  Future<void> _navigateToEdit() async {
    if (_match == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchFormScreen(match: _match),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _copyMatch() async {
    if (_match == null) return;

    final now = DateTime.now();
    final copiedMatch = Match(
      id: const Uuid().v4(),
      opponentName: _match!.opponentName,
      opponentName2: _match!.opponentName2,
      partnerName: _match!.partnerName,
      matchDate: null, // Clear date for the copy
      matchResult: null,
      matchScoreUser: null,
      matchScoreOpponent: null,
      setScores: null,
      matchType: _match!.matchType,
      matchFormat: _match!.matchFormat,
      noAds: _match!.noAds,
      tiebreakSet: _match!.tiebreakSet,
      courtName: _match!.courtName,
      courtSurface: _match!.courtSurface,
      courtSpeed: _match!.courtSpeed,
      courtCover: _match!.courtCover,
      courtConditions: _match!.courtConditions,
      altitude: _match!.altitude,
      myAdjustment: null,
      opponentAdjustment: null,
      balls: _match!.balls,
      crowd: null,
      notes: null,
      createdAt: now,
      updatedAt: now,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchFormScreen(match: copiedMatch),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match copied successfully')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Match'),
        content: const Text(
          'Are you sure you want to delete this match? '
          'Linked tactics conversations will be preserved but unlinked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _matchRepository.deleteMatch(widget.matchId);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _navigateToNewConversation() async {
    // If conversation already exists, navigate to it
    if (_conversations.isNotEmpty) {
      _navigateToConversation(_conversations.first);
      return;
    }

    // Navigate to tactics screen with this match linked and auto-generate advice
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TacticsScreen(
          matchId: widget.matchId,
          autoGenerateAdvice: true,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToConversation(Conversation conversation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TacticsScreen(
          conversationId: conversation.id,
          matchId: widget.matchId,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _cycleAdjustmentStatus(PlayAdjustment adjustment) async {
    // Cycle through: pending (?) → successful (✓) → unsuccessful (✗) → pending
    final index = _adjustments.indexWhere((a) => a.id == adjustment.id);
    if (index == -1) return;

    PlayAdjustment updated;
    if (adjustment.isSuccessful) {
      // successful → unsuccessful
      await _adjustmentRepository.markUnsuccessful(adjustment.id);
      updated = adjustment.copyWith(outcome: 'unsuccessful');
    } else if (adjustment.isUnsuccessful) {
      // unsuccessful → pending
      await _adjustmentRepository.clearOutcome(adjustment.id);
      updated = PlayAdjustment(
        id: adjustment.id,
        matchId: adjustment.matchId,
        shortName: adjustment.shortName,
        description: adjustment.description,
        situation: adjustment.situation,
        momentum: adjustment.momentum,
        gridPosition: adjustment.gridPosition,
        createdAt: adjustment.createdAt,
        outcome: null,
      );
    } else {
      // pending → successful
      await _adjustmentRepository.markSuccessful(adjustment.id);
      updated = adjustment.copyWith(outcome: 'successful');
    }

    setState(() {
      _adjustments[index] = updated;
    });
  }

  Future<void> _cycleAiTacticStatus(AiTactic tactic) async {
    // Cycle through: pending (?) → successful (✓) → unsuccessful (✗) → pending
    final index = _aiTactics.indexWhere((t) => t.id == tactic.id);
    if (index == -1) return;

    AiTactic updated;
    if (tactic.isSuccessful) {
      // successful → unsuccessful
      await _aiTacticRepository.markUnsuccessful(tactic.id);
      updated = tactic.copyWith(outcome: 'unsuccessful');
    } else if (tactic.isUnsuccessful) {
      // unsuccessful → pending
      await _aiTacticRepository.clearOutcome(tactic.id);
      updated = AiTactic(
        id: tactic.id,
        conversationId: tactic.conversationId,
        matchId: tactic.matchId,
        shortName: tactic.shortName,
        description: tactic.description,
        createdAt: tactic.createdAt,
        outcome: null,
      );
    } else {
      // pending → successful
      await _aiTacticRepository.markSuccessful(tactic.id);
      updated = tactic.copyWith(outcome: 'successful');
    }

    setState(() {
      _aiTactics[index] = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Details')),
        body: const Center(child: Text('Match not found')),
      );
    }

    final match = _match!;
    final isWin = match.isWin;
    final resultColor = isWin ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyMatch,
            tooltip: 'Copy',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Match info card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.opponentName2 != null && match.opponentName2!.isNotEmpty
                                ? 'vs ${match.opponentName} & ${match.opponentName2}'
                                : 'vs ${match.opponentName}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (match.matchScoreUser != null &&
                            match.matchScoreOpponent != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: resultColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: resultColor, width: 2),
                            ),
                            child: Text(
                              isWin ? 'WIN' : 'LOSS',
                              style: TextStyle(
                                color: resultColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                        Icons.calendar_today,
                        'Date',
                        match.matchDate != null
                            ? DateFormatter.formatDate(match.matchDate!)
                            : 'Date not set'),
                    if (match.courtName != null)
                      _buildInfoRow(
                          Icons.location_on, 'Court', match.courtName!),
                    _buildInfoRow(
                        Icons.sports_tennis, 'Score', match.scoreDisplay),
                    if (match.partnerName != null && match.partnerName!.isNotEmpty)
                      _buildInfoRow(
                          Icons.person_outline, 'Partner', match.partnerName!),
                    if (match.myAdjustment != null && match.myAdjustment!.isNotEmpty)
                      _buildInfoRow(
                          Icons.person, 'My', match.myAdjustment!.replaceAll(',', ', ')),
                    if (match.opponentAdjustment != null && match.opponentAdjustment!.isNotEmpty)
                      _buildInfoRow(
                          Icons.person_off, "Opponent's", match.opponentAdjustment!.replaceAll(',', ', ')),
                    if (match.courtConditions != null && match.courtConditions!.isNotEmpty)
                      _buildInfoRow(
                          Icons.wb_sunny, 'Conditions', match.courtConditions!),
                    if (match.balls != null && match.balls!.isNotEmpty)
                      _buildInfoRowWithWidget(
                          TennisBallIcon(size: 16, color: Colors.grey[600]), 'Balls', match.balls!),
                    if (match.crowd != null && match.crowd!.isNotEmpty)
                      _buildInfoRow(
                          Icons.groups, 'Crowd', match.crowd!),
                    if (match.notes != null && match.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Notes',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.notes!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tactics section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tactics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _navigateToNewConversation,
                  icon: Icon(
                    _conversations.isEmpty ? Icons.psychology : Icons.chat,
                    size: 18,
                  ),
                  label: Text(_conversations.isEmpty
                      ? 'Get AI Advice'
                      : 'Continue Tactics'),
                ),
              ],
            ),

            // AI Tactics list
            if (_aiTactics.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._aiTactics.map((tactic) => _buildAiTacticCard(tactic)),
            ],

            // Adjustments section
            if (_adjustments.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Adjustments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ..._adjustments.map((adjustment) => _buildAdjustmentCard(adjustment)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithWidget(Widget icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Center(child: icon),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentCard(PlayAdjustment adjustment) {
    final isSuccessful = adjustment.isSuccessful;
    final isUnsuccessful = adjustment.isUnsuccessful;
    final isHidden = _hiddenItems.containsKey(adjustment.shortName);

    Color borderColor;
    int borderWidth = 1;
    if (isSuccessful) {
      borderColor = Colors.green[600]!;
      borderWidth = 2;
    } else if (isUnsuccessful) {
      borderColor = Colors.red[600]!;
      borderWidth = 2;
    } else {
      borderColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHidden ? Colors.grey[400]! : borderColor,
          width: borderWidth.toDouble(),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    adjustment.shortName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isHidden ? TextDecoration.lineThrough : null,
                          color: isHidden ? Colors.grey[500] : null,
                        ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _cycleAdjustmentStatus(adjustment),
                  child: Icon(
                    isSuccessful
                        ? Icons.check_circle
                        : isUnsuccessful
                            ? Icons.cancel
                            : Icons.help,
                    color: isHidden
                        ? Colors.grey[400]
                        : isSuccessful
                            ? Colors.green[600]
                            : isUnsuccessful
                                ? Colors.red[600]
                                : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              adjustment.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                    color: isHidden ? Colors.grey[500] : null,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTag(adjustment.situation, Icons.sports_tennis),
                const SizedBox(width: 8),
                _buildTag(adjustment.momentum, Icons.trending_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiTacticCard(AiTactic tactic) {
    final isSuccessful = tactic.isSuccessful;
    final isUnsuccessful = tactic.isUnsuccessful;
    final isHidden = _hiddenItems.containsKey(tactic.shortName);

    Color borderColor;
    int borderWidth = 1;
    if (isSuccessful) {
      borderColor = Colors.green[600]!;
      borderWidth = 2;
    } else if (isUnsuccessful) {
      borderColor = Colors.red[600]!;
      borderWidth = 2;
    } else {
      borderColor = Theme.of(context).colorScheme.secondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHidden ? Colors.grey[400]! : borderColor,
          width: borderWidth.toDouble(),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tactic.shortName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isHidden ? TextDecoration.lineThrough : null,
                          color: isHidden ? Colors.grey[500] : null,
                        ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _cycleAiTacticStatus(tactic),
                  child: Icon(
                    isSuccessful
                        ? Icons.check_circle
                        : isUnsuccessful
                            ? Icons.cancel
                            : Icons.help,
                    color: isHidden
                        ? Colors.grey[400]
                        : isSuccessful
                            ? Colors.green[600]
                            : isUnsuccessful
                                ? Colors.red[600]
                                : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tactic.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                    color: isHidden ? Colors.grey[500] : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
