import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import './Home/home.dart';

class MainHome extends StatefulWidget {
  const MainHome({super.key});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  int _currentIndex = 0;
  // final SupabaseClient _supabase = Supabase.instance.client;

  final List<Widget> _pages = [
    Home(),
    Text("Page 2"),
    Text("Page 3"),
    Text("Page 4"),
  ];

  // Future<void> _signOut() async {
  //   try {
  //     await _supabase.auth.signOut();
  //     if (mounted) {
  //       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Logout failed: ${e.toString()}')),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (value) => setState(() {
          _currentIndex = value;
        }),
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
