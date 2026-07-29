import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/date_formatter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();

  bool _isSyncing = false;
  Map<String, dynamic>? _syncInfo;

  @override
  void initState() {
    super.initState();
    _loadSyncInfo();
    _syncService.addListener(_onSyncStatusChanged);
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncStatusChanged);
    super.dispose();
  }

  void _onSyncStatusChanged() {
    _loadSyncInfo();
  }

  Future<void> _loadSyncInfo() async {
    final info = await _syncService.getSyncInfo();
    if (mounted) {
      setState(() {
        _syncInfo = info;
      });
    }
  }

  Future<void> _performSync() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);

    try {
      await _syncService.syncAll();
      await _loadSyncInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _pullFromCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pull from Cloud'),
        content: const Text(
          'This will replace your local data with data from the cloud. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pull'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isSyncing = true);

    try {
      await _syncService.pullFromCloud();
      await _loadSyncInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data pulled from cloud successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pull failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _pushToCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Push to Cloud'),
        content: const Text(
          'This will upload all your local data to the cloud. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Push'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isSyncing = true);

    try {
      await _syncService.pushToCloud();
      await _loadSyncInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data pushed to cloud successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Push failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your local data will remain on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildDataRow(String label, String localValue, String cloudValue, ThemeData theme) {
    final localNum = int.tryParse(localValue);
    final cloudNum = int.tryParse(cloudValue);
    final isDifferent = localNum != null && cloudNum != null && localNum != cloudNum;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        Expanded(
          child: Text(
            localValue,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDifferent ? Colors.orange : null,
            ),
          ),
        ),
        Expanded(
          child: Text(
            cloudValue,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDifferent ? Colors.orange : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Sync'),
      ),
      body: _syncInfo == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // User Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.primaryColor,
                          child: Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.email ?? 'Not signed in',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _authService.isSignedIn ? 'Signed In' : 'Guest',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sync Status
                Text(
                  'Sync Status',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          _syncService.status == SyncStatus.success
                              ? Icons.check_circle
                              : _syncService.status == SyncStatus.error
                                  ? Icons.error
                                  : _syncService.status == SyncStatus.syncing
                                      ? Icons.sync
                                      : Icons.cloud_off,
                          color: _syncService.status == SyncStatus.success
                              ? Colors.green
                              : _syncService.status == SyncStatus.error
                                  ? Colors.red
                                  : Colors.grey,
                        ),
                        title: Text(
                          _syncService.status.toString().split('.').last.toUpperCase(),
                        ),
                        subtitle: _syncService.lastSyncTime != null
                            ? Text(
                                'Last synced: ${DateFormatter.formatDateTime(_syncService.lastSyncTime!)}')
                            : const Text('Never synced'),
                      ),
                      if (_syncService.lastError != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error: ${_syncService.lastError}',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sync Actions
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _performSync,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSyncing ? null : _pullFromCloud,
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Pull'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSyncing ? null : _pushToCloud,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Push'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Data Statistics - Side by side comparison
                if (_syncInfo!['local'] != null || _syncInfo!['remote'] != null) ...[
                  Text(
                    'Data Statistics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Header row
                          Row(
                            children: [
                              const Expanded(
                                flex: 2,
                                child: Text(''),
                              ),
                              Expanded(
                                child: Text(
                                  'Local',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Cloud',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          // User Profile row
                          _buildDataRow(
                            'User Profile',
                            _syncInfo!['local']?['user_profile']?.toString() ?? '-',
                            _syncInfo!['remote']?['user_profile']?.toString() ?? '-',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          // Opponents row
                          _buildDataRow(
                            'Opponents',
                            _syncInfo!['local']?['opponents']?.toString() ?? '-',
                            _syncInfo!['remote']?['opponents']?.toString() ?? '-',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          // Matches row
                          _buildDataRow(
                            'Matches',
                            _syncInfo!['local']?['matches']?.toString() ?? '-',
                            _syncInfo!['remote']?['matches']?.toString() ?? '-',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          // Tactics row
                          _buildDataRow(
                            'Tactics',
                            _syncInfo!['local']?['ai_tactics']?.toString() ?? '-',
                            _syncInfo!['remote']?['ai_tactics']?.toString() ?? '-',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          // Play Adjustments row
                          _buildDataRow(
                            'Adjustments',
                            _syncInfo!['local']?['play_adjustments']?.toString() ?? '-',
                            _syncInfo!['remote']?['play_adjustments']?.toString() ?? '-',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          // Practice Drills row
                          _buildDataRow(
                            'Drills',
                            _syncInfo!['local']?['practice_drills']?.toString() ?? '-',
                            _syncInfo!['remote']?['practice_drills']?.toString() ?? '-',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          // Conversations row
                          _buildDataRow(
                            'Conversations',
                            _syncInfo!['local']?['conversations']?.toString() ?? '-',
                            _syncInfo!['remote']?['conversations']?.toString() ?? '-',
                            theme,
                          ),
                          const SizedBox(height: 12),
                          // Messages row
                          _buildDataRow(
                            'Messages',
                            _syncInfo!['local']?['messages']?.toString() ?? '-',
                            _syncInfo!['remote']?['messages']?.toString() ?? '-',
                            theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Sign Out Button
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
    );
  }
}
