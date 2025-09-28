import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketCard extends StatelessWidget {
  final Event event;

  const TicketCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';
    final qrData = 'event_${event.id}_user_$userId';
    final status = _getEventStatus(event.startDateTime, event.endDateTime);
    final ticketPrice = event.tickets.isNotEmpty
        ? event.tickets.first.price
        : 0.0;
    final ticketType = event.tickets.isNotEmpty
        ? event.tickets.first.type
        : 'General';

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
                      'MK ${ticketPrice.toStringAsFixed(2)}',
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
                                  event.location!,
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
    final ticketPrice = event.tickets.isNotEmpty
        ? event.tickets.first.price
        : 0.0;
    final ticketType = event.tickets.isNotEmpty
        ? event.tickets.first.type
        : 'General';
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                _buildDetailRow(
                  'Price:',
                  'MK ${ticketPrice.toStringAsFixed(2)}',
                ),
                _buildDetailRow('Date:', _formatDate(event.startDateTime)),
                _buildDetailRow('Location:', event.location!),
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
