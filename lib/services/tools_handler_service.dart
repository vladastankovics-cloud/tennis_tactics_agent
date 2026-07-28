import '../models/match.dart';
import '../repositories/match_repository.dart';
import '../repositories/conversation_repository.dart';

/// Service to handle Claude AI tool/function calls for match CRUD operations
class ToolsHandlerService {
  final MatchRepository _matchRepository;
  final ConversationRepository _conversationRepository;
  String? _currentConversationId;

  ToolsHandlerService(this._matchRepository, this._conversationRepository);

  /// Factory constructor to create instance with database
  static Future<ToolsHandlerService> create({String? conversationId}) async {
    final matchRepo = MatchRepository();
    final conversationRepo = ConversationRepository();
    final handler = ToolsHandlerService(matchRepo, conversationRepo);
    handler._currentConversationId = conversationId;
    return handler;
  }

  /// Execute a tool call from Claude
  Future<Map<String, dynamic>> handleToolCall(
    String toolName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      switch (toolName) {
        case 'create_match':
          return await _createMatch(parameters);
        case 'update_match':
          return await _updateMatch(parameters);
        case 'delete_match':
          return await _deleteMatch(parameters);
        case 'list_matches':
          return await _listMatches(parameters);
        case 'get_match_stats':
          return await _getMatchStats(parameters);
        case 'link_to_match':
          return await _linkToMatch(parameters);
        default:
          return {
            'success': false,
            'error': 'Unknown tool: $toolName',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error executing tool: $e',
      };
    }
  }

