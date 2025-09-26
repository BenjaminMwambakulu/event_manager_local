import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/utils/image_utils.dart';

class OrganiserAllEvents extends StatefulWidget {
  const OrganiserAllEvents({super.key});

  @override
  State<OrganiserAllEvents> createState() => _OrganiserAllEventsState();
}

class _OrganiserAllEventsState extends State<OrganiserAllEvents> {
  final _supabase = Supabase.instance.client;
  List<Event> _events = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _loading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not authenticated")),
          );
        }
        return;
      }

      final response = await _supabase
          .from('events')
          .select('*, profiles(*), tickets(*), event_categories(category_id)')
          .eq('organiser_id', user.id)
          .order('created_at', ascending: false);

      final events = response.map((json) => Event.fromJson(json)).toList();
      setState(() => _events = events);
    // ignore: dead_code
        } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Database error: ${e.message}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading events: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
      setState(() {
        _events.removeWhere((e) => e.id == eventId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event deleted")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Events')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No events found"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchEvents,
                        child: const Text("Refresh"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _events.length,
                  itemBuilder: (context, index) =>
                      _buildEventCard(_events[index]),
                ),
    );
  }

  Widget _buildEventCard(Event event) {
    final minPrice = event.tickets.isNotEmpty
        ? event.tickets.map((t) => t.price).reduce((a, b) => a < b ? a : b)
        : 0.0;
    final maxPrice = event.tickets.isNotEmpty
        ? event.tickets.map((t) => t.price).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image(
              image:
                  ImageUtils.cachedNetworkImageProvider(event.bannerUrl) ??
                      const AssetImage('assets/default_banner.png')
                          as ImageProvider,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${event.startDateTime.toLocal()} - ${event.endDateTime.toLocal()}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                if (event.tickets.isNotEmpty)
                  Text(
                    "Tickets: \$$minPrice - \$$maxPrice",
                    style: const TextStyle(color: Colors.black87),
                  ),
                const SizedBox(height: 8),
                Text(
                  "Total attendees: (todo)", // placeholder
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  "Total check-ins: (todo)",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: navigate to attendees page
                      },
                      child: const Text("View attendees"),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: navigate to edit event page
                      },
                      child: const Text("Edit"),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteEvent(event.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}