import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_tactic.dart';
import '../models/match.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../models/opponent.dart';
import '../models/play_adjustment.dart';
import '../models/practice_drill.dart';

class SupabaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ==================== HELPER METHODS ====================

  /// Convert milliseconds since epoch to ISO 8601 string for Supabase
  String? _timestampToISO(int? milliseconds) {
    if (milliseconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds).toUtc().toIso8601String();
  }

  /// Convert Match from SQLite format to Supabase format
  Map<String, dynamic> _matchToSupabaseMap(Match match) {
    final map = match.toMap();

    // Convert BIGINT timestamps to ISO 8601 strings
    map['match_date'] = _timestampToISO(map['match_date'] as int?);
    map['created_at'] = _timestampToISO(map['created_at'] as int);
    map['updated_at'] = _timestampToISO(map['updated_at'] as int);

    // Remove last_synced (managed by Supabase)
    map.remove('last_synced');

    return map;
  }

  /// Convert Conversation from SQLite format to Supabase format
  Map<String, dynamic> _conversationToSupabaseMap(Conversation conversation) {
    final map = conversation.toMap();

    // Convert BIGINT timestamps to ISO 8601 strings
    map['created_at'] = _timestampToISO(map['created_at'] as int);
    map['updated_at'] = _timestampToISO(map['updated_at'] as int);

    // Remove last_synced (managed by Supabase)
    map.remove('last_synced');

    return map;
  }

  /// Convert Message from SQLite format to Supabase format
  Map<String, dynamic> _messageToSupabaseMap(Message message) {
    final map = message.toMap();

    // Convert BIGINT timestamp to ISO 8601 string
    map['timestamp'] = _timestampToISO(map['timestamp'] as int);

    // Convert INTEGER (0/1) to BOOLEAN
    final isError = map['is_error'];
    if (isError is int) {
      map['is_error'] = isError != 0;
    }

    // Remove last_synced (managed by Supabase)
    map.remove('last_synced');

    return map;
  }

  // ==================== MATCHES ====================

  /// Upload matches to Supabase
  Future<void> uploadMatches(List<Match> matches) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final data = matches.map((match) {
        final map = _matchToSupabaseMap(match);
        map['user_id'] = currentUserId;
        return map;
      }).toList();

      debugPrint('🔼 Uploading ${data.length} matches to Supabase...');
      await _supabase.from('matches').upsert(data);
      debugPrint('✅ Matches uploaded successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading matches: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download all matches from Supabase
  Future<List<Match>> downloadMatches() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('matches')
        .select()
        .eq('user_id', currentUserId!)
        .order('match_date', ascending: false);

    return (response as List).map((json) => Match.fromMap(json)).toList();
  }

  /// Delete match from Supabase
  Future<void> deleteMatch(String matchId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase
        .from('matches')
        .delete()
        .eq('id', matchId)
        .eq('user_id', currentUserId!);
  }

  // ==================== CONVERSATIONS ====================

  /// Upload conversations to Supabase
  Future<void> uploadConversations(List<Conversation> conversations) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final data = conversations.map((conversation) {
        final map = _conversationToSupabaseMap(conversation);
        map['user_id'] = currentUserId;
        return map;
      }).toList();

      debugPrint('🔼 Uploading ${data.length} conversations to Supabase...');
      await _supabase.from('conversations').upsert(data);
      debugPrint('✅ Conversations uploaded successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading conversations: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download all conversations from Supabase
  Future<List<Conversation>> downloadConversations() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('conversations')
        .select()
        .eq('user_id', currentUserId!)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Conversation.fromMap(json))
        .toList();
  }

  /// Delete conversation from Supabase
  Future<void> deleteConversation(String conversationId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase
        .from('conversations')
        .delete()
        .eq('id', conversationId)
        .eq('user_id', currentUserId!);
  }

  // ==================== MESSAGES ====================

  /// Upload messages to Supabase
  Future<void> uploadMessages(List<Message> messages) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final data = messages.map((message) {
        final map = _messageToSupabaseMap(message);
        map['user_id'] = currentUserId;
        return map;
      }).toList();

      debugPrint('🔼 Uploading ${data.length} messages to Supabase...');
      await _supabase.from('messages').upsert(data);
      debugPrint('✅ Messages uploaded successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading messages: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download messages for specific conversations
  Future<List<Message>> downloadMessages(List<String> conversationIds) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    if (conversationIds.isEmpty) return [];

    final response = await _supabase
        .from('messages')
        .select()
        .eq('user_id', currentUserId!)
        .inFilter('conversation_id', conversationIds)
        .order('timestamp', ascending: true);

    return (response as List).map((json) => Message.fromMap(json)).toList();
  }

  /// Download all messages from Supabase (for full sync)
  Future<List<Message>> downloadAllMessages() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('messages')
        .select()
        .eq('user_id', currentUserId!)
        .order('timestamp', ascending: true);

    return (response as List).map((json) => Message.fromMap(json)).toList();
  }

  // ==================== USER PROFILE ====================

  /// Convert UserProfile from SQLite format to Supabase format
  Map<String, dynamic> _userProfileToSupabaseMap(UserProfile profile) {
    final map = profile.toMap();

    // Convert BIGINT timestamps to ISO 8601 strings
    map['created_at'] = _timestampToISO(map['created_at'] as int);
    map['updated_at'] = _timestampToISO(map['updated_at'] as int);

    return map;
  }

  /// Upload user profile to Supabase
  Future<void> uploadUserProfile(UserProfile profile) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final map = _userProfileToSupabaseMap(profile);
      // Use the Supabase user_id as the profile id (instead of local "me")
      map['id'] = currentUserId;
      map['user_id'] = currentUserId;

      debugPrint('🔼 Uploading user profile to Supabase...');
      debugPrint('   Profile data: $map');
      await _supabase.from('user_profile').upsert(map);
      debugPrint('✅ User profile uploaded successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading user profile: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download user profile from Supabase
  Future<UserProfile?> downloadUserProfile() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('user_profile')
        .select()
        .eq('user_id', currentUserId!)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromMap(response);
  }

  // ==================== OPPONENTS ====================

  /// Convert Opponent from SQLite format to Supabase format
  Map<String, dynamic> _opponentToSupabaseMap(Opponent opponent) {
    final map = opponent.toMap();

    // Convert BIGINT timestamps to ISO 8601 strings
    map['created_at'] = _timestampToISO(map['created_at'] as int);
    map['updated_at'] = _timestampToISO(map['updated_at'] as int);

    return map;
  }

  /// Upload opponents to Supabase
  Future<void> uploadOpponents(List<Opponent> opponents) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final data = opponents.map((opponent) {
        final map = _opponentToSupabaseMap(opponent);
        map['user_id'] = currentUserId;
        return map;
      }).toList();

      if (data.isNotEmpty) {
        debugPrint('🔼 Uploading ${data.length} opponents to Supabase...');
        await _supabase.from('opponents').upsert(data);
        debugPrint('✅ Opponents uploaded successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading opponents: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download all opponents from Supabase
  Future<List<Opponent>> downloadOpponents() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('opponents')
        .select()
        .eq('user_id', currentUserId!)
        .order('name', ascending: true);

    return (response as List).map((json) => Opponent.fromMap(json)).toList();
  }

  /// Delete opponent from Supabase
  Future<void> deleteOpponent(String opponentId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase
        .from('opponents')
        .delete()
        .eq('id', opponentId)
        .eq('user_id', currentUserId!);
  }

  // ==================== PLAY ADJUSTMENTS ====================

  /// Convert PlayAdjustment from SQLite format to Supabase format
  Map<String, dynamic> _playAdjustmentToSupabaseMap(PlayAdjustment adjustment) {
    final map = adjustment.toMap();

    // Convert BIGINT timestamp to ISO 8601 string
    map['created_at'] = _timestampToISO(map['created_at'] as int);

    return map;
  }

  /// Upload play adjustments to Supabase
  Future<void> uploadPlayAdjustments(List<PlayAdjustment> adjustments) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final data = adjustments.map((adjustment) {
        final map = _playAdjustmentToSupabaseMap(adjustment);
        map['user_id'] = currentUserId;
        return map;
      }).toList();

      if (data.isNotEmpty) {
        debugPrint('🔼 Uploading ${data.length} play adjustments to Supabase...');
        await _supabase.from('play_adjustments').upsert(data);
        debugPrint('✅ Play adjustments uploaded successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading play adjustments: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download all play adjustments from Supabase
  Future<List<PlayAdjustment>> downloadPlayAdjustments() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('play_adjustments')
        .select()
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false);

    return (response as List).map((json) => PlayAdjustment.fromMap(json)).toList();
  }

  /// Delete play adjustment from Supabase
  Future<void> deletePlayAdjustment(String adjustmentId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase
        .from('play_adjustments')
        .delete()
        .eq('id', adjustmentId)
        .eq('user_id', currentUserId!);
  }

  // ==================== AI TACTICS ====================

  /// Convert AiTactic from SQLite format to Supabase format
  Map<String, dynamic> _aiTacticToSupabaseMap(AiTactic tactic) {
    final map = tactic.toMap();

    // Convert BIGINT timestamp to ISO 8601 string
    map['created_at'] = _timestampToISO(map['created_at'] as int);

    return map;
  }

  /// Upload AI tactics to Supabase
  Future<void> uploadAiTactics(List<AiTactic> tactics) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final data = tactics.map((tactic) {
        final map = _aiTacticToSupabaseMap(tactic);
        map['user_id'] = currentUserId;
        return map;
      }).toList();

      if (data.isNotEmpty) {
        debugPrint('🔼 Uploading ${data.length} AI tactics to Supabase...');
        await _supabase.from('ai_tactics').upsert(data);
        debugPrint('✅ AI tactics uploaded successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading AI tactics: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download all AI tactics from Supabase
  Future<List<AiTactic>> downloadAiTactics() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('ai_tactics')
        .select()
        .eq('user_id', currentUserId!)
        .order('created_at', ascending: false);

    return (response as List).map((json) => AiTactic.fromMap(json)).toList();
  }

  /// Delete AI tactic from Supabase
  Future<void> deleteAiTactic(String tacticId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase
        .from('ai_tactics')
        .delete()
        .eq('id', tacticId)
        .eq('user_id', currentUserId!);
  }

  // ==================== PRACTICE DRILLS ====================

  /// Convert PracticeDrill from SQLite format to Supabase format
  Map<String, dynamic> _practiceDrillToSupabaseMap(PracticeDrill drill) {
    return {
      'id': drill.id,
      'tactic_short_name': drill.tacticShortName,
      'title': drill.title,
      'description': drill.description,
      'duration': drill.duration,
      'difficulty': drill.difficulty,
      'order_index': drill.orderIndex,
      'created_at': drill.createdAt.toUtc().toIso8601String(),
      'movements': drill.movements != null ? json.encode(drill.movements) : null,
      'positions': drill.positions != null ? json.encode(drill.positions) : null,
    };
  }

  /// Upload practice drills to Supabase
  Future<void> uploadPracticeDrills(List<PracticeDrill> drills) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final data = drills.map((drill) {
        final map = _practiceDrillToSupabaseMap(drill);
        map['user_id'] = currentUserId;
        return map;
      }).toList();

      if (data.isNotEmpty) {
        debugPrint('🔼 Uploading ${data.length} practice drills to Supabase...');
        await _supabase.from('practice_drills').upsert(data);
        debugPrint('✅ Practice drills uploaded successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading practice drills: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Download all practice drills from Supabase
  Future<List<PracticeDrill>> downloadPracticeDrills() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('practice_drills')
        .select()
        .eq('user_id', currentUserId!)
        .order('tactic_short_name', ascending: true)
        .order('order_index', ascending: true);

    return (response as List).map((json) {
      // Parse JSON strings back to lists
      List<Map<String, dynamic>>? movements;
      if (json['movements'] != null) {
        final decoded = json['movements'] is String
            ? jsonDecode(json['movements'] as String)
            : json['movements'];
        movements = (decoded as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      List<Map<String, dynamic>>? positions;
      if (json['positions'] != null) {
        final decoded = json['positions'] is String
            ? jsonDecode(json['positions'] as String)
            : json['positions'];
        positions = (decoded as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      return PracticeDrill(
        id: json['id'] as String,
        tacticShortName: json['tactic_short_name'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        duration: json['duration'] as String?,
        difficulty: json['difficulty'] as String?,
        orderIndex: json['order_index'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        movements: movements,
        positions: positions,
      );
    }).toList();
  }

  /// Delete practice drills for a tactic from Supabase
  Future<void> deletePracticeDrillsForTactic(String tacticShortName) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    await _supabase
        .from('practice_drills')
        .delete()
        .eq('tactic_short_name', tacticShortName)
        .eq('user_id', currentUserId!);
  }

  // ==================== BATCH OPERATIONS ====================

  /// Upload all data (matches, conversations, messages, user_profile, opponents, adjustments, ai_tactics, practice_drills)
  Future<void> uploadAll({
    required List<Match> matches,
    required List<Conversation> conversations,
    required List<Message> messages,
    UserProfile? userProfile,
    List<Opponent>? opponents,
    List<PlayAdjustment>? playAdjustments,
    List<AiTactic>? aiTactics,
    List<PracticeDrill>? practiceDrills,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Upload in order to maintain referential integrity
    // 1. User profile (no dependencies)
    if (userProfile != null) {
      await uploadUserProfile(userProfile);
    }

    // 2. Opponents (no dependencies)
    if (opponents != null && opponents.isNotEmpty) {
      await uploadOpponents(opponents);
    }

    // 3. Matches (no dependencies)
    if (matches.isNotEmpty) {
      await uploadMatches(matches);
    }

    // 4. Conversations (depends on matches)
    if (conversations.isNotEmpty) {
      await uploadConversations(conversations);
    }

    // 5. Messages (depends on conversations)
    if (messages.isNotEmpty) {
      await uploadMessages(messages);
    }

    // 6. Play adjustments (depends on matches)
    if (playAdjustments != null && playAdjustments.isNotEmpty) {
      await uploadPlayAdjustments(playAdjustments);
    }

    // 7. AI tactics (depends on conversations and matches)
    if (aiTactics != null && aiTactics.isNotEmpty) {
      await uploadAiTactics(aiTactics);
    }

    // 8. Practice drills (no dependencies)
    if (practiceDrills != null && practiceDrills.isNotEmpty) {
      await uploadPracticeDrills(practiceDrills);
    }
  }

  /// Clear all user data from Supabase
  Future<void> clearAllData() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    // Delete in reverse order to maintain referential integrity
    await _supabase
        .from('messages')
        .delete()
        .eq('user_id', currentUserId!);

    await _supabase
        .from('conversations')
        .delete()
        .eq('user_id', currentUserId!);

    await _supabase
        .from('matches')
        .delete()
        .eq('user_id', currentUserId!);
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStatistics() async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final matchesData = await _supabase
        .from('matches')
        .select()
        .eq('user_id', currentUserId!) as List;

    final conversationsData = await _supabase
        .from('conversations')
        .select()
        .eq('user_id', currentUserId!) as List;

    final messagesData = await _supabase
        .from('messages')
        .select()
        .eq('user_id', currentUserId!) as List;

    final userProfileData = await _supabase
        .from('user_profile')
        .select()
        .eq('user_id', currentUserId!) as List;

    final opponentsData = await _supabase
        .from('opponents')
        .select()
        .eq('user_id', currentUserId!) as List;

    final adjustmentsData = await _supabase
        .from('play_adjustments')
        .select()
        .eq('user_id', currentUserId!) as List;

    final aiTacticsData = await _supabase
        .from('ai_tactics')
        .select()
        .eq('user_id', currentUserId!) as List;

    final practiceDrillsData = await _supabase
        .from('practice_drills')
        .select()
        .eq('user_id', currentUserId!) as List;

    return {
      'matches': matchesData.length,
      'conversations': conversationsData.length,
      'messages': messagesData.length,
      'user_profile': userProfileData.length,
      'opponents': opponentsData.length,
      'play_adjustments': adjustmentsData.length,
      'ai_tactics': aiTacticsData.length,
      'practice_drills': practiceDrillsData.length,
    };
  }
}
