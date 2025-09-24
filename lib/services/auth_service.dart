// lib/services/supabase_auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Singleton instance of Supabase client
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {"username": username},
      );
      return response;
    } on AuthException catch (e) {
      throw Exception("Sign up failed: ${e.message}");
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception("Login failed: ${e.message}");
    }
  }

  Future<AuthResponse> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();
      return response;
    } on AuthException catch (e) {
      throw Exception("Anonymous login failed: ${e.message}");
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception("Logout failed: ${e.message}");
    }
  }

  User? get currentUser {
    return _client.auth.currentUser;
  }

  Stream<AuthState> get onAuthStateChange {
    return _client.auth.onAuthStateChange;
  }
}