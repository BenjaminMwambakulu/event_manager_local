import 'package:flutter/material.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/models/ticket.dart';

class Attendee {
  final String id;
  final String userId;
  final String eventId;
  final String ticketId;
  final DateTime registeredAt;
  final Event? event;
  final Ticket? ticket;

  Attendee({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.ticketId,
    required this.registeredAt,
    this.event,
    this.ticket,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    try {
      return Attendee(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        eventId: json['event_id'].toString(),
        ticketId: json['ticket_id'].toString(),
        registeredAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
        event: json['events'] != null ? Event.fromJson(json['events']) : null,
        ticket: json['tickets'] != null ? Ticket.fromJson(json['tickets']) : null,
      );
    } catch (e) {
      debugPrint('Attendee.fromJson: Error parsing JSON: $e');
      rethrow;
    }
  }

  /// Generate QR code data for this attendee
  String get qrCodeData {
    return 'attendee_${id}_event_${eventId}_ticket_$ticketId';
  }

  /// Get formatted registration date
  String get formattedRegistrationDate {
    return '${registeredAt.day}/${registeredAt.month}/${registeredAt.year}';
  }
}