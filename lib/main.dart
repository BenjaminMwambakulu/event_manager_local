import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:event_manager_local/screens/Auth/login_page.dart';
import 'package:event_manager_local/screens/Auth/signup.dart';
import 'package:event_manager_local/screens/auth_wrapper.dart';
import 'package:event_manager_local/screens/main_home.dart';
import 'package:event_manager_local/themedata.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your local instance
  await Supabase.initialize(
    url: 'http://10.0.2.2:54321',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE',
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
      routes: {
        "/home": (context) => const MainHome(),
        "/login": (context) => const LoginPage(),
        "/signup": (context) => const SignupPage(),
      },
    );
  }
}
