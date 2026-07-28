# App Configuration

Secure configuration management for the Tennis Tactics Agent app using `flutter_secure_storage`.

## Overview

This module provides secure storage for sensitive data like API keys using platform-specific secure storage:
- **iOS**: Keychain
- **Android**: EncryptedSharedPreferences
- **Web**: Web Crypto API
- **Windows/Linux/macOS**: libsecret/Keychain

## Files

- `app_config.dart` - Main configuration service with secure storage
- `config_example.dart` - Usage examples and helper functions

## Installation

The required dependencies are already added to `pubspec.yaml`:

```yaml
dependencies:
  flutter_secure_storage: ^9.2.2
  http: ^1.1.0
```

Run to install:
```bash
flutter pub get
```

## Platform-Specific Setup

### Android

For Android, add the following to your `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 18  // Minimum required for EncryptedSharedPreferences
    }
}
```

### iOS

No additional setup required. The Keychain is used automatically.

### Web

For web, the Web Crypto API is used. Ensure your app is served over HTTPS in production.

## Usage

### 1. Basic Setup - Saving API Key

```dart
import 'package:tennis_tactics_agent/config/app_config.dart';

final config = AppConfig();

// Save API key securely
await config.setClaudeApiKey('sk-ant-your-api-key-here');

// Check if API key exists
bool hasKey = await config.hasClaudeApiKey();

// Retrieve API key
String? apiKey = await config.getClaudeApiKey();
```

### 2. Using with ClaudeService

#### Option A: Initialize from Config (Recommended)

```dart
import 'package:tennis_tactics_agent/services/claude_service.dart';

// Initialize ClaudeService with stored credentials
final claudeService = await ClaudeService.fromConfig();

if (claudeService != null) {
  final response = await claudeService.sendMessage(
    message: 'Analyze this tennis match...',
  );

  if (response['success']) {
    print(response['message']);
  }
}
```

#### Option B: Manual Initialization

```dart
import 'package:tennis_tactics_agent/config/app_config.dart';
import 'package:tennis_tactics_agent/services/claude_service.dart';

final config = AppConfig();
final apiKey = await config.getClaudeApiKey();
final model = await config.getClaudeModel();

if (apiKey != null) {
  final claudeService = ClaudeService(
    apiKey: apiKey,
    model: model,
  );
}
```

### 3. Model Management

```dart
// Set preferred model
await config.setClaudeModel('claude-3-5-sonnet-20241022');

// Get current model (returns default if not set)
String model = await config.getClaudeModel();

// Available models
// - claude-3-5-sonnet-20241022 (default, best for most tasks)
// - claude-3-opus-20240229 (most capable)
// - claude-3-sonnet-20240229 (balanced)
// - claude-3-haiku-20240307 (fastest)
```

### 4. Complete Example - First Time Setup

```dart
import 'package:flutter/material.dart';
import 'package:tennis_tactics_agent/config/app_config.dart';
import 'package:tennis_tactics_agent/services/claude_service.dart';

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _apiKeyController = TextEditingController();
  final _config = AppConfig();

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();

    // Validate API key format
    if (!_config.isValidApiKeyFormat(apiKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid API key format')),
      );
      return;
    }

    // Save API key
    await _config.setClaudeApiKey(apiKey);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('API key saved securely')),
    );

    // Navigate to main app
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup API Key')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'Claude API Key',
                hintText: 'sk-ant-...',
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveApiKey,
              child: Text('Save API Key'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5. Security Best Practices

```dart
// Check if user is logged in before accessing API key
Future<bool> isUserAuthenticated() async {
  final config = AppConfig();
  return await config.hasClaudeApiKey();
}

// Clear all data on logout
Future<void> logout() async {
  final config = AppConfig();
  await config.clearAll();
  // Navigate to login screen
}

// Update API key
Future<void> updateApiKey(String newApiKey) async {
  final config = AppConfig();

  if (!config.isValidApiKeyFormat(newApiKey)) {
    throw Exception('Invalid API key format');
  }

  await config.setClaudeApiKey(newApiKey);
}

// Delete specific key
Future<void> removeApiKey() async {
  final config = AppConfig();
  await config.deleteClaudeApiKey();
}
```

### 6. Error Handling

```dart
try {
  final config = AppConfig();
  await config.setClaudeApiKey(apiKey);
} catch (e) {
  print('Failed to save API key: $e');
  // Handle error (show message to user, retry, etc.)
}

try {
  final apiKey = await config.getClaudeApiKey();
  if (apiKey == null) {
    // API key not found - redirect to setup
  }
} catch (e) {
  print('Failed to retrieve API key: $e');
  // Handle error
}
```

## API Key Format Validation

The `isValidApiKeyFormat()` method performs basic validation:
- Checks if the key starts with `sk-ant-`
- Verifies the key is at least 50 characters long

This is a basic check. The actual validation happens when making API calls.

## Security Considerations

1. **Never hardcode API keys** in your source code
2. **Never commit API keys** to version control
3. Use `.gitignore` to exclude any files containing keys
4. The secure storage is encrypted at rest
5. API keys are only accessible within your app
6. Consider implementing additional authentication before allowing API key access
7. Rotate API keys regularly
8. Use the least privileged API key for your use case

## Debugging

For debugging purposes only (never in production):

```dart
// Get all stored configuration
Map<String, String> allConfig = await config.getAllConfig();
print(allConfig);  // Be careful with this in production!
```

## Migration

If you need to migrate from insecure storage:

```dart
// Read from old storage (e.g., SharedPreferences)
final oldApiKey = prefs.getString('api_key');

if (oldApiKey != null) {
  // Save to secure storage
  await config.setClaudeApiKey(oldApiKey);

  // Delete from old storage
  await prefs.remove('api_key');
}
```

## Troubleshooting

### Android: "MissingPluginException"

Make sure you've run `flutter pub get` and rebuilt the app:
```bash
flutter pub get
flutter clean
flutter run
```

### iOS: "Keychain access error"

Ensure your app has the proper entitlements. This is usually handled automatically.

### Web: Storage not persisting

Make sure your app is served over HTTPS. Local development (localhost) works with HTTP.

## Getting Claude API Keys

1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (it starts with `sk-ant-`)
6. Store it securely using this configuration module

## Additional Resources

- [flutter_secure_storage documentation](https://pub.dev/packages/flutter_secure_storage)
- [Anthropic API documentation](https://docs.anthropic.com/)
- [Claude API reference](https://docs.anthropic.com/claude/reference)
