import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../widgets/form_textfield.dart';
import '../../widgets/full_width_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    try {
      final response = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final user = response.user;
      if (user != null) {
        await _completeOnboarding();
        _prefs.setString('userId', user.id);
        _prefs.setString('email', user.email ?? '');
        _prefs.setString("username", user.userMetadata?['username'] ?? '');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Login",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 20.0),
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FullWidthButton(
                      onTap: () {
                        if (_formKey.currentState!.validate()) {
                          _login();
                        }
                      },
                      buttonText: "LogIn",
                      isLoading: _isLoading,
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 100,
                    child: Column(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text("Forgot Password?"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/signup');
                          },
                          child: Text("Don't have an account? Sign Up"),
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