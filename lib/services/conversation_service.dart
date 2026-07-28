import 'package:uuid/uuid.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../repositories/conversation_repository.dart';
import 'gemini_service.dart';

class ConversationService {
  final ConversationRepository _repository = ConversationRepository();
  final Uuid _uuid = const Uuid();

  /// Creates a new conversation and returns its ID
  Future<String> createConversation({
    String? matchId,
    String? title,
  }) async {
    final now = DateTime.now();
    final conversation = Conversation(
      id: _uuid.v4(),
      matchId: matchId,
      title: title,
      createdAt: now,
      updatedAt: now,
    );

    print('Creating conversation: id=${conversation.id}, matchId=$matchId, title=$title');
    await _repository.createConversation(conversation);
    print('Conversation created successfully');
    return conversation.id;
  }

  /// Loads a conversation from database and sets it in GeminiService
  Future<void> loadConversation(String conversationId, GeminiService geminiService) async {
    final messages = await _repository.getMessagesByConversationId(conversationId);

    // Convert database messages to GeminiService format
    final history = messages.map((msg) => {
      'role': msg.role,
      'content': msg.content,
    }).toList();

    // Set the history in GeminiService
    geminiService.setHistory(history);
    geminiService.setConversationId(conversationId);
  }

  /// Auto-saves the current conversation from GeminiService to database
  Future<void> autoSave(GeminiService geminiService) async {
    final conversationId = geminiService.conversationId;
    if (conversationId == null) {
      throw Exception('No conversation ID set in GeminiService');
    }

    print('AutoSave: conversationId=$conversationId');

    // Get conversation history from GeminiService
    final history = geminiService.conversationHistory;
    print('AutoSave: total history length=${history.length}');

    // Filter out messages with non-string content (tool use messages)
    // Only save text messages that can be displayed to the user
    final textMessages = history.where((msg) {
      final content = msg['content'];
      return content is String;
    }).toList();
    print('AutoSave: text messages in history=${textMessages.length}');

    // Get existing messages from database
    final existingMessages = await _repository.getMessagesByConversationId(conversationId);
    final existingCount = existingMessages.length;
    print('AutoSave: existing messages in DB=$existingCount');

    // Only save new text messages (messages added since last save)
    if (textMessages.length > existingCount) {
      final newMessages = textMessages.sublist(existingCount);
      print('AutoSave: saving ${newMessages.length} new messages');

      final messagesToSave = newMessages.map((msg) {
        return Message(
          id: _uuid.v4(),
          conversationId: conversationId,
          role: msg['role'] as String,
          content: msg['content'] as String,
          timestamp: DateTime.now(),
          isError: false,
        );
      }).toList();

      // Save new messages to database
      await _repository.saveMessages(messagesToSave);
      print('AutoSave: messages saved');

      // Update conversation's updated_at timestamp
      final conversation = await _repository.getConversationById(conversationId);
      if (conversation != null) {
        print('AutoSave: updating conversation timestamp, title="${conversation.title}"');
        await _repository.updateConversation(
          conversation.copyWith(updatedAt: DateTime.now()),
        );
        print('AutoSave: conversation updated');
      } else {
        print('AutoSave: WARNING - conversation not found in DB!');
      }
    } else {
      print('AutoSave: no new messages to save');
    }
  }

  /// Saves all messages from GeminiService to a new or existing conversation
  Future<void> persistAllMessages(
    GeminiService geminiService, {
    String? conversationId,
    String? matchId,
    String? title,
  }) async {
    String convId;

    // Create new conversation if no ID provided
    if (conversationId == null) {
      convId = await createConversation(matchId: matchId, title: title);
      geminiService.setConversationId(convId);
    } else {
      convId = conversationId;
    }

    // Delete existing messages to avoid duplicates
    await _repository.deleteMessagesForConversation(convId);

    // Save all messages
    final history = geminiService.conversationHistory;
    final messages = history.map((msg) {
      return Message(
        id: _uuid.v4(),
        conversationId: convId,
        role: msg['role'] as String,
        content: msg['content'] as String,
        timestamp: DateTime.now(),
        isError: false,
      );
    }).toList();

    await _repository.saveMessages(messages);

    // Update conversation timestamp
    final conversation = await _repository.getConversationById(convId);
    if (conversation != null) {
      await _repository.updateConversation(
        conversation.copyWith(updatedAt: DateTime.now()),
      );
    }
  }

  /// Deletes a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    await _repository.deleteConversation(conversationId);
  }

  /// Gets all conversations
  Future<List<Conversation>> getAllConversations() async {
    return await _repository.getAllConversations();
  }

  /// Gets conversations for a specific match
  Future<List<Conversation>> getConversationsForMatch(String matchId) async {
    return await _repository.getConversationsByMatchId(matchId);
  }

  /// Gets standalone conversations (not linked to any match)
  Future<List<Conversation>> getStandaloneConversations() async {
    return await _repository.getStandaloneConversations();
  }

  /// Links an existing conversation to a match
  Future<void> linkToMatch(String conversationId, String matchId) async {
    await _repository.linkConversationToMatch(conversationId, matchId);
  }

  /// Unlinks a conversation from its match
  Future<void> unlinkFromMatch(String conversationId) async {
    await _repository.unlinkConversationFromMatch(conversationId);
  }

  /// Gets a conversation by ID
  Future<Conversation?> getConversationById(String id) async {
    return await _repository.getConversationById(id);
  }

  /// Updates conversation title
  Future<void> updateTitle(String conversationId, String newTitle) async {
    final conversation = await _repository.getConversationById(conversationId);
    if (conversation != null) {
      await _repository.updateConversation(
        conversation.copyWith(
          title: newTitle,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Gets message count for a conversation
  Future<int> getMessageCount(String conversationId) async {
    return await _repository.getMessageCount(conversationId);
  }

  /// Gets total conversation count
  Future<int> getTotalConversationCount() async {
    return await _repository.getConversationCount();
  }

  /// Generates a sensible title from the first user message
  String generateTitleFromMessage(String message) {
    // Clean the message
    String cleaned = message.trim();

    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // If message is short enough, use it as is
    if (cleaned.length <= 50) {
      return cleaned;
    }

    // Try to find a natural break point (sentence end, question mark, etc.)
    final firstSentence = RegExp(r'^[^.!?]+[.!?]').firstMatch(cleaned);
    if (firstSentence != null) {
      final sentence = firstSentence.group(0)!;
      if (sentence.length <= 50) {
        return sentence.trim();
      }
    }

    // Truncate at word boundary
    if (cleaned.length > 47) {
      final lastSpace = cleaned.lastIndexOf(' ', 47);
      if (lastSpace > 30) {
        return '${cleaned.substring(0, lastSpace)}...';
      }
    }

    // Fallback: hard truncate
    return '${cleaned.substring(0, 47)}...';
  }

  /// Auto-generates and updates title if conversation doesn't have one
  Future<void> ensureConversationHasTitle(String conversationId) async {
    print('EnsureTitle: conversationId=$conversationId');

    final conversation = await _repository.getConversationById(conversationId);
    if (conversation == null) {
      print('EnsureTitle: conversation not found');
      return;
    }

    print('EnsureTitle: current title="${conversation.title}"');

    // Get the messages to summarize
    final messages = await _repository.getMessagesByConversationId(conversationId);
    print('EnsureTitle: found ${messages.length} messages');

    if (messages.isEmpty) {
      print('EnsureTitle: no messages found, cannot generate title');
      return;
    }

    // Generate AI summary title
    await generateAITitle(conversationId, messages);
  }

  /// Uses AI to generate a 2-3 word summary title for the conversation
  Future<void> generateAITitle(String conversationId, List<Message> messages) async {
    try {
      final geminiService = await GeminiService.fromConfig();
      if (geminiService == null) {
        print('GenerateAITitle: Gemini service not available, using fallback');
        await _generateFallbackTitle(conversationId, messages);
        return;
      }

      // Build a summary of the conversation (first few exchanges)
      final conversationSummary = StringBuffer();
      final messagesToSummarize = messages.take(6); // First 3 exchanges
      for (final msg in messagesToSummarize) {
        conversationSummary.write('${msg.role}: ${msg.content}\n\n');
      }

      final response = await geminiService.sendMessageWithSystem(
        message: conversationSummary.toString(),
        systemPrompt: '''Generate a 2-3 word title that summarizes this tennis tactics conversation.
Rules:
- Exactly 2-3 words
- Focus on the main topic/tactic discussed
- No punctuation
- Be specific (e.g., "Backhand Defense Strategy" not "Tennis Tactics")

Reply with ONLY the 2-3 word title, nothing else.''',
        maxTokens: 20,
        temperature: 0.3,
        addToHistory: false,
      );

      if (response['success'] == true) {
        String title = (response['message'] as String).trim();
        // Clean up the title - remove quotes, extra whitespace
        if (title.startsWith('"') || title.startsWith("'")) {
          title = title.substring(1);
        }
        if (title.endsWith('"') || title.endsWith("'")) {
          title = title.substring(0, title.length - 1);
        }
        title = title.trim();
        // Limit to reasonable length
        if (title.length > 40) {
          title = title.substring(0, 40);
        }

        print('GenerateAITitle: AI generated title="$title"');

        final conversation = await _repository.getConversationById(conversationId);
        if (conversation != null) {
          await _repository.updateConversation(
            conversation.copyWith(title: title),
          );
          print('GenerateAITitle: title updated successfully');
        }
      } else {
        print('GenerateAITitle: AI failed, using fallback');
        await _generateFallbackTitle(conversationId, messages);
      }
    } catch (e) {
      print('GenerateAITitle: Error: $e, using fallback');
      await _generateFallbackTitle(conversationId, messages);
    }
  }

  /// Fallback title generation when AI is not available
  Future<void> _generateFallbackTitle(String conversationId, List<Message> messages) async {
    final firstUserMessage = messages.firstWhere(
      (msg) => msg.role == 'user',
      orElse: () => messages.first,
    );

    final title = generateTitleFromMessage(firstUserMessage.content);
    print('FallbackTitle: generated title="$title"');

    final conversation = await _repository.getConversationById(conversationId);
    if (conversation != null) {
      await _repository.updateConversation(
        conversation.copyWith(title: title),
      );
    }
  }
}
