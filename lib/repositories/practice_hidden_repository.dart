import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';

class PracticeHiddenRepository {
  final DatabaseService _db = DatabaseService.instance;
  final String _tableName = 'practice_hidden';

  /// Hide a tactic/adjustment by short_name
  Future<void> hide(String shortName) async {
    final db = await _db.database;
    await db.insert(
      _tableName,
      {
        'short_name': shortName,
        'hidden_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Unhide a tactic/adjustment
  Future<void> unhide(String shortName) async {
    await _db.delete(
      _tableName,
      where: 'short_name = ?',
      whereArgs: [shortName],
    );
  }

  /// Get all hidden items with their hidden_at timestamp
  Future<Map<String, int>> getHiddenItems() async {
    final maps = await _db.query(_tableName);
    return {
      for (var map in maps)
        map['short_name'] as String: map['hidden_at'] as int,
    };
  }

  /// Check if an item is hidden
  Future<bool> isHidden(String shortName) async {
    final maps = await _db.query(
      _tableName,
      where: 'short_name = ?',
      whereArgs: [shortName],
    );
    return maps.isNotEmpty;
  }

  /// Get the hidden_at timestamp for an item (null if not hidden)
  Future<int?> getHiddenAt(String shortName) async {
    final maps = await _db.query(
      _tableName,
      where: 'short_name = ?',
      whereArgs: [shortName],
    );
    if (maps.isEmpty) return null;
    return maps.first['hidden_at'] as int;
  }
}
