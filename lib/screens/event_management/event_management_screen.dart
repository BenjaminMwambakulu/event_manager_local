// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/models/attendee_model.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:event_manager_local/models/payment.dart';
import 'package:event_manager_local/services/event_management_service.dart';
import 'package:event_manager_local/screens/event_management/widgets/overview_tab.dart';
import 'package:event_manager_local/screens/event_management/widgets/attendees_tab.dart';
import 'package:event_manager_local/screens/event_management/widgets/tickets_tab.dart';
import 'package:event_manager_local/screens/event_management/widgets/payments_tab.dart';
import 'package:event_manager_local/screens/event_management/widgets/event_selector.dart';
import 'package:event_manager_local/screens/event_management/widgets/empty_state.dart';
import 'package:event_manager_local/screens/event_management/widgets/error_state.dart';
import 'package:event_manager_local/screens/event_management/dialogs/event_dialog.dart';
import 'package:event_manager_local/screens/event_management/dialogs/ticket_dialog.dart';
import 'package:event_manager_local/screens/event_management/dialogs/delete_confirmation_dialog.dart';

class EventManagementPage extends StatefulWidget {
  final String organiserId;

  const EventManagementPage({super.key, required this.organiserId});

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventManagementService _eventService = EventManagementService();

  List<Event> events = [];
  Event? selectedEvent;
  List<Attendee> attendees = [];
  List<Ticket> tickets = [];
  List<Payment> payments = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      events = await _eventService.loadEvents(widget.organiserId);

      if (events.isNotEmpty) {
        selectedEvent = events.first;
        await _loadEventDetails(selectedEvent!.id);
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadEventDetails(String eventId) async {
    try {
      setState(() => isLoading = true);

      // Load attendees with profile information
      attendees = await _eventService.loadAttendees(eventId);

      // Load tickets
      tickets = await _eventService.loadTickets(eventId);

      // Load payments with profile information
      payments = await _eventService.loadPayments(eventId);

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _createEvent(Event event) async {
    try {
      await _eventService.createEvent(event);
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateEvent(Event event) async {
    try {
      await _eventService.updateEvent(event);
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update event: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _eventService.deleteEvent(eventId);
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete event: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createTicket(Ticket ticket) async {
    if (selectedEvent == null) return;

    try {
      await _eventService.createTicket(ticket, selectedEvent!.id);
      await _loadEventDetails(selectedEvent!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ticket: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateTicket(Ticket ticket) async {
    if (selectedEvent == null) return;

    try {
      await _eventService.updateTicket(ticket, selectedEvent!.id);
      await _loadEventDetails(selectedEvent!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update ticket: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteTicket(String ticketId) async {
    if (selectedEvent == null) return;

    try {
      await _eventService.deleteTicket(ticketId);
      await _loadEventDetails(selectedEvent!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete ticket: ${e.toString()}')),
        );
      }
    }
  }

  void _showCreateEventDialog() {
    EventDialog.showCreateEventDialog(
      context,
      widget.organiserId,
      _createEvent,
    );
  }

  void _showEditEventDialog(Event event) {
    EventDialog.showEditEventDialog(
      context,
      event,
      _updateEvent,
    );
  }

  void _showDeleteEventDialog(Event event) {
    DeleteConfirmationDialog.showDeleteEventDialog(
      context,
      event,
      _deleteEvent,
    );
  }

  void _showAddTicketDialog() {
    if (selectedEvent == null) return;

    TicketDialog.showAddTicketDialog(
      context,
      _createTicket,
    );
  }

  void _showEditTicketDialog(Ticket ticket) {
    TicketDialog.showEditTicketDialog(
      context,
      ticket,
      _updateTicket,
    );
  }

  void _showDeleteTicketDialog(Ticket ticket) {
    DeleteConfirmationDialog.showDeleteTicketDialog(
      context,
      ticket,
      _deleteTicket,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
        ],
      ),
      body: error != null
          ? ErrorState(
              errorMessage: error!,
              onRetry: _loadEvents,
            )
          : isLoading && events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : events.isEmpty
                  ? EmptyState(
                      title: 'No events found',
                      message: 'Create your first event to get started',
                      onAction: _showCreateEventDialog,
                      actionText: 'Create Event',
                    )
                  : Column(
                      children: [
                        EventSelector(
                          selectedEvent: selectedEvent,
                          events: events,
                          onChanged: (Event? event) async {
                            if (event != null) {
                              setState(() {
                                selectedEvent = event;
                              });
                              await _loadEventDetails(event.id);
                            }
                          },
                          onEditEvent: () =>
                              _showEditEventDialog(selectedEvent!),
                          onDeleteEvent: () =>
                              _showDeleteEventDialog(selectedEvent!),
                        ),
                        _buildTabBar(),
                        Expanded(child: _buildTabBarView()),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.black87,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 18)),
          Tab(text: 'Attendees', icon: Icon(Icons.people, size: 18)),
          Tab(text: 'Tickets', icon: Icon(Icons.confirmation_number, size: 18)),
          Tab(text: 'Payments', icon: Icon(Icons.payment, size: 18)),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    if (selectedEvent == null) return Container();

    return TabBarView(
      controller: _tabController,
      children: [
        OverviewTab(
          event: selectedEvent!,
          attendees: attendees,
          tickets: tickets,
          payments: payments,
        ),
        AttendeesTab(
          attendees: attendees,
          isLoading: isLoading,
        ),
        TicketsTab(
          tickets: tickets,
          isLoading: isLoading,
          onAddTicket: _showAddTicketDialog,
          onEditTicket: _showEditTicketDialog,
          onDeleteTicket: _showDeleteTicketDialog,
        ),
        PaymentsTab(
          payments: payments,
          isLoading: isLoading,
        ),
      ],
    );
  }
}