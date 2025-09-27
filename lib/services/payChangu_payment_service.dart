import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Payment status enum matching your database enum
enum PaymentStatus { pending, success, failed, cancelled }

/// Mobile money operators supported by PayChangu
enum MobileOperator {
  tnm('27494cb5-ba9e-437f-a114-4e7a7686bcca', 'TNM'),
  airtel('20be6c20-adeb-4b5b-a7ba-0769820df4fb', 'AIRTEL');

  const MobileOperator(this.id, this.name);
  final String id;
  final String name;
}

/// Event Payment Request
class EventPaymentRequest {
  final String eventId;
  final String ticketId;
  final String userId;
  final double amount;
  final MobileOperator operator;
  final String phoneNumber;
  final String email;

  EventPaymentRequest({
    required this.eventId,
    required this.ticketId,
    required this.userId,
    required this.amount,
    required this.operator,
    required this.phoneNumber,
    required this.email,
  });
}

/// Payment result for events
class EventPaymentResult {
  final bool isSuccess;
  final bool isPending;
  final bool isFailed;
  final bool isCancelled;
  final String message;
  final String? paymentId;
  final String? chargeId;
  final String? transactionCharge;

  EventPaymentResult({
    required this.isSuccess,
    required this.isPending,
    required this.isFailed,
    required this.isCancelled,
    required this.message,
    this.paymentId,
    this.chargeId,
    this.transactionCharge,
  });

  factory EventPaymentResult.success({
    required String message,
    String? paymentId,
    String? chargeId,
    String? transactionCharge,
  }) {
    return EventPaymentResult(
      isSuccess: true,
      isPending: false,
      isFailed: false,
      isCancelled: false,
      message: message,
      paymentId: paymentId,
      chargeId: chargeId,
      transactionCharge: transactionCharge,
    );
  }

  factory EventPaymentResult.pending({
    required String message,
    String? paymentId,
    String? chargeId,
  }) {
    return EventPaymentResult(
      isSuccess: false,
      isPending: true,
      isFailed: false,
      isCancelled: false,
      message: message,
      paymentId: paymentId,
      chargeId: chargeId,
    );
  }

  factory EventPaymentResult.failed({
    required String message,
    String? paymentId,
    String? chargeId,
  }) {
    return EventPaymentResult(
      isSuccess: false,
      isPending: false,
      isFailed: true,
      isCancelled: false,
      message: message,
      paymentId: paymentId,
      chargeId: chargeId,
    );
  }

  factory EventPaymentResult.cancelled({required String message}) {
    return EventPaymentResult(
      isSuccess: false,
      isPending: false,
      isFailed: false,
      isCancelled: true,
      message: message,
    );
  }
}

/// Event Payment Service with PayChangu and Supabase integration
class EventPaymentService {
  final String apiKey;
  final SupabaseClient supabase;
  final bool isTestMode;

  static const String _baseUrl =
      'https://api.paychangu.com/mobile-money/payments';
  late final Map<String, String> _headers;

  EventPaymentService({
    required this.apiKey,
    required this.supabase,
    this.isTestMode = true,
  }) {
    _headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "host": "api.paychangu.com",
    };
  }

  /// Generates a unique charge ID for the payment
  String _generateChargeId() => const Uuid().v4();

  /// Creates a payment record in Supabase
  Future<String> _createPaymentRecord(
    EventPaymentRequest request,
    String chargeId,
  ) async {
    try {
      final response = await supabase
          .from('payment')
          .insert({
            'user_id': request.userId,
            'event_id': request.eventId,
            'ticket_id': request.ticketId,
            'amount': request.amount,
            'payment_method':
                'mobile_money_${request.operator.name.toLowerCase()}',
            'payment_status': 'pending',
            // Store the charge_id in a metadata field or create a custom field
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create payment record: $e');
    }
  }

  /// Updates payment record status
  Future<void> _updatePaymentStatus(
    String paymentId,
    PaymentStatus status,
  ) async {
    try {
      await supabase
          .from('payment')
          .update({
            'payment_status': status.name,
            'payment_date': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Creates attendee record after successful payment
  Future<void> _createAttendeeRecord(
    String userId,
    String eventId,
    String ticketId,
  ) async {
    try {
      await supabase.from('attendee').insert({
        'user_id': userId,
        'event_id': eventId,
        'ticket_id': ticketId,
        'check_in': false,
      });
    } catch (e) {
      throw Exception('Failed to create attendee record: $e');
    }
  }

  /// Checks if user is already registered for the event
  Future<bool> isUserAlreadyRegistered(String userId, String eventId) async {
    try {
      final response = await supabase
          .from('attendee')
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Initiates payment with PayChangu
  Future<EventPaymentResult> _initiatePayment(
    EventPaymentRequest request,
    String chargeId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/initialize'),
        headers: _headers,
        body: jsonEncode({
          "mobile_money_operator_ref_id": request.operator.id,
          "mobile": request.phoneNumber,
          "amount": request.amount,
          "charge_id": chargeId,
          "email": request.email,
          "paidFor": "Event Ticket Payment",
        }),
      );

      // Validate response content type
      if (!(response.headers['content-type']?.contains("application/json") ??
          false)) {
        return EventPaymentResult.failed(
          message: "Invalid response format from payment gateway",
        );
      }

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == "success") {
        return EventPaymentResult.pending(
          message: "Payment initiated. Please complete on your phone.",
          chargeId: chargeId,
        );
      } else {
        return EventPaymentResult.failed(
          message: data['message'] ?? "Failed to initiate payment",
        );
      }
    } catch (e) {
      return EventPaymentResult.failed(message: "Network error: $e");
    }
  }

  /// Verifies payment status with PayChangu
  Future<EventPaymentResult> verifyPayment(
    String chargeId,
    String paymentId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$chargeId/verify'),
        headers: _headers,
      );

      if (!(response.headers['content-type']?.contains("application/json") ??
          false)) {
        return EventPaymentResult.failed(
          message: "Invalid response format from payment gateway",
          paymentId: paymentId,
        );
      }

      final data = jsonDecode(response.body);
      final statusText = data['data']?['status'] ?? data['status'];
      final transactionCharge = data['data']?['transaction_charges']?['amount']
          ?.toString();

      switch (statusText?.toLowerCase()) {
        case 'success':
          return EventPaymentResult.success(
            message: "Payment completed successfully!",
            paymentId: paymentId,
            chargeId: chargeId,
            transactionCharge: transactionCharge,
          );
        case 'pending':
          return EventPaymentResult.pending(
            message: "Payment is still being processed",
            paymentId: paymentId,
            chargeId: chargeId,
          );
        case 'failed':
        case 'cancelled':
          return EventPaymentResult.failed(
            message: "Payment was unsuccessful",
            paymentId: paymentId,
            chargeId: chargeId,
          );
        default:
          return EventPaymentResult.failed(
            message: "Unknown payment status: $statusText",
            paymentId: paymentId,
            chargeId: chargeId,
          );
      }
    } catch (e) {
      return EventPaymentResult.failed(
        message: "Payment verification error: $e",
        paymentId: paymentId,
      );
    }
  }

  /// Process complete event ticket payment
  Future<EventPaymentResult> processEventPayment(
    EventPaymentRequest request, {
    Duration verificationDelay = const Duration(seconds: 4),
  }) async {
    try {
      // Check if user is already registered
      final isRegistered = await isUserAlreadyRegistered(
        request.userId,
        request.eventId,
      );
      if (isRegistered) {
        return EventPaymentResult.failed(
          message: "You are already registered for this event",
        );
      }

      // Generate charge ID
      final chargeId = _generateChargeId();

      // Create payment record in database
      final paymentId = await _createPaymentRecord(request, chargeId);

      // Initiate payment
      final initResult = await _initiatePayment(request, chargeId);

      if (!initResult.isPending) {
        // Update payment status to failed
        await _updatePaymentStatus(paymentId, PaymentStatus.failed);
        return EventPaymentResult.failed(
          message: initResult.message,
          paymentId: paymentId,
        );
      }

      // Wait before verification
      await Future.delayed(verificationDelay);

      // Verify payment
      final verifyResult = await verifyPayment(chargeId, paymentId);

      // Update payment status based on result
      PaymentStatus finalStatus;
      if (verifyResult.isSuccess) {
        finalStatus = PaymentStatus.success;
        // Create attendee record for successful payment
        await _createAttendeeRecord(
          request.userId,
          request.eventId,
          request.ticketId,
        );
      } else if (verifyResult.isPending) {
        finalStatus = PaymentStatus.pending;
      } else {
        finalStatus = PaymentStatus.failed;
      }

      await _updatePaymentStatus(paymentId, finalStatus);

      return EventPaymentResult(
        isSuccess: verifyResult.isSuccess,
        isPending: verifyResult.isPending,
        isFailed: verifyResult.isFailed,
        isCancelled: verifyResult.isCancelled,
        message: verifyResult.message,
        paymentId: paymentId,
        chargeId: chargeId,
        transactionCharge: verifyResult.transactionCharge,
      );
    } catch (e) {
      return EventPaymentResult.failed(message: "Payment processing error: $e");
    }
  }

  /// Register for free event
  Future<EventPaymentResult> registerForFreeEvent(
    String userId,
    String eventId,
    String ticketId,
  ) async {
    try {
      // Check if user is already registered
      final isRegistered = await isUserAlreadyRegistered(userId, eventId);
      if (isRegistered) {
        return EventPaymentResult.failed(
          message: "You are already registered for this event",
        );
      }

      // Create attendee record directly for free events
      await _createAttendeeRecord(userId, eventId, ticketId);

      return EventPaymentResult.success(
        message: "Successfully registered for the event!",
      );
    } catch (e) {
      return EventPaymentResult.failed(message: "Registration failed: $e");
    }
  }

  /// Get available mobile operators
  static List<MobileOperator> getAvailableOperators() {
    return MobileOperator.values;
  }

  /// Public method to verify payment status (alias for verifyPayment)
  Future<EventPaymentResult> verifyPaymentStatus(
    String chargeId,
    String paymentId,
  ) async {
    return await verifyPayment(chargeId, paymentId);
  }

  /// Find operator by name (case-insensitive)
  static MobileOperator? getOperatorByName(String name) {
    try {
      return MobileOperator.values.firstWhere(
        (op) => op.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
