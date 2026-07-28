import '../models/ai_tactic.dart';
import '../services/database_service.dart';

class AiTacticRepository {
  final DatabaseService _db = DatabaseService.instance;
  final String _tableName = 'ai_tactics';

  /// Get all tactics (for sync)
  Future<List<AiTactic>> getTacticsForAllMatches() async {
    final maps = await _db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => AiTactic.fromMap(map)).toList();
  }

  /// Get all tactics for a match
  Future<List<AiTactic>> getTacticsForMatch(String matchId) async {
    final maps = await _db.query(
      _tableName,
      where: 'match_id = ?',
      whereArgs: [matchId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => AiTactic.fromMap(map)).toList();
  }

  /// Get all tactics for a conversation
  Future<List<AiTactic>> getTacticsForConversation(String conversationId) async {
    final maps = await _db.query(
      _tableName,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => AiTactic.fromMap(map)).toList();
  }

  /// Create a new tactic
  Future<void> createTactic(AiTactic tactic) async {
    await _db.insert(_tableName, tactic.toMap());
  }

  /// Create multiple tactics at once
  Future<void> createTactics(List<AiTactic> tactics) async {
    for (final tactic in tactics) {
      await _db.insert(_tableName, tactic.toMap());
    }
  }

  /// Delete a tactic
  Future<void> deleteTactic(String id) async {
    await _db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all tactics for a conversation
  Future<void> deleteTacticsForConversation(String conversationId) async {
    await _db.delete(
      _tableName,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  /// Mark tactic as successful
  Future<void> markSuccessful(String tacticId) async {
    await _db.update(
      _tableName,
      {'outcome': 'successful'},
      where: 'id = ?',
      whereArgs: [tacticId],
    );
  }

  /// Mark tactic as unsuccessful
  Future<void> markUnsuccessful(String tacticId) async {
    await _db.update(
      _tableName,
      {'outcome': 'unsuccessful'},
      where: 'id = ?',
      whereArgs: [tacticId],
    );
  }

  /// Clear outcome from tactic (back to pending)
  Future<void> clearOutcome(String tacticId) async {
    await _db.update(
      _tableName,
      {'outcome': null},
      where: 'id = ?',
      whereArgs: [tacticId],
    );
  }

  /// Update a tactic
  Future<void> updateTactic(AiTactic tactic) async {
    await _db.update(
      _tableName,
      tactic.toMap(),
      where: 'id = ?',
      whereArgs: [tactic.id],
    );
  }

  /// Get all successful tactics aggregated by short_name with count
  Future<List<Map<String, dynamic>>> getSuccessfulTacticsAggregated() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT short_name, description, COUNT(*) as count, MAX(created_at) as latest_at
      FROM $_tableName
      WHERE outcome = 'successful'
      GROUP BY short_name
      ORDER BY count DESC
    ''');
    return result;
  }

  /// Get all unsuccessful tactics aggregated by short_name with count
  Future<List<Map<String, dynamic>>> getUnsuccessfulTacticsAggregated() async {
    final db = await _db.database;
    final result = await db.rawQuery('''
      SELECT short_name, description, COUNT(*) as count, MAX(created_at) as latest_at
      FROM $_tableName
      WHERE outcome = 'unsuccessful'
      GROUP BY short_name
      ORDER BY count DESC
    ''');
    return result;
  }
}
