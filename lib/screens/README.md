# Screens Documentation

This directory contains the main UI screens for the Tennis Tactics Coach app.

## Screens Overview

### 1. SplashScreen (in main.dart)
- **Purpose**: Initial loading screen that checks for API key
- **Flow**:
  - Shows app logo and loading indicator
  - Checks if Claude API key is configured
  - Routes to SetupScreen if no key found
  - Routes to TacticsScreen if key exists

### 2. SetupScreen
- **Purpose**: First-time setup for configuring Claude API key
- **Features**:
  - API key input field with show/hide toggle
  - Model selection dropdown
  - Key format validation
  - Informative help section
  - Beautiful Material Design 3 UI
- **Flow**:
  - User enters API key from Anthropic Console
  - Selects preferred Claude model
  - Validates key format (starts with sk-ant-)
  - Saves to secure storage
  - Navigates to TacticsScreen

### 3. TacticsScreen
- **Purpose**: Main chat interface for tennis coaching
- **Features**:
  - Real-time chat with Claude AI
  - Tennis-specific system prompt
  - Message history display
  - Typing indicator
  - Error handling
  - Clear conversation option
  - Settings button (placeholder)
  - Material Design 3 UI with custom message bubbles

## Screen Flow Diagram

```
App Launch
    ↓
SplashScreen
    ↓
Check API Key?
    ├─ No  → SetupScreen → TacticsScreen
    └─ Yes → TacticsScreen
```

## Usage Examples

### Navigating to TacticsScreen from anywhere

```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => const TacticsScreen(),
  ),
);
```

### Navigating to SetupScreen (e.g., from settings)

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const SetupScreen(),
  ),
);
```

### Checking setup status before navigation

```dart
final config = AppConfig();
final hasKey = await config.hasClaudeApiKey();

if (hasKey) {
  // Navigate to TacticsScreen
} else {
  // Navigate to SetupScreen
}
```

## TacticsScreen Deep Dive

### State Management
- Uses StatefulWidget for managing local state
- Maintains list of ChatMessage objects
- Tracks loading states (initializing, sending message)
- Handles errors gracefully

### Key Methods

#### _initializeService()
Initializes Claude service on screen load:
- Checks for API key existence
- Creates ClaudeService instance from config
- Shows welcome message
- Handles errors with user-friendly messages

#### _sendMessage()
Sends user message to Claude:
- Validates input (not empty, service initialized)
- Adds user message to chat
- Shows typing indicator
- Calls Claude API with tennis system prompt
- Adds assistant response to chat
- Handles errors and displays them as error messages
- Scrolls to bottom automatically

#### _clearConversation()
Clears chat history:
- Shows confirmation dialog
- Clears local messages list
- Clears Claude service history
- Adds new welcome message

### UI Components

#### App Bar
- Title: "Tennis Tactics Coach"
- Clear conversation button (trash icon)
- Settings button

#### Message List
- Scrollable list of messages
- Custom MessageBubble widgets
- Typing indicator when loading
- Empty state message
- Auto-scroll to latest message

#### Input Field
- Multi-line text input
- Rounded corners (Material 3 style)
- Hint text: "Ask about tennis tactics..."
- Disabled during loading
- Submit on enter key

#### Send Button
- Circular button with send icon
- Primary color when text entered
- Disabled appearance when empty or loading
- Tap to send message

## SetupScreen Deep Dive

### Features

#### API Key Input
- Obscured text field (can toggle visibility)
- Validation for empty and invalid format
- Real-time error messages
- Key icon prefix
- Visibility toggle suffix

#### Model Selection
- Dropdown with all available Claude models
- Display names and descriptions
- Default: Claude 3.5 Sonnet
- Model descriptions shown in dropdown

#### Continue Button
- Filled button style (Material 3)
- Loading state with spinner
- Disabled during save operation
- Arrow forward icon

#### Help Section
- Info card with instructions
- Getting started guide
- Links to Anthropic Console
- Clear 4-step process

### Validation

```dart
// API key must:
// 1. Not be empty
// 2. Start with "sk-ant-"
// 3. Be at least 50 characters long

if (!_config.isValidApiKeyFormat(apiKey)) {
  // Show error
}
```

## Customization

### Changing Theme Colors

In main.dart:
```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue, // Change this
    brightness: Brightness.light,
  ),
  useMaterial3: true,
),
```

### Modifying System Prompt

In TacticsScreen, line ~116:
```dart
final response = await _claudeService!.sendMessageWithSystem(
  message: text,
  systemPrompt: TennisConfig.defaultSystemPrompt, // Change this
  // ...
);
```

Or modify the default in `lib/config/constants.dart`.

### Adding More Settings

Add settings items in TacticsScreen AppBar actions:
```dart
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  },
),
```

## Error Handling

### TacticsScreen Errors

1. **Initialization Errors**
   - No API key found → Shows error with retry button
   - Service creation failed → Shows error with retry button

2. **Message Sending Errors**
   - API errors → Displayed as error message in chat
   - Network errors → Displayed as error message in chat
   - All errors are preserved in chat history

3. **Error Display**
   - Error messages appear as red message bubbles
   - Include error text from API or exception
   - User can retry by sending another message

### SetupScreen Errors

1. **Validation Errors**
   - Empty key → "Please enter your API key"
   - Invalid format → "Invalid API key format..."

2. **Save Errors**
   - Storage errors → Displayed below input field
   - User can retry by tapping Continue again

## Best Practices

1. **Always validate API key** before allowing access to TacticsScreen
2. **Handle loading states** to prevent multiple simultaneous requests
3. **Show user-friendly errors** instead of raw exception messages
4. **Auto-scroll to new messages** for better UX
5. **Preserve conversation history** during screen lifecycle
6. **Use secure storage** for API keys (via AppConfig)
7. **Provide clear setup instructions** in SetupScreen

## Future Enhancements

Potential additions:
- Settings screen for managing API key and model
- Conversation history persistence (save/load)
- Export conversation to file
- Voice input for messages
- Suggested questions/prompts
- Match analysis mode with structured input
- Practice drill generator
- Video analysis integration
