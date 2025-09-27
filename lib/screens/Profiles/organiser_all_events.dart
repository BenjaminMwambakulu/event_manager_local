import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your existing models
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/models/attendee_model.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:event_manager_local/models/profile.dart';

// Add this Payment model to your models folder
class Payment {
  final String id;
  final String? userId;
  final String eventId;
  final String? ticketId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String paymentStatus;
  final Profile? profile;

  Payment({
    required this.id,
    this.userId,
    required this.eventId,
    this.ticketId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.paymentStatus,
    this.profile,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      userId: json['user_id']?.toString(),
      eventId: json['event_id'].toString(),
      ticketId: json['ticket_id']?.toString(),
      amount: double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'] ?? '',
      paymentDate: DateTime.parse(json['payment_date']),
      paymentStatus: json['payment_status'] ?? 'pending',
      profile: json['profiles'] != null ? Profile.fromJson(json['profiles']) : null,
    );
  }

  String get username => profile?.username ?? 'Unknown';
  String get email => profile?.email ?? '';
}

class EventManagementPage extends StatefulWidget {
  final String organiserId;

  const EventManagementPage({Key? key, required this.organiserId}) : super(key: key);

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient supabase = Supabase.instance.client;
  
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

      final response = await supabase
          .from('events')
          .select('''
            *,
            profiles!events_organiser_id_fkey (
              id,
              username,
              email,
              profile_url
            )
          ''')
          .eq('organiser_id', widget.organiserId)
          .order('created_at', ascending: false);

      events = (response as List)
          .map((eventJson) => Event.fromJson(eventJson))
          .toList();

