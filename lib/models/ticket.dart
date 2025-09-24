class Ticket {
  final int id;
  final String type;
  final double price;

  Ticket({required this.id, required this.type, required this.price});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      type: json['type'] ?? '',
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson(int eventId) {
    return {'event_id': eventId, 'type': type, 'price': price};
  }
}
