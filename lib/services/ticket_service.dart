import 'package:flutter/material.dart';
import 'package:event_manager_local/models/attendee_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all tickets for the current user
  Future<List<Attendee>> getUserTickets() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('TicketService: No authenticated user found');
        return [];
      }

      // Get the profile ID for the current user
      final profileId = await _getUserProfileId(user.id);
      if (profileId == null) {
        debugPrint('TicketService: No profile found for user ${user.id}');
        return [];
      }

      // Fetch attendee records with related event and ticket data
      final response = await _supabase
          .from('attendee')
          .select('''
            *,
            events (
              *,
              profiles (*)
            ),
            tickets (*)
          ''')
          .eq('user_id', profileId)
          .order('created_at', ascending: false);

      debugPrint('TicketService: Fetched ${response.length} tickets for user');
      
      final attendees = (response as List<dynamic>)
          .map((json) => Attendee.fromJson(json as Map<String, dynamic>))
          .toList();

      return attendees;
    } catch (e) {
      debugPrint('TicketService: Error fetching user tickets: $e');
      return [];
    }
  }

  /// Get tickets for a specific event
  Future<List<Attendee>> getEventTickets(String eventId) async {
    try {
      final response = await _supabase
          .from('attendee')
          .select('''
            *,
            events (*),
            tickets (*),
            profiles (*)
          ''')
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => Attendee.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching event tickets: $e');
      return [];
    }
  }

  /// Check if user has a ticket for a specific event
  Future<Attendee?> getUserTicketForEvent(String eventId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profileId = await _getUserProfileId(user.id);
      if (profileId == null) return null;

      final response = await _supabase
          .from('attendee')
          .select('''
            *,
            events (
              *,
              profiles (*)
            ),
            tickets (*)
          ''')
          .eq('user_id', profileId)
          .eq('event_id', eventId)
          .maybeSingle();

      if (response != null) {
        return Attendee.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error checking user ticket for event: $e');
      return null;
    }
  }

  /// Get ticket count for the current user
  Future<int> getUserTicketCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final profileId = await _getUserProfileId(user.id);
      if (profileId == null) return 0;

      final response = await _supabase
          .from('attendee')
          .select('id')
          .eq('user_id', profileId);

      return response.length;
    } catch (e) {
      debugPrint('Error getting user ticket count: $e');
      return 0;
    }
  }

  /// Get the profile ID for a given auth user ID
  Future<String?> _getUserProfileId(String authUserId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', authUserId)
          .maybeSingle();

      return response?['id']?.toString();
    } catch (e) {
      debugPrint('TicketService: Error getting user profile ID: $e');
      return null;
    }
  }

  /// Validate a QR code and return attendee info
  Future<Attendee?> validateQRCode(String qrData) async {
    try {
      // Parse QR code data: attendee_${id}_event_${eventId}_ticket_${ticketId}
      final parts = qrData.split('_');
      if (parts.length < 6 || parts[0] != 'attendee') {
        return null;
      }

      final attendeeId = parts[1];
      
      final response = await _supabase
          .from('attendee')
          .select('''
            *,
            events (
              *,
              profiles (*)
            ),
            tickets (*)
          ''')
          .eq('id', attendeeId)
          .maybeSingle();

      if (response != null) {
        return Attendee.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error validating QR code: $e');
      return null;
    }
  }
}