import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tennis_tactics_agent/config/app_config.dart';
import 'package:tennis_tactics_agent/config/tools_definitions.dart';
import 'package:tennis_tactics_agent/services/tools_handler_service.dart';

class ClaudeService {
  final String apiKey;
  final String baseUrl = 'https://api.anthropic.com/v1';
  final String model;
  final List<Map<String, dynamic>> _conversationHistory = [];
  String? _conversationId;

  ClaudeService({
    required this.apiKey,
    this.model = 'claude-sonnet-4-5-20250929',
  });

  /// Factory constructor to create ClaudeService from stored configuration
  static Future<ClaudeService?> fromConfig() async {
    final config = AppConfig();

    // Check if API key exists
    if (!await config.hasClaudeApiKey()) {
      return null;
    }

    // Get the API key and model
    final apiKey = await config.getClaudeApiKey();
    final model = await config.getClaudeModel();

    if (apiKey == null) {
      return null;
    }

    return ClaudeService(
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
  }

  /// Removes the last message from conversation history
  void removeLastMessage() {
    if (_conversationHistory.isNotEmpty) {
      _conversationHistory.removeLast();
    }
  }

  /// Sends a message to Claude API and returns the response
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

      // Prepare the request body
      final requestBody = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': _conversationHistory,
      };

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract assistant's reply
        final assistantMessage = responseData['content'][0]['text'] as String;

        // Add assistant's response to history if requested
        if (addToHistory) {
          addMessage(role: 'assistant', content: assistantMessage);
        }

        return {
          'success': true,
          'message': assistantMessage,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error']?['message'] ?? 'Unknown error occurred',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}',
      };
    }
  }

  /// Sends a message with custom system prompt and optional tools
  Future<Map<String, dynamic>> sendMessageWithSystem({
    required String message,
    required String systemPrompt,
    int maxTokens = 1024,
    double temperature = 1.0,
    bool addToHistory = true,
    bool enableTools = false,
  }) async {
    try {
      // Add user message to history if requested
      if (addToHistory) {
        addMessage(role: 'user', content: message);
      }

      // Prepare the request body with system prompt
      final requestBody = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'system': systemPrompt,
        'messages': _conversationHistory,
      };

      // Add tools if enabled
      if (enableTools) {
        requestBody['tools'] = ToolsDefinitions.tools;
      }

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if Claude wants to use a tool
        final content = responseData['content'] as List;
        final hasToolUse = content.any((block) => block['type'] == 'tool_use');

        if (hasToolUse && enableTools) {
          // Handle tool execution
          return await _handleToolExecution(
            responseData,
            systemPrompt,
            maxTokens,
            temperature,
            addToHistory,
          );
        }

        // Extract assistant's reply (text block)
        String assistantMessage = '';
        for (var block in content) {
          if (block['type'] == 'text') {
            assistantMessage += block['text'] as String;
          }
        }

        // Add assistant's response to history if requested
        if (addToHistory) {
          addMessage(role: 'assistant', content: assistantMessage);
        }

        return {
          'success': true,
          'message': assistantMessage,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error']?['message'] ?? 'Unknown error occurred',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception occurred: ${e.toString()}',
      };
    }
  }

  /// Handles tool execution when Claude requests to use a tool
  Future<Map<String, dynamic>> _handleToolExecution(
    Map<String, dynamic> responseData,
    String systemPrompt,
    int maxTokens,
    double temperature,
    bool addToHistory,
  ) async {
    try {
      final content = responseData['content'] as List;

      // Add assistant's tool use to history
      if (addToHistory) {
        _conversationHistory.add({
          'role': 'assistant',
          'content': content,
        });
      }

      // Execute each tool call
      final toolResults = <Map<String, dynamic>>[];
      final toolsHandler = await ToolsHandlerService.create(conversationId: _conversationId);

      for (var block in content) {
        if (block['type'] == 'tool_use') {
          final toolName = block['name'] as String;
          final toolInput = block['input'] as Map<String, dynamic>;
          final toolUseId = block['id'] as String;

          // Execute the tool
          final toolResult = await toolsHandler.handleToolCall(toolName, toolInput);

          // Format tool result for Claude
          toolResults.add({
            'type': 'tool_result',
            'tool_use_id': toolUseId,
            'content': jsonEncode(toolResult),
          });
        }
      }

      // Add tool results to conversation
      if (addToHistory && toolResults.isNotEmpty) {
        _conversationHistory.add({
          'role': 'user',
          'content': toolResults,
        });
      }

      // Send tool results back to Claude to get final response
      final requestBody = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'system': systemPrompt,
        'messages': _conversationHistory,
        'tools': ToolsDefinitions.tools,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final finalResponseData = jsonDecode(response.body);
        final finalContent = finalResponseData['content'] as List;

        // Extract final text response
        String finalMessage = '';
        for (var block in finalContent) {
          if (block['type'] == 'text') {
            finalMessage += block['text'] as String;
          }
        }

        // Add final response to history
        if (addToHistory) {
          addMessage(role: 'assistant', content: finalMessage);
        }

        return {
          'success': true,
          'message': finalMessage,
          'data': finalResponseData,
          'tool_results': toolResults.map((r) => jsonDecode(r['content'] as String)).toList(),
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error']?['message'] ?? 'Unknown error occurred',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Tool execution failed: ${e.toString()}',
      };
    }
  }

  /// Sends a streaming message to Claude API
  Stream<String> sendMessageStream({
    required String message,
    int maxTokens = 1024,
    double temperature = 1.0,
    bool addToHistory = true,
  }) async* {
    try {
      // Add user message to history if requested
      if (addToHistory) {
        addMessage(role: 'user', content: message);
      }

      // Prepare the request body
      final requestBody = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': _conversationHistory,
        'stream': true,
      };

      // Make streaming API request
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/messages'),
      );

      request.headers.addAll({
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      });

      request.body = jsonEncode(requestBody);

      final streamedResponse = await request.send();
      final fullResponse = StringBuffer();

      await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
        // Parse SSE format
        final lines = chunk.split('\n');
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') continue;

            try {
              final jsonData = jsonDecode(data);
              if (jsonData['type'] == 'content_block_delta') {
                final text = jsonData['delta']?['text'] as String?;
                if (text != null) {
                  fullResponse.write(text);
                  yield text;
                }
              }
            } catch (_) {
              // Skip invalid JSON chunks
            }
          }
        }
      }

      // Add complete assistant response to history
      if (addToHistory && fullResponse.isNotEmpty) {
        addMessage(role: 'assistant', content: fullResponse.toString());
      }
    } catch (e) {
      yield 'Error: ${e.toString()}';
    }
  }

  /// Gets the total number of messages in conversation history
  int getMessageCount() {
    return _conversationHistory.length;
  }

  /// Exports conversation history as JSON string
  String exportHistory() {
    return jsonEncode(_conversationHistory);
  }

  /// Imports conversation history from JSON string
  void importHistory(String jsonHistory) {
    try {
      final List<dynamic> history = jsonDecode(jsonHistory);
      _conversationHistory.clear();
      for (var message in history) {
        if (message is Map<String, dynamic>) {
          _conversationHistory.add(message);
        }
      }
    } catch (e) {
      throw Exception('Failed to import history: ${e.toString()}');
    }
  }

  /// Sets the entire conversation history
  void setHistory(List<Map<String, dynamic>> history) {
    _conversationHistory.clear();
    _conversationHistory.addAll(history);
  }
}
