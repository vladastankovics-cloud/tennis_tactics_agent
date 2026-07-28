import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:tennis_tactics_agent/config/app_config.dart';
import 'package:tennis_tactics_agent/config/constants.dart';
import 'package:tennis_tactics_agent/models/ai_tactic.dart';
import 'package:tennis_tactics_agent/models/chat_message.dart';
import 'package:tennis_tactics_agent/models/match.dart';
import 'package:tennis_tactics_agent/models/opponent.dart';
import 'package:tennis_tactics_agent/models/user_profile.dart';
import 'package:tennis_tactics_agent/services/gemini_service.dart';
import 'package:tennis_tactics_agent/services/conversation_service.dart';
import 'package:tennis_tactics_agent/repositories/ai_tactic_repository.dart';
import 'package:tennis_tactics_agent/repositories/match_repository.dart';
import 'package:tennis_tactics_agent/repositories/opponent_repository.dart';
import 'package:tennis_tactics_agent/repositories/user_profile_repository.dart';
import 'package:tennis_tactics_agent/utils/date_formatter.dart';
import 'package:tennis_tactics_agent/widgets/message_bubble.dart';

/// Main screen for tennis tactics chat interface
class TacticsScreen extends StatefulWidget {
  final String? conversationId;
  final String? matchId;
  final bool embedded;
  final VoidCallback? onConversationUpdated;
  final bool autoGenerateAdvice;

  const TacticsScreen({
    super.key,
    this.conversationId,
    this.matchId,
    this.embedded = false,
    this.onConversationUpdated,
    this.autoGenerateAdvice = false,
  });

  @override
  State<TacticsScreen> createState() => _TacticsScreenState();
}

