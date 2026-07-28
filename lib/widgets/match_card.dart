import 'package:flutter/material.dart';
import '../models/match.dart';
import '../utils/date_formatter.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.onLongPress,
  });

  String _getOpponentDisplay() {
    if (match.opponentName2 != null && match.opponentName2!.isNotEmpty) {
      return '${match.opponentName} & ${match.opponentName2}';
    }
    return match.opponentName;
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWin = match.isWin;
    final resultColor = isWin ? Colors.green : Colors.red;
    final resultIcon = isWin ? Icons.check_circle : Icons.cancel;
    final resultText = isWin ? 'WIN' : 'LOSS';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Opponent name(s)
                  Expanded(
                    child: Text(
                      'vs ${_getOpponentDisplay()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Win/Loss indicator
                  if (match.matchScoreUser != null &&
                      match.matchScoreOpponent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: resultColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: resultColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            resultIcon,
                            size: 16,
                            color: resultColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            resultText,
                            style: TextStyle(
                              color: resultColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Date, court, and score
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    match.matchDate != null
                        ? DateFormatter.formatDate(match.matchDate!)
                        : 'Date not set',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          fontStyle: match.matchDate == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                  ),
                  if (match.courtName != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match.courtName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(width: 16),
                  Icon(
                    Icons.sports_tennis,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    match.scoreDisplay,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              // Optional match details (adjustments tags)
              if ((match.myAdjustment != null && match.myAdjustment!.isNotEmpty) ||
                  (match.opponentAdjustment != null && match.opponentAdjustment!.isNotEmpty) ||
                  (match.courtConditions != null && match.courtConditions!.isNotEmpty) ||
                  (match.balls != null && match.balls!.isNotEmpty) ||
                  (match.crowd != null && match.crowd!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (match.myAdjustment != null && match.myAdjustment!.isNotEmpty)
                      _buildTag('My: ${match.myAdjustment!.replaceAll(',', ', ')}'),
                    if (match.opponentAdjustment != null && match.opponentAdjustment!.isNotEmpty)
                      _buildTag("Opp: ${match.opponentAdjustment!.replaceAll(',', ', ')}"),
                    if (match.courtConditions != null && match.courtConditions!.isNotEmpty)
                      _buildTag(match.courtConditions!),
                    if (match.balls != null && match.balls!.isNotEmpty)
                      _buildTag(match.balls!),
                    if (match.crowd != null && match.crowd!.isNotEmpty)
                      _buildTag(match.crowd!),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
