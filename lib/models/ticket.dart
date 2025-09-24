class Ticket {
  final String id;
  final String type;
  final double price;

  Ticket({required this.id, required this.type, required this.price});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      price: (json['price'] is num 
          ? json['price'] 
          : double.parse(json['price'].toString())),
    );
  }

  Map<String, dynamic> toJson(String eventId) {
    return {'event_id': eventId, 'type': type, 'price': price};
  }
}