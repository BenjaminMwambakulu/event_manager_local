import 'package:flutter/material.dart';
import 'package:event_manager_local/models/event_model.dart';

class EventSelector extends StatelessWidget {
  final Event? selectedEvent;
  final List<Event> events;
  final Function(Event?) onChanged;
  final VoidCallback onEditEvent;
  final VoidCallback onDeleteEvent;

  const EventSelector({
    super.key,
    required this.selectedEvent,
    required this.events,
    required this.onChanged,
    required this.onEditEvent,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: Colors.black45),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<Event>(
              value: selectedEvent,
              isExpanded: true,
              hint: const Text('Select an event'),
              underline: Container(),
              items: events.map((event) {
                return DropdownMenuItem<Event>(
                  value: event,
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Event'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Event', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit' && selectedEvent != null) {
                onEditEvent();
              } else if (value == 'delete' && selectedEvent != null) {
                onDeleteEvent();
              }
            },
          ),
        ],
      ),
    );
  }
}