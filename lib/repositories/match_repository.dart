import '../models/match.dart';
import '../services/database_service.dart';

class MatchRepository {
  final DatabaseService _db = DatabaseService.instance;
  static const String _tableName = 'matches';

  // Get all matches, sorted by date (newest first)
  Future<List<Match>> getAllMatches() async {
    final maps = await _db.query(
      _tableName,
      orderBy: 'match_date DESC',
    );
    return maps.map((map) => Match.fromMap(map)).toList();
  }

  // Get the most recent match (by date) that has already been played (in the past)
  Future<Match?> getMostRecentMatch() async {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    final maps = await _db.query(
      _tableName,
      where: 'match_date IS NOT NULL AND match_date <= ?',
      whereArgs: [todayEnd],
      orderBy: 'match_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Match.fromMap(maps.first);
  }

  // Get a single match by ID
  Future<Match?> getMatchById(String id) async {
    final maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Match.fromMap(maps.first);
  }

  // Create a new match
  Future<void> createMatch(Match match) async {
    await _db.insert(_tableName, match.toMap());
  }

  // Update an existing match
  Future<void> updateMatch(Match match) async {
    await _db.update(
      _tableName,
      match.toMap(),
      where: 'id = ?',
      whereArgs: [match.id],
    );
  }

  // Delete a match
  Future<void> deleteMatch(String id) async {
    // First, unlink any conversations associated with this match
    await _db.update(
      'conversations',
      {'match_id': null},
      where: 'match_id = ?',
      whereArgs: [id],
    );

    // Then delete the match
    await _db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Search matches by opponent name
  Future<List<Match>> searchMatches(String query) async {
    final maps = await _db.query(
      _tableName,
      where: 'opponent_name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'match_date DESC',
    );
    return maps.map((map) => Match.fromMap(map)).toList();
  }

  // Get matches filtered by result (wins or losses)
  Future<List<Match>> getMatchesByResult(bool wins) async {
    final allMatches = await getAllMatches();
    return allMatches.where((match) {
      if (match.matchScoreUser == null || match.matchScoreOpponent == null) {
        return false;
      }
      final isWin = match.matchScoreUser! > match.matchScoreOpponent!;
      return isWin == wins;
    }).toList();
  }

  // Get count of total matches
  Future<int> getMatchCount() async {
    return await _db.getTableCount(_tableName);
  }

  // Get matches in a date range
  Future<List<Match>> getMatchesInDateRange(
      DateTime start, DateTime end) async {
    final maps = await _db.query(
      _tableName,
      where: 'match_date >= ? AND match_date <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'match_date DESC',
    );
    return maps.map((map) => Match.fromMap(map)).toList();
  }
}
