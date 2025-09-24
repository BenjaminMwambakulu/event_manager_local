import 'package:event_manager_local/widgets/full_width_button.dart';
import 'package:event_manager_local/widgets/ticket_selector.dart';
import 'package:event_manager_local/services/registration_service.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:flutter/material.dart';
import 'package:event_manager_local/models/event_model.dart';

class EventDetails extends StatefulWidget {
  final Event event;

  const EventDetails({super.key, required this.event});

  @override
  State<EventDetails> createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  final RegistrationService _registrationService = RegistrationService();
  Ticket? _selectedTicket;
  bool _isRegistering = false;
  bool _isAlreadyRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final isRegistered = await _registrationService.isUserRegistered(widget.event.id);
    if (mounted) {
      setState(() {
        _isAlreadyRegistered = isRegistered;
      });
    }
  }

  Future<void> _handleRegistration() async {
    if (_selectedTicket == null) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      final RegistrationResult result;
      
      if (_selectedTicket!.price == 0) {
        // Free event registration
        result = await _registrationService.registerForFreeEvent(
          event: widget.event,
          ticket: _selectedTicket!,
        );
      } else {
        // Paid event registration
        result = await _registrationService.initiatePaymentFlow(
          event: widget.event,
          ticket: _selectedTicket!,
          context: context,
        );
      }

      if (mounted) {
        if (result.isSuccess) {
          _showSuccessMessage(result.message);
          setState(() {
            _isAlreadyRegistered = true;
            _selectedTicket = null;
          });
        } else if (!result.isCancelled) {
          _showErrorMessage(result.message);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 300,
                child: ClipRRect(
                  child: widget.event.bannerUrl.isNotEmpty
                      ? Image.network(
                          widget.event.bannerUrl,
                          fit: BoxFit.cover,
                          height: 300,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 300,
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.event,
                                color: Colors.grey.shade400,
                                size: 64,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 300,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.event,
                            color: Colors.grey.shade400,
                            size: 64,
                          ),
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.location,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateTime(widget.event.startDateTime),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.event.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Organizer',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              widget.event.organiser.profileUrl.isNotEmpty
                              ? NetworkImage(widget.event.organiser.profileUrl)
                              : null,
                          child: widget.event.organiser.profileUrl.isEmpty
                              ? Icon(Icons.person, color: Colors.grey[600])
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.event.organiser.username,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    
                    // Ticket Selection Section
                    if (widget.event.tickets.isNotEmpty && !_isAlreadyRegistered) ...[
                      const SizedBox(height: 16),
                      TicketSelector(
                        tickets: widget.event.tickets,
                        selectedTicket: _selectedTicket,
                        onTicketSelected: (ticket) {
                          setState(() {
                            _selectedTicket = ticket;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    _buildActionButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isAlreadyRegistered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Text(
              'Already Registered',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final hasTickets = widget.event.tickets.isNotEmpty;
    final isEnabled = !hasTickets || _selectedTicket != null;
    final buttonText = _getButtonText();

    return FullWidthButton(
      buttonText: buttonText,
      onTap: isEnabled ? _handleRegistration : null,
      isLoading: _isRegistering,
    );
  }

  String _getButtonText() {
    if (widget.event.tickets.isEmpty) {
      return 'Register (Free)';
    }
    
    if (_selectedTicket == null) {
      return 'Select a Ticket';
    }
    
    if (_selectedTicket!.price == 0) {
      return 'Register (Free)';
    }
    
    return 'Get Ticket - \$${_selectedTicket!.price.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12;
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }
}