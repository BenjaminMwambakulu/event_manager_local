import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/models/profile.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HorizontalTicketsSection extends StatelessWidget {
  const HorizontalTicketsSection({super.key});

  // Sample data for user tickets
  List<Event> get _sampleUserTickets {
    return [
      Event(
        id: 'evt_001',
        title: 'Flutter Conference 2024',
        description: 'Annual Flutter developer conference',
        location: 'Convention Center, Downtown',
        bannerUrl: 'https://example.com/banner1.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        startDateTime: DateTime.now().add(const Duration(days: 15)),
        endDateTime: DateTime.now().add(const Duration(days: 15, hours: 8)),
        isFeatured: true,
        organiser: Profile(
          id: 'org_001',
          username: 'flutter_org',
          profileUrl: 'https://example.com/profile1.jpg',
        ),
        tickets: [
          Ticket(id: 'tkt_001', type: 'VIP', price: 299.99),
        ],
        categoryIds: ['tech'],
      ),
      Event(
        id: 'evt_002',
        title: 'Tech Meetup',
        description: 'Monthly tech meetup for developers',
        location: 'Tech Hub, Silicon Valley',
        bannerUrl: 'https://example.com/banner2.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        startDateTime: DateTime.now().subtract(const Duration(days: 5)),
        endDateTime: DateTime.now().subtract(const Duration(days: 5, hours: -3)),
        isFeatured: false,
        organiser: Profile(
          id: 'org_002',
          username: 'tech_hub',
          profileUrl: 'https://example.com/profile2.jpg',
        ),
        tickets: [
          Ticket(id: 'tkt_002', type: 'General', price: 49.99),
        ],
        categoryIds: ['networking'],
      ),
      Event(
        id: 'evt_003',
        title: 'Design Workshop',
        description: 'UI/UX design workshop for beginners',
        location: 'Design Studio, Creative District',
        bannerUrl: 'https://example.com/banner3.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        startDateTime: DateTime.now().add(const Duration(days: 7)),
        endDateTime: DateTime.now().add(const Duration(days: 7, hours: 6)),
        isFeatured: false,
        organiser: Profile(
          id: 'org_003',
          username: 'design_studio',
          profileUrl: 'https://example.com/profile3.jpg',
        ),
        tickets: [
          Ticket(id: 'tkt_003', type: 'Premium', price: 149.99),
        ],
        categoryIds: ['design'],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final userTickets = _sampleUserTickets;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 12.0, top: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "My Tickets",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${userTickets.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: userTickets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tickets available',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: userTickets.map((event) {
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        child: TicketCard(event: event),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class TicketCard extends StatelessWidget {
  final Event event;

  const TicketCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';
    final qrData = 'event_${event.id}_user_$userId';
    final status = _getEventStatus(event.startDateTime, event.endDateTime);
    final ticketPrice = event.tickets.isNotEmpty ? event.tickets.first.price : 0.0;
    final ticketType = event.tickets.isNotEmpty ? event.tickets.first.type : 'General';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showTicketDetails(context, event);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with event name and status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Ticket type and price
                Row(
                  children: [
                    Text(
                      ticketType,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${ticketPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // QR Code section
                Row(
                  children: [
                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: qrData,
                        size: 60,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Ticket details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _formatDate(event.startDateTime),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getEventStatus(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      return 'Active';
    } else if (now.isAfter(endTime)) {
      return 'Expired';
    } else {
      return 'Live';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'live':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showTicketDetails(BuildContext context, Event event) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';
    final qrData = 'event_${event.id}_user_$userId';
    final ticketPrice = event.tickets.isNotEmpty ? event.tickets.first.price : 0.0;
    final ticketType = event.tickets.isNotEmpty ? event.tickets.first.type : 'General';
    final status = _getEventStatus(event.startDateTime, event.endDateTime);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Large QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: qrData,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Event details
                _buildDetailRow('Event ID:', event.id),
                _buildDetailRow('Type:', ticketType),
                _buildDetailRow('Price:', '\$${ticketPrice.toStringAsFixed(2)}'),
                _buildDetailRow('Date:', _formatDate(event.startDateTime)),
                _buildDetailRow('Location:', event.location),
                _buildDetailRow('Status:', status),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}