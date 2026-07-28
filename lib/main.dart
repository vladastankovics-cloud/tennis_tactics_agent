import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tennis_tactics_agent/config/app_config.dart';
import 'package:tennis_tactics_agent/screens/setup_screen.dart';
import 'package:tennis_tactics_agent/screens/tactics_screen.dart';
import 'package:tennis_tactics_agent/screens/matches_list_screen.dart';
import 'package:tennis_tactics_agent/screens/play_screen.dart';
import 'package:tennis_tactics_agent/screens/practice_screen.dart';
import 'package:tennis_tactics_agent/screens/settings_screen.dart';
import 'package:tennis_tactics_agent/screens/my_profile_screen.dart';
import 'package:tennis_tactics_agent/models/match.dart';
import 'package:tennis_tactics_agent/models/conversation.dart';
import 'package:tennis_tactics_agent/repositories/conversation_repository.dart';
import 'package:tennis_tactics_agent/services/sync_service.dart';
import 'package:tennis_tactics_agent/utils/date_formatter.dart';
import 'package:tennis_tactics_agent/widgets/court_icon.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hzmhiitjcwwmlvwfnvea.supabase.co',
    anonKey: 'sb_publishable_qzLpQNV7Z1S1sUlBIOri-g_HVHk-kKs',
  );

  runApp(const TennisTacticsApp());
}

// Global Supabase client - use this throughout your app
final supabase = Supabase.instance.client;

class TennisTacticsApp extends StatelessWidget {
  const TennisTacticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tennis Tactics App',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          // Court blue as primary - bright vivid blue
          primary: Color(0xFF3B82C4),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD0E6FA),
          onPrimaryContainer: Color(0xFF0A2540),
          // Surround green as secondary
          secondary: Color(0xFF6B8F55),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFD0E4C4),
          onSecondaryContainer: Color(0xFF1E3A12),
          // Surface colors
          surface: Color(0xFFF5F8F2),
          onSurface: Color(0xFF1A1C19),
          surfaceContainerHighest: Color(0xFFE4EAE0),
          // Error colors
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          // Court blue as primary - bright for dark mode
          primary: Color(0xFF6AAEE8),
          onPrimary: Color(0xFF0A2540),
          primaryContainer: Color(0xFF2A6090),
          onPrimaryContainer: Color(0xFFD0E6FA),
          // Surround green as secondary
          secondary: Color(0xFF98C484),
          onSecondary: Color(0xFF1E3A12),
          secondaryContainer: Color(0xFF3F5A35),
          onSecondaryContainer: Color(0xFFD0E4C4),
          // Surface colors
          surface: Color(0xFF1A1C19),
          onSurface: Color(0xFFE2E3DE),
          surfaceContainerHighest: Color(0xFF2D302A),
          // Error colors
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Splash screen that determines which screen to show
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    // Give a brief moment to show splash
    await Future.delayed(const Duration(milliseconds: 500));

    final config = AppConfig();

    // Clear old model preference to use new default
    await config.deleteGeminiModel();

    // Check for Gemini API key
    final hasApiKey = await config.hasGeminiApiKey();

    if (!mounted) return;

    // Navigate to appropriate screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            hasApiKey ? const HomeScreen() : const SetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_tennis,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Tennis Tactics App',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ConversationRepository _conversationRepository = ConversationRepository();
  final SyncService _syncService = SyncService();
  List<Conversation> _conversations = [];
  bool _loadingConversations = true;
  int _currentIndex = 0;
  Match? _playMatch; // Match selected for Play mode
  Timer? _periodicSyncTimer;
  static const Duration _syncInterval = Duration(minutes: 10);

  List<Widget> get _screens => [
    MatchesListScreen(
      embedded: true,
      onPlayMatch: _onPlayMatch,
    ), // Plan
    PlayScreen(embedded: true, match: _playMatch), // Play
    const PracticeScreen(embedded: true), // Practice
  ];

  void _onPlayMatch(Match match) {
    setState(() {
      _playMatch = match;
      _currentIndex = 1; // Switch to Play tab
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConversations();
    _performInitialSync();
    _startPeriodicSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - sync and refresh
        debugPrint('🔄 App resumed - syncing...');
        _performSync();
        _loadConversations();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background - quick sync to upload any pending changes
        debugPrint('🔄 App paused - quick sync...');
        _performQuickSync();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App being terminated or hidden - nothing to do
        break;
    }
  }

  /// Perform initial sync on app launch
  Future<void> _performInitialSync() async {
    if (!_syncService.canSync) return;
    try {
      await _syncService.syncAll();
      _loadConversations(); // Refresh after sync
    } catch (e) {
      debugPrint('Initial sync failed: $e');
    }
  }

  /// Perform full sync (bidirectional)
  Future<void> _performSync() async {
    if (!_syncService.canSync) return;
    try {
      await _syncService.syncAll();
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  /// Perform quick sync (upload only)
  Future<void> _performQuickSync() async {
    if (!_syncService.canSync) return;
    try {
      await _syncService.quickSync();
    } catch (e) {
      debugPrint('Quick sync failed: $e');
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_syncInterval, (_) {
      debugPrint('🔄 Periodic sync triggered');
      _performSync();
    });
  }

  Future<void> _loadConversations() async {
    setState(() => _loadingConversations = true);
    try {
      final conversations = await _conversationRepository.getAllConversations();
      setState(() {
        _conversations = conversations;
        _loadingConversations = false;
      });
    } catch (e) {
      setState(() => _loadingConversations = false);
    }
  }

  void _openConversation(Conversation conversation) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TacticsScreen(
          conversationId: conversation.id,
          matchId: conversation.matchId,
          onConversationUpdated: _loadConversations,
        ),
      ),
    ).then((_) => _loadConversations()); // Refresh when returning
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete "${conversation.title ?? 'Untitled Chat'}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _conversationRepository.deleteConversation(conversation.id);
        _loadConversations(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete chat: $e')),
          );
        }
      }
    }
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithWidget(int index, Widget iconWidget, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Theme(
                data: Theme.of(context).copyWith(
                  iconTheme: IconThemeData(color: color),
                ),
                child: iconWidget,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _loadConversations();
        }
      },
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.sports_tennis,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tennis Tactics App',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ],
              ),
            ),
            // Conversations Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conversations',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_loadingConversations)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            // Conversations List - Scrollable
            Expanded(
              child: _conversations.isEmpty && !_loadingConversations
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'No conversations yet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        return ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            conversation.title ?? 'Untitled Conversation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormatter.formatRelative(conversation.updatedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            iconSize: 20,
                            color: Colors.grey,
                            onPressed: () => _deleteConversation(conversation),
                            tooltip: 'Delete conversation',
                          ),
                          onTap: () => _openConversation(conversation),
                        );
                      },
                    ),
            ),
            // Me
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.person,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black, offset: Offset(1, 0)),
                  Shadow(color: Colors.black, offset: Offset(-1, 0)),
                  Shadow(color: Colors.black, offset: Offset(0, 1)),
                  Shadow(color: Colors.black, offset: Offset(0, -1)),
                ],
              ),
              title: const Text('Me'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyProfileScreen(),
                  ),
                );
              },
            ),
            // Settings - Always at bottom
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.event_note_outlined, Icons.event_note, 'Plan'),
                _buildNavItem(1, Icons.sports_tennis_outlined, Icons.sports_tennis, 'Play'),
                _buildNavItemWithWidget(2, const CourtIcon(filled: false), 'Practice'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}