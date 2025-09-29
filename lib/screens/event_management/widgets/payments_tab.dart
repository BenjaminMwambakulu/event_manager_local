import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:event_manager_local/models/payment.dart';

class PaymentsTab extends StatelessWidget {
  final List<Payment> payments;
  final bool isLoading;

  const PaymentsTab({
    super.key,
    required this.payments,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    // Include both 'success' and 'completed' status
    final totalRevenue = payments
        .where(
          (p) => p.paymentStatus == 'success' || p.paymentStatus == 'completed',
        )
        .fold(0.0, (sum, p) => sum + p.amount);

    final pendingAmount = payments
        .where((p) => p.paymentStatus == 'pending')
        .fold(0.0, (sum, p) => sum + p.amount);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Revenue',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'MK ${totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'MK ${pendingAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : payments.isEmpty
                  ? const Center(
                      child: Text(
                        'No payments yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        // Check for both 'success' and 'completed' status
                        final isCompleted = payment.paymentStatus == 'success' ||
                            payment.paymentStatus == 'completed';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCompleted
                                  ? Colors.green
                                  : payment.paymentStatus == 'pending'
                                      ? Colors.orange
                                      : Colors.red,
                              child: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : payment.paymentStatus == 'pending'
                                        ? Icons.schedule
                                        : Icons.error,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                                'MK ${payment.amount.toStringAsFixed(2)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${payment.username} - ${payment.paymentMethod}',
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy - HH:mm')
                                      .format(payment.paymentDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                payment.paymentStatus.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: isCompleted
                                  ? Colors.green
                                  : payment.paymentStatus == 'pending'
                                      ? Colors.orange
                                      : Colors.red,
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}