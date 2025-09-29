import 'package:event_manager_local/services/payChangu_payment_service.dart';
import 'package:event_manager_local/widgets/event_payment_dialog.dart';
import 'package:event_manager_local/widgets/full_width_button.dart';
import 'package:event_manager_local/widgets/ticket_selector.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:event_manager_local/utils/image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventDetails extends StatefulWidget {
  final Event event;

  const EventDetails({super.key, required this.event});

  @override
  State<EventDetails> createState() => _EventDetailsState();
}

class _EventDetailsState extends State<EventDetails> {
  late final EventPaymentService _paymentService;
  final SupabaseClient _supabase = Supabase.instance.client;

  Ticket? _selectedTicket;
  bool _isProcessing = false;
  bool _isAlreadyRegistered = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePaymentService();
    _checkRegistrationStatus();
  }

  void _initializePaymentService() {
    _paymentService = EventPaymentService(
      apiKey:
          "sec-test-f2NqaRNqhEdDQSgcMr4eRtPr0uJ2pgXP", 
      supabase: _supabase,
      isTestMode: true, // Set to false for production
    );
  }

  Future<void> _checkRegistrationStatus() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get user profile to get the profile ID
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', currentUser.id)
          .single();

      final profileId = profileResponse['id'] as String;

      // Check if user is already registered
      final isRegistered = await _paymentService.isUserAlreadyRegistered(
        profileId,
        widget.event.id,
      );

      if (mounted) {
        setState(() {
          _isAlreadyRegistered = isRegistered;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking registration status: $e');
      }
    }
  }

  Future<String> _getCurrentUserProfileId() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', currentUser.id)
          .single();

      return profileResponse['id'] as String;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> _handleRegistration() async {
    if (_selectedTicket == null) {
      _showErrorMessage('Please select a ticket first');
      return;
    }

    try {
      final profileId = await _getCurrentUserProfileId();

      if (_selectedTicket!.price == 0) {
        // Handle free event registration
        await _handleFreeRegistration(profileId);
      } else {
        // Handle paid event registration
        await _handlePaidRegistration();
      }
    } catch (e) {
      _showErrorMessage('Registration failed: $e');
    }
  }

  Future<void> _handleFreeRegistration(String profileId) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Registering for event...';
    });

    try {
      final result = await _paymentService.registerForFreeEvent(
        profileId,
        widget.event.id,
        _selectedTicket!.id,
      );

      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });

      if (result.isSuccess) {
        _showSuccessMessage(result.message);
        setState(() {
          _isAlreadyRegistered = true;
          _selectedTicket = null;
        });
      } else {
        _showErrorMessage(result.message);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      _showErrorMessage('Registration failed: $e');
    }
  }

  Future<void> _handlePaidRegistration() async {
    // Show payment dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EventPaymentDialog(
        eventTitle: widget.event.title,
        ticketType: _selectedTicket!.type,
        ticketPrice: _selectedTicket!.price,
        onPaymentInitiated: _processPayment,
      ),
    );
  }

  Future<void> _processPayment(EventPaymentRequest paymentRequest) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Initializing payment...';
    });

    try {
      // Get the current user's profile ID
      final profileId = await _getCurrentUserProfileId();

      // Update the payment request with correct IDs
      final updatedRequest = EventPaymentRequest(
        eventId: widget.event.id,
        ticketId: _selectedTicket!.id,
        userId: profileId,
        amount: paymentRequest.amount,
        operator: paymentRequest.operator,
        phoneNumber: paymentRequest.phoneNumber,
        email: paymentRequest.email,
      );

      setState(() {
        _statusMessage = 'Processing payment...';
      });

      // Process the payment
      final result = await _paymentService.processEventPayment(updatedRequest);

      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });

      // Handle the result
      if (result.isSuccess) {
        _showSuccessMessage(result.message);
        setState(() {
          _isAlreadyRegistered = true;
          _selectedTicket = null;
        });
      } else if (result.isPending) {
        _showPendingDialog(result);
      } else if (!result.isCancelled) {
        _showErrorMessage(result.message);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      _showErrorMessage('Payment processing failed: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showPendingDialog(EventPaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Pending'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pending_actions, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(result.message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (result.paymentId != null)
              Text(
                'Payment ID: ${result.paymentId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _recheckPaymentStatus(result);
            },
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }

  Future<void> _recheckPaymentStatus(EventPaymentResult result) async {
    if (result.chargeId == null || result.paymentId == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Checking payment status...';
    });

    try {
      final updatedResult = await _paymentService.verifyPaymentStatus(
        result.chargeId!,
        result.paymentId!,
      );

      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });

      if (updatedResult.isSuccess) {
        _showSuccessMessage(updatedResult.message);
        setState(() {
          _isAlreadyRegistered = true;
          _selectedTicket = null;
        });
      } else if (updatedResult.isPending) {
        _showErrorMessage('Payment is still pending. Please try again later.');
      } else {
        _showErrorMessage(updatedResult.message);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      _showErrorMessage('Failed to check payment status: $e');
    }
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
              // Event Banner
              SizedBox(
                height: 300,
                child: ClipRRect(
                  child: CachedNetworkImage(
                    imageUrl: ImageUtils.fixImageUrl(widget.event.bannerUrl),
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
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
              ),

              // Content
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Title
                    Text(
                      widget.event.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.location!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Date and Time
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

                    // Description
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.event.description ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),

                    // Organizer
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
                              widget.event.organiser!.profileUrl.isNotEmpty
                              ? ImageUtils.cachedNetworkImageProvider(
                                  widget.event.organiser!.profileUrl,
                                )
                              : null,
                          child: widget.event.organiser!.profileUrl.isEmpty
                              ? Icon(Icons.person, color: Colors.grey[600])
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.event.organiser!.username,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),

                    // Ticket Selection Section
                    if (widget.event.tickets.isNotEmpty &&
                        !_isAlreadyRegistered) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Select Ticket',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
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

                    // Status Message
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
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
                fontSize: 16,
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
      onTap: isEnabled && !_isProcessing ? _handleRegistration : null,
      isLoading: _isProcessing,
    );
  }

  String _getButtonText() {
    if (_isProcessing) {
      return 'Processing...';
    }

    if (widget.event.tickets.isEmpty) {
      return 'Register (Free)';
    }

    if (_selectedTicket == null) {
      return 'Select a Ticket';
    }

    if (_selectedTicket!.price == 0) {
      return 'Register (Free)';
    }

    return 'Get Ticket - ${_selectedTicket!.price.toStringAsFixed(2)}';
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
