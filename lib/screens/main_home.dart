import 'package:event_manager_local/screens/Explore/expolore_screen.dart';
import 'package:event_manager_local/screens/Profiles/profile_screen.dart'; // Updated import path
import 'package:event_manager_local/screens/Search/search_screen.dart';
import 'package:event_manager_local/screens/event_map/event_map.dart';
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
    SearchScreen(),
    EventMap(),
    ExploreScreen(),
    ProfileScreen(), // Using ProfileScreen instead of Profile
  ];

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
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
