import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/models/attendee_model.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:event_manager_local/models/payment.dart';

class EventManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Load all events for a specific organizer
  Future<List<Event>> loadEvents(String organizerId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('''
            *,
            profiles!events_organiser_id_fkey (
              id,
              username,
              email,
              profile_url
            )
          ''')
          .eq('organiser_id', organizerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((eventJson) => Event.fromJson(eventJson))
          .toList();
    } catch (e) {
      throw Exception('Failed to load events: ${e.toString()}');
    }
  }

  /// Load attendees with profile information for a specific event
  Future<List<Attendee>> loadAttendees(String eventId) async {
    try {
      final response = await _supabase
          .from('attendee')
          .select('''
            *,
            profiles!attendee_user_id_fkey (
              id,
              username,
              email,
              phone,
              profile_url
            )
          ''')
          .eq('event_id', eventId);

      return (response as List)
          .map((json) => Attendee.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load attendees: ${e.toString()}');
    }
  }

  /// Load tickets for a specific event
  Future<List<Ticket>> loadTickets(String eventId) async {
    try {
      final response = await _supabase
          .from('tickets')
          .select('*')
          .eq('event_id', eventId);

      return (response as List)
          .map((json) => Ticket.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tickets: ${e.toString()}');
    }
  }

  /// Load payments with profile information for a specific event
  Future<List<Payment>> loadPayments(String eventId) async {
    try {
      final response = await _supabase
          .from('payment')
          .select('''
            *,
            profiles!payment_user_id_fkey (
              id,
              username,
              email,
              profile_url
            )
          ''')
          .eq('event_id', eventId)
          .order('payment_date', ascending: false);

      return (response as List)
          .map((json) => Payment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load payments: ${e.toString()}');
    }
  }

  /// Create a new event
  Future<void> createEvent(Event event) async {
    try {
      await _supabase.from('events').insert(event.toJson());
    } catch (e) {
      throw Exception('Failed to create event: ${e.toString()}');
    }
  }

  /// Update an existing event
  Future<void> updateEvent(Event event) async {
    try {
      await _supabase.from('events').update(event.toJson()).eq('id', event.id);
    } catch (e) {
      throw Exception('Failed to update event: ${e.toString()}');
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
    } catch (e) {
      throw Exception('Failed to delete event: ${e.toString()}');
    }
  }

  /// Create a new ticket
  Future<void> createTicket(Ticket ticket, String eventId) async {
    try {
      await _supabase.from('tickets').insert(ticket.toJson(eventId));
    } catch (e) {
      throw Exception('Failed to create ticket: ${e.toString()}');
    }
  }

  /// Update an existing ticket
  Future<void> updateTicket(Ticket ticket, String eventId) async {
    try {
      await _supabase
          .from('tickets')
          .update(ticket.toJson(eventId))
          .eq('id', ticket.id);
    } catch (e) {
      throw Exception('Failed to update ticket: ${e.toString()}');
    }
  }

  /// Delete a ticket
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _supabase.from('tickets').delete().eq('id', ticketId);
    } catch (e) {
      throw Exception('Failed to delete ticket: ${e.toString()}');
    }
  }
}