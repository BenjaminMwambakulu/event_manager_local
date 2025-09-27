import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:event_manager_local/screens/Auth/login_page.dart';
import 'package:event_manager_local/screens/Auth/signup.dart';
import 'package:event_manager_local/screens/auth_wrapper.dart';
import 'package:event_manager_local/screens/main_home.dart';
import 'package:event_manager_local/screens/Home/event_details.dart';
import 'package:event_manager_local/screens/tickets_screen.dart';
import 'package:event_manager_local/models/event_model.dart';
import 'package:event_manager_local/themedata.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your local instance
  await Supabase.initialize(
    url: 'https://nhjtarucvmudvygklrma.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5oanRhcnVjdm11ZHZ5Z2tscm1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5OTU3OTUsImV4cCI6MjA3NDU3MTc5NX0.Ss4N_VCkrrAqyePOt9ibVl_r6R0nGRURj5j_CpdOr_A',
    debug: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: MinimalTheme.lightTheme,
      home: const AuthWrapper(),
      onGenerateRoute: (settings) {
        // Handle the event details route with arguments
        if (settings.name == '/event_details') {
          final event = settings.arguments as Event;
          return MaterialPageRoute(
            builder: (context) => EventDetails(event: event),
          );
        }

        // Handle other named routes
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (context) => const MainHome());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginPage());
          case '/signup':
            return MaterialPageRoute(builder: (context) => const SignupPage());
          case '/tickets':
            return MaterialPageRoute(
              builder: (context) => const TicketsScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}
