import 'package:flutter/material.dart';
import '../models/match.dart';
import '../repositories/match_repository.dart';
import '../widgets/match_card.dart';
import '../widgets/empty_state_widget.dart';
import 'match_detail_screen.dart';
import 'match_form_screen.dart';
import 'tactics_screen.dart';

class MatchesListScreen extends StatefulWidget {
  final bool embedded;
  final void Function(Match match)? onPlayMatch;

  const MatchesListScreen({super.key, this.embedded = false, this.onPlayMatch});

  @override
  State<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends State<MatchesListScreen> {
  final MatchRepository _repository = MatchRepository();
  List<Match> _matches = [];
  List<Match> _filteredMatches = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'soon'; // 'past', 'soon', 'future', or 'all'

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    try {
      final matches = await _repository.getAllMatches();
      setState(() {
        _matches = matches;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading matches: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = _matches;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((match) {
        return match.opponentName
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply temporal filter
    final now = DateTime.now();
    final twoWeeksFromNow = now.add(const Duration(days: 14));

    if (_filterType == 'past') {
      // Past: matches with dates that have passed (exclude null dates)
      filtered = filtered.where((match) {
        return match.matchDate != null && match.matchDate!.isBefore(now);
      }).toList();
      // Sort descending (most recent first)
      filtered.sort((a, b) => b.matchDate!.compareTo(a.matchDate!));
    } else if (_filterType == 'soon') {
      // Soon: matches in the next 2 weeks (exclude null dates)
      filtered = filtered.where((match) {
        if (match.matchDate == null) return false;
        return match.matchDate!.isAfter(now) &&
            match.matchDate!.isBefore(twoWeeksFromNow);
      }).toList();
      // Sort ascending (soonest first)
      filtered.sort((a, b) => a.matchDate!.compareTo(b.matchDate!));
    } else if (_filterType == 'future') {
      // Future: matches beyond 2 weeks OR matches with no date (null date = future)
      filtered = filtered.where((match) {
        if (match.matchDate == null) return true; // Null dates are treated as future
        return match.matchDate!.isAfter(twoWeeksFromNow) ||
            match.matchDate!.isAtSameMomentAs(twoWeeksFromNow);
      }).toList();
      // Sort ascending (soonest first), null dates go to the end
      filtered.sort((a, b) {
        if (a.matchDate == null && b.matchDate == null) return 0;
        if (a.matchDate == null) return 1; // a goes after b
        if (b.matchDate == null) return -1; // b goes after a
        return a.matchDate!.compareTo(b.matchDate!);
      });
    } else if (_filterType == 'all') {
      // All: all matches sorted descending, null dates go to the top
      filtered.sort((a, b) {
        if (a.matchDate == null && b.matchDate == null) return 0;
        if (a.matchDate == null) return -1; // a goes before b
        if (b.matchDate == null) return 1; // b goes before a
        return b.matchDate!.compareTo(a.matchDate!);
      });
    }

    _filteredMatches = filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _setFilter(String filterType) {
    setState(() {
      _filterType = filterType;
      _applyFilters();
    });
  }

  Future<void> _navigateToAddMatch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MatchFormScreen(),
      ),
    );

    if (result == true) {
      _loadMatches();
    }
  }

  Future<void> _navigateToMatchDetail(Match match) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailScreen(matchId: match.id),
      ),
    );

    if (result == true) {
      _loadMatches();
    }
  }

  void _openPlayMode(Match match) {
    if (widget.onPlayMatch != null) {
      widget.onPlayMatch!(match);
    }
  }

  Widget _buildBody() {
    return Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Past'),
                  selected: _filterType == 'past',
                  onSelected: (_) => _setFilter('past'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Soon'),
                  selected: _filterType == 'soon',
                  onSelected: (_) => _setFilter('soon'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Future'),
                  selected: _filterType == 'future',
                  onSelected: (_) => _setFilter('future'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('All'),
                  selected: _filterType == 'all',
                  onSelected: (_) => _setFilter('all'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Matches list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMatches.isEmpty
                    ? EmptyStateWidget(
                        icon: _searchQuery.isNotEmpty || _filterType != 'all'
                            ? Icons.search_off
                            : Icons.sports_tennis,
                        title: _searchQuery.isNotEmpty || _filterType != 'all'
                            ? 'No matches found'
                            : 'No matches yet',
                        message: _searchQuery.isNotEmpty || _filterType != 'all'
                            ? 'Try adjusting your search or filters'
                            : 'Add your first match to start tracking your tennis games',
                        actionLabel:
                            _searchQuery.isEmpty && _filterType == 'all'
                                ? 'Add Match'
                                : null,
                        onActionPressed:
                            _searchQuery.isEmpty && _filterType == 'all'
                                ? _navigateToAddMatch
                                : null,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMatches,
                        child: ListView.builder(
                          itemCount: _filteredMatches.length,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemBuilder: (context, index) {
                            final match = _filteredMatches[index];
                            return MatchCard(
                              match: match,
                              onTap: () => _navigateToMatchDetail(match),
                              onLongPress: () => _openPlayMode(match),
                            );
                          },
                        ),
                      ),
          ),
        ],
      );
  }

  Future<void> _navigateToChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TacticsScreen(),
      ),
    );
    _loadMatches(); // Refresh when returning from chat
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // When embedded
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
            title: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search matches...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadMatches,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _navigateToAddMatch,
                tooltip: 'Add Match',
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }

    // Standalone mode - full Scaffold
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search matches...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMatches,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMatch,
        tooltip: 'Add Match',
        child: const Icon(Icons.add),
      ),
    );
  }
}
