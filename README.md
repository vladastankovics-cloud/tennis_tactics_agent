# Tennis Tactics App

An AI-powered tennis coaching app built with Flutter and Claude AI. Get personalized tennis strategy advice, match analysis, and tactical guidance through an intelligent chat interface.

## Features

- **AI Tennis Coach**: Chat with Claude AI trained on tennis tactics and strategy
- **Real-time Conversations**: Natural language interface for asking questions
- **Secure API Key Storage**: Uses platform-specific secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
- **Multiple Claude Models**: Choose from Claude 3.5 Sonnet, Opus, Sonnet, or Haiku
- **Beautiful Material Design 3 UI**: Modern, clean interface with light/dark theme support
- **Conversation Management**: Clear history, export/import conversations
- **Tennis-Specific System Prompt**: Optimized responses for tennis coaching

## Screenshots

### Setup Screen
First-time configuration for Claude API key and model selection.

### Chat Interface
Real-time tennis coaching advice with message history and typing indicators.

## Getting Started

### Prerequisites

- Flutter SDK (^3.10.7)
- Dart SDK (^3.10.7)
- Claude API key from [Anthropic Console](https://console.anthropic.com/)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd tennis_tactics_agent
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### First Time Setup

1. Launch the app
2. On the setup screen, enter your Claude API key (starts with `sk-ant-`)
3. Select your preferred Claude model
4. Tap "Continue"
5. Start chatting with your AI tennis coach!

## Project Structure

```
lib/
├── config/              # Configuration and constants
│   ├── app_config.dart  # Secure storage for API keys
│   ├── constants.dart   # App constants and model definitions
│   └── README.md        # Configuration documentation
├── models/              # Data models
│   └── chat_message.dart
├── screens/             # UI screens
│   ├── setup_screen.dart    # API key setup
│   ├── tactics_screen.dart  # Main chat interface
│   └── README.md            # Screens documentation
├── services/            # API services
│   └── claude_service.dart  # Claude API integration
├── widgets/             # Reusable widgets
│   └── message_bubble.dart  # Chat message bubbles
└── main.dart           # App entry point
```

## Key Components

### ClaudeService (`lib/services/claude_service.dart`)
Handles all communication with the Anthropic Claude API:
- Send messages and receive responses
- Manage conversation history
- Support for streaming responses
- System prompts for tennis coaching
- Import/export conversation history

### AppConfig (`lib/config/app_config.dart`)
Secure configuration management:
- Store API keys in platform-specific secure storage
- Manage model preferences
- Validate API key formats
- Import/export settings

### TacticsScreen (`lib/screens/tactics_screen.dart`)
Main chat interface:
- Real-time messaging with Claude AI
- Message history display
- Typing indicators
- Error handling
- Clear conversation functionality

## Configuration

### Changing the Default Model

Edit `lib/config/constants.dart`:
```dart
class AppConstants {
  static const String defaultModel = ClaudeModels.sonnet35; // Change here
}
```

### Customizing the Tennis System Prompt

Edit `lib/config/constants.dart`:
```dart
class TennisConfig {
  static const String defaultSystemPrompt = '''
  Your custom tennis coaching prompt here...
  ''';
}
```

### Available Claude Models

- **claude-3-5-sonnet-20241022** (Default) - Best for most tasks
- **claude-3-opus-20240229** - Most capable for complex reasoning
- **claude-3-sonnet-20240229** - Balanced speed and capability
- **claude-3-haiku-20240307** - Fastest for simple queries

## API Usage

### Getting Your Claude API Key

1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Sign up or log in
3. Navigate to API Keys
4. Create a new API key
5. Copy the key (starts with `sk-ant-`)

### Example Usage

```dart
import 'package:tennis_tactics_agent/services/claude_service.dart';

// Initialize from stored config
final service = await ClaudeService.fromConfig();

// Send a message
final response = await service.sendMessage(
  message: 'What are the best tactics for playing against a serve-and-volley player?',
);

if (response['success']) {
  print(response['message']);
}
```

## Security

- API keys are stored using `flutter_secure_storage`
- Keys are encrypted at rest on all platforms
- No hardcoded API keys in source code
- Keys are never logged or exposed

## Dependencies

### Main Dependencies
- `flutter_secure_storage: ^9.2.2` - Secure storage for API keys
- `http: ^1.1.0` - HTTP client for API calls
- `supabase_flutter: ^2.12.0` - Supabase integration (optional)

### Dev Dependencies
- `flutter_test` - Testing framework
- `flutter_lints: ^6.0.0` - Linting rules

## Platform Support

- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Troubleshooting

### "No API key found" error
- Make sure you've entered your API key in the setup screen
- Verify the key starts with `sk-ant-`
- Try clearing app data and setting up again

### API errors
- Check your API key is valid and active
- Verify you have credits in your Anthropic account
- Check your internet connection

### Secure storage issues on Android
- Ensure `minSdkVersion` is at least 18 in `android/app/build.gradle`
- On Android 6.0+, the app needs proper permissions

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is private and not licensed for public use.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Powered by [Claude AI](https://www.anthropic.com/claude)
- Icons from [Material Design](https://material.io/design)

## Support

For issues and questions:
- Check the [lib/config/README.md](lib/config/README.md) for configuration help
- Check the [lib/screens/README.md](lib/screens/README.md) for UI documentation
- Review example code in `lib/config/config_example.dart`

## Roadmap

- [ ] Settings screen for managing API keys and preferences
- [ ] Conversation persistence (save/load)
- [ ] Export conversations to file
- [ ] Voice input support
- [ ] Suggested questions/prompts
- [ ] Match analysis mode
- [ ] Practice drill generator
- [ ] Video analysis integration
- [ ] Multi-language support
