import 'package:flutter/material.dart';
import 'package:event_manager_local/models/ticket.dart';

class TicketsTab extends StatelessWidget {
  final List<Ticket> tickets;
  final bool isLoading;
  final VoidCallback onAddTicket;
  final Function(Ticket) onEditTicket;
  final Function(Ticket) onDeleteTicket;

  const TicketsTab({
    super.key,
    required this.tickets,
    required this.isLoading,
    required this.onAddTicket,
    required this.onEditTicket,
    required this.onDeleteTicket,
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
              const Text(
                'Ticket Types',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: onAddTicket,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : tickets.isEmpty
                  ? const Center(
                      child: Text(
                        'No tickets created yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.black,
                              child: const Icon(
                                Icons.confirmation_number,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(ticket.type),
                            subtitle:
                                Text('MK ${ticket.price.toStringAsFixed(2)}'),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEditTicket(ticket);
                                } else if (value == 'delete') {
                                  onDeleteTicket(ticket);
                                }
                              },
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