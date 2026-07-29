import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../repositories/ai_tactic_repository.dart';
import '../repositories/match_repository.dart';
import '../repositories/conversation_repository.dart';
import '../repositories/user_profile_repository.dart';
import '../repositories/opponent_repository.dart';
import '../repositories/play_adjustment_repository.dart';
import '../repositories/practice_drill_repository.dart';
import '../repositories/supabase_repository.dart';
import '../services/database_service.dart';
import 'auth_service.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final AuthService _authService = AuthService();
  final MatchRepository _matchRepository = MatchRepository();
  final ConversationRepository _conversationRepository =
      ConversationRepository();
  final UserProfileRepository _userProfileRepository = UserProfileRepository();
  final OpponentRepository _opponentRepository = OpponentRepository();
  final PlayAdjustmentRepository _playAdjustmentRepository =
      PlayAdjustmentRepository();
  final AiTacticRepository _aiTacticRepository = AiTacticRepository();
  final PracticeDrillRepository _practiceDrillRepository =
      PracticeDrillRepository();
  final SupabaseRepository _supabaseRepository = SupabaseRepository();
  final DatabaseService _databaseService = DatabaseService.instance;

  SyncStatus _status = SyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;

  // Listeners for sync status changes
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  SyncStatus get status => _status;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if user is authenticated and can sync
  bool get canSync => _authService.isSignedIn;

  /// Perform full bidirectional sync
  Future<void> syncAll() async {
    if (!canSync) {
      throw Exception('User not authenticated. Please sign in to sync.');
    }

    _status = SyncStatus.syncing;
    _lastError = null;

    try {
      debugPrint('🔄 Starting full sync...');

      // Step 1: Get current user ID
      final userId = _authService.currentUserId!;

      // Step 2: Upload local data that hasn't been synced
      await _uploadLocalData(userId);

      // Step 3: Download remote data
      await _downloadRemoteData(userId);

      // Step 4: Mark sync as complete
      _lastSyncTime = DateTime.now();
      _status = SyncStatus.success;
      _notifyListeners();
      debugPrint('✅ Sync completed successfully');
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      _notifyListeners();
      debugPrint('❌ Sync failed: $e');
      rethrow;
    }
  }

  /// Upload local data to Supabase
  Future<void> _uploadLocalData(String userId) async {
    debugPrint('⬆️  Uploading local data...');

    // Get all local data
    debugPrint('📦 Fetching local matches...');
    final localMatches = await _matchRepository.getAllMatches();
    debugPrint('📦 Fetching local conversations...');
    final localConversations = await _conversationRepository.getAllConversations();
    debugPrint('📦 Fetching local user profile...');
    final localUserProfile = await _userProfileRepository.getProfile();
    debugPrint('📦 Fetching local opponents...');
    final localOpponents = await _opponentRepository.getAllOpponents();
    debugPrint('📦 Fetching local adjustments...');
    final localAdjustments = await _playAdjustmentRepository.getAllAdjustments();
    debugPrint('📦 Fetching local AI tactics...');
    final localAiTactics = await _aiTacticRepository.getTacticsForAllMatches();
    debugPrint('📦 Fetching local practice drills...');
    final localPracticeDrills = await _practiceDrillRepository.getAllDrills();

    // Get conversation IDs to fetch messages
    final conversationIds = localConversations.map((c) => c.id).toList();
    List<Message> allMessages = [];
    for (var convId in conversationIds) {
      final messages = await _conversationRepository.getMessagesByConversationId(convId);
      allMessages.addAll(messages);
    }

    // Update user_id for all local data
    final db = await _databaseService.database;
    await db.update(
      'matches',
      {'user_id': userId},
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [''],
    );
    await db.update(
      'conversations',
      {'user_id': userId},
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [''],
    );
    await db.update(
      'messages',
      {'user_id': userId},
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [''],
    );
    await db.update(
      'user_profile',
      {'user_id': userId},
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [''],
    );
    await db.update(
      'opponents',
      {'user_id': userId},
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [''],
    );
    await db.update(
      'play_adjustments',
      {'user_id': userId},
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [''],
    );
    await db.update(
      'ai_tactics',
      {'user_id': userId},
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [''],
    );
    await db.update(
      'practice_drills',
      {'user_id': userId},
      where: 'user_id IS NULL OR user_id = ?',
      whereArgs: [''],
    );

    // Upload to Supabase
    await _supabaseRepository.uploadAll(
      matches: localMatches,
      conversations: localConversations,
      messages: allMessages,
      userProfile: localUserProfile,
      opponents: localOpponents,
      playAdjustments: localAdjustments,
      aiTactics: localAiTactics,
      practiceDrills: localPracticeDrills,
    );

    // Update last_synced timestamps
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var match in localMatches) {
      await db.update(
        'matches',
        {'last_synced': now},
        where: 'id = ?',
        whereArgs: [match.id],
      );
    }
    for (var conv in localConversations) {
      await db.update(
        'conversations',
        {'last_synced': now},
        where: 'id = ?',
        whereArgs: [conv.id],
      );
    }
    for (var msg in allMessages) {
      await db.update(
        'messages',
        {'last_synced': now},
        where: 'id = ?',
        whereArgs: [msg.id],
      );
    }

    debugPrint('✅ Uploaded ${localMatches.length} matches, '
        '${localConversations.length} conversations, '
        '${allMessages.length} messages, '
        '${localUserProfile != null ? 1 : 0} user profile, '
        '${localOpponents.length} opponents, '
        '${localAdjustments.length} adjustments, '
        '${localAiTactics.length} ai tactics, '
        '${localPracticeDrills.length} practice drills');
  }

  /// Download remote data from Supabase
  Future<void> _downloadRemoteData(String userId) async {
    debugPrint('⬇️  Downloading remote data...');

    // Download from Supabase
    final remoteMatches = await _supabaseRepository.downloadMatches();
    final remoteConversations = await _supabaseRepository.downloadConversations();
    final remoteMessages = await _supabaseRepository.downloadAllMessages();
    final remoteUserProfile = await _supabaseRepository.downloadUserProfile();
    final remoteOpponents = await _supabaseRepository.downloadOpponents();
    final remoteAdjustments = await _supabaseRepository.downloadPlayAdjustments();
    final remoteAiTactics = await _supabaseRepository.downloadAiTactics();
    final remotePracticeDrills = await _supabaseRepository.downloadPracticeDrills();

    // Get local data for comparison
    final localMatches = await _matchRepository.getAllMatches();
    final localConversations = await _conversationRepository.getAllConversations();
    final localUserProfile = await _userProfileRepository.getProfile();
    final localOpponents = await _opponentRepository.getAllOpponents();
    final localAdjustments = await _playAdjustmentRepository.getAllAdjustments();
    final localAiTactics = await _aiTacticRepository.getTacticsForAllMatches();
    final localPracticeDrills = await _practiceDrillRepository.getAllDrills();

    final localMatchIds = localMatches.map((m) => m.id).toSet();
    final localConvIds = localConversations.map((c) => c.id).toSet();
    final localOpponentIds = localOpponents.map((o) => o.id).toSet();
    final localAdjustmentIds = localAdjustments.map((a) => a.id).toSet();
    final localAiTacticIds = localAiTactics.map((t) => t.id).toSet();
    final localPracticeDrillIds = localPracticeDrills.map((d) => d.id).toSet();

    // Find new items to insert
    final newMatches = remoteMatches.where((m) => !localMatchIds.contains(m.id)).toList();
    final newConversations = remoteConversations.where((c) => !localConvIds.contains(c.id)).toList();
    final newOpponents = remoteOpponents.where((o) => !localOpponentIds.contains(o.id)).toList();
    final newAdjustments = remoteAdjustments.where((a) => !localAdjustmentIds.contains(a.id)).toList();
    final newAiTactics = remoteAiTactics.where((t) => !localAiTacticIds.contains(t.id)).toList();
    final newPracticeDrills = remotePracticeDrills.where((d) => !localPracticeDrillIds.contains(d.id)).toList();

    // Insert new data into local database
    final db = await _databaseService.database;

    // Download user profile (upsert - replace if exists)
    if (remoteUserProfile != null) {
      final map = remoteUserProfile.toMap();
      map['user_id'] = userId;
      // Use rawInsert with ON CONFLICT to handle both insert and update
      final columns = map.keys.join(', ');
      final placeholders = map.keys.map((_) => '?').join(', ');
      final updateSet = map.keys.where((k) => k != 'id').map((k) => '$k = excluded.$k').join(', ');
      await db.rawInsert(
        'INSERT INTO user_profile ($columns) VALUES ($placeholders) ON CONFLICT(id) DO UPDATE SET $updateSet',
        map.values.toList(),
      );
    }

    // Download opponents
    for (var opponent in newOpponents) {
      final map = opponent.toMap();
      map['user_id'] = userId;
      await db.insert('opponents', map);
    }

    for (var match in newMatches) {
      final map = match.toMap();
      map['user_id'] = userId;
      map['last_synced'] = DateTime.now().millisecondsSinceEpoch;
      await db.insert('matches', map);
    }

    for (var conversation in newConversations) {
      final map = conversation.toMap();
      map['user_id'] = userId;
      map['last_synced'] = DateTime.now().millisecondsSinceEpoch;
      await db.insert('conversations', map);
    }

    // Insert messages for new conversations
    for (var message in remoteMessages) {
      // Check if message already exists
      final existing = await db.query(
        'messages',
        where: 'id = ?',
        whereArgs: [message.id],
      );

      if (existing.isEmpty) {
        final map = message.toMap();
        map['user_id'] = userId;
        map['last_synced'] = DateTime.now().millisecondsSinceEpoch;
        await db.insert('messages', map);
      }
    }

    // Download play adjustments
    for (var adjustment in newAdjustments) {
      final map = adjustment.toMap();
      map['user_id'] = userId;
      await db.insert('play_adjustments', map);
    }

    // Download AI tactics
    for (var tactic in newAiTactics) {
      final map = tactic.toMap();
      map['user_id'] = userId;
      await db.insert('ai_tactics', map);
    }

    // Download practice drills
    for (var drill in newPracticeDrills) {
      final map = drill.toMap();
      map['user_id'] = userId;
      // Encode movements and positions as JSON strings for SQLite
      if (map['movements'] != null && map['movements'] is! String) {
        map['movements'] = json.encode(map['movements']);
      }
      if (map['positions'] != null && map['positions'] is! String) {
        map['positions'] = json.encode(map['positions']);
      }
      await db.insert('practice_drills', map);
    }

    debugPrint('✅ Downloaded ${newMatches.length} new matches, '
        '${newConversations.length} new conversations, '
        '${remoteMessages.length} messages, '
        '${remoteUserProfile != null && localUserProfile == null ? 1 : 0} user profile, '
        '${newOpponents.length} opponents, '
        '${newAdjustments.length} adjustments, '
        '${newAiTactics.length} ai tactics, '
        '${newPracticeDrills.length} practice drills');
  }

  /// Quick sync - only upload new/modified local data
  Future<void> quickSync() async {
    if (!canSync) {
      throw Exception('User not authenticated. Please sign in to sync.');
    }

    _status = SyncStatus.syncing;
    _lastError = null;

    try {
      debugPrint('🔄 Starting quick sync...');

      final userId = _authService.currentUserId!;
      await _uploadLocalData(userId);

      _lastSyncTime = DateTime.now();
      _status = SyncStatus.success;
      _notifyListeners();
      debugPrint('✅ Quick sync completed');
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      _notifyListeners();
      debugPrint('❌ Quick sync failed: $e');
      rethrow;
    }
  }

  /// Clear local data and download fresh from cloud
  Future<void> pullFromCloud() async {
    if (!canSync) {
      throw Exception('User not authenticated. Please sign in to sync.');
    }

    _status = SyncStatus.syncing;
    _lastError = null;

    try {
      debugPrint('🔄 Pulling data from cloud...');

      // Clear local data
      await _databaseService.clearAllData();

      // Download from cloud
      final userId = _authService.currentUserId!;
      await _downloadRemoteData(userId);

      _lastSyncTime = DateTime.now();
      _status = SyncStatus.success;
      _notifyListeners();
      debugPrint('✅ Pull from cloud completed');
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      _notifyListeners();
      debugPrint('❌ Pull from cloud failed: $e');
      rethrow;
    }
  }

  /// Upload all local data to cloud (overwrite)
  Future<void> pushToCloud() async {
    if (!canSync) {
      throw Exception('User not authenticated. Please sign in to sync.');
    }

    _status = SyncStatus.syncing;
    _lastError = null;

    try {
      debugPrint('🔄 Pushing data to cloud...');

      final userId = _authService.currentUserId!;
      await _uploadLocalData(userId);

      _lastSyncTime = DateTime.now();
      _status = SyncStatus.success;
      _notifyListeners();
      debugPrint('✅ Push to cloud completed');
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
      _notifyListeners();
      debugPrint('❌ Push to cloud failed: $e');
      rethrow;
    }
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncInfo() async {
    if (!canSync) {
      return {
        'canSync': false,
        'lastSync': null,
        'status': 'Not signed in',
      };
    }

    // Get local counts
    final localMatches = await _matchRepository.getMatchCount();
    final localConversations = await _conversationRepository.getConversationCount();
    final localMessages = await _databaseService.getTableCount('messages');
    final localUserProfile = await _userProfileRepository.getProfile() != null ? 1 : 0;
    final localOpponents = (await _opponentRepository.getAllOpponents()).length;
    final localAdjustments = (await _playAdjustmentRepository.getAllAdjustments()).length;
    final localAiTactics = (await _aiTacticRepository.getTacticsForAllMatches()).length;
    final localPracticeDrills = (await _practiceDrillRepository.getAllDrills()).length;

    final local = {
      'matches': localMatches,
      'conversations': localConversations,
      'messages': localMessages,
      'user_profile': localUserProfile,
      'opponents': localOpponents,
      'play_adjustments': localAdjustments,
      'ai_tactics': localAiTactics,
      'practice_drills': localPracticeDrills,
    };

    Map<String, int>? remote;
    try {
      remote = await _supabaseRepository.getSyncStatistics();
    } catch (e) {
      remote = null;
    }

    return {
      'canSync': true,
      'lastSync': _lastSyncTime,
      'status': _status.toString().split('.').last,
      'local': local,
      'remote': remote,
      'lastError': _lastError,
    };
  }
}
