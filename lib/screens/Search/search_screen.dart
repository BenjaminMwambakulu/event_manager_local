import 'package:event_manager_local/models/event_model.dart';
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

  /// Search both events and profiles (and expand relations)
  Future<void> _search(String query) async {
    setState(() => _loading = true);

    try {
      // 🔍 Search events by title or location
      final eventsResponse = await _supabase
          .from('events')
          .select('*, profiles(*), tickets(*), event_categories(*)')
          .or('title.ilike.%$query%,location.ilike.%$query%');

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
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search events or profiles...',
                  border: InputBorder.none,
                ),
                onChanged: (query) => _search(query),
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text("No results"))
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(event.bannerUrl),
                      ),
                      title: Text(event.title),
                      subtitle: Text(event.location),
                    );
                  },
                ),
    );
  }
}
