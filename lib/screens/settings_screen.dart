import 'package:flutter/material.dart';
import 'package:tennis_tactics_agent/config/app_config.dart';
import 'package:tennis_tactics_agent/config/constants.dart';
import 'package:tennis_tactics_agent/screens/setup_screen.dart';
import 'package:tennis_tactics_agent/screens/login_screen.dart';
import 'package:tennis_tactics_agent/screens/account_screen.dart';
import 'package:tennis_tactics_agent/services/database_service.dart';
import 'package:tennis_tactics_agent/services/auth_service.dart';

/// Settings screen for managing API key and preferences
class SettingsScreen extends StatefulWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppConfig _config = AppConfig();
  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService();

  String? _currentModel;
  bool _hasApiKey = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final model = await _config.getGeminiModel();
    final hasKey = await _config.hasGeminiApiKey();

    setState(() {
      _currentModel = model;
      _hasApiKey = hasKey;
      _isLoading = false;
    });
  }

  Future<void> _changeApiKey() async {
    // Navigate to setup screen to change API key
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SetupScreen(),
      ),
    );

    // Reload settings after returning
    if (result != null || mounted) {
      _loadSettings();
    }
  }

  Future<void> _deleteApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API Key'),
        content: const Text(
          'Are you sure you want to delete your API key? You will need to set it up again to use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _config.clearAll();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const SetupScreen(),
        ),
      );
    }
  }

  Future<void> _changeModel() async {
    final selectedModel = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GeminiModels.all.map((model) {
            return RadioListTile<String>(
              title: Text(GeminiModels.getDisplayName(model)),
              subtitle: Text(GeminiModels.getDescription(model)),
              value: model,
              groupValue: _currentModel,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (selectedModel != null) {
      await _config.setGeminiModel(selectedModel);
      _loadSettings();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model changed to ${GeminiModels.getDisplayName(selectedModel)}'),
        ),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all matches and conversations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _databaseService.clearAllData();
      _loadSettings();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared successfully'),
        ),
      );
    }
  }

  Future<void> _navigateToAccount() async {
    if (_authService.isSignedIn) {
      // Navigate to account screen
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AccountScreen()),
      );
    } else {
      // Navigate to login screen
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
    _loadSettings();
  }

  Widget _buildBody(ThemeData theme) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
              children: [
                const SizedBox(height: 16),

                // Account & Sync Section
                ListTile(
                  leading: Icon(
                    _authService.isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                    color: _authService.isSignedIn ? Colors.green : Colors.grey,
                  ),
                  title: Text(_authService.isSignedIn ? 'Account & Sync' : 'Sign In'),
                  subtitle: Text(
                    _authService.isSignedIn
                        ? 'Signed in as ${_authService.userEmail}'
                        : 'Sign in to sync your data across devices',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _navigateToAccount,
                ),
                const Divider(),

                // API Key Section
                ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('API Key'),
                  subtitle: Text(
                    _hasApiKey ? 'API key configured' : 'No API key set',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changeApiKey,
                ),
                const Divider(),

                // Model Selection
                ListTile(
                  leading: const Icon(Icons.psychology),
                  title: const Text('Model'),
                  subtitle: Text(
                    _currentModel != null
                        ? GeminiModels.getDisplayName(_currentModel!)
                        : 'Not set',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changeModel,
                ),
                const Divider(),

                const SizedBox(height: 16),

                // Danger Zone
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'DANGER ZONE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete API Key',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('Remove all stored configuration'),
                  onTap: _deleteApiKey,
                ),

                ListTile(
                  leading: Icon(
                    Icons.storage,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Clear All Data',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('Delete all matches and conversations'),
                  onTap: _clearAllData,
                ),

                const SizedBox(height: 32),

                // App Info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.sports_tennis, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Tennis Tactics App',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Powered by Gemini AI',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.embedded) {
      // When embedded in bottom navigation, only return content
      return Column(
        children: [
          AppBar(
            title: const Text('Settings'),
          ),
          Expanded(child: _buildBody(theme)),
        ],
      );
    }

    // Standalone mode - full Scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _buildBody(theme),
    );
  }
}
