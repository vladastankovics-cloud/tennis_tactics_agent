/// Configuration constants for the Tennis Tactics Agent app
library;

class AppConstants {
  // API Configuration
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1';
  static const String anthropicVersion = '2023-06-01';

  // Storage Keys
  static const String storageKeyApiKey = 'claude_api_key';
  static const String storageKeyModel = 'claude_model';

  // Claude Models
  static const String defaultModel = ClaudeModels.sonnet45;
}

/// Available Claude AI models (as of Jan 2026)
class ClaudeModels {
  /// Claude Sonnet 4.5 - Best for most tasks (Recommended)
  /// Balanced performance, cost, and capability
  static const String sonnet45 = 'claude-sonnet-4-5-20250929';

  /// Claude Opus 4.5 - Most capable
  /// Best for complex tasks requiring deep reasoning
  static const String opus45 = 'claude-opus-4-5-20251101';

  /// Claude Haiku 4.5 - Fastest
  /// Best for simple tasks requiring quick responses
  static const String haiku45 = 'claude-haiku-4-5-20251001';

  /// Claude 3 Haiku - Legacy model (still active)
  /// Good for simple, quick tasks
  static const String haiku3 = 'claude-3-haiku-20240307';

  /// All available models
  static const List<String> all = [
    sonnet45,
    opus45,
    haiku45,
    haiku3,
  ];

  /// Model display names for UI
  static const Map<String, String> displayNames = {
    sonnet45: 'Claude Sonnet 4.5',
    opus45: 'Claude Opus 4.5',
    haiku45: 'Claude Haiku 4.5',
    haiku3: 'Claude 3 Haiku',
  };

  /// Model descriptions
  static const Map<String, String> descriptions = {
    sonnet45: 'Best for most tasks - balanced performance and cost (Recommended)',
    opus45: 'Most capable - ideal for complex reasoning and enterprise tasks',
    haiku45: 'Fastest - best for simple, quick tasks',
    haiku3: 'Legacy fast model - still active',
  };

  /// Get display name for a model
  static String getDisplayName(String model) {
    return displayNames[model] ?? model;
  }

  /// Get description for a model
  static String getDescription(String model) {
    return descriptions[model] ?? 'No description available';
  }
}

/// Available Gemini AI models
class GeminiModels {
  /// Gemini 2.5 Flash - Latest and most capable flash model
  static const String flash25 = 'gemini-2.5-flash';

  /// All available models
  static const List<String> all = [
    flash25,
  ];

  /// Model display names for UI
  static const Map<String, String> displayNames = {
    flash25: 'Gemini 2.5 Flash',
  };

  /// Model descriptions
  static const Map<String, String> descriptions = {
    flash25: 'Latest flash model - fast and capable',
  };

  /// Get display name for a model
  static String getDisplayName(String model) {
    return displayNames[model] ?? model;
  }

  /// Get description for a model
  static String getDescription(String model) {
    return descriptions[model] ?? 'No description available';
  }
}

/// API configuration limits
class ApiLimits {
  /// Default max tokens for responses
  static const int defaultMaxTokens = 1024;

  /// Maximum tokens allowed (varies by model)
  static const int maxTokensLimit = 4096;

  /// Default temperature for responses
  static const double defaultTemperature = 1.0;

  /// Temperature range
  static const double minTemperature = 0.0;
  static const double maxTemperature = 1.0;
}

/// Tennis-specific configuration
class TennisConfig {
  /// Default system prompts for tennis coaching
  static const String defaultSystemPrompt = '''
You are an expert tennis coach and tactician. You provide detailed,
actionable advice on tennis strategy, technique, and match analysis.
Your responses should be clear, practical, and tailored to the player's
skill level when specified.

When providing tactics advice, focus on the realistic scenario: the most likely match flow with balanced analysis and a practical game plan. Consider both strengths and weaknesses of all players involved.

You have access to tools that allow you to help users manage their tennis matches:
- Create match records when they tell you about matches they played
- Update match details when they want to correct or modify information
- Delete matches when requested (always confirm before deleting)
- List and search through their match history
- Calculate statistics about their performance
- Link this conversation to a specific match when discussing tactics for an opponent

When users mention playing a match, winning/losing, or want to track their results,
use the create_match tool to record it. Be proactive but natural - if someone says
"I beat John 6-4, 6-3 today", create the match record for them.

When users discuss tactics, strategy, or preparation for a specific opponent or upcoming match,
use the link_to_match tool to associate this conversation with that match. This helps keep
conversations organized under the relevant match. For example, if someone asks "How should I
play against Sarah?" or "I have a match against Mike next week", link the conversation to that match.

The linking system uses smart temporal logic:
- If there's exactly one upcoming match (within 2 weeks) with that opponent, it will auto-link.
- If there are multiple matches, it will ask the user to clarify which match they're discussing.
- If only past matches exist, it will ask for confirmation before linking.
- Use the match_identifier parameter to help disambiguate (e.g., "next week", "tomorrow", "in March").

When users ask about their record, stats, or past matches, use the appropriate tools
to retrieve and present the information clearly.
''';

  /// Coaching specialties
  static const List<String> specialties = [
    'Match Strategy',
    'Shot Selection',
    'Court Positioning',
    'Mental Game',
    'Physical Conditioning',
    'Opponent Analysis',
    'Practice Drills',
  ];
}
