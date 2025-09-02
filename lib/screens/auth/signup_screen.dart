import 'package:flutter/material.dart';
import 'package:nutriplan/screens/auth/desktop_email_verification_screen.dart';
import 'login_screen.dart';
import '../../widgets/animated_logo.dart';
import '../../widgets/decorative_auth_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  // Removed phone controller
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Remove verification choice dialog and SMS OTP logic

  void _signupWithEmailOtp() async {
    setState(() { _isLoading = true; });
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DesktopEmailVerificationScreen(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _fullNameController.text,
            phoneNumber: '', // No phone
          ),
        ),
      );
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      _signupWithEmailOtp();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    // Removed phone controller dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecorativeAuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AnimatedLogo(),
                const SizedBox(height: 32),
                // Place the Sign Up title just above the card
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20.0, top: 0, bottom: 16.0),
                    
                  ),
                ),
                Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: const Color.fromARGB(221, 247, 247, 247)),
                    ),
                SizedBox(height: 60),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Removed phone number input
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF4CAF50),
                                      side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    onPressed: _signup,
                                    child: const Text('Sign Up', style: TextStyle(fontSize: 18, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Move the TextButton just below the card
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                  ),
                  child: const Text('Already have an account? Login here', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 