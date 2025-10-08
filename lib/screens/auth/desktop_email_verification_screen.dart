import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import '../../widgets/animated_logo.dart';
import '../../widgets/decorative_auth_background.dart';

class DesktopEmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;
  
  const DesktopEmailVerificationScreen({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
    super.key,
  });

  @override
  State<DesktopEmailVerificationScreen> createState() => _DesktopEmailVerificationScreenState();
}

class _DesktopEmailVerificationScreenState extends State<DesktopEmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  int _resendTimer = 60;
  bool _canResend = false;
  int _checkDelay = 7;
  bool _canCheckVerification = false;
  Timer? _checkDelayTimer;

  @override
  void initState() {
    super.initState();
    _sendEmailVerification();
    _startResendTimer();
    _startCheckDelay();
    // Don't auto-check verification - let user do it manually
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });
    
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _startCheckDelay() {
    setState(() {
      _checkDelay = 7;
      _canCheckVerification = false;
    });
    _checkDelayTimer?.cancel();
    _checkDelayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_checkDelay > 1) {
            _checkDelay--;
          } else {
            _canCheckVerification = true;
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendEmailVerification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Sending email verification to: ${widget.email}');
      
      // Create account with email verification
      await Supabase.instance.client.auth.signUp(
        email: widget.email,
        password: widget.password,
        data: {
          'full_name': widget.fullName,
        },
      );
      
      print('Email verification sent successfully');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your email and click the link.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error sending email verification: $e');
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = 'Error sending verification email';
      if (e.toString().contains('Invalid email')) {
        errorMessage = 'Invalid email format';
      } else if (e.toString().contains('rate limit')) {
        errorMessage = 'Too many attempts. Please wait before trying again.';
      } else if (e.toString().contains('already registered')) {
        errorMessage = 'This email is already registered. Please log in instead.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
                           backgroundColor: const Color(0xFFFF6961),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
    });

    try {
      await _sendEmailVerification();
      _startResendTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resending email: $e')),
        );
      }
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Checking verification status for: ${widget.email}');
      
      // Try to sign in with the credentials to check if email was verified
      // This will work even if there's no active session
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: widget.email,
        password: widget.password,
      );

      final user = response.user;
      print('User verification status: ${user?.emailConfirmedAt}');

      if (user != null && user.emailConfirmedAt != null) {
        print('Email verified! Proceeding to account creation...');
        // Insert profile row for the user
        try {
          await Supabase.instance.client
            .from('profiles')
            .insert({
              'id': user.id,
              'username': widget.fullName,
            });
        } catch (e) {
          print('Error inserting profile: $e');
        }
        setState(() {
          _isVerified = true;
          _isLoading = false;
        });
        // Sign out immediately since we just wanted to check verification
        await Supabase.instance.client.auth.signOut();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email verified successfully! Please log in.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Email not verified yet');
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Email not verified yet. Please check your email and click the verification link first.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking verification: $e');
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = 'Error checking verification';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = '❌ Email not verified yet. Please check your email and click the verification link first.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = '❌ Email not verified yet. Please check your email and click the verification link first.';
      } else {
        errorMessage = '❌ Error checking verification: $e';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _checkDelayTimer?.cancel();
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
                Text(
                  'Verify Email Address',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(221, 247, 247, 247),
                  ),
                ),
                const SizedBox(height: 60),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        if (_isVerified)
                          const Column(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 64),
                              SizedBox(height: 16),
                              Text(
                                'Email verified! Redirecting to login...',
                                style: TextStyle(fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              const Icon(Icons.email, color: Color(0xFF4CAF50), size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'We\'ve sent a verification email to:',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.email,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                '📧 Check your email and click the verification link\n\n'
                                'IMPORTANT: After clicking the link in your email, come back here and click "Check Verification" below',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              if (_isLoading)
                                const Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Checking verification status...'),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        border: Border.all(color: Colors.orange),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '⚠️ Step 2: Click the verification link in your email first, then click the button below',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _canCheckVerification ? const Color(0xFF4CAF50) : Colors.grey[300],
                                          foregroundColor: _canCheckVerification ? Colors.white : Colors.grey[500],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        onPressed: _canCheckVerification ? _checkVerificationStatus : null,
                                        child: _canCheckVerification
                                            ? const Text(
                                                '🔍 Check Verification Status',
                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              )
                                            : Text(
                                                'Wait $_checkDelay s...',
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF4CAF50),
                                          side: const BorderSide(color: Color(0xFF4CAF50)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        onPressed: () {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                                            (route) => false,
                                          );
                                        },
                                        child: const Text(
                                          '🚀 Try Login Instead',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Didn\'t receive the email? ',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: _canResend ? _resendEmail : null,
                                    child: _isResending
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text(
                                            _canResend ? 'Resend' : 'Resend in $_resendTimer s',
                                            style: TextStyle(
                                              color: _canResend ? const Color(0xFF4CAF50) : Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 