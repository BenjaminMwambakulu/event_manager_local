import 'dart:async';

import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/widgets/event_list_tiles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Event> _events = [];
  bool _loading = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Debounced search to avoid excessive API calls
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _events.clear();
        _hasSearched = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _hasSearched = true;
    });

    try {
      // 🔍 Search events by title or location
      final eventsResponse = await _supabase
          .from('events')
          .select('*, profiles(*), tickets(*), event_categories(*)')
          .or('title.ilike.%$query%,location.ilike.%$query%')
          .order('created_at', ascending: false);

      final events = (eventsResponse as List)
          .map((e) => Event.fromJson(e))
          .toList();

      setState(() {
        _events = events;
      });

      // 🔍 Search profiles separately (if needed in UI)
      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%');

      if (kDebugMode) {
        print("Profiles found: $profilesResponse");
      }

    } catch (e) {
      if (kDebugMode) {
        print("Search error: $e");
      }
      // Show error state if needed
    } finally {
      setState(() => _loading = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _events.clear();
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.search),
            const SizedBox(width: 8),
            const Text("Search Events"),
          ],
        ) ,
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        ),
                        
                      ],
                      border: Border.all(
                        color: Colors.black.withValues(alpha:  0.1),
                        width: 1,
                      ),  
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Search events by title or location...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[500],
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[500],
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: _buildResultsContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent(ThemeData theme) {
    if (!_hasSearched) {
      return _buildEmptyState(theme);
    }

    if (_loading) {
      return _buildLoadingState();
    }

    if (_events.isEmpty) {
      return _buildNoResultsState(theme);
    }

    return _buildResultsList();
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.search_rounded,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha:0.3),
          ),
          const SizedBox(height: 24),
          Text(
            "Find Events",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Search for events by title, location, or category",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:0.7),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip("Concert", theme),
              _buildSuggestionChip("Conference", theme),
              _buildSuggestionChip("Workshop", theme),
              _buildSuggestionChip("Networking", theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _performSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha:0.3),
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Searching events..."),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha:0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No events found",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try different keywords or check the spelling",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha:0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            "Found ${_events.length} event${_events.length == 1 ? '' : 's'}",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.8),
                ),
          ),
        ),
        Expanded(
          child: EventListTiles(
            events: _events,
            onTap:(event) {
                Navigator.pushNamed(
                  context,
                  '/event_details',
                  arguments: event,
                );
              },
          ),
        ),
      ],
    );
  }
}