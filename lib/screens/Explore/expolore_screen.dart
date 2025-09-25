import 'package:event_manager_local/models/category_model.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/services/event_service.dart';
import 'package:event_manager_local/widgets/event_list_tiles.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EventService _eventService = EventService();
  late Future<List<CategoryModel>> _categoriesFuture;
  late Future<List<Event>> _eventsFuture;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _getAllCategories();
    _eventsFuture = _getAllEvents();
  }

  Future<List<CategoryModel>> _getAllCategories() async {
    try {
      final response = await _supabase.from('categories').select('*');
      final convertedCategories = (response as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return convertedCategories;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching categories: $e');
      }
      rethrow;
    }
  }

  Future<List<Event>> _getAllEvents() async {
    try {
      final response = await _eventService.getEvents();
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching events: $e');
      }
      rethrow;
    }
  }

  void _refreshEvents() {
    setState(() {
      _eventsFuture = _getAllEvents();
    });
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  List<Event> _filterEvents(List<Event> events) {
    if (_selectedCategory == null) return events;
    return events.where((event) => event.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.explore_outlined),
            SizedBox(width: 12),
            Text(
              'Explore Events',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshEvents();
          await _eventsFuture;
        },
        child: CustomScrollView(
          slivers: [
            // Search Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimaryContainer.withValues( alpha :0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withValues( alpha :0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      // Implement search functionality
                    },
                  ),
                ),
              ),
            ),

            // Categories Section
            SliverToBoxAdapter(
              child: FutureBuilder<List<CategoryModel>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorSection(
                      'Failed to load categories',
                      onRetry: () {
                        setState(() {
                          _categoriesFuture = _getAllCategories();
                        });
                      },
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final categories = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length + 1, // +1 for "All" category
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildCategoryChip(
                                'All',
                                isSelected: _selectedCategory == null,
                                onTap: () => _filterByCategory(null),
                              );
                            }
                            final category = categories[index - 1];
                            return _buildCategoryChip(
                              category.name,
                              isSelected: _selectedCategory == category.name,
                              onTap: () => _filterByCategory(category.name),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),

            // Events Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (_selectedCategory != null)
                      GestureDetector(
                        onTap: () => _filterByCategory(null),
                        child: Text(
                          'Clear filter',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Events List
            FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading events...'),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: _buildErrorSection(
                      'Failed to load events',
                      onRetry: _refreshEvents,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues( alpha :0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events found',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface.withValues( alpha :0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCategory != null 
                                ? 'Try changing the category filter'
                                : 'Check back later for new events',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues( alpha :0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final events = _filterEvents(snapshot.data!);
                
                if (events.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues( alpha :0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No events in this category',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface.withValues( alpha :0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _filterByCategory(null),
                            child: const Text('Show all events'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = events[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: EventListTiles(
                          events: [event],
                          onTap: (event) {
                            Navigator.pushNamed(
                              context,
                              "/event_details",
                              arguments: event,
                            );
                          },
                        ),
                      );
                    },
                    childCount: events.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String category, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(
        category,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surfaceVariant.withValues( alpha :0.3),
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues( alpha :0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      showCheckmark: true,
    );
  }

  Widget _buildErrorSection(String message, {required VoidCallback onRetry}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}