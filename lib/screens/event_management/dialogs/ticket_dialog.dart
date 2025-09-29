import 'package:flutter/material.dart';
import 'package:event_manager_local/models/ticket.dart';

class TicketDialog {
  static Future<void> showAddTicketDialog(
    BuildContext context,
    Function(Ticket) onCreate,
  ) async {
    final typeController = TextEditingController();
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Ticket Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Ticket Type *',
                border: OutlineInputBorder(),
                hintText: 'e.g., General, VIP, Student',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price *',
                border: OutlineInputBorder(),
                prefixText: 'MK ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (typeController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                final price = double.tryParse(priceController.text);
                if (price != null && price >= 0) {
                  final ticket = Ticket(
                    id: '',
                    type: typeController.text,
                    price: price,
                  );
                  Navigator.pop(context);
                  onCreate(ticket);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  static Future<void> showEditTicketDialog(
    BuildContext context,
    Ticket ticket,
    Function(Ticket) onUpdate,
  ) async {
    final typeController = TextEditingController(text: ticket.type);
    final priceController =
        TextEditingController(text: ticket.price.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Ticket Type *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price *',
                border: OutlineInputBorder(),
                prefixText: 'MK ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (typeController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                final price = double.tryParse(priceController.text);
                if (price != null && price >= 0) {
                  final updatedTicket = Ticket(
                    id: ticket.id,
                    type: typeController.text,
                    price: price,
                  );
                  Navigator.pop(context);
                  onUpdate(updatedTicket);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}