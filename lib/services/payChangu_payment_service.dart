// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Payment status enum for better type safety
enum PaymentStatus {
  success,
  pending,
  failed,
  error,
}

/// Mobile money operators supported by PayChangu
enum MobileOperator {
  tnm('27494cb5-ba9e-437f-a114-4e7a7686bcca', 'TNM'),
  airtel('20be6c20-adeb-4b5b-a7ba-0769820df4fb', 'AIRTEL');

  const MobileOperator(this.id, this.name);
  final String id;
  final String name;
}

/// Payment result class to hold payment response data
class PaymentResult {
  final PaymentStatus status;
  final String chargeId;
  final String? transactionCharge;
  final String? message;
  final Map<String, dynamic>? rawData;

  PaymentResult({
    required this.status,
    required this.chargeId,
    this.transactionCharge,
    this.message,
    this.rawData,
  });
}

/// Payment request data class
class PaymentRequest {
  final MobileOperator operator;
  final String phoneNumber;
  final double amount;
  final String email;
  final String paidFor;
  final String? customChargeId;

  PaymentRequest({
    required this.operator,
    required this.phoneNumber,
    required this.amount,
    required this.email,
    required this.paidFor,
    this.customChargeId,
  });
}

/// PayChangu Mobile Money Payment Service
/// 
/// This service handles mobile money payments through PayChangu API for Malawi.
/// It supports TNM and Airtel mobile money operators.
/// 
/// Usage:
/// 1. Initialize the service with your API key
/// 2. Create a PaymentRequest with payment details
/// 3. Call initiatePayment() to start the payment
/// 4. Call verifyPayment() to check payment status
class PayChanguService {
  final String apiKey;
  final String baseUrl;
  final bool isTestMode;

  late final Map<String, String> _headers;

  /// Constructor
  /// 
  /// [apiKey] - Your PayChangu API key (test or live)
  /// [isTestMode] - Set to true for test environment, false for production
  PayChanguService({
    required this.apiKey,
    this.isTestMode = true,
  }) : baseUrl = 'https://api.paychangu.com/mobile-money/payments' {
    _headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "host": "api.paychangu.com",
    };
  }

  /// Generates a unique charge ID for the payment
  String _generateChargeId() => const Uuid().v4();

  /// Validates the payment request
  bool _validatePaymentRequest(PaymentRequest request) {
    if (request.phoneNumber.isEmpty) return false;
    if (request.amount <= 0) return false;
    if (request.email.isEmpty) return false;
    if (request.paidFor.isEmpty) return false;
    return true;
  }

  /// Initiates a mobile money payment
  /// 
  /// [request] - Payment request containing all payment details
  /// 
  /// Returns a PaymentResult with the initial payment response
  /// 
  /// Throws an exception if the request fails
  Future<PaymentResult> initiatePayment(PaymentRequest request) async {
    if (!_validatePaymentRequest(request)) {
      throw ArgumentError('Invalid payment request data');
    }

    final chargeId = request.customChargeId ?? _generateChargeId();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/initialize'),
        headers: _headers,
        body: jsonEncode({
          "mobile_money_operator_ref_id": request.operator.id,
          "mobile": request.phoneNumber,
          "amount": request.amount,
          "charge_id": chargeId,
          "email": request.email,
          "paidFor": request.paidFor,
        }),
      );

      // Validate response content type
      if (!(response.headers['content-type']?.contains("application/json") ?? false)) {
        return PaymentResult(
          status: PaymentStatus.error,
          chargeId: chargeId,
          message: "Invalid response format from payment gateway",
        );
      }

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['status'] == "success") {
        return PaymentResult(
          status: PaymentStatus.pending,
          chargeId: chargeId,
          message: "Payment initiated successfully",
          rawData: data,
        );
      } else {
        return PaymentResult(
          status: PaymentStatus.failed,
          chargeId: chargeId,
          message: data['message'] ?? "Failed to initiate payment",
          rawData: data,
        );
      }
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.error,
        chargeId: chargeId,
        message: "Network error: $e",
      );
    }
  }

  /// Verifies the status of a payment
  /// 
  /// [chargeId] - The charge ID returned from initiatePayment
  /// 
  /// Returns a PaymentResult with the current payment status
  /// 
  /// Throws an exception if the verification fails
  Future<PaymentResult> verifyPayment(String chargeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$chargeId/verify'),
        headers: _headers,
      );

      // Validate response content type
      if (!(response.headers['content-type']?.contains("application/json") ?? false)) {
        return PaymentResult(
          status: PaymentStatus.error,
          chargeId: chargeId,
          message: "Invalid response format from payment gateway",
        );
      }

      final data = jsonDecode(response.body);
      final statusText = data['data']?['status'] ?? data['status'];
      final transactionCharge = data['data']?['transaction_charges']?['amount']?.toString();

      PaymentStatus status;
      switch (statusText?.toLowerCase()) {
        case 'success':
          status = PaymentStatus.success;
          break;
        case 'pending':
          status = PaymentStatus.pending;
          break;
        case 'failed':
        case 'cancelled':
          status = PaymentStatus.failed;
          break;
        default:
          status = PaymentStatus.error;
      }

      return PaymentResult(
        status: status,
        chargeId: chargeId,
        transactionCharge: transactionCharge,
        message: data['message'] ?? statusText,
        rawData: data,
      );
    } catch (e) {
      return PaymentResult(
        status: PaymentStatus.error,
        chargeId: chargeId,
        message: "Verification error: $e",
      );
    }
  }

  /// Convenience method to process a complete payment flow
  /// 
  /// [request] - Payment request
  /// [verificationDelay] - Delay before verification (default 4 seconds)
  /// 
  /// Returns the final payment result after verification
  Future<PaymentResult> processPayment(
    PaymentRequest request, {
    Duration verificationDelay = const Duration(seconds: 4),
  }) async {
    // Initiate payment
    final initResult = await initiatePayment(request);
    
    if (initResult.status != PaymentStatus.pending) {
      return initResult;
    }

    // Wait before verification
    await Future.delayed(verificationDelay);

    // Verify payment
    return await verifyPayment(initResult.chargeId);
  }

  /// Gets available mobile operators
  static List<MobileOperator> getAvailableOperators() {
    return MobileOperator.values;
  }

  /// Finds operator by name (case-insensitive)
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