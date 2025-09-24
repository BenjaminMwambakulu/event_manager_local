// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/services/event_service.dart';
import 'package:event_manager_local/widgets/event_list_tiles.dart';
import 'package:event_manager_local/widgets/featured_courasel.dart';
import 'package:event_manager_local/widgets/my_ticket_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? username;
  List<Event> events = [];
  List<Event> featuredEvents = [];
  List<Event> upcomingEvents = [];

  @override
  void dispose() {
    // Any necessary cleanup can be done here
    super.dispose();
  }

  void getUserInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Check if the widget is still mounted before setting state
    if (mounted) {
      setState(() {
        username = prefs.getString('username');
      });
    }
  }

  void getEvents() async {
    final EventService eventService = EventService();
    final List<Event> events = await eventService.getEvents();
    setState(() {
      this.events = events;
    });
  }

  void getFeaturedEvents() async {
    final EventService eventService = EventService();
    final List<Event> allEvents = await eventService.getEvents();
    if (kDebugMode) {
      print('Total events fetched: ${allEvents.length}');
    }

    final List<Event> featuredEvents = allEvents
        .where((event) => event.isFeatured)
        .toList();

    final List<Event> upcomingEvents = allEvents
        .where((event) => event.startDateTime.isAfter(DateTime.now()))
        .toList();

    if (kDebugMode) {
      print('Featured events found: ${featuredEvents.length}');
      print('Upcoming events found: ${upcomingEvents.length}');
    }
    for (var event in allEvents) {
      if (kDebugMode) {
        print('Event: ${event.title}, isFeatured: ${event.isFeatured}');
      }
    }

    setState(() {
      this.featuredEvents = featuredEvents;
      this.upcomingEvents = upcomingEvents;
    });
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();
    getFeaturedEvents();
  }

  Future<void> _signOut() async {
    try {
      final SupabaseClient _supabase = Supabase.instance.client;
      await _supabase.auth.signOut();
    } catch (e) {
      // Check if the widget is still mounted before showing snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage("assets/images/profile.png"),
            ),
            SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Welcome,", style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  username ?? "User",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none)),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text("Logout"),
                onTap: () {
                  Future.delayed(Duration.zero, () async {
                    await _signOut();
                    // Check if the widget is still mounted before navigating
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            // Featured carousel with fixed height
            Container(
              height: 280,
              width: double.infinity,
              child: FeaturedCarousel(featuredEvents),
            ),
            SizedBox(height: 20),
            // Event list with flexible height
            EventListTiles(
              events: upcomingEvents,
              title: "Upcoming Events",
              limit: 10, // Show only first 10 events by default
            ),
            SizedBox(height: 20),
            // MyTicketCard
            MyTicketCard(),
            SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }
}