class _TacticsScreenState extends State<TacticsScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AppConfig _config = AppConfig();
  final ConversationService _conversationService = ConversationService();
  final MatchRepository _matchRepository = MatchRepository();
  final OpponentRepository _opponentRepository = OpponentRepository();
  final UserProfileRepository _userProfileRepository = UserProfileRepository();
  final AiTacticRepository _aiTacticRepository = AiTacticRepository();

  GeminiService? _geminiService;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _initError;
  Match? _linkedMatch;
  Opponent? _linkedOpponent;
  Opponent? _linkedOpponent2;
  Opponent? _linkedPartner;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _autoSave();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize the Gemini service and load/create conversation
  Future<void> _initializeService() async {
    try {
      setState(() {
        _isInitializing = true;
        _initError = null;
      });

      // Check if API key exists
      final hasKey = await _config.hasGeminiApiKey();

      if (!hasKey) {
        setState(() {
          _isInitializing = false;
          _initError = 'No API key found. Please configure your API key first.';
        });
        return;
      }

      // Initialize service from config
      _geminiService = await GeminiService.fromConfig();

      if (_geminiService == null) {
        setState(() {
          _isInitializing = false;
          _initError = 'Failed to initialize Gemini service.';
        });
        return;
      }

      // Load user profile
      _userProfile = await _userProfileRepository.getUserProfile();

      // Load linked match info if matchId is provided
      if (widget.matchId != null) {
        _linkedMatch = await _matchRepository.getMatchById(widget.matchId!);

        // Load opponent analytics if match has an opponent
        if (_linkedMatch != null) {
          _linkedOpponent = await _opponentRepository.getOpponentByName(_linkedMatch!.opponentName);

          // Load partner and opponent 2 for doubles matches
          if (_linkedMatch!.matchType == 'Doubles') {
            if (_linkedMatch!.partnerName != null && _linkedMatch!.partnerName!.isNotEmpty) {
              _linkedPartner = await _opponentRepository.getOpponentByName(_linkedMatch!.partnerName!);
            }
            if (_linkedMatch!.opponentName2 != null && _linkedMatch!.opponentName2!.isNotEmpty) {
              _linkedOpponent2 = await _opponentRepository.getOpponentByName(_linkedMatch!.opponentName2!);
            }
          }
        }
      }

      // Load existing conversation if provided
      if (widget.conversationId != null) {
        // Load existing conversation
        await _conversationService.loadConversation(
          widget.conversationId!,
          _geminiService!,
        );

        // Convert conversation history to chat messages for display
        final history = _geminiService!.conversationHistory;
        for (var msg in history) {
          if (msg['role'] == 'user') {
            _messages.add(ChatMessage.user(msg['content'] as String));
          } else if (msg['role'] == 'assistant') {
            _messages.add(ChatMessage.assistant(msg['content'] as String));
          }
        }
      } else {
        // Don't create conversation until first message is sent
        // Just show welcome message (not saved)
        if (_linkedMatch != null) {
          _addMessage(ChatMessage.assistant(_buildMatchWelcomeMessage()));
        } else {
          _addMessage(ChatMessage.assistant(
            'Hello! I\'m your tennis tactics coach. Ask me anything about tennis strategy, technique, shot selection, or match analysis. How can I help improve your game today?',
          ));
        }
      }

      setState(() {
        _isInitializing = false;
      });

      // Auto-generate advice if requested and this is a new match conversation
      if (widget.autoGenerateAdvice &&
          widget.conversationId == null &&
          _linkedMatch != null) {
        _autoGenerateAdvice();
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _initError = 'Error: ${e.toString()}';
      });
    }
  }

  /// Auto-generate tactical advice for the match with retry logic
  Future<void> _autoGenerateAdvice() async {
    if (_geminiService == null || _linkedMatch == null) return;

    // Create a comprehensive prompt asking for tactical advice
    const advicePrompt = '''Give me comprehensive tactical advice for this match. Structure your response as follows:

1. **MATCH ANALYSIS**: Brief analysis of the matchup considering my profile vs opponent's profile and court conditions.

2. **SERVE TACTICS**: Strategies when I'm serving - placement, patterns, approach shots.

3. **RETURN TACTICS**: How to handle their serve - positioning, targets, counter-attacking.

4. **BASELINE TACTICS**: Rally patterns, shot selection, court positioning when trading groundstrokes.

5. **NET TACTICS**: When to approach, volleys, dealing with passing shots.

6. **SPECIALTY SHOTS**: Lobs, drop shots, angles, and situational plays.

7. **MENTAL TACTICS**: Focus points, game management, momentum shifts.

8. **KEY TACTICS TO REMEMBER**: List the 5 most important tactics I can quickly reference during the match. For each, use this exact format:

**TACTIC: [2-4 word name]**
[One sentence description]

''';

    const maxRetries = 2;
    const retryDelay = 15; // Wait 15 seconds before retry

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      // Set the text and send the message
      _textController.text = advicePrompt;
      await _sendMessage();

      // Check if the last message was an error
      if (_messages.isNotEmpty && _messages.last.isError) {
        final errorMsg = _messages.last.content.toLowerCase();

        // Don't retry on quota/rate limit errors - these won't resolve quickly
        final isQuotaError = errorMsg.contains('quota') ||
                             errorMsg.contains('rate') ||
                             errorMsg.contains('limit') ||
                             errorMsg.contains('429');

        if (isQuotaError || attempt >= maxRetries - 1) {
          // Don't retry - show error and exit
          debugPrint('Not retrying: quota error or max attempts reached');
          return;
        }

        // Remove the error message before retrying
        setState(() {
          _messages.removeLast(); // Remove error
          if (_messages.isNotEmpty && _messages.last.isUser) {
            _messages.removeLast(); // Remove user message too
          }
        });

        // Show retry message
        _addMessage(ChatMessage.assistant(
          'Connection issue. Retrying in $retryDelay seconds...',
        ));

        // Wait before retrying
        await Future.delayed(const Duration(seconds: retryDelay));

        // Remove retry message
        setState(() {
          _messages.removeLast();
        });
      } else {
        // Success - parse and save tactics
        await _extractAndSaveTactics();
        return;
      }
    }

    debugPrint('All $maxRetries attempts to get AI advice failed');
  }

  /// Extract tactics from the last AI response and save to database
  Future<void> _extractAndSaveTactics() async {
    if (_geminiService?.conversationId == null || _linkedMatch == null) return;

    // Find the last assistant message
    final lastAssistantMessage = _messages.reversed
        .firstWhere(
          (msg) => !msg.isUser && !msg.isError,
          orElse: () => ChatMessage.assistant(''),
        );

    if (lastAssistantMessage.content.isEmpty) return;

    // Parse tactics from the response using regex
    final tacticPattern = RegExp(
      r'\*\*TACTIC:\s*(.+?)\*\*\s*\n(.+?)(?=\n\n\*\*TACTIC:|\n\n[^*]|$)',
      multiLine: true,
      dotAll: true,
    );

    final matches = tacticPattern.allMatches(lastAssistantMessage.content);
    final tactics = <AiTactic>[];
    final uuid = const Uuid();
    final now = DateTime.now();

    for (final match in matches) {
      final shortName = match.group(1)?.trim() ?? '';
      final description = match.group(2)?.trim() ?? '';

      if (shortName.isNotEmpty && description.isNotEmpty) {
        tactics.add(AiTactic(
          id: uuid.v4(),
          conversationId: _geminiService!.conversationId!,
          matchId: _linkedMatch!.id,
          shortName: shortName,
          description: description,
          createdAt: now,
        ));
      }
    }

    // Save tactics to database
    if (tactics.isNotEmpty) {
      await _aiTacticRepository.createTactics(tactics);
      debugPrint('Saved ${tactics.length} AI tactics');
    }
  }

  /// Auto-save conversation to database
  Future<void> _autoSave() async {
    if (_geminiService != null && _geminiService!.conversationId != null) {
      try {
        debugPrint('Auto-saving conversation: ${_geminiService!.conversationId}');
        await _conversationService.autoSave(_geminiService!);
        debugPrint('Auto-save successful');
      } catch (e, stackTrace) {
        // Log detailed error information
        debugPrint('Auto-save failed: $e');
        debugPrint('Stack trace: $stackTrace');

        // Show error in development mode
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save chat: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      debugPrint('Cannot auto-save: claudeService=${_geminiService != null}, conversationId=${_geminiService?.conversationId}');
    }
  }

  /// Build welcome message with match context
  String _buildMatchWelcomeMessage() {
    if (_linkedMatch == null) return '';

    final match = _linkedMatch!;
    final buffer = StringBuffer();

    buffer.write('Hello! I\'m your tennis tactics coach. ');
    if (match.matchType == 'Doubles') {
      buffer.write('I see you have a doubles match against **${match.opponentName}**');
      if (match.opponentName2 != null && match.opponentName2!.isNotEmpty) {
        buffer.write(' and **${match.opponentName2}**');
      }
      if (match.partnerName != null && match.partnerName!.isNotEmpty) {
        buffer.write(', partnering with **${match.partnerName}**');
      }
      buffer.write('.\n\n');
    } else {
      buffer.write('I see you have a match against **${match.opponentName}**.\n\n');
    }

    buffer.write('**Match Details:**\n');
    if (match.matchDate != null) {
      buffer.write('• Date: ${DateFormatter.formatDate(match.matchDate!)}\n');
    }
    if (match.matchType != null) {
      buffer.write('• Type: ${match.matchType}\n');
    }

    // Court details
    if (match.courtName != null || match.courtSurface != null) {
      if (match.courtName != null) {
        buffer.write('• Court: ${match.courtName}\n');
      }
      if (match.courtSurface != null) {
        buffer.write('• Surface: ${match.courtSurface}');
        if (match.courtSpeed != null) {
          buffer.write(' (${match.courtSpeed})');
        }
        buffer.write('\n');
      }
      if (match.courtCover != null) {
        buffer.write('• Cover: ${match.courtCover}\n');
      }
      if (match.courtConditions != null) {
        buffer.write('• Conditions: ${match.courtConditions}\n');
      }
    }

    if (match.notes != null && match.notes!.isNotEmpty) {
      buffer.write('• Notes: ${match.notes}\n');
    }

    // Mention analytics profiles if available
    final List<String> profilesAvailable = [];
    if (_linkedOpponent != null) {
      profilesAvailable.add('**${match.opponentName}\'s**');
    }
    if (_linkedOpponent2 != null) {
      profilesAvailable.add('**${match.opponentName2}\'s**');
    }
    if (_linkedPartner != null) {
      profilesAvailable.add('**${match.partnerName}\'s**');
    }

    if (profilesAvailable.isNotEmpty) {
      buffer.write('\nI have access to ${profilesAvailable.join(', ')} analytics profile${profilesAvailable.length > 1 ? 's' : ''} and will use ${profilesAvailable.length > 1 ? 'them' : 'it'} to provide tailored advice.');
    }

    buffer.write('\n\nLet\'s discuss strategy and tactics for this match. How can I help you prepare?');

    return buffer.toString();
  }

  /// Build system prompt with match context
  String _buildMatchSystemPrompt() {
    if (_linkedMatch == null) {
      return TennisConfig.defaultSystemPrompt;
    }

    final match = _linkedMatch!;
    final buffer = StringBuffer();

    buffer.write(TennisConfig.defaultSystemPrompt);
    buffer.write('\n\n## Current Match Context\n\n');
    buffer.write('The user is preparing for a match with the following details:\n');
    buffer.write('- Opponent 1: ${match.opponentName}\n');
    if (match.matchType == 'Doubles') {
      if (match.opponentName2 != null && match.opponentName2!.isNotEmpty) {
        buffer.write('- Opponent 2: ${match.opponentName2}\n');
      }
      if (match.partnerName != null && match.partnerName!.isNotEmpty) {
        buffer.write('- Partner: ${match.partnerName}\n');
      }
    }

    if (match.matchDate != null) {
      buffer.write('- Match Date: ${DateFormatter.formatDate(match.matchDate!)}\n');
    }
    if (match.matchType != null) {
      buffer.write('- Match Type: ${match.matchType}\n');
    }
    if (match.matchFormat != null) {
      buffer.write('- Match Format: ${match.matchFormat}\n');
      if (match.noAds) {
        buffer.write('- Scoring: No ads (sudden death at deuce)\n');
      }
      if (match.tiebreakSet) {
        buffer.write('- Final Set: Tiebreak set (at 1:1 in best of 3, or 2:2 in best of 5)\n');
      }
    }
    if (match.matchScoreUser != null && match.matchScoreOpponent != null) {
      buffer.write('- Previous Score: ${match.matchScoreUser}-${match.matchScoreOpponent}\n');
    }
    if (match.notes != null && match.notes!.isNotEmpty) {
      buffer.write('- Additional Notes: ${match.notes}\n');
    }

    // Court details
    if (match.courtName != null || match.courtSurface != null || match.courtSpeed != null ||
        match.courtCover != null || match.courtConditions != null || match.altitude != null) {
      buffer.write('\n### Court Details\n');
      if (match.courtName != null) {
        buffer.write('- Court Name: ${match.courtName}\n');
      }
      if (match.courtSurface != null) {
        buffer.write('- Surface: ${match.courtSurface}\n');
      }
      if (match.courtSpeed != null) {
        buffer.write('- Speed: ${match.courtSpeed}\n');
      }
      if (match.courtCover != null) {
        buffer.write('- Cover: ${match.courtCover}\n');
      }
      if (match.courtConditions != null) {
        buffer.write('- Conditions: ${match.courtConditions}\n');
      }
      if (match.altitude != null) {
        buffer.write('- Altitude: ${match.altitude}\n');
      }
    }

    // Opponent 1 analytics
    if (_linkedOpponent != null) {
      final opp = _linkedOpponent!;
      final isDoubles = match.matchType == 'Doubles';
      final oppLabel = isDoubles ? 'Opponent 1' : 'Opponent';

      // Profile information
      if (opp.level != null || opp.birthYear != null || opp.heightCm != null || opp.weightKg != null ||
          opp.activeSinceYear != null || opp.hands != null || opp.backhandType != null) {
        buffer.write('\n### $oppLabel Profile (${match.opponentName})\n');
        if (opp.level != null) {
          buffer.write('- Level: ${opp.level}\n');
        }
        if (opp.birthYear != null) {
          final age = DateTime.now().year - opp.birthYear!;
          buffer.write('- Age: $age years old (born ${opp.birthYear})\n');
        }
        if (opp.heightCm != null) {
          final totalInches = opp.heightCm! / 2.54;
          final feet = (totalInches / 12).floor();
          final inches = (totalInches % 12).round();
          buffer.write("- Height: ${opp.heightCm}cm ($feet'$inches\")\n");
        }
        if (opp.weightKg != null) {
          final lbs = (opp.weightKg! * 2.20462).round();
          buffer.write('- Weight: ${opp.weightKg!.toStringAsFixed(1)}kg (${lbs}lbs)\n');
        }
        if (opp.activeSinceYear != null) {
          final yearsActive = DateTime.now().year - int.parse(opp.activeSinceYear!);
          buffer.write('- Years Active: $yearsActive (since ${opp.activeSinceYear})\n');
        }
        if (opp.hands != null) {
          buffer.write('- Hands: ${opp.hands}\n');
        }
        if (opp.backhandType != null) {
          buffer.write('- Backhand: ${opp.backhandType}\n');
        }
      }

      buffer.write('\n### $oppLabel Evaluation (scale 0-100, 50 is average)\n');

      buffer.write('\n**Physical Attributes:**\n');
      buffer.write('- Agility: ${opp.agility}, Mobility: ${opp.mobility}, Endurance: ${opp.endurance}\n');
      buffer.write('- Power: ${opp.power}, Reach: ${opp.reach}, Coordination: ${opp.coordination}\n');
      buffer.write('- Balance: ${opp.balance}, Lean Body: ${opp.leanBody}\n');

      buffer.write('\n**Technical Skills:**\n');
      buffer.write('- Serve: ${opp.serve}, Return: ${opp.returnServe}\n');
      buffer.write('- Forehand: ${opp.forehand}, Backhand: ${opp.backhand}\n');
      buffer.write('- Transition: ${opp.transition}, Net: ${opp.net}, Specialty: ${opp.specialty}\n');

      buffer.write('\n**Playing Styles:**\n');
      buffer.write('- Counterpuncher: ${opp.counterpuncher}, Aggressive Baseliner: ${opp.aggressiveBaseliner}\n');
      buffer.write('- All-Court: ${opp.allCourtPlayer}, Net Rusher: ${opp.netRusher}\n');
      buffer.write('- Serve & Volley: ${opp.serveAndVolleyer}, Big Server: ${opp.bigServer}\n');

      buffer.write('\n**Mental Attributes:**\n');
      buffer.write('- Focus: ${opp.focus}, Calmness: ${opp.calmness}\n');
      buffer.write('- Clutchness: ${opp.clutchness}, Confidence: ${opp.confidence}\n');

      buffer.write('\n**Support System:**\n');
      buffer.write('- Family: ${opp.family}, Coaches: ${opp.coaches}, Partners: ${opp.partners}\n');
      buffer.write('- Crowd: ${opp.crowd}, Sponsors: ${opp.sponsors}\n');
    }

    // Opponent 2 analytics (doubles only)
    if (_linkedOpponent2 != null) {
      final opp = _linkedOpponent2!;

      // Profile information
      if (opp.level != null || opp.birthYear != null || opp.heightCm != null || opp.weightKg != null ||
          opp.activeSinceYear != null || opp.hands != null || opp.backhandType != null) {
        buffer.write('\n### Opponent 2 Profile (${match.opponentName2})\n');
        if (opp.level != null) {
          buffer.write('- Level: ${opp.level}\n');
        }
        if (opp.birthYear != null) {
          final age = DateTime.now().year - opp.birthYear!;
          buffer.write('- Age: $age years old (born ${opp.birthYear})\n');
        }
        if (opp.heightCm != null) {
          final totalInches = opp.heightCm! / 2.54;
          final feet = (totalInches / 12).floor();
          final inches = (totalInches % 12).round();
          buffer.write("- Height: ${opp.heightCm}cm ($feet'$inches\")\n");
        }
        if (opp.weightKg != null) {
          final lbs = (opp.weightKg! * 2.20462).round();
          buffer.write('- Weight: ${opp.weightKg!.toStringAsFixed(1)}kg (${lbs}lbs)\n');
        }
        if (opp.activeSinceYear != null) {
          final yearsActive = DateTime.now().year - int.parse(opp.activeSinceYear!);
          buffer.write('- Years Active: $yearsActive (since ${opp.activeSinceYear})\n');
        }
        if (opp.hands != null) {
          buffer.write('- Hands: ${opp.hands}\n');
        }
        if (opp.backhandType != null) {
          buffer.write('- Backhand: ${opp.backhandType}\n');
        }
      }

      buffer.write('\n### Opponent 2 Evaluation (scale 0-100, 50 is average)\n');

      buffer.write('\n**Physical Attributes:**\n');
      buffer.write('- Agility: ${opp.agility}, Mobility: ${opp.mobility}, Endurance: ${opp.endurance}\n');
      buffer.write('- Power: ${opp.power}, Reach: ${opp.reach}, Coordination: ${opp.coordination}\n');
      buffer.write('- Balance: ${opp.balance}, Lean Body: ${opp.leanBody}\n');

      buffer.write('\n**Technical Skills:**\n');
      buffer.write('- Serve: ${opp.serve}, Return: ${opp.returnServe}\n');
      buffer.write('- Forehand: ${opp.forehand}, Backhand: ${opp.backhand}\n');
      buffer.write('- Transition: ${opp.transition}, Net: ${opp.net}, Specialty: ${opp.specialty}\n');

      buffer.write('\n**Playing Styles:**\n');
      buffer.write('- Counterpuncher: ${opp.counterpuncher}, Aggressive Baseliner: ${opp.aggressiveBaseliner}\n');
      buffer.write('- All-Court: ${opp.allCourtPlayer}, Net Rusher: ${opp.netRusher}\n');
      buffer.write('- Serve & Volley: ${opp.serveAndVolleyer}, Big Server: ${opp.bigServer}\n');

      buffer.write('\n**Mental Attributes:**\n');
      buffer.write('- Focus: ${opp.focus}, Calmness: ${opp.calmness}\n');
      buffer.write('- Clutchness: ${opp.clutchness}, Confidence: ${opp.confidence}\n');

      buffer.write('\n**Support System:**\n');
      buffer.write('- Family: ${opp.family}, Coaches: ${opp.coaches}, Partners: ${opp.partners}\n');
      buffer.write('- Crowd: ${opp.crowd}, Sponsors: ${opp.sponsors}\n');
    }

    // Partner analytics (doubles only)
    if (_linkedPartner != null) {
      final partner = _linkedPartner!;

      // Profile information
      if (partner.birthYear != null || partner.heightCm != null || partner.weightKg != null ||
          partner.activeSinceYear != null || partner.hands != null || partner.backhandType != null) {
        buffer.write('\n### Partner Profile (${match.partnerName})\n');
        if (partner.birthYear != null) {
          final age = DateTime.now().year - partner.birthYear!;
          buffer.write('- Age: $age years old (born ${partner.birthYear})\n');
        }
        if (partner.heightCm != null) {
          final totalInches = partner.heightCm! / 2.54;
          final feet = (totalInches / 12).floor();
          final inches = (totalInches % 12).round();
          buffer.write("- Height: ${partner.heightCm}cm ($feet'$inches\")\n");
        }
        if (partner.weightKg != null) {
          final lbs = (partner.weightKg! * 2.20462).round();
          buffer.write('- Weight: ${partner.weightKg!.toStringAsFixed(1)}kg (${lbs}lbs)\n');
        }
        if (partner.activeSinceYear != null) {
          final yearsActive = DateTime.now().year - int.parse(partner.activeSinceYear!);
          buffer.write('- Years Active: $yearsActive (since ${partner.activeSinceYear})\n');
        }
        if (partner.hands != null) {
          buffer.write('- Hands: ${partner.hands}\n');
        }
        if (partner.backhandType != null) {
          buffer.write('- Backhand: ${partner.backhandType}\n');
        }
      }

      buffer.write('\n### Partner Evaluation (scale 0-100, 50 is average)\n');

      buffer.write('\n**Physical Attributes:**\n');
      buffer.write('- Agility: ${partner.agility}, Mobility: ${partner.mobility}, Endurance: ${partner.endurance}\n');
      buffer.write('- Power: ${partner.power}, Reach: ${partner.reach}, Coordination: ${partner.coordination}\n');
      buffer.write('- Balance: ${partner.balance}, Lean Body: ${partner.leanBody}\n');

      buffer.write('\n**Technical Skills:**\n');
      buffer.write('- Serve: ${partner.serve}, Return: ${partner.returnServe}\n');
      buffer.write('- Forehand: ${partner.forehand}, Backhand: ${partner.backhand}\n');
      buffer.write('- Transition: ${partner.transition}, Net: ${partner.net}, Specialty: ${partner.specialty}\n');

      buffer.write('\n**Playing Styles:**\n');
      buffer.write('- Counterpuncher: ${partner.counterpuncher}, Aggressive Baseliner: ${partner.aggressiveBaseliner}\n');
      buffer.write('- All-Court: ${partner.allCourtPlayer}, Net Rusher: ${partner.netRusher}\n');
      buffer.write('- Serve & Volley: ${partner.serveAndVolleyer}, Big Server: ${partner.bigServer}\n');

      buffer.write('\n**Mental Attributes:**\n');
      buffer.write('- Focus: ${partner.focus}, Calmness: ${partner.calmness}\n');
      buffer.write('- Clutchness: ${partner.clutchness}, Confidence: ${partner.confidence}\n');

      buffer.write('\n**Support System:**\n');
      buffer.write('- Family: ${partner.family}, Coaches: ${partner.coaches}, Partners: ${partner.partners}\n');
      buffer.write('- Crowd: ${partner.crowd}, Sponsors: ${partner.sponsors}\n');
    }

    // User's own profile
    if (_userProfile != null) {
      final me = _userProfile!;

      // Profile information
      if (me.level != null || me.birthYear != null || me.heightCm != null || me.weightKg != null ||
          me.activeSinceYear != null || me.hands != null || me.backhandType != null) {
        buffer.write('\n### Your Profile\n');
        if (me.level != null) {
          buffer.write('- Level: ${me.level}\n');
        }
        if (me.birthYear != null) {
          final age = DateTime.now().year - me.birthYear!;
          buffer.write('- Age: $age years old (born ${me.birthYear})\n');
        }
        if (me.heightCm != null) {
          final totalInches = me.heightCm! / 2.54;
          final feet = (totalInches / 12).floor();
          final inches = (totalInches % 12).round();
          buffer.write("- Height: ${me.heightCm}cm ($feet'$inches\")\n");
        }
        if (me.weightKg != null) {
          final lbs = (me.weightKg! * 2.20462).round();
          buffer.write('- Weight: ${me.weightKg!.toStringAsFixed(1)}kg (${lbs}lbs)\n');
        }
        if (me.activeSinceYear != null) {
          final yearsActive = DateTime.now().year - int.parse(me.activeSinceYear!);
          buffer.write('- Years Active: $yearsActive (since ${me.activeSinceYear})\n');
        }
        if (me.hands != null) {
          buffer.write('- Hands: ${me.hands}\n');
        }
        if (me.backhandType != null) {
          buffer.write('- Backhand: ${me.backhandType}\n');
        }
      }

      buffer.write('\n### Your Evaluation (scale 0-100, 50 is average)\n');

      buffer.write('\n**Physical Attributes:**\n');
      buffer.write('- Agility: ${me.agility}, Mobility: ${me.mobility}, Endurance: ${me.endurance}\n');
      buffer.write('- Power: ${me.power}, Reach: ${me.reach}, Coordination: ${me.coordination}\n');
      buffer.write('- Balance: ${me.balance}, Lean Body: ${me.leanBody}\n');

      buffer.write('\n**Technical Skills:**\n');
      buffer.write('- Serve: ${me.serve}, Return: ${me.returnServe}\n');
      buffer.write('- Forehand: ${me.forehand}, Backhand: ${me.backhand}\n');
      buffer.write('- Transition: ${me.transition}, Net: ${me.net}, Specialty: ${me.specialty}\n');

      buffer.write('\n**Playing Styles:**\n');
      buffer.write('- Counterpuncher: ${me.counterpuncher}, Aggressive Baseliner: ${me.aggressiveBaseliner}\n');
      buffer.write('- All-Court: ${me.allCourtPlayer}, Net Rusher: ${me.netRusher}\n');
      buffer.write('- Serve & Volley: ${me.serveAndVolleyer}, Big Server: ${me.bigServer}\n');

      buffer.write('\n**Mental Attributes:**\n');
      buffer.write('- Focus: ${me.focus}, Calmness: ${me.calmness}\n');
      buffer.write('- Clutchness: ${me.clutchness}, Confidence: ${me.confidence}\n');

      buffer.write('\n**Support System:**\n');
      buffer.write('- Family: ${me.family}, Coaches: ${me.coaches}, Partners: ${me.partners}\n');
      buffer.write('- Crowd: ${me.crowd}, Sponsors: ${me.sponsors}\n');
    }

    buffer.write('\nProvide advice and strategy specifically tailored to this match context. ');
    if (match.matchType == 'Doubles') {
      buffer.write('Consider your team\'s combined strengths/weaknesses, your partner\'s capabilities, the opposing team\'s strengths/weaknesses, doubles-specific positioning and communication, court conditions, and any other relevant details when giving recommendations.');
    } else {
      buffer.write('Consider both your strengths/weaknesses and the opponent\'s strengths/weaknesses, playing styles, court conditions, and any other relevant details when giving recommendations.');
    }

    return buffer.toString();
  }

  /// Send a message to Claude
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();

    if (text.isEmpty || _isLoading || _geminiService == null) {
      return;
    }

    // Clear input field
    _textController.clear();

    // Add user message
    final userMessage = ChatMessage.user(text);
    _addMessage(userMessage);

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Create conversation on first message if it doesn't exist
      if (_geminiService!.conversationId == null) {
        final conversationId = await _conversationService.createConversation(
          matchId: widget.matchId,
          title: null, // AI will generate title after first exchange
        );
        _geminiService!.setConversationId(conversationId);

        // Add the initial welcome message to history so it gets saved
        final welcomeMessage = _linkedMatch != null
            ? _buildMatchWelcomeMessage()
            : 'Hello! I\'m your tennis tactics coach. Ask me anything about tennis strategy, technique, shot selection, or match analysis. How can I help improve your game today?';
        _geminiService!.addMessage(role: 'assistant', content: welcomeMessage);
      }

      // Send message to Claude with tennis system prompt (including match context) and tools enabled
      final response = await _geminiService!.sendMessageWithSystem(
        message: text,
        systemPrompt: _buildMatchSystemPrompt(),
        maxTokens: ApiLimits.maxTokensLimit,
        temperature: ApiLimits.defaultTemperature,
        enableTools: true,
      );

      if (response['success'] == true) {
        // Add assistant response
        final assistantMessage = ChatMessage.assistant(
          response['message'] as String,
        );
        _addMessage(assistantMessage);

        // Auto-save after message exchange
        await _autoSave();

        // Generate title from match context or AI
        if (_geminiService!.conversationId != null) {
          if (_linkedMatch != null) {
            // Use match-based title: "Tactics vs [Opponent] on [Court]"
            final opponent = _linkedMatch!.opponentName;
            final court = _linkedMatch!.courtName;
            String title = 'Tactics vs $opponent';
            if (court != null && court.isNotEmpty) {
              title += ' on $court';
            }
            await _conversationService.updateTitle(
              _geminiService!.conversationId!,
              title,
            );
          } else {
            // Fall back to AI-generated title for standalone conversations
            await _conversationService.ensureConversationHasTitle(
              _geminiService!.conversationId!,
            );
          }
        }

        // Notify that conversation was updated
        widget.onConversationUpdated?.call();
      } else {
        // Add error message
        final errorMessage = ChatMessage.error(
          'Error: ${response['error'] ?? "Failed to get response"}',
        );
        _addMessage(errorMessage);
      }
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage.error(
        'Exception: ${e.toString()}',
      );
      _addMessage(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Add a message to the list and scroll to bottom
  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });

    // Scroll to bottom after a short delay to allow the widget to build
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Clear conversation history
  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text(
          'Are you sure you want to clear the entire conversation history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _messages.clear();
                _geminiService?.clearHistory();
              });
              Navigator.pop(context);

              // Create a new conversation
              final conversationId = await _conversationService.createConversation(
                matchId: widget.matchId,
                title: null, // AI will generate title after first exchange
              );
              _geminiService?.setConversationId(conversationId);

              // Add welcome message again (to UI and history)
              const welcomeMessage = 'Conversation cleared. How can I help you with your tennis game?';
              _addMessage(ChatMessage.assistant(welcomeMessage));
              _geminiService?.addMessage(role: 'assistant', content: welcomeMessage);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // When embedded in bottom navigation, only return body content
      // Parent HomeScreen will provide the Scaffold and bottom navigation
      return Column(
        children: [
          AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Menu',
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tennis Tactics App'),
                if (_linkedMatch != null)
                  Text(
                    'Match vs ${_linkedMatch!.opponentName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
              ],
            ),
            actions: [
              if (!_isInitializing && _initError == null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _messages.isEmpty ? null : _clearConversation,
                  tooltip: 'Clear conversation',
                ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }

    // Standalone mode - full Scaffold with AppBar
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tennis Tactics App'),
            if (_linkedMatch != null)
              Text(
                'Match vs ${_linkedMatch!.opponentName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
          ],
        ),
        actions: [
          if (!_isInitializing && _initError == null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _messages.isEmpty ? null : _clearConversation,
              tooltip: 'Clear conversation',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing Tennis Tactics App...'),
          ],
        ),
      );
    }

    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _initError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeService,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'Start a conversation about tennis tactics',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      // Show typing indicator
                      return const TypingIndicator();
                    }

                    final message = _messages[index];
                    return MessageBubble(message: message);
                  },
                ),
        ),

        // Input field
        _buildInputField(),
      ],
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Ask about tennis tactics...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isLoading,
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Material(
              color: _textController.text.isEmpty || _isLoading
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _isLoading ? null : _sendMessage,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.send,
                    color: _textController.text.isEmpty || _isLoading
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3)
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
