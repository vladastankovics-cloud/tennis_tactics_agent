import '../models/conversation.dart';
import '../models/message.dart';
import '../services/database_service.dart';

class ConversationRepository {
  final DatabaseService _db = DatabaseService.instance;
  static const String _conversationsTable = 'conversations';
  static const String _messagesTable = 'messages';

  // Get all conversations, sorted by updated date (newest first)
  Future<List<Conversation>> getAllConversations() async {
    final maps = await _db.query(
      _conversationsTable,
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Conversation.fromMap(map)).toList();
  }

  // Get conversations linked to a specific match
  Future<List<Conversation>> getConversationsByMatchId(String matchId) async {
    final maps = await _db.query(
      _conversationsTable,
      where: 'match_id = ?',
      whereArgs: [matchId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Conversation.fromMap(map)).toList();
  }

  // Get standalone conversations (not linked to any match)
  Future<List<Conversation>> getStandaloneConversations() async {
    final maps = await _db.query(
      _conversationsTable,
      where: 'match_id IS NULL',
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Conversation.fromMap(map)).toList();
  }

  // Get a single conversation by ID
  Future<Conversation?> getConversationById(String id) async {
    final maps = await _db.query(
      _conversationsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Conversation.fromMap(maps.first);
  }

  // Create a new conversation
  Future<void> createConversation(Conversation conversation) async {
    await _db.insert(_conversationsTable, conversation.toMap());
  }

  // Update an existing conversation
  Future<void> updateConversation(Conversation conversation) async {
    await _db.update(
      _conversationsTable,
      conversation.toMap(),
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  // Delete a conversation (messages will be cascade deleted)
  Future<void> deleteConversation(String id) async {
    await _db.delete(
      _conversationsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all messages for a conversation, sorted by timestamp
  Future<List<Message>> getMessagesByConversationId(String conversationId) async {
    final maps = await _db.query(
      _messagesTable,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => Message.fromMap(map)).toList();
  }

  // Save a single message
  Future<void> saveMessage(Message message) async {
    await _db.insert(_messagesTable, message.toMap());
  }

  // Save multiple messages (batch operation)
  Future<void> saveMessages(List<Message> messages) async {
    for (final message in messages) {
      await saveMessage(message);
    }
  }

  // Delete all messages for a conversation
  Future<void> deleteMessagesForConversation(String conversationId) async {
    await _db.delete(
      _messagesTable,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
  }

  // Get message count for a conversation
  Future<int> getMessageCount(String conversationId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM $_messagesTable WHERE conversation_id = ?',
      [conversationId],
    );
    return result.first['count'] as int;
  }

  // Get total conversation count
  Future<int> getConversationCount() async {
    return await _db.getTableCount(_conversationsTable);
  }

  // Link a conversation to a match
  Future<void> linkConversationToMatch(String conversationId, String matchId) async {
    await _db.update(
      _conversationsTable,
      {
        'match_id': matchId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  // Unlink a conversation from a match
  Future<void> unlinkConversationFromMatch(String conversationId) async {
    await _db.update(
      _conversationsTable,
      {
        'match_id': null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }
}
