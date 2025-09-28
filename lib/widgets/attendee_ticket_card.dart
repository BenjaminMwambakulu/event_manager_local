import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:event_manager_local/models/attendee_model.dart';

class AttendeeTicketCard extends StatelessWidget {
  final Attendee attendee;
  final VoidCallback? onTap;

  const AttendeeTicketCard({
    super.key,
    required this.attendee,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final event = attendee.event;
    final ticket = attendee.ticket;
    
    if (event == null || ticket == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      height: 200, // Fixed height to prevent overflow
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:  0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event Info Section
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor.withValues(alpha:0.1),
                          Theme.of(context).primaryColor.withValues(alpha:0.05),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Title
                        Flexible(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Event Details
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _formatDateTime(event.startDateTime),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        
                        // Ticket Type and Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${ticket.type} - ${ticket.price == 0 ? 'FREE' : 'MK ${ticket.price.toStringAsFixed(2)}'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Dotted Separator
                _buildDottedSeparator(),
                
                // QR Code Section
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: QrImageView(
                            data: attendee.qrCodeData,
                            size: 50,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                        const SizedBox(width: 10),
                        
                        // QR Info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Ticket',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Show QR at entrance',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Reg: ${attendee.formattedRegistrationDate}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDottedSeparator() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              height: 1,
              color: index % 2 == 0 ? Colors.grey.shade300 : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final hour = dateTime.hour % 12;
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$month $day • ${hour == 0 ? 12 : hour}:$minute $period';
  }
}