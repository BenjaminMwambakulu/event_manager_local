import 'package:event_manager_local/models/profile.dart';
import 'package:event_manager_local/models/ticket.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final String location;
  final String bannerUrl;
  final DateTime createdAt;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isFeatured;
  final Profile organiser;
  final List<Ticket> tickets;
  final List<int> categoryIds;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.bannerUrl,
    required this.createdAt,
    required this.startDateTime,
    required this.endDateTime,
    required this.isFeatured,
    required this.organiser,
    required this.tickets,
    required this.categoryIds,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      bannerUrl: json['banner_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      startDateTime: DateTime.parse(json['start_datetime']),
      endDateTime: DateTime.parse(json['end_datetime']),
      isFeatured: json['isFeatured'] ?? false,
      organiser: Profile.fromJson(json['profiles'] ?? {}),
      tickets: (json['tickets'] as List<dynamic>? ?? [])
          .map((t) => Ticket.fromJson(t))
          .toList(),
      categoryIds: (json['event_categories'] as List<dynamic>? ?? [])
          .map((c) => c['category_id'] as int)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'banner_url': bannerUrl,
      'start_datetime': startDateTime.toIso8601String(),
      'end_datetime': endDateTime.toIso8601String(),
      'isFeatured': isFeatured,
      'organiser_id': organiser.id, // FK
    };
  }
}
