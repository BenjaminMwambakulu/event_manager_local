import 'package:event_manager_local/models/category_model.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/services/event_service.dart';
import 'package:event_manager_local/widgets/event_list_tiles.dart';
import 'package:event_manager_local/widgets/featured_courasel.dart';
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

  // Controllers and states
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  late Future<List<Event>> _eventsFuture;
  late Future<List<CategoryModel>> _categoriesFuture;
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _eventsFuture = _getAllEvents();
    _categoriesFuture = _getAllCategories();
  }

  // Fetch events from Supabase
  Future<List<Event>> _getAllEvents() async {
    try {
      final response = await _eventService.getEvents();
      return response;
    } catch (e) {
      if (kDebugMode) print('Error fetching events: $e');
      return [];
    }
  }

  // Fetch categories
  Future<List<CategoryModel>> _getAllCategories() async {
    try {
      final response = await _supabase.from('categories').select('*');
      return (response as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching categories: $e');
      return [];
    }
  }

  // Filter by category + search
  List<Event> _filterEvents(List<Event> events) {
    final query = _searchController.text.trim().toLowerCase();

    return events.where((event) {
      final matchesCategory =
          _selectedCategory == null ||
          event.categoryIds.contains(_selectedCategory); // use categoryIds
      final matchesSearch =
          query.isEmpty || event.title.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // Get only featured events
  Future<List<Event>> _getFeaturedEvents() async {
    try {
      // Reuse your event service
      final allEvents = await _eventService.getEvents();

      // Filter only featured ones
      return allEvents.where((event) => event.isFeatured).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching featured events: $e");
      }
      return [];
    }
  }

  // Refresh handler
  Future<void> _refreshEvents() async {
    setState(() {
      _eventsFuture = _getAllEvents();
      _categoriesFuture = _getAllCategories();
    });
  }

  // Build empty states
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? message,
    VoidCallback? onAction,
    String actionLabel = 'Show all events',
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  // Build category chips
  Widget _buildCategoryChips(List<CategoryModel> categories) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];

          return ChoiceChip(
            label: Text(
              category.name,
              style: TextStyle(
                color: _selectedCategory == category.id
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            selected: _selectedCategory == category.id,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? category.id : null;
              });
            },
            backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            selectedColor: Theme.of(context).colorScheme.primary,
            showCheckmark: false,
            side: BorderSide(
              color: _selectedCategory == category.id
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 1),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            avatar: _selectedCategory == category.id
                ? Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [Icon(Icons.explore), SizedBox(width: 8), Text('Explore')],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshEvents,
        child: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search events...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            // Category chips
            SliverToBoxAdapter(
              child: FutureBuilder<List<CategoryModel>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return _buildEmptyState(
                      icon: Icons.error_outline,
                      title: 'Failed to load categories',
                      message: 'Please try again later.',
                      onAction: _refreshEvents,
                      actionLabel: 'Retry',
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.category_outlined,
                      title: 'No categories available',
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCategoryChips(snapshot.data!),
                  );
                },
              ),
            ),

            // Featured events
            SliverToBoxAdapter(
              child: FutureBuilder<List<Event>>(
                future: _getFeaturedEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  }
                  final featuredEvents = snapshot.data ?? [];
                  return FeaturedCarousel(featuredEvents);
                },
              ),
            ),

            // Events list
            SliverToBoxAdapter(child: SizedBox(height: 30)),
            FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(
                      icon: Icons.error_outline,
                      title: 'Failed to load events',
                      message: 'Please check your connection and try again.',
                      onAction: _refreshEvents,
                      actionLabel: 'Retry',
                    ),
                  );
                }
                final events = snapshot.data ?? [];
                final filteredEvents = _filterEvents(events);

                if (filteredEvents.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _buildEmptyState(
                      icon: Icons.event_busy,
                      title: 'No events found',
                      message: _selectedCategory != null
                          ? 'No events match your selected category.'
                          : 'Try a different search.',
                      onAction: () {
                        setState(() {
                          _selectedCategory = null;
                          _searchController.clear();
                        });
                      },
                      actionLabel: 'Clear filters',
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final event = filteredEvents[index];
                    return EventListTiles(
                      events: [event], // If EventListTiles expects a list
                      onTap: (event) {
                        Navigator.pushNamed(
                          context,
                          "/event_details",
                          arguments: event,
                        );
                      },
                    );
                  }, childCount: filteredEvents.length),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
