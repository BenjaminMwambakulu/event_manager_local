import 'package:event_manager_local/services/payChangu_payment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EventPaymentDialog extends StatefulWidget {
  final String eventTitle;
  final String ticketType;
  final double ticketPrice;
  final Function(EventPaymentRequest) onPaymentInitiated;

  const EventPaymentDialog({
    super.key,
    required this.eventTitle,
    required this.ticketType,
    required this.ticketPrice,
    required this.onPaymentInitiated,
  });

  @override
  State<EventPaymentDialog> createState() => _EventPaymentDialogState();
}

class _EventPaymentDialogState extends State<EventPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  MobileOperator? _selectedOperator;
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    
    // Remove any spaces or special characters
    final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check for 9-digit format (without country code) - PayChangu expects this format
    if (cleanNumber.length == 9) {
      // Valid 9-digit number
      return null;
    }
    
    // Check for 12-digit format with country code (265xxxxxxxxx)
    if (cleanNumber.length == 12 && cleanNumber.startsWith('265')) {
      return null;
    }
    
    return 'Enter a valid mobile number of nine (9) digits.';
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final cleanNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // PayChangu expects the number WITHOUT the country code
    // If it starts with 265, remove it to get the 9-digit format
    if (cleanNumber.startsWith('265') && cleanNumber.length == 12) {
      return cleanNumber.substring(3); // Remove '265' prefix
    }
    
    // If it's already 9 digits, return as is
    if (cleanNumber.length == 9) {
      return cleanNumber;
    }
    
    // For any other format, return the clean number
    return cleanNumber;
  }

  void _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOperator == null) {
      _showErrorMessage('Please select a mobile operator');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // You'll need to get these values from your app's state management or user session
      final userId = 'current-user-id'; // Replace with actual user ID
      final eventId = 'current-event-id'; // Replace with actual event ID
      final ticketId = 'current-ticket-id'; // Replace with actual ticket ID

      final paymentRequest = EventPaymentRequest(
        eventId: eventId,
        ticketId: ticketId,
        userId: userId,
        amount: widget.ticketPrice,
        operator: _selectedOperator!,
        phoneNumber: _formatPhoneNumber(_phoneController.text.trim()),
        email: _emailController.text.trim(),
      );

      // Close dialog and pass the request back to the parent
      Navigator.of(context).pop();
      widget.onPaymentInitiated(paymentRequest);

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorMessage('Error preparing payment: $e');
    }
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
    return AlertDialog(
      title: Text(
        'Complete Payment',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event and ticket details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event: ${widget.eventTitle}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Ticket: ${widget.ticketType}'),
                    const SizedBox(height: 4),
                    Text(
                      'Amount: \$${widget.ticketPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Phone number input
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '990000000 or 899817565',
                  helperText: 'Enter 9 digits without country code (265)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12), // Allow for country code input too
                ],
                validator: _validatePhoneNumber,
              ),
              const SizedBox(height: 16),

              // Mobile operator selection
              DropdownButtonFormField<MobileOperator>(
                value: _selectedOperator,
                decoration: const InputDecoration(
                  labelText: 'Mobile Operator',
                  prefixIcon: Icon(Icons.sim_card),
                  border: OutlineInputBorder(),
                ),
                items: EventPaymentService.getAvailableOperators()
                    .map((operator) => DropdownMenuItem(
                          value: operator,
                          child: Text(operator.name),
                        ))
                    .toList(),
                onChanged: (operator) {
                  setState(() {
                    _selectedOperator = operator;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a mobile operator';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email input
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),

              // Payment info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You will receive a mobile money prompt on your phone to complete the payment.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Test Numbers:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    Text(
                      'Airtel: 990000000 (Success), 990000001 (Failed)\nTNM: 899817565 (Success), 899817566 (Failed)',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handlePayment,
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Pay \$${widget.ticketPrice.toStringAsFixed(2)}'),
        ),
      ],
    );
  }
}