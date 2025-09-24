import 'package:flutter/material.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/models/ticket.dart';
import 'package:event_manager_local/services/event_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationService {
  final EventService _eventService = EventService();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Register for a free event
  Future<RegistrationResult> registerForFreeEvent({
    required Event event,
    required Ticket ticket,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return RegistrationResult.failure('Please log in to register for events');
      }

      // Get the profile ID for the current user
      final profileId = await _getUserProfileId(user.id);
      if (profileId == null) {
        return RegistrationResult.failure('Profile not found. Please complete your profile setup.');
      }

      await _eventService.registerToEvent(event.id, profileId, ticket.id);
      
      return RegistrationResult.success('Successfully registered for ${event.title}!');
    } catch (e) {
      debugPrint('Error registering for free event: $e');
      
      // Handle specific error types
      final errorMessage = e.toString();
      if (errorMessage.contains('foreign key constraint')) {
        return RegistrationResult.failure('Account setup incomplete. Please contact support.');
      } else if (errorMessage.contains('duplicate key')) {
        return RegistrationResult.failure('You are already registered for this event.');
      }
      
      return RegistrationResult.failure('Failed to register. Please try again.');
    }
  }

  /// Initiate payment flow for paid events
  Future<RegistrationResult> initiatePaymentFlow({
    required Event event,
    required Ticket ticket,
    required BuildContext context,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return RegistrationResult.failure('Please log in to register for events');
      }

      // TODO: Implement payment gateway integration
      // For now, we'll simulate the payment flow
      final shouldProceed = await _showPaymentDialog(context, event, ticket);
      
      if (shouldProceed) {
        // Simulate payment processing
        await Future.delayed(const Duration(seconds: 2));
        
        // Get the profile ID for the current user
        final profileId = await _getUserProfileId(user.id);
        if (profileId == null) {
          return RegistrationResult.failure('Profile not found. Please complete your profile setup.');
        }

        // Register after successful payment
        await _eventService.registerToEvent(event.id, profileId, ticket.id);
        
        return RegistrationResult.success(
          'Payment successful! You are now registered for ${event.title}.'
        );
      } else {
        return RegistrationResult.cancelled('Payment cancelled');
      }
    } catch (e) {
      debugPrint('Error in payment flow: $e');
      
      // Handle specific error types
      final errorMessage = e.toString();
      if (errorMessage.contains('foreign key constraint')) {
        return RegistrationResult.failure('Account setup incomplete. Please contact support.');
      } else if (errorMessage.contains('duplicate key')) {
        return RegistrationResult.failure('You are already registered for this event.');
      }
      
      return RegistrationResult.failure('Payment failed. Please try again.');
    }
  }

  /// Show payment dialog (placeholder for actual payment gateway)
  Future<bool> _showPaymentDialog(
    BuildContext context,
    Event event,
    Ticket ticket,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event: ${event.title}'),
            Text('Ticket: ${ticket.type}'),
            Text('Amount: \$${ticket.price.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text(
              'This is a demo. In a real app, this would redirect to your payment gateway.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Check if user is already registered for an event
  Future<bool> isUserRegistered(String eventId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Get the profile ID for the current user
      final profileId = await _getUserProfileId(user.id);
      if (profileId == null) return false;

      final response = await _supabase
          .from('attendee')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', profileId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking registration status: $e');
      return false;
    }
  }

  /// Get the profile ID for a given auth user ID
  Future<String?> _getUserProfileId(String authUserId) async {
    try {
      // First, try to get existing profile
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', authUserId)
          .maybeSingle();

      if (response != null) {
        return response['id']?.toString();
      }

      // If no profile exists, create one
      debugPrint('No profile found for user $authUserId, creating one...');
      return await _createUserProfile(authUserId);
    } catch (e) {
      debugPrint('Error getting user profile ID: $e');
      return null;
    }
  }

  /// Create a new profile for the user
  Future<String?> _createUserProfile(String authUserId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .insert({
            'user_id': authUserId,
            'username': user.email?.split('@')[0] ?? 'User', // Default username from email
            'email': user.email,
            'role': 'customer', // Default role
          })
          .select('id')
          .single();

      debugPrint('Created new profile with ID: ${response['id']}');
      return response['id']?.toString();
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return null;
    }
  }
}

class RegistrationResult {
  final bool isSuccess;
  final String message;
  final bool isCancelled;

  RegistrationResult._({
    required this.isSuccess,
    required this.message,
    this.isCancelled = false,
  });

  factory RegistrationResult.success(String message) {
    return RegistrationResult._(isSuccess: true, message: message);
  }

  factory RegistrationResult.failure(String message) {
    return RegistrationResult._(isSuccess: false, message: message);
  }

  factory RegistrationResult.cancelled(String message) {
    return RegistrationResult._(
      isSuccess: false,
      message: message,
      isCancelled: true,
    );
  }
}