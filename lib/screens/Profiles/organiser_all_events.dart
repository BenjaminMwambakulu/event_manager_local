import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventManagementPage extends StatefulWidget {
  final String organiserId; 

  const EventManagementPage({super.key, required this.organiserId});

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => loading = true);

    // Step 1: Fetch events by organiser
    final response = await supabase
        .from('events')
        .select()
        .eq('organiser_id', widget.organiserId);

    final data = response as List<dynamic>;
    events = [];

    // Step 2: For each event, fetch other data separately
    for (var e in data) {
      final eventId = e['id'];

      // Tickets
      final tickets = await supabase
          .from('tickets')
          .select()
          .eq('event_id', eventId);

      // Attendees
      final attendees = await supabase
          .from('attendee')
          .select()
          .eq('event_id', eventId);

      // Payments
      final payments = await supabase
          .from('payment')
          .select()
          .eq('event_id', eventId);

      // Categories (via event_categories)
      final eventCategories = await supabase
          .from('event_categories')
          .select()
          .eq('event_id', eventId);

      // Ratings (via event_rating)
      final eventRatings = await supabase
          .from('event_rating')
          .select()
          .eq('event_id', eventId);

      events.add({
        'event': e,
        'tickets': tickets,
        'attendees': attendees,
        'payments': payments,
        'categories': eventCategories,
        'ratings': eventRatings,
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Organiser Event Management")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index];
                final event = e['event'];
                final tickets = e['tickets'] as List;
                final attendees = e['attendees'] as List;
                final payments = e['payments'] as List;

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event['title'] ?? 'Untitled',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(event['description'] ?? ''),
                        const SizedBox(height: 8),
                        Text("Tickets: ${tickets.length}"),
                        Text("Attendees: ${attendees.length}"),
                        Text("Payments: ${payments.length}"),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Navigate to detailed event page
                          },
                          child: const Text("Manage Event"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
