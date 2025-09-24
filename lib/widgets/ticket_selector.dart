import 'package:flutter/material.dart';
import 'package:event_manager_local/models/ticket.dart';

class TicketSelector extends StatefulWidget {
  final List<Ticket> tickets;
  final Ticket? selectedTicket;
  final Function(Ticket?) onTicketSelected;

  const TicketSelector({
    super.key,
    required this.tickets,
    required this.selectedTicket,
    required this.onTicketSelected,
  });

  @override
  State<TicketSelector> createState() => _TicketSelectorState();
}

class _TicketSelectorState extends State<TicketSelector> {
  @override
  Widget build(BuildContext context) {
    if (widget.tickets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Ticket',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.tickets.map((ticket) => _buildTicketCard(ticket)),
      ],
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final isSelected = widget.selectedTicket?.id == ticket.id;
    final isFree = ticket.price == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onTicketSelected(
            isSelected ? null : ticket,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.05)
                  : Colors.white,
            ),
            child: Row(
              children: [
                // Selection indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Ticket info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.type,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : null,
                        ),
                      ),
                      if (!isFree) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Price per ticket',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isFree ? 'FREE' : '\$${ticket.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isFree 
                            ? Colors.green 
                            : isSelected 
                                ? Theme.of(context).primaryColor 
                                : null,
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
}