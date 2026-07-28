// Example usage of AppConfig with ClaudeService
// This file demonstrates how to use secure storage for API keys

import 'package:tennis_tactics_agent/config/app_config.dart';
import 'package:tennis_tactics_agent/services/claude_service.dart';

/// Example: Initialize ClaudeService with stored API key
Future<ClaudeService?> initializeClaudeService() async {
  final config = AppConfig();

  // Check if API key exists
  if (!await config.hasClaudeApiKey()) {
    print('No API key found. Please set it first.');
    return null;
  }

  // Get the API key and model
  final apiKey = await config.getClaudeApiKey();
  final model = await config.getClaudeModel();

  if (apiKey == null) {
    return null;
  }

  // Create and return ClaudeService instance
  return ClaudeService(
    apiKey: apiKey,
    model: model,
  );
}

/// Example: Save API key on first setup
Future<void> setupApiKey(String apiKey) async {
  final config = AppConfig();

  // Validate API key format
  if (!config.isValidApiKeyFormat(apiKey)) {
    throw Exception('Invalid API key format');
  }

  // Save the API key
  await config.setClaudeApiKey(apiKey);
  print('API key saved securely');
}

/// Example: Change model preference
Future<void> changeModel(String model) async {
  final config = AppConfig();
  await config.setClaudeModel(model);
  print('Model preference updated to: $model');
}

/// Example: Complete workflow
Future<void> exampleWorkflow() async {
  final config = AppConfig();

  // Step 1: Setup API key (first time only)
  if (!await config.hasClaudeApiKey()) {
    const apiKey = 'sk-ant-your-api-key-here';
    await setupApiKey(apiKey);
  }

  // Step 2: Initialize ClaudeService
  final claudeService = await initializeClaudeService();

  if (claudeService == null) {
    print('Failed to initialize Claude service');
    return;
  }

  // Step 3: Use the service
  final response = await claudeService.sendMessage(
    message: 'What are the best tennis tactics for beginners?',
    maxTokens: 1024,
  );

  if (response['success']) {
    print('Response: ${response['message']}');
  } else {
    print('Error: ${response['error']}');
  }

  // Optional: Clear API key when logging out
  // await config.deleteClaudeApiKey();
}

/// Example: Handle API key updates
Future<void> updateApiKey(String newApiKey) async {
  final config = AppConfig();

  // Validate new key
  if (!config.isValidApiKeyFormat(newApiKey)) {
    throw Exception('Invalid API key format');
  }

  // Delete old key and save new one
  await config.deleteClaudeApiKey();
  await config.setClaudeApiKey(newApiKey);

  print('API key updated successfully');
}

/// Example: Available Claude models (as of Jan 2026)
class ClaudeModels {
  static const String sonnet45 = 'claude-sonnet-4-5-20250929';
  static const String opus45 = 'claude-opus-4-5-20251101';
  static const String haiku45 = 'claude-haiku-4-5-20251001';
  static const String haiku3 = 'claude-3-haiku-20240307';

  static List<String> get all => [
    sonnet45,
    opus45,
    haiku45,
    haiku3,
  ];
}
