import 'package:flutter/material.dart';
import 'package:nutriplan/user/screens/auth/email_verification_screen.dart';
import 'package:nutriplan/user/screens/auth/phone_otp_verification_screen.dart';
import '../../services/sms_otp_service.dart';
import 'login_screen.dart';
import '../../widgets/decorative_auth_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _usePhone = false; // Toggle between email and phone

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
            phoneNumber: '',
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

  void _signupWithPhoneOtp() async {
    setState(() { _isLoading = true; });
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneOtpVerificationScreen(
            phoneNumber: _phoneController.text,
            password: _passwordController.text,
            fullName: _fullNameController.text,
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
    // Dismiss keyboard / input cursor when signup is pressed
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      if (_usePhone) {
        _signupWithPhoneOtp();
      } else {
        _signupWithEmailOtp();
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
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
    final bool isKeyboardVisible =
        MediaQuery.of(context).viewInsets.bottom > 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: DecorativeAuthBackground(
        child: Center(
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
                    const SizedBox(height: 40),
                    // NutriPlan Logo + Text
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/widgets/NutriPlan_Logo.png',
                          height: 32,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'NutriPlan',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 255, 255, 255),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Centered tagline under logo, similar to login
                    Padding(
                      padding: EdgeInsets.only(
                        top: isKeyboardVisible ? 0.0 : 4.0,
                        bottom: isKeyboardVisible ? 24.0 : 60.0,
                      ),
                      child: const Text(
                        'Start your journey to healthier meals.\nCreate your account and discover personalized nutrition.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Color.fromARGB(230, 255, 255, 255),
                          fontWeight: FontWeight.w600,
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
                            
                            // Toggle between Email and Phone
                            Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _usePhone = false;
                                          _phoneController.clear();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !_usePhone ? const Color(0xFF4CAF50) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.email,
                                              size: 18,
                                              color: !_usePhone ? Colors.white : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Email',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: !_usePhone ? Colors.white : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _usePhone = true;
                                          _emailController.clear();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _usePhone ? const Color(0xFF4CAF50) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: 18,
                                              color: _usePhone ? Colors.white : Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Phone',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: _usePhone ? Colors.white : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Email or Phone input field
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: _usePhone
                                  ? TextFormField(
                                      controller: _phoneController,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Phone Number',
                                        labelStyle: const TextStyle(fontSize: 13),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Icon(
                                            Icons.phone,
                                            size: 20,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        if (!SmsOtpService.isValidPhoneNumber(value)) {
                                          return 'Please enter a valid phone number';
                                        }
                                        return null;
                                      },
                                    )
                                  : TextFormField(
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
                                    ' Login',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
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
      ),
    );
  }
}