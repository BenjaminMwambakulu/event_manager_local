// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../widgets/form_textfield.dart';
import '../../widgets/full_width_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }

  void _signup() async {
    setState(() {
      _isLoading = true;
    });
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    try {
      final response = await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
      );
      final user = response.user;
      if (user != null) {
        await _completeOnboarding();
        _prefs.setString('userId', user.id);
        _prefs.setString('email', user.email ?? '');
        _prefs.setString("username", _usernameController.text);
        
        // Check if the widget is still mounted before navigating
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      // Check if the widget is still mounted before showing snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.toString()}')),
        );
      }
    } finally {
      // Check if the widget is still mounted before setting state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Sign up to continue",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 20.0),
                  FormTextfield(
                    labelText: "Username",
                    controller: _usernameController,
                    hintText: "username",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your username";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15.0),
                  FormTextfield(
                    labelText: "Email",
                    controller: _emailController,
                    hintText: "your_email@example.com",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  FormTextfield(
                    labelText: "Password",
                    controller: _passwordController,
                    hintText: "********",
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a password";
                      }
                      if (value.length < 8) {
                        return "Password must be at least 8 characters long";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  FormTextfield(
                    labelText: "Confirm Password",
                    controller: _confirmPasswordController,
                    hintText: "********",
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please confirm your password";
                      }
                      if (value != _passwordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FullWidthButton(
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          _signup();
                        }
                      },
                      buttonText: "Sign Up",
                      isLoading: _isLoading,
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    child: Column(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text("Already have an account? LogIn"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}