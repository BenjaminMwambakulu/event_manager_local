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
}
