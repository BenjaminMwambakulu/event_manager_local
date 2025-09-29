import 'package:event_manager_local/models/profile.dart';

class Payment {
  final String id;
  final String? userId;
  final String eventId;
  final String? ticketId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String paymentStatus;
  final Profile? profile;

  Payment({
    required this.id,
    this.userId,
    required this.eventId,
    this.ticketId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.paymentStatus,
    this.profile,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      userId: json['user_id']?.toString(),
      eventId: json['event_id'].toString(),
      ticketId: json['ticket_id']?.toString(),
      amount: double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'] ?? '',
      paymentDate: DateTime.parse(json['payment_date']),
      paymentStatus: json['payment_status'] ?? 'pending',
      profile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'])
          : null,
    );
  }

  String get username => profile?.username ?? 'Unknown';
  String get email => profile?.email ?? '';
}