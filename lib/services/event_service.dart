import 'package:event_manager_local/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Event>> getEvents({int? limit}) async {
    try {
      var query = _supabase
          .from('events')
          .select('''
          *,
          profiles (*),
          tickets (*),
          event_categories (*)
        ''')
          .order('created_at', ascending: true);
          
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;

      debugPrint("Raw response from Supabase: $response");
      
      final events = (response as List<dynamic>)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
          
      debugPrint("Parsed ${events.length} events successfully");
      return events;
    } catch (e) {
      debugPrint("Error fetching events: $e");
      return [];
    }
  }

  // Handle Register to an Event
  Future<void> registerToEvent(String eventId, String profileId, String ticketId) async {
    try {
      await _supabase.from('attendee').insert({
        'event_id': eventId,
        'user_id': profileId, // This should be the profile ID, not auth user ID
        'ticket_id': ticketId
      });
      debugPrint("Successfully registered user $profileId to event $eventId");
    } catch (e) {
      debugPrint("Error registering to event: $e");
      rethrow; // Re-throw so the calling code can handle it
    }
  }
}


