import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:tennis_tactics_agent/config/app_config.dart';

class GeminiService {
  final String apiKey;
  final String model;
  late GenerativeModel _model;
  late ChatSession _chat;
  final List<Map<String, dynamic>> _conversationHistory = [];
  String? _conversationId;
  String? _systemPrompt;

  GeminiService({
    required this.apiKey,
    this.model = 'gemini-2.0-flash',
  }) {
    _model = GenerativeModel(
      model: model,
      apiKey: apiKey,
    );
    _chat = _model.startChat();
  }

  /// Factory constructor to create GeminiService from stored configuration
  static Future<GeminiService?> fromConfig() async {
    final config = AppConfig();

    // Check if API key exists
    if (!await config.hasGeminiApiKey()) {
      return null;
    }

    // Get the API key and model
    final apiKey = await config.getGeminiApiKey();
    final model = await config.getGeminiModel();

    if (apiKey == null) {
      return null;
    }

    return GeminiService(
      apiKey: apiKey,
      model: model,
    );
  }

  /// Returns the current conversation history
  List<Map<String, dynamic>> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// Gets the current conversation ID
  String? get conversationId => _conversationId;

  /// Sets the conversation ID for persistence tracking
  void setConversationId(String? id) {
    _conversationId = id;
  }

  /// Adds a message to the conversation history
  void addMessage({
    required String role,
    required String content,
  }) {
    _conversationHistory.add({
      'role': role,
      'content': content,
    });
  }

  /// Clears the conversation history
  void clearHistory() {
    _conversationHistory.clear();
    _chat = _model.startChat();
  }

  /// Removes the last message from conversation history
  void removeLastMessage() {
    if (_conversationHistory.isNotEmpty) {
      _conversationHistory.removeLast();
    }
  }

  /// Sends a message to Gemini API and returns the response
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    int maxTokens = 1024,
    double temperature = 1.0,
    bool addToHistory = true,
  }) async {
    try {
      // Add user message to history if requested
      if (addToHistory) {
        addMessage(role: 'user', content: message);
      }

      // Send message to Gemini
      final response = await _chat.sendMessage(Content.text(message));
      final responseText = response.text ?? '';

      // Add assistant's response to history if requested
      if (addToHistory) {
        addMessage(role: 'assistant', content: responseText);
      }

      return {
        'success': true,
        'message': responseText,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}',
      };
    }
  }

  /// Sends a message with custom system prompt
  Future<Map<String, dynamic>> sendMessageWithSystem({
    required String message,
    required String systemPrompt,
    int maxTokens = 1024,
    double temperature = 1.0,
    bool addToHistory = true,
    bool enableTools = false, // Tools not implemented for Gemini yet
  }) async {
    try {
      // If system prompt changed, recreate the model with new system instruction
      if (_systemPrompt != systemPrompt) {
        _systemPrompt = systemPrompt;
        _model = GenerativeModel(
          model: model,
          apiKey: apiKey,
          systemInstruction: Content.system(systemPrompt),
        );

        // Rebuild chat with existing history
        final history = _conversationHistory.map((msg) {
          if (msg['role'] == 'user') {
            return Content.text(msg['content'] as String);
          } else {
            return Content.model([TextPart(msg['content'] as String)]);
          }
        }).toList();

        _chat = _model.startChat(history: history);
      }

      // Add user message to history if requested
      if (addToHistory) {
        addMessage(role: 'user', content: message);
      }

      // Send message to Gemini
      final response = await _chat.sendMessage(Content.text(message));
      final responseText = response.text ?? '';

      // Add assistant's response to history if requested
      if (addToHistory) {
        addMessage(role: 'assistant', content: responseText);
      }

      return {
        'success': true,
        'message': responseText,
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}',
      };
    }
  }

  /// Gets the total number of messages in conversation history
  int getMessageCount() {
    return _conversationHistory.length;
  }

  /// Exports conversation history as JSON string
  String exportHistory() {
    return _conversationHistory.toString();
  }

  /// Sets the entire conversation history
  void setHistory(List<Map<String, dynamic>> history) {
    _conversationHistory.clear();
    _conversationHistory.addAll(history);

    // Rebuild chat with the imported history
    final chatHistory = history.map((msg) {
      if (msg['role'] == 'user') {
        return Content.text(msg['content'] as String);
      } else {
        return Content.model([TextPart(msg['content'] as String)]);
      }
    }).toList();

    if (_systemPrompt != null) {
      _model = GenerativeModel(
        model: model,
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt!),
      );
    }

    _chat = _model.startChat(history: chatHistory);
  }
}
