import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/models/attendee_model.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:event_manager_local/models/payment.dart';
import 'package:event_manager_local/screens/event_management/widgets/stat_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:event_manager_local/utils/image_utils.dart';

class OverviewTab extends StatelessWidget {
  final Event event;
  final List<Attendee> attendees;
  final List<Ticket> tickets;
  final List<Payment> payments;

  const OverviewTab({
    super.key,
    required this.event,
    required this.attendees,
    required this.tickets,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final checkedInCount = attendees.where((a) => a.checkIn).length;

    // Include both 'success' and 'completed' status for revenue calculation
    final totalRevenue = payments
        .where(
          (p) => p.paymentStatus == 'success' || p.paymentStatus == 'completed',
        )
        .fold(0.0, (sum, p) => sum + p.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.bannerUrl != null && event.bannerUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: ImageUtils.fixImageUrl(event.bannerUrl!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      if (event.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    Text(
                      event.description!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location ?? 'Location TBD',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${DateFormat('MMM dd, yyyy - HH:mm').format(event.startDateTime)} - ${DateFormat('HH:mm').format(event.endDateTime)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Attendees',
                  attendees.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Checked In',
                  checkedInCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Ticket Types',
                  tickets.length.toString(),
                  Icons.confirmation_number,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Revenue',
                  'MK ${totalRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return StatCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
    );
  }
}