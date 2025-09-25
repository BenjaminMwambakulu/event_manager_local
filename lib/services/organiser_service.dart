import 'package:supabase_flutter/supabase_flutter.dart';

class OrganiserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Helper: get current organiser's profile.id (not auth.users.id)
  Future<String?> _getCurrentProfileId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    return response?['id'] as String?;
  }

  /// Fetch all events organised by the current user
  Future<List<Map<String, dynamic>>> getOrganiserEvents() async {
    try {
      final profileId = await _getCurrentProfileId();
      if (profileId == null) return [];

      final response = await _supabase
          .from('events')
          .select('*, profiles(*)')
          .eq('organiser_id', profileId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  /// Get organiser's event IDs (used in other queries)
  Future<List<String>> _getOrganiserEventIds() async {
    final profileId = await _getCurrentProfileId();
    if (profileId == null) return [];

    final eventResponse = await _supabase
        .from('events')
        .select('id')
        .eq('organiser_id', profileId);

    final eventIds = (eventResponse as List)
        .map((e) => e['id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    return eventIds;
  }

  /// Get total registrations for organiser's events
  Future<int> getTotalRegistrations() async {
    try {
      final eventIds = await _getOrganiserEventIds();
      if (eventIds.isEmpty) return 0;

      final response = await _supabase
          .from('attendee')
          .select('id')
          .inFilter('event_id', eventIds);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total check-ins
  Future<int> getTotalCheckins() async {
    try {
      final eventIds = await _getOrganiserEventIds();
      if (eventIds.isEmpty) return 0;

      final response = await _supabase
          .from('attendee')
          .select('id')
          .eq('check_in', true)
          .inFilter('event_id', eventIds);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get total revenue from payments
  Future<double> getTotalRevenue() async {
    try {
      final eventIds = await _getOrganiserEventIds();
      if (eventIds.isEmpty) return 0.0;

      final response = await _supabase
          .from('payment')
          .select('amount')
          .eq('payment_status', 'completed')
          .inFilter('event_id', eventIds);

      double total = 0.0;
      for (var payment in response as List) {
        if (payment['amount'] != null) {
          total += (payment['amount'] as num).toDouble();
        }
      }

      return total;
    } catch (e) {
      return 0.0;
    }
  }
}
