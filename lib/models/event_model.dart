import 'package:event_manager_local/models/profile.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:flutter/foundation.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final String? bannerUrl;
  final String organiserId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Profile? organiser;
  final List<Ticket> tickets;
  final List<String> categoryIds;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.bannerUrl,
    required this.organiserId,
    required this.startDateTime,
    required this.endDateTime,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
    this.organiser,
    this.tickets = const [],
    this.categoryIds = const [],
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    try {
      return Event(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        description: json['description'],
        location: json['location'],
        bannerUrl: json['banner_url'],
        organiserId: json['organiser_id'].toString(),
        startDateTime: DateTime.parse(json['start_datetime']),
        endDateTime: DateTime.parse(json['end_datetime']),
        isFeatured: json['is_featured'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        organiser: json['profiles'] != null ? Profile.fromJson(json['profiles']) : null,
        tickets: (json['tickets'] as List<dynamic>? ?? [])
            .map((t) => Ticket.fromJson(t))
            .toList(),
        categoryIds: (json['event_categories'] as List<dynamic>? ?? [])
            .map((c) => c['category_id'].toString())
            .toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing event: $e');
        print('JSON data: $json');
      }
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'banner_url': bannerUrl,
      'organiser_id': organiserId,
      'start_datetime': startDateTime.toIso8601String(),
      'end_datetime': endDateTime.toIso8601String(),
      'is_featured': isFeatured,
    };
  }
}