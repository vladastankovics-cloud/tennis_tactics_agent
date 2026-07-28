import '../models/play_adjustment.dart';
import '../services/database_service.dart';

class PlayAdjustmentRepository {
  final DatabaseService _db = DatabaseService.instance;
  final String _tableName = 'play_adjustments';

  /// Get all adjustments (for sync)
  Future<List<PlayAdjustment>> getAllAdjustments() async {
    final maps = await _db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => PlayAdjustment.fromMap(map)).toList();
  }

  /// Get all adjustments for a match
  Future<List<PlayAdjustment>> getAdjustmentsForMatch(String matchId) async {
    final maps = await _db.query(
      _tableName,
      where: 'match_id = ?',
      whereArgs: [matchId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => PlayAdjustment.fromMap(map)).toList();
  }

  /// Get adjustment by context (match, grid position, situation, momentum)
  Future<PlayAdjustment?> getAdjustmentByContext({
    required String matchId,
    required int gridPosition,
    required String situation,
    required String momentum,
  }) async {
    final maps = await _db.query(
      _tableName,
      where: 'match_id = ? AND grid_position = ? AND situation = ? AND momentum = ?',
      whereArgs: [matchId, gridPosition, situation, momentum],
    );

    if (maps.isEmpty) return null;
    return PlayAdjustment.fromMap(maps.first);
  }

  /// Get adjustments for a specific situation/momentum combo
  Future<List<PlayAdjustment>> getAdjustmentsForContext({
    required String matchId,
    required String situation,
    required String momentum,
  }) async {
    final maps = await _db.query(
      _tableName,
      where: 'match_id = ? AND situation = ? AND momentum = ?',
      whereArgs: [matchId, situation, momentum],
      orderBy: 'grid_position ASC',
    );

    return maps.map((map) => PlayAdjustment.fromMap(map)).toList();
  }

  /// Create a new adjustment
  Future<void> createAdjustment(PlayAdjustment adjustment) async {
    await _db.insert(_tableName, adjustment.toMap());
  }

  /// Delete an adjustment
  Future<void> deleteAdjustment(String id) async {
    await _db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete adjustment by context
  Future<void> deleteAdjustmentByContext({
    required String matchId,
    required int gridPosition,
    required String situation,
    required String momentum,
  }) async {
    await _db.delete(
      _tableName,
      where: 'match_id = ? AND grid_position = ? AND situation = ? AND momentum = ?',
      whereArgs: [matchId, gridPosition, situation, momentum],
    );
  }

  /// Check if adjustment exists for context
  Future<bool> hasAdjustmentForContext({
    required String matchId,
    required int gridPosition,
    required String situation,
    required String momentum,
  }) async {
    final adjustment = await getAdjustmentByContext(
      matchId: matchId,
      gridPosition: gridPosition,
      situation: situation,
      momentum: momentum,
    );
    return adjustment != null;
  }

  /// Get successful adjustments for a match
  Future<List<PlayAdjustment>> getSuccessfulAdjustments(String matchId) async {
    final maps = await _db.query(
      _tableName,
      where: 'match_id = ? AND outcome = ?',
      whereArgs: [matchId, 'successful'],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => PlayAdjustment.fromMap(map)).toList();
  }

  /// Get unsuccessful adjustments for a match
  Future<List<PlayAdjustment>> getUnsuccessfulAdjustments(String matchId) async {
    final maps = await _db.query(
      _tableName,
      where: 'match_id = ? AND outcome = ?',
      whereArgs: [matchId, 'unsuccessful'],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => PlayAdjustment.fromMap(map)).toList();
  }

  /// Get the latest adjustment for a match (most recently created)
  Future<PlayAdjustment?> getLatestAdjustment(String matchId) async {
    final maps = await _db.query(
      _tableName,
      where: 'match_id = ?',
      whereArgs: [matchId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PlayAdjustment.fromMap(maps.first);
  }

  /// Get the active adjustment (latest with outcome or just latest)
  Future<PlayAdjustment?> getActiveAdjustment(String matchId) async {
    return await getLatestAdjustment(matchId);
  }

  /// Mark adjustment as successful
  Future<void> markSuccessful(String adjustmentId) async {
    await _db.update(
      _tableName,
      {'outcome': 'successful'},
      where: 'id = ?',
      whereArgs: [adjustmentId],
    );
  }

  /// Mark adjustment as unsuccessful
  Future<void> markUnsuccessful(String adjustmentId) async {
    await _db.update(
      _tableName,
      {'outcome': 'unsuccessful'},
      where: 'id = ?',
      whereArgs: [adjustmentId],
    );
  }

  /// Clear outcome from adjustment
  Future<void> clearOutcome(String adjustmentId) async {
    await _db.update(
      _tableName,
      {'outcome': null},
      where: 'id = ?',
      whereArgs: [adjustmentId],
    );
  }

  /// Update an existing adjustment
  Future<void> updateAdjustment(PlayAdjustment adjustment) async {
    await _db.update(
      _tableName,
      adjustment.toMap(),
      where: 'id = ?',
      whereArgs: [adjustment.id],
    );
  }

  /// Get all successful adjustments aggregated by short_name with count
  Future<List<Map<String, dynamic>>> getSuccessfulAdjustmentsAggregated() async {
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

  /// Get all unsuccessful adjustments aggregated by short_name with count
  Future<List<Map<String, dynamic>>> getUnsuccessfulAdjustmentsAggregated() async {
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