  /// Create a new match
  Future<Map<String, dynamic>> _createMatch(
      Map<String, dynamic> params) async {
    try {
      final match = Match(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        opponentName: params['opponent_name'] as String,
        matchDate: DateTime.parse(params['match_date'] as String),
        matchResult: params['match_result'] as String?,
        matchScoreUser: params['user_score'] as int?,
        matchScoreOpponent: params['opponent_score'] as int?,
        matchType: params['match_type'] as String?,
        courtName: params['court_name'] as String?,
        courtSurface: params['court_surface'] as String?,
        courtCover: params['court_cover'] as String?,
        courtConditions: params['court_conditions'] as String?,
        notes: params['notes'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _matchRepository.createMatch(match);

      return {
        'success': true,
        'match_id': match.id,
        'message':
            'Match against ${match.opponentName} on ${match.matchDate.toString().split(' ')[0]} created successfully.',
        'match': match.toMap(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create match: $e',
      };
    }
  }

  /// Update an existing match
  Future<Map<String, dynamic>> _updateMatch(
      Map<String, dynamic> params) async {
    try {
      final identifier = params['match_identifier'] as String;
      final match = await _resolveMatchIdentifier(identifier);

      if (match == null) {
        return {
          'success': false,
          'error': 'Could not find match: $identifier',
        };
      }

      // Update only provided fields
      final updatedMatch = Match(
        id: match.id,
        opponentName:
            params['opponent_name'] as String? ?? match.opponentName,
        matchDate: params['match_date'] != null
            ? DateTime.parse(params['match_date'] as String)
            : match.matchDate,
        matchResult: params['match_result'] as String? ?? match.matchResult,
        matchScoreUser: params['user_score'] as int? ?? match.matchScoreUser,
        matchScoreOpponent:
            params['opponent_score'] as int? ?? match.matchScoreOpponent,
        matchType: params['match_type'] as String? ?? match.matchType,
        courtName: params['court_name'] as String? ?? match.courtName,
        courtSurface: params['court_surface'] as String? ?? match.courtSurface,
        courtCover: params['court_cover'] as String? ?? match.courtCover,
        courtConditions: params['court_conditions'] as String? ?? match.courtConditions,
        notes: params['notes'] as String? ?? match.notes,
        createdAt: match.createdAt,
        updatedAt: DateTime.now(),
      );

      await _matchRepository.updateMatch(updatedMatch);

      return {
        'success': true,
        'match_id': updatedMatch.id,
        'message': 'Match updated successfully.',
        'match': updatedMatch.toMap(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to update match: $e',
      };
    }
  }

  /// Delete a match
  Future<Map<String, dynamic>> _deleteMatch(
      Map<String, dynamic> params) async {
    try {
      final identifier = params['match_identifier'] as String;
      final match = await _resolveMatchIdentifier(identifier);

      if (match == null) {
        return {
          'success': false,
          'error': 'Could not find match: $identifier',
        };
      }

      await _matchRepository.deleteMatch(match.id);

      return {
        'success': true,
        'message':
            'Match against ${match.opponentName} on ${match.matchDate.toString().split(' ')[0]} deleted successfully.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to delete match: $e',
      };
    }
  }

  /// List matches with filters
  Future<Map<String, dynamic>> _listMatches(Map<String, dynamic> params) async {
    try {
      final filter = params['filter'] as String;
      final opponentName = params['opponent_name'] as String?;
      final courtSurface = params['court_surface'] as String?;
      final limit = params['limit'] as int? ?? 10;

      List<Match> matches = await _matchRepository.getAllMatches();

      // Apply filters
      if (filter == 'wins') {
        matches = matches.where((m) => m.isWin).toList();
      } else if (filter == 'losses') {
        matches = matches.where((m) => !m.isWin).toList();
      } else if (filter == 'recent') {
        matches = matches.take(limit).toList();
      } else if (filter == 'by_opponent' && opponentName != null) {
        matches = matches
            .where((m) =>
                m.opponentName.toLowerCase().contains(opponentName.toLowerCase()))
            .toList();
      }

      if (courtSurface != null) {
        matches = matches
            .where((m) =>
                m.courtSurface?.toLowerCase() == courtSurface.toLowerCase())
            .toList();
      }

      // Apply limit
      if (matches.length > limit) {
        matches = matches.take(limit).toList();
      }

      return {
        'success': true,
        'count': matches.length,
        'matches': matches.map((m) => m.toMap()).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to list matches: $e',
      };
    }
  }

  /// Get match statistics
  Future<Map<String, dynamic>> _getMatchStats(
      Map<String, dynamic> params) async {
    try {
      final statType = params['stat_type'] as String;
      final opponentName = params['opponent_name'] as String?;

      final matches = await _matchRepository.getAllMatches();

      if (matches.isEmpty) {
        return {
          'success': true,
          'message': 'No matches found to calculate statistics.',
          'stats': {},
        };
      }

      Map<String, dynamic> stats = {};

      if (statType == 'overall') {
        final wins = matches.where((m) => m.isWin).length;
        final losses = matches.length - wins;
        final winRate =
            matches.isNotEmpty ? (wins / matches.length * 100).toStringAsFixed(1) : '0.0';

        stats = {
          'total_matches': matches.length,
          'wins': wins,
          'losses': losses,
          'win_rate': '$winRate%',
        };
      } else if (statType == 'by_surface') {
        final surfaces = <String, Map<String, int>>{};
        for (final match in matches) {
          final surface = match.courtSurface ?? 'Unknown';
          surfaces.putIfAbsent(surface, () => {'wins': 0, 'losses': 0});
          if (match.isWin) {
            surfaces[surface]!['wins'] = surfaces[surface]!['wins']! + 1;
          } else {
            surfaces[surface]!['losses'] = surfaces[surface]!['losses']! + 1;
          }
        }
        stats = {'by_surface': surfaces};
      } else if (statType == 'by_opponent' && opponentName != null) {
        final opponentMatches = matches
            .where((m) =>
                m.opponentName.toLowerCase() == opponentName.toLowerCase())
            .toList();
        final wins = opponentMatches.where((m) => m.isWin).length;
        final losses = opponentMatches.length - wins;

        stats = {
          'opponent': opponentName,
          'total_matches': opponentMatches.length,
          'wins': wins,
          'losses': losses,
          'win_rate': opponentMatches.isNotEmpty
              ? '${(wins / opponentMatches.length * 100).toStringAsFixed(1)}%'
              : '0.0%',
        };
      } else if (statType == 'recent_form') {
        final recentMatches = matches.take(10).toList();
        final wins = recentMatches.where((m) => m.isWin).length;
        final losses = recentMatches.length - wins;

        stats = {
          'last_10_matches': recentMatches.length,
          'wins': wins,
          'losses': losses,
          'form': recentMatches.map((m) => m.isWin ? 'W' : 'L').join(', '),
        };
      }

      return {
        'success': true,
        'stat_type': statType,
        'stats': stats,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to calculate statistics: $e',
      };
    }
  }

  /// Resolve match identifier to actual Match object
  /// Supports: "last match", "most recent match", "match against [opponent]", "my last win", "my last loss"
  Future<Match?> _resolveMatchIdentifier(String identifier) async {
    final matches = await _matchRepository.getAllMatches();
    if (matches.isEmpty) return null;

    final lowerIdentifier = identifier.toLowerCase();

    // Last match / most recent
    if (lowerIdentifier.contains('last') ||
        lowerIdentifier.contains('recent') ||
        lowerIdentifier.contains('latest')) {
      if (lowerIdentifier.contains('win')) {
        return matches.firstWhere((m) => m.isWin, orElse: () => matches.first);
      } else if (lowerIdentifier.contains('loss')) {
        return matches.firstWhere((m) => !m.isWin, orElse: () => matches.first);
      }
      return matches.first;
    }

    // Match against specific opponent
    if (lowerIdentifier.contains('against')) {
      final opponentPart = lowerIdentifier.split('against').last.trim();
      return matches.firstWhere(
        (m) => m.opponentName.toLowerCase().contains(opponentPart),
        orElse: () => matches.first,
      );
    }

    // Try to find by opponent name directly
    final matchingOpponent = matches.firstWhere(
      (m) => m.opponentName.toLowerCase().contains(lowerIdentifier),
      orElse: () => matches.first,
    );

    return matchingOpponent;
  }

  /// Link current conversation to a match with smart temporal logic
  Future<Map<String, dynamic>> _linkToMatch(
      Map<String, dynamic> params) async {
    try {
      if (_currentConversationId == null) {
        return {
          'success': false,
          'error': 'No conversation ID available for linking',
        };
      }

      final opponentName = params['opponent_name'] as String;
      final matchIdentifier = params['match_identifier'] as String?;

      // Find all matches with this opponent
      final allMatches = await _matchRepository.getAllMatches();
      var matchingMatches = allMatches.where((m) =>
        m.opponentName.toLowerCase().contains(opponentName.toLowerCase()) ||
        opponentName.toLowerCase().contains(m.opponentName.toLowerCase())
      ).toList();

      // If match_identifier is provided, try to filter further
      if (matchIdentifier != null && matchingMatches.length > 1) {
        final identifier = matchIdentifier.toLowerCase();
        final now = DateTime.now();

        // Try to match by timeframe keywords
        if (identifier.contains('today')) {
          matchingMatches = matchingMatches.where((m) =>
            m.matchDate != null &&
            m.matchDate!.year == now.year &&
            m.matchDate!.month == now.month &&
            m.matchDate!.day == now.day
          ).toList();
        } else if (identifier.contains('tomorrow')) {
          final tomorrow = now.add(const Duration(days: 1));
          matchingMatches = matchingMatches.where((m) =>
            m.matchDate != null &&
            m.matchDate!.year == tomorrow.year &&
            m.matchDate!.month == tomorrow.month &&
            m.matchDate!.day == tomorrow.day
          ).toList();
        } else if (identifier.contains('this week') || identifier.contains('next week')) {
          final twoWeeksFromNow = now.add(const Duration(days: 14));
          matchingMatches = matchingMatches.where((m) =>
            m.matchDate != null &&
            m.matchDate!.isAfter(now) &&
            m.matchDate!.isBefore(twoWeeksFromNow)
          ).toList();
        } else if (identifier.contains('past') || identifier.contains('previous') || identifier.contains('last')) {
          matchingMatches = matchingMatches.where((m) =>
            m.matchDate != null && m.matchDate!.isBefore(now)
          ).toList();
        }

        // Try to match by month name
        final months = ['january', 'february', 'march', 'april', 'may', 'june',
                       'july', 'august', 'september', 'october', 'november', 'december'];
        for (int i = 0; i < months.length; i++) {
          if (identifier.contains(months[i])) {
            matchingMatches = matchingMatches.where((m) =>
              m.matchDate != null && m.matchDate!.month == (i + 1)
            ).toList();
            break;
          }
        }
      }

      if (matchingMatches.isEmpty) {
        // Create a new match record for this opponent (without date/score)
        final newMatch = Match(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          opponentName: opponentName,
          matchDate: null, // Will be set later by user
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _matchRepository.createMatch(newMatch);

        // Link conversation to the new match
        await _conversationRepository.linkConversationToMatch(
          _currentConversationId!,
          newMatch.id,
        );

        return {
          'success': true,
          'match_id': newMatch.id,
          'message': 'Created a new match record for $opponentName and linked this conversation to it.',
        };
      }

      // Categorize matches by temporal status
      final now = DateTime.now();
      final twoWeeksFromNow = now.add(const Duration(days: 14));

      final pastMatches = matchingMatches.where((m) =>
        m.matchDate != null && m.matchDate!.isBefore(now)
      ).toList();

      final soonMatches = matchingMatches.where((m) =>
        m.matchDate != null &&
        m.matchDate!.isAfter(now) &&
        m.matchDate!.isBefore(twoWeeksFromNow)
      ).toList();

      final futureMatches = matchingMatches.where((m) =>
        m.matchDate == null ||
        m.matchDate!.isAfter(twoWeeksFromNow) ||
        m.matchDate!.isAtSameMomentAs(twoWeeksFromNow)
      ).toList();

      // Apply smart linking logic
      if (soonMatches.length == 1 && futureMatches.isEmpty) {
        // Exactly one "soon" match and no future matches - auto-link
        final match = soonMatches.first;
        await _conversationRepository.linkConversationToMatch(
          _currentConversationId!,
          match.id,
        );

        final dateStr = match.matchDate != null
            ? 'on ${_formatDate(match.matchDate!)}'
            : '';

        return {
          'success': true,
          'match_id': match.id,
          'message': 'This conversation has been linked to your upcoming match against ${match.opponentName} $dateStr.',
        };
      } else if (soonMatches.isNotEmpty || futureMatches.isNotEmpty) {
        // Multiple upcoming matches - ask user to clarify
        final upcomingMatches = [...soonMatches, ...futureMatches];
        final matchList = upcomingMatches.map((m) {
          final dateStr = m.matchDate != null
              ? _formatDate(m.matchDate!)
              : 'no date set';
          final timeframe = _getTimeframe(m.matchDate);
          return '- Match $timeframe ($dateStr)';
        }).join('\n');

        return {
          'success': false,
          'error': 'I found multiple matches with $opponentName:\n\n$matchList\n\nPlease specify which match you\'re discussing (e.g., "the match next week" or "the match in March").',
          'multiple_matches': true,
          'match_count': upcomingMatches.length,
        };
      } else if (pastMatches.isNotEmpty) {
        // Only past matches found - ask for confirmation
        final match = pastMatches.first;
        final dateStr = match.matchDate != null
            ? _formatDate(match.matchDate!)
            : 'no date';

        return {
          'success': false,
          'error': 'I found a past match with ${match.opponentName} from $dateStr. Are you discussing tactics for a rematch or reviewing the past match? If you\'re planning a new match, I can create a new match record.',
          'past_match_only': true,
        };
      }

      // Fallback - shouldn't reach here
      return {
        'success': false,
        'error': 'Could not determine which match to link to.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to link conversation to match: $e',
      };
    }
  }

  /// Helper method to format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Helper method to get timeframe description
  String _getTimeframe(DateTime? date) {
    if (date == null) return 'with no date set';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'in the past';
    } else if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'tomorrow';
    } else if (difference < 7) {
      return 'this week';
    } else if (difference < 14) {
      return 'next week';
    } else if (difference < 30) {
      return 'this month';
    } else {
      return 'in the future';
    }
  }
}
