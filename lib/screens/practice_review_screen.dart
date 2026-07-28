import 'package:flutter/material.dart';
import '../models/match.dart';

/// Screen for reviewing a past match (currently empty)
class PracticeReviewScreen extends StatelessWidget {
  final Match match;

  const PracticeReviewScreen({super.key, required this.match});

  String _getOpponentDisplay() {
    if (match.opponentName2 != null && match.opponentName2!.isNotEmpty) {
      return '${match.opponentName} & ${match.opponentName2}';
    }
    return match.opponentName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Review: ${_getOpponentDisplay()}'),
      ),
      body: const Center(
        child: Text('Review screen coming soon'),
      ),
    );
  }
}
