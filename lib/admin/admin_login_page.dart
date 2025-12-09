import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple admin login page that checks credentials against an `admin_users` table.
/// Table schema (run in Supabase SQL editor):
///
/// CREATE TABLE IF NOT EXISTS admin_users (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   email TEXT UNIQUE NOT NULL,
///   password TEXT NOT NULL,
///   created_at TIMESTAMPTZ DEFAULT NOW()
/// );
///
/// INSERT INTO admin_users (email, password)
/// VALUES ('admin@example.com', 'your-password-here');
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Widget _buildBrandRow({
    double logoSize = 90,
    double fontSize = 48,
    Color textColor = Colors.white,
    double letterSpacing = 1.2,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/widgets/NutriPlan_Logo.png',
          height: logoSize,
        ),
        const SizedBox(width: 12),
        Text(
          'NutriPlan',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('admin_users')
          .select('id, email, password')
          .eq('email', email)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _errorText = 'Invalid email or password.';
          _isLoading = false;
        });
        return;
      }

      final storedPassword = response['password'] as String?;
      if (storedPassword == null || storedPassword != password) {
        setState(() {
          _errorText = 'Invalid email or password.';
          _isLoading = false;
        });
        return;
      }

      // Authenticate with Supabase Auth to allow RLS policies to work
      // This is required for fetching recipes and feedback
      try {
        // Try to sign in with email/password
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (signInError) {
        // If sign in fails, try to sign up (create the user in Supabase Auth)
        // This will work if email confirmation is disabled in Supabase settings
        try {
          await supabase.auth.signUp(
            email: email,
            password: password,
            emailRedirectTo: null, // No email confirmation redirect needed
          );
          
          // After sign up, try to sign in again
          await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
        } catch (signUpError) {
          // If both sign in and sign up fail, show error
          if (mounted) {
            setState(() {
              _errorText = 'Failed to authenticate. Please ensure the admin user exists in Supabase Auth or contact support.';
              _isLoading = false;
            });
          }
          return;
        }
      }

      // Verify we have an authenticated session
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _errorText = 'Authentication failed. Please try again.';
            _isLoading = false;
          });
        }
        return;
      }

      // Login successful – go to admin panel
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/admin');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Login failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Green top half
          Expanded(
            child: Container(
              color: const Color(0xFF4CAF50),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                _buildBrandRow(),
                    const SizedBox(height: 8),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // White bottom half
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                if (_errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.grey, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.grey, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2.5),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your admin email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.grey, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Colors.grey, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2.5),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


