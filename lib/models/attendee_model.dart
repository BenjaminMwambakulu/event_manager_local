import 'package:flutter/material.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:event_manager_local/models/profile.dart';

class Attendee {
  final String id;
  final String? userId;
  final String eventId;
  final String? ticketId;
  final DateTime createdAt;
  final bool checkIn;
  final Event? event;
  final Ticket? ticket;
  final Profile? profile;

  Attendee({
    required this.id,
    this.userId,
    required this.eventId,
    this.ticketId,
    required this.createdAt,
    this.checkIn = false,
    this.event,
    this.ticket,
    this.profile,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    try {
      return Attendee(
        id: json['id'].toString(),
        userId: json['user_id']?.toString(),
        eventId: json['event_id'].toString(),
        ticketId: json['ticket_id']?.toString(),
        createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        checkIn: json['check_in'] ?? false,
        event: json['events'] != null ? Event.fromJson(json['events']) : null,
        ticket: json['tickets'] != null
            ? Ticket.fromJson(json['tickets'])
            : null,
        profile: json['profiles'] != null
            ? Profile.fromJson(json['profiles'])
            : null,
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
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Helper getters for easier access
  String get username => profile?.username ?? 'Unknown User';
  String get email => profile?.email ?? '';
  String get phone => ''; // Add phone to Profile model if needed
}
