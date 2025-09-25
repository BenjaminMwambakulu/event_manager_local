import 'package:event_manager_local/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Profile?> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      return Profile.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
