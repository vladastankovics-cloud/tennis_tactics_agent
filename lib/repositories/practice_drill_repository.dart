import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/practice_drill.dart';
import '../services/database_service.dart';

class PracticeDrillRepository {
  final DatabaseService _db = DatabaseService.instance;
  final String _tableName = 'practice_drills';
  final _uuid = const Uuid();

  /// Get all drills for a specific tactic
  Future<List<PracticeDrill>> getDrillsForTactic(String tacticShortName) async {
    final maps = await _db.query(
      _tableName,
      where: 'tactic_short_name = ?',
      whereArgs: [tacticShortName],
      orderBy: 'order_index ASC',
    );
    return maps.map((map) => _drillFromDbMap(map)).toList();
  }

  /// Convert DB map to PracticeDrill, parsing JSON fields
  PracticeDrill _drillFromDbMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>>? movements;
    if (map['movements'] != null && map['movements'] is String) {
      final decoded = json.decode(map['movements'] as String);
      movements = (decoded as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    List<Map<String, dynamic>>? positions;
    if (map['positions'] != null && map['positions'] is String) {
      final decoded = json.decode(map['positions'] as String);
      positions = (decoded as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return PracticeDrill(
      id: map['id'] as String,
      tacticShortName: map['tactic_short_name'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      duration: map['duration'] as String?,
      difficulty: map['difficulty'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      movements: movements,
      positions: positions,
    );
  }

  /// Check if drills exist for a tactic
  Future<bool> hasDrills(String tacticShortName) async {
    final maps = await _db.query(
      _tableName,
      where: 'tactic_short_name = ?',
      whereArgs: [tacticShortName],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// Save drills for a tactic (replaces existing)
  Future<void> saveDrills(String tacticShortName, List<PracticeDrill> drills) async {
    final db = await _db.database;

    // Delete existing drills for this tactic
    await db.delete(
      _tableName,
      where: 'tactic_short_name = ?',
      whereArgs: [tacticShortName],
    );

    // Insert new drills
    for (var i = 0; i < drills.length; i++) {
      final drill = drills[i];
      await db.insert(
        _tableName,
        _drillToDbMap(drill, tacticShortName, i),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Add drills to existing drills for a tactic (doesn't delete existing)
  Future<void> addDrills(String tacticShortName, List<PracticeDrill> drills) async {
    final db = await _db.database;

    // Get current max order_index
    final result = await db.rawQuery(
      'SELECT MAX(order_index) as max_index FROM $_tableName WHERE tactic_short_name = ?',
      [tacticShortName],
    );
    final maxIndex = (result.first['max_index'] as int?) ?? -1;

    // Insert new drills after existing ones
    for (var i = 0; i < drills.length; i++) {
      final drill = drills[i];
      await db.insert(
        _tableName,
        _drillToDbMap(drill, tacticShortName, maxIndex + 1 + i),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Convert PracticeDrill to DB map, encoding JSON fields
  Map<String, dynamic> _drillToDbMap(PracticeDrill drill, String tacticShortName, int orderIndex) {
    return {
      'id': drill.id.isEmpty ? _uuid.v4() : drill.id,
      'tactic_short_name': tacticShortName,
      'title': drill.title,
      'description': drill.description,
      'duration': drill.duration,
      'difficulty': drill.difficulty,
      'order_index': orderIndex,
      'created_at': drill.createdAt.millisecondsSinceEpoch,
      'movements': drill.movements != null ? json.encode(drill.movements) : null,
      'positions': drill.positions != null ? json.encode(drill.positions) : null,
    };
  }

  /// Delete all drills for a tactic
  Future<void> deleteDrillsForTactic(String tacticShortName) async {
    await _db.delete(
      _tableName,
      where: 'tactic_short_name = ?',
      whereArgs: [tacticShortName],
    );
  }

  /// Get all drills
  Future<List<PracticeDrill>> getAllDrills() async {
    final maps = await _db.query(
      _tableName,
      orderBy: 'tactic_short_name, order_index ASC',
    );
    return maps.map((map) => _drillFromDbMap(map)).toList();
  }
}
