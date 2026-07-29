import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  late final FlutterSecureStorage _secureStorage;

  // Storage keys
  static const String _claudeApiKeyKey = 'claude_api_key';
  static const String _claudeModelKey = 'claude_model';
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _geminiModelKey = 'gemini_model';

  factory AppConfig() {
    return _instance;
  }

  AppConfig._internal() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  /// Saves the Claude API key securely
  Future<void> setClaudeApiKey(String apiKey) async {
    try {
      await _secureStorage.write(
        key: _claudeApiKeyKey,
        value: apiKey,
      );
    } catch (e) {
      throw Exception('Failed to save API key: ${e.toString()}');
    }
  }

  /// Retrieves the Claude API key
  Future<String?> getClaudeApiKey() async {
    try {
      return await _secureStorage.read(key: _claudeApiKeyKey);
    } catch (e) {
      throw Exception('Failed to retrieve API key: ${e.toString()}');
    }
  }

  /// Deletes the Claude API key
  Future<void> deleteClaudeApiKey() async {
    try {
      await _secureStorage.delete(key: _claudeApiKeyKey);
    } catch (e) {
      throw Exception('Failed to delete API key: ${e.toString()}');
    }
  }

  /// Checks if Claude API key exists
  Future<bool> hasClaudeApiKey() async {
    try {
      final apiKey = await _secureStorage.read(key: _claudeApiKeyKey);
      return apiKey != null && apiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Saves the preferred Claude model
  Future<void> setClaudeModel(String model) async {
    try {
      await _secureStorage.write(
        key: _claudeModelKey,
        value: model,
      );
    } catch (e) {
      throw Exception('Failed to save model preference: ${e.toString()}');
    }
  }

  /// Retrieves the preferred Claude model
  /// Returns default model if not set
  Future<String> getClaudeModel() async {
    try {
      final model = await _secureStorage.read(key: _claudeModelKey);
      return model ?? 'claude-sonnet-4-5-20250929';
    } catch (e) {
      return 'claude-sonnet-4-5-20250929';
    }
  }

  /// Deletes the Claude model preference
  Future<void> deleteClaudeModel() async {
    try {
      await _secureStorage.delete(key: _claudeModelKey);
    } catch (e) {
      throw Exception('Failed to delete model preference: ${e.toString()}');
    }
  }

  /// Clears all stored configuration
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear configuration: ${e.toString()}');
    }
  }

  /// Validates a Claude API key format (basic check)
  bool isValidApiKeyFormat(String apiKey) {
    // Claude API keys typically start with 'sk-ant-' and are ~100+ characters
    return apiKey.startsWith('sk-ant-') && apiKey.length > 50;
  }

  // ==================== Gemini API Key Management ====================

  /// Saves the Gemini API key securely
  Future<void> setGeminiApiKey(String apiKey) async {
    try {
      await _secureStorage.write(
        key: _geminiApiKeyKey,
        value: apiKey,
      );
    } catch (e) {
      throw Exception('Failed to save Gemini API key: ${e.toString()}');
    }
  }

  /// Retrieves the Gemini API key
  Future<String?> getGeminiApiKey() async {
    try {
      return await _secureStorage.read(key: _geminiApiKeyKey);
    } catch (e) {
      throw Exception('Failed to retrieve Gemini API key: ${e.toString()}');
    }
  }

  /// Deletes the Gemini API key
  Future<void> deleteGeminiApiKey() async {
    try {
      await _secureStorage.delete(key: _geminiApiKeyKey);
    } catch (e) {
      throw Exception('Failed to delete Gemini API key: ${e.toString()}');
    }
  }

  /// Checks if Gemini API key exists
  Future<bool> hasGeminiApiKey() async {
    try {
      final apiKey = await _secureStorage.read(key: _geminiApiKeyKey);
      return apiKey != null && apiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Saves the preferred Gemini model
  Future<void> setGeminiModel(String model) async {
    try {
      await _secureStorage.write(
        key: _geminiModelKey,
        value: model,
      );
    } catch (e) {
      throw Exception('Failed to save Gemini model preference: ${e.toString()}');
    }
  }

  /// Retrieves the preferred Gemini model
  /// Returns default model if not set
  Future<String> getGeminiModel() async {
    try {
      final model = await _secureStorage.read(key: _geminiModelKey);
      return model ?? 'gemini-2.0-flash';
    } catch (e) {
      return 'gemini-2.0-flash';
    }
  }

  /// Deletes the Gemini model preference
  Future<void> deleteGeminiModel() async {
    try {
      await _secureStorage.delete(key: _geminiModelKey);
    } catch (e) {
      // Ignore errors when deleting
    }
  }

  /// Validates a Gemini API key format (basic check)
  bool isValidGeminiApiKeyFormat(String apiKey) {
    // Gemini API keys start with 'AIza' and are 39 characters
    return apiKey.startsWith('AIza') && apiKey.length >= 39;
  }

  /// Gets all configuration data (for debugging purposes)
  /// Note: This should be used carefully and not exposed in production
  Future<Map<String, String>> getAllConfig() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      throw Exception('Failed to read all configuration: ${e.toString()}');
    }
  }
}
