import '../models/opponent.dart';
import '../services/database_service.dart';

class OpponentRepository {
  final DatabaseService _db = DatabaseService.instance;
  final String _tableName = 'opponents';

  /// Get opponent by ID
  Future<Opponent?> getOpponentById(String id) async {
    final maps = await _db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Opponent.fromMap(maps.first);
  }

  /// Get opponent by name (case-insensitive)
  Future<Opponent?> getOpponentByName(String name) async {
    final maps = await _db.query(
      _tableName,
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
    );

    if (maps.isEmpty) return null;
    return Opponent.fromMap(maps.first);
  }

  /// Get all opponents
  Future<List<Opponent>> getAllOpponents() async {
    final maps = await _db.query(
      _tableName,
      orderBy: 'name ASC',
    );

    return maps.map((map) => Opponent.fromMap(map)).toList();
  }

  /// Create new opponent
  Future<void> createOpponent(Opponent opponent) async {
    await _db.insert(_tableName, opponent.toMap());
  }

  /// Update existing opponent
  Future<void> updateOpponent(Opponent opponent) async {
    await _db.update(
      _tableName,
      opponent.toMap(),
      where: 'id = ?',
      whereArgs: [opponent.id],
    );
  }

  /// Delete opponent
  Future<void> deleteOpponent(String id) async {
    await _db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get or create opponent by name
  /// Returns existing opponent if found, creates new one otherwise
  Future<Opponent> getOrCreateOpponent(String name, String id) async {
    final existing = await getOpponentByName(name);
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();
    final newOpponent = Opponent(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );

    await createOpponent(newOpponent);
    return newOpponent;
  }

  /// Search opponents by name
  Future<List<Opponent>> searchOpponents(String query) async {
    final maps = await _db.query(
      _tableName,
      where: 'LOWER(name) LIKE LOWER(?)',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Opponent.fromMap(map)).toList();
  }
}