      if (events.isNotEmpty) {
        selectedEvent = events.first;
        await _loadEventDetails(selectedEvent!.id);
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        error = 'Failed to load events: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadEventDetails(String eventId) async {
    try {
      setState(() => isLoading = true);

      // Load attendees with profile information
      final attendeesResponse = await supabase
          .from('attendee')
          .select('''
            *,
            profiles!attendee_user_id_fkey (
              id,
              username,
              email,
              phone,
              profile_url
            )
          ''')
          .eq('event_id', eventId);

      attendees = (attendeesResponse as List)
          .map((json) => Attendee.fromJson(json))
          .toList();

      // Load tickets
      final ticketsResponse = await supabase
          .from('tickets')
          .select('*')
          .eq('event_id', eventId);

      tickets = (ticketsResponse as List)
          .map((json) => Ticket.fromJson(json))
          .toList();

      // Load payments with profile information
      final paymentsResponse = await supabase
          .from('payment')
          .select('''
            *,
            profiles!payment_user_id_fkey (
              id,
              username,
              email,
              profile_url
            )
          ''')
          .eq('event_id', eventId)
          .order('payment_date', ascending: false);

      payments = (paymentsResponse as List)
          .map((json) => Payment.fromJson(json))
          .toList();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        error = 'Failed to load event details: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _createEvent(Event event) async {
    try {
      await supabase.from('events').insert(event.toJson());
      await _loadEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateEvent(Event event) async {
    try {
      await supabase
          .from('events')
          .update(event.toJson())
          .eq('id', event.id);
      await _loadEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update event: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await supabase.from('events').delete().eq('id', eventId);
      await _loadEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: ${e.toString()}')),
      );
    }
  }

  Future<void> _createTicket(Ticket ticket) async {
    try {
      await supabase.from('tickets').insert(ticket.toJson(selectedEvent!.id));
      await _loadEventDetails(selectedEvent!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create ticket: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateTicket(Ticket ticket) async {
    try {
      await supabase
          .from('tickets')
          .update(ticket.toJson(selectedEvent!.id))
          .eq('id', ticket.id);
      await _loadEventDetails(selectedEvent!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ticket: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteTicket(String ticketId) async {
    try {
      await supabase.from('tickets').delete().eq('id', ticketId);
      await _loadEventDetails(selectedEvent!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete ticket: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: error != null
          ? _buildErrorState()
          : isLoading && events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : events.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        _buildEventSelector(),
                        _buildTabBar(),
                        Expanded(child: _buildTabBarView()),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first event to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateEventDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: Colors.deepPurple),
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
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: (Event? event) async {
                if (event != null) {
                  setState(() {
                    selectedEvent = event;
                  });
                  await _loadEventDetails(event.id);
                }
              },
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
                _showEditEventDialog(selectedEvent!);
              } else if (value == 'delete' && selectedEvent != null) {
                _showDeleteEventDialog(selectedEvent!);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.deepPurple,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.deepPurple,
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
        _buildOverviewTab(),
        _buildAttendeesTab(),
        _buildTicketsTab(),
        _buildPaymentsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final event = selectedEvent!;
    final checkedInCount = attendees.where((a) => a.checkIn).length;
    final totalRevenue = payments
        .where((p) => p.paymentStatus == 'completed')
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
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
                  '\$${totalRevenue.toStringAsFixed(2)}',
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeesTab() {
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
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export functionality coming soon')),
                  );
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
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
                              backgroundColor: attendee.checkIn ? Colors.green : Colors.grey,
                              child: Icon(
                                attendee.checkIn ? Icons.check : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(attendee.username),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (attendee.email.isNotEmpty) Text(attendee.email),
                                Text(
                                  'Registered: ${attendee.formattedRegistrationDate}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            trailing: attendee.checkIn
                                ? const Chip(
                                    label: Text('Checked In', style: TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.green,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                : const Chip(
                                    label: Text('Pending', style: TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.orange,
                                    labelStyle: TextStyle(color: Colors.white),
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTicketsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ticket Types',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddTicketDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
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
                              backgroundColor: Colors.deepPurple,
                              child: const Icon(Icons.confirmation_number, color: Colors.white),
                            ),
                            title: Text(ticket.type),
                            subtitle: Text('\${ticket.price.toStringAsFixed(2)}'),
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
                                      Icon(Icons.delete, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditTicketDialog(ticket);
                                } else if (value == 'delete') {
                                  _showDeleteTicketDialog(ticket);
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

  Widget _buildPaymentsTab() {
    final totalRevenue = payments
        .where((p) => p.paymentStatus == 'completed')
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
            color: Colors.deepPurple.withOpacity(0.1),
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
                      '\${totalRevenue.toStringAsFixed(2)}',
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
                      '\${pendingAmount.toStringAsFixed(2)}',
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
                        final isCompleted = payment.paymentStatus == 'completed';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCompleted ? Colors.green : Colors.orange,
                              child: Icon(
                                isCompleted ? Icons.check_circle : Icons.schedule,
                                color: Colors.white,
                              ),
                            ),
                            title: Text('\${payment.amount.toStringAsFixed(2)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${payment.username} - ${payment.paymentMethod}'),
                                Text(
                                  DateFormat('MMM dd, yyyy - HH:mm').format(payment.paymentDate),
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
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: isCompleted ? Colors.green : Colors.orange,
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

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime startDateTime = DateTime.now().add(const Duration(days: 7));
    DateTime endDateTime = DateTime.now().add(const Duration(days: 7, hours: 3));
    bool isFeatured = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(startDateTime),
                            );
                            if (time != null) {
                              setState(() {
                                startDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date & Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy - HH:mm').format(startDateTime),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDateTime,
                            firstDate: startDateTime,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endDateTime),
                            );
                            if (time != null) {
                              setState(() {
                                endDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date & Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy - HH:mm').format(endDateTime),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isFeatured,
                      onChanged: (value) {
                        setState(() {
                          isFeatured = value ?? false;
                        });
                      },
                    ),
                    const Text('Featured Event'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final event = Event(
                    id: '',
                    title: titleController.text,
                    description: descriptionController.text.isNotEmpty 
                        ? descriptionController.text 
                        : null,
                    location: locationController.text.isNotEmpty 
                        ? locationController.text 
                        : null,
                    organiserId: widget.organiserId,
                    startDateTime: startDateTime,
                    endDateTime: endDateTime,
                    isFeatured: isFeatured,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  Navigator.pop(context);
                  _createEvent(event);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventDialog(Event event) {
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description ?? '');
    final locationController = TextEditingController(text: event.location ?? '');
    DateTime startDateTime = event.startDateTime;
    DateTime endDateTime = event.endDateTime;
    bool isFeatured = event.isFeatured;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDateTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(startDateTime),
                            );
                            if (time != null) {
                              setState(() {
                                startDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date & Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy - HH:mm').format(startDateTime),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDateTime,
                            firstDate: startDateTime,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(endDateTime),
                            );
                            if (time != null) {
                              setState(() {
                                endDateTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date & Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy - HH:mm').format(endDateTime),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isFeatured,
                      onChanged: (value) {
                        setState(() {
                          isFeatured = value ?? false;
                        });
                      },
                    ),
                    const Text('Featured Event'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final updatedEvent = Event(
                    id: event.id,
                    title: titleController.text,
                    description: descriptionController.text.isNotEmpty 
                        ? descriptionController.text 
                        : null,
                    location: locationController.text.isNotEmpty 
                        ? locationController.text 
                        : null,
                    organiserId: event.organiserId,
                    startDateTime: startDateTime,
                    endDateTime: endDateTime,
                    isFeatured: isFeatured,
                    createdAt: event.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  Navigator.pop(context);
                  _updateEvent(updatedEvent);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(event.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddTicketDialog() {
    if (selectedEvent == null) return;

    final typeController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
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
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              if (typeController.text.isNotEmpty && priceController.text.isNotEmpty) {
                final price = double.tryParse(priceController.text);
                if (price != null && price >= 0) {
                  final ticket = Ticket(
                    id: '',
                    type: typeController.text,
                    price: price,
                  );
                  Navigator.pop(context);
                  _createTicket(ticket);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTicketDialog(Ticket ticket) {
    final typeController = TextEditingController(text: ticket.type);
    final priceController = TextEditingController(text: ticket.price.toString());

    showDialog(
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
                prefixText: '\$',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              if (typeController.text.isNotEmpty && priceController.text.isNotEmpty) {
                final price = double.tryParse(priceController.text);
                if (price != null && price >= 0) {
                  final updatedTicket = Ticket(
                    id: ticket.id,
                    type: typeController.text,
                    price: price,
                  );
                  Navigator.pop(context);
                  _updateTicket(updatedTicket);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteTicketDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket'),
        content: Text('Are you sure you want to delete "${ticket.type}" ticket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTicket(ticket.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}