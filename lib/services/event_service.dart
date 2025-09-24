import 'package:event_manager_local/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Event>> getEvents() async {
    try {
      final response = await _supabase
          .from('events')
          .select('''
          *,
          profiles (*),
          tickets (*),
          event_categories (*)
        ''')
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error fetching events: $e");
      return [];
    }
  }
}
