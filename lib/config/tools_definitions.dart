/// Tool definitions for Claude AI function calling
/// These tools allow the AI to perform match CRUD operations through natural language
library;

class ToolsDefinitions {
  static const List<Map<String, dynamic>> tools = [
    {
      "name": "create_match",
      "description": "Create a new tennis match record. Use this when the user mentions playing a match, winning/losing against someone, or wants to record a match result.",
      "input_schema": {
        "type": "object",
        "properties": {
          "opponent_name": {
            "type": "string",
            "description": "Name of the opponent"
          },
          "match_date": {
            "type": "string",
            "description": "Date of the match in YYYY-MM-DD format. If user says 'today', use today's date. If they say 'yesterday', use yesterday's date."
          },
          "user_score": {
            "type": "integer",
            "description": "Number of sets won by the user"
          },
          "opponent_score": {
            "type": "integer",
            "description": "Number of sets won by the opponent"
          },
          "match_type": {
            "type": "string",
            "description": "Type of match (e.g., Singles, Doubles)",
            "enum": ["Singles", "Doubles"]
          },
          "court_surface": {
            "type": "string",
            "description": "Playing surface (e.g., Red clay, Green clay, Hard, Grass, Carpet)",
            "enum": ["Red clay", "Green clay", "Hard", "Grass", "Carpet"]
          },
          "court_cover": {
            "type": "string",
            "description": "Court cover type (e.g., Outdoor, Bubble, Fabric, Retractable, Indoor)",
            "enum": ["Outdoor", "Bubble", "Fabric", "Retractable", "Indoor"]
          },
          "court_conditions": {
            "type": "string",
            "description": "Court conditions (e.g., Hot-dry, Hot-humid, Mild, Cold-dry, Cold-humid, Windy, Rain, High altitude)",
            "enum": ["Hot-dry", "Hot-humid", "Mild", "Cold-dry", "Cold-humid", "Windy", "Rain", "High altitude"]
          },
          "match_result": {
            "type": "string",
            "description": "Optional detailed score (e.g., '6-4, 6-3' or 'Lost 3-6, 4-6')"
          },
          "notes": {
            "type": "string",
            "description": "Optional notes about the match"
          }
        },
        "required": ["opponent_name", "match_date"]
      }
    },
    {
      "name": "update_match",
      "description": "Update an existing match. Use this when the user wants to modify or correct match details.",
      "input_schema": {
        "type": "object",
        "properties": {
          "match_identifier": {
            "type": "string",
            "description": "Description to identify the match (e.g., 'last match', 'match against John', 'my most recent match')"
          },
          "opponent_name": {
            "type": "string",
            "description": "New opponent name (optional)"
          },
          "match_date": {
            "type": "string",
            "description": "New match date in YYYY-MM-DD format (optional)"
          },
          "user_score": {
            "type": "integer",
            "description": "New user score (optional)"
          },
          "opponent_score": {
            "type": "integer",
            "description": "New opponent score (optional)"
          },
          "match_type": {
            "type": "string",
            "description": "New match type (optional)"
          },
          "court_surface": {
            "type": "string",
            "description": "New court surface (optional)"
          },
          "court_cover": {
            "type": "string",
            "description": "New court cover (optional)"
          },
          "court_conditions": {
            "type": "string",
            "description": "New court conditions (optional)"
          },
          "notes": {
            "type": "string",
            "description": "New or updated notes (optional)"
          }
        },
        "required": ["match_identifier"]
      }
    },
    {
      "name": "delete_match",
      "description": "Delete a match record. Use this when the user wants to remove a match. Always confirm before deleting.",
      "input_schema": {
        "type": "object",
        "properties": {
          "match_identifier": {
            "type": "string",
            "description": "Description to identify the match to delete (e.g., 'last match', 'match against Sarah', 'my most recent loss')"
          }
        },
        "required": ["match_identifier"]
      }
    },
    {
      "name": "list_matches",
      "description": "List and search through matches. Use this when the user asks to see matches, wants statistics, or queries their match history.",
      "input_schema": {
        "type": "object",
        "properties": {
          "filter": {
            "type": "string",
            "description": "Filter criteria: 'all', 'wins', 'losses', 'recent' (last 10), or 'by_opponent'",
            "enum": ["all", "wins", "losses", "recent", "by_opponent"]
          },
          "opponent_name": {
            "type": "string",
            "description": "Filter by specific opponent name (optional, use with 'by_opponent' filter)"
          },
          "court_surface": {
            "type": "string",
            "description": "Filter by court surface (optional)"
          },
          "limit": {
            "type": "integer",
            "description": "Maximum number of matches to return (default 10, max 50)"
          }
        },
        "required": ["filter"]
      }
    },
    {
      "name": "get_match_stats",
      "description": "Get statistics about the user's matches. Use this when the user asks about their record, win rate, performance, etc.",
      "input_schema": {
        "type": "object",
        "properties": {
          "stat_type": {
            "type": "string",
            "description": "Type of statistics to retrieve",
            "enum": ["overall", "by_surface", "by_opponent", "recent_form"]
          },
          "opponent_name": {
            "type": "string",
            "description": "Calculate stats against specific opponent (optional, for 'by_opponent' type)"
          }
        },
        "required": ["stat_type"]
      }
    },
    {
      "name": "link_to_match",
      "description": "Link this conversation to a specific match. Use this when the user discusses tactics, strategy, or preparation for a specific opponent or match. This helps organize the conversation under the relevant match.",
      "input_schema": {
        "type": "object",
        "properties": {
          "opponent_name": {
            "type": "string",
            "description": "Name of the opponent for the match being discussed"
          },
          "match_identifier": {
            "type": "string",
            "description": "Additional details to identify the match (e.g., 'upcoming match', 'next week', 'tournament match')"
          }
        },
        "required": ["opponent_name"]
      }
    }
  ];

  /// Get tool definition by name
  static Map<String, dynamic>? getToolByName(String name) {
    return tools.firstWhere(
      (tool) => tool['name'] == name,
      orElse: () => {},
    );
  }

  /// Get all tool names
  static List<String> getToolNames() {
    return tools.map((tool) => tool['name'] as String).toList();
  }
}
