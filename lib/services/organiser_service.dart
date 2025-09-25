import 'package:event_manager_local/models/event_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganiserService {
  final SupabaseClient _supabase = Supabase.instance.client;
  Future<List<Event>> getOrganisedEvents() async {
    final response = await _supabase
        .from('events')
        .select('''
          *,
          profiles (*)
        ''')
        .eq('user_id', _supabase.auth.currentUser!.id)
        .eq('role', "organiser")
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
