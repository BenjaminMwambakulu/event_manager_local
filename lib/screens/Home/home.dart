import 'package:event_manager_local/widgets/featured_courasel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? username;

  @override
  void dispose() {
    // Any necessary cleanup can be done here
    super.dispose();
  }

  void getUserInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Check if the widget is still mounted before setting state
    if (mounted) {
      setState(() {
        username = prefs.getString('username');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> _signOut() async {
    try {
      final SupabaseClient _supabase = Supabase.instance.client;
      await _supabase.auth.signOut();
    } catch (e) {
      // Check if the widget is still mounted before showing snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage("assets/images/profile.png"),
            ),
            SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Welcome,", style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  username ?? "User",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none)),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text("Logout"),
                onTap: () {
                  Future.delayed(Duration.zero, () async {
                    await _signOut();
                    // Check if the widget is still mounted before navigating
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Expanded(child: FeaturedCarousel()),
        ],
      ),
    );
  }
}
