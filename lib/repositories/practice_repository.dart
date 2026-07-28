import 'package:sqflite/sqflite.dart';
import '../services/database_service.dart';

/// Status values for practice matches
class PracticeStatus {
  static const String dismissed = 'dismissed';
  static const String later = 'later';
}

/// Repository for managing practice status of matches
class PracticeRepository {
  final DatabaseService _db = DatabaseService.instance;

  /// Get status for a match (null if not set)
  Future<String?> getStatus(String matchId) async {
    final results = await _db.query(
      'practice_status',
      where: 'match_id = ?',
      whereArgs: [matchId],
    );
    if (results.isEmpty) return null;
    return results.first['status'] as String;
  }

  /// Set status for a match (dismiss or later)
  Future<void> setStatus(String matchId, String status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _db.database;

    await db.insert(
      'practice_status',
      {
        'match_id': matchId,
        'status': status,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Dismiss a match from practice forever
  Future<void> dismiss(String matchId) async {
    await setStatus(matchId, PracticeStatus.dismissed);
  }

  /// Mark a match for later review
  Future<void> markForLater(String matchId) async {
    await setStatus(matchId, PracticeStatus.later);
  }

  /// Clear "later" status (called at start of new session)
  Future<void> clearLaterStatus() async {
    await _db.delete(
      'practice_status',
      where: 'status = ?',
      whereArgs: [PracticeStatus.later],
    );
  }

  /// Get all dismissed match IDs
  Future<List<String>> getDismissedMatchIds() async {
    final results = await _db.query(
      'practice_status',
      columns: ['match_id'],
      where: 'status = ?',
      whereArgs: [PracticeStatus.dismissed],
    );
    return results.map((r) => r['match_id'] as String).toList();
  }

  /// Get all "later" match IDs
  Future<List<String>> getLaterMatchIds() async {
    final results = await _db.query(
      'practice_status',
      columns: ['match_id'],
      where: 'status = ?',
      whereArgs: [PracticeStatus.later],
    );
    return results.map((r) => r['match_id'] as String).toList();
  }
}
