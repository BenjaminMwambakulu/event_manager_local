import 'package:flutter/material.dart';
import 'package:event_manager_local/models/attendee_model.dart';

class AttendeesTab extends StatelessWidget {
  final List<Attendee> attendees;
  final bool isLoading;

  const AttendeesTab({
    super.key,
    required this.attendees,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendees (${attendees.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : attendees.isEmpty
                  ? const Center(
                      child: Text(
                        'No attendees yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: attendees.length,
                      itemBuilder: (context, index) {
                        final attendee = attendees[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  attendee.checkIn ? Colors.green : Colors.grey,
                              child: Icon(
                                attendee.checkIn ? Icons.check : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(attendee.username),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (attendee.email.isNotEmpty)
                                  Text(attendee.email),
                                Text(
                                  'Registered: ${attendee.formattedRegistrationDate}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: attendee.checkIn
                                ? const Chip(
                                    label: Text(
                                      'Checked In',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.green,
                                    labelStyle:
                                        TextStyle(color: Colors.white),
                                  )
                                : const Chip(
                                    label: Text(
                                      'Pending',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.orange,
                                    labelStyle:
                                        TextStyle(color: Colors.white),
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