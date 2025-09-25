import 'package:event_manager_local/screens/Profiles/build_profile_row.dart';
import 'package:event_manager_local/screens/Profiles/simple_dash.dart';
import 'package:event_manager_local/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:event_manager_local/models/profile.dart';

// Renamed from Profile to ProfileScreen to avoid naming conflict with Profile model
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  // Get the user profile information
  void getProfile() async {
    final user = await _profileService.getProfile();
    setState(() {
      _profile = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [Icon(Icons.person), SizedBox(width: 8), Text('Profile')],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
          IconButton(
            onPressed: () {
              _supabase.auth.signOut();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _profile == null
                ? Center(child: CircularProgressIndicator())
                : buildProfileRow(_profile!),
            SimpleDash(),
          ],
        ),
      ),
    );
  }
}
