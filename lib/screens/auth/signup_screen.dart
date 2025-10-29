import 'package:flutter/material.dart';
import 'package:nutriplan/screens/auth/desktop_email_verification_screen.dart';
import 'login_screen.dart';
import '../../widgets/animated_logo.dart';

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
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
            phoneNumber: '', // No phone needed
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding =
        MediaQuery.of(context).size.width < 430 ? 16.0 : 24.0;
    final double verticalPadding =
        MediaQuery.of(context).size.height < 900 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 80), // Move layout up
                  const AnimatedLogo(),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: 20.0, top: 50, bottom: 16.0),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  // Signup Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: TextFormField(
                                controller: _fullNameController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: const TextStyle(fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: TextFormField(
                                controller: _emailController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Email address',
                                  labelStyle: const TextStyle(fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Icon(
                                      Icons.email,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                  ),
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
                            ),
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: TextFormField(
                                controller: _passwordController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Icon(
                                      Icons.lock,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
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
                            ),
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle: const TextStyle(fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Icon(
                                      Icons.lock,
                                      size: 20,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  suffixIcon: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                        size: 20,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
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
                            ),
                            const SizedBox(height: 30),
                            
                            // Sign Up Button
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(
                                color: Color.fromARGB(255, 112, 110, 110),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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