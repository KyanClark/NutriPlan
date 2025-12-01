import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/sms_otp_service.dart';
import 'login_screen.dart';
import '../../widgets/animated_logo.dart';
import '../../widgets/decorative_auth_background.dart';

class PhoneOtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String password;
  final String fullName;
  
  const PhoneOtpVerificationScreen({
    required this.phoneNumber,
    required this.password,
    required this.fullName,
    super.key,
  });

  @override
  State<PhoneOtpVerificationScreen> createState() => _PhoneOtpVerificationScreenState();
}

class _PhoneOtpVerificationScreenState extends State<PhoneOtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final Map<int, String> _previousValues = {}; // Track previous values for backspace detection
  bool _isLoading = false;
  bool _isResending = false;
  bool _isVerified = false;
  int _resendTimer = 60;
  bool _canResend = false;
  Timer? _resendTimerInstance;
  String? _formattedPhoneNumber; // Store the formatted phone number from sendOtp
  bool _isVerifying = false; // Prevent multiple simultaneous verification attempts

  @override
  void initState() {
    super.initState();
    _sendOtp();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });
    
    _resendTimerInstance?.cancel();
    _resendTimerInstance = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await SmsOtpService.sendOtp(widget.phoneNumber);
      
      // Store the formatted phone number returned from sendOtp
      if (result['phone'] != null) {
        _formattedPhoneNumber = result['phone'] as String;
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully! Please check your phone.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['message']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending OTP: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
    });

    try {
      await _sendOtp();
      _startResendTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resending OTP: $e')),
        );
      }
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  void _onOtpChanged(int index, String value) {
    final previousValue = _previousValues[index] ?? '';
    
    // If field became empty (backspace was pressed on a filled field) - allow it
    if (value.isEmpty && previousValue.isNotEmpty) {
      _previousValues[index] = '';
      // Field was cleared - this is fine, user can type again or move to previous
      return;
    }
    
    // Update previous value
    _previousValues[index] = value;
    
    // Handle input: if a digit is entered, move to next field
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto-verify when all 6 digits are entered (only if not already verifying)
    if (index == 5 && value.length == 1 && !_isVerifying && !_isLoading) {
      // Small delay to ensure all fields are updated
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_isVerifying && !_isLoading) {
          _verifyOtp();
        }
      });
    }
  }
  
  // Handle backspace on empty field - called from focus node
  void _handleBackspace(int index) {
    if (index > 0 && _otpControllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
      _previousValues[index - 1] = '';
    }
  }

  Future<void> _verifyOtp() async {
    // Prevent multiple simultaneous verification attempts
    if (_isVerifying || _isLoading || _isVerified) {
      return;
    }

    // Get OTP from individual controllers
    final otp = _otpControllers.map((controller) => controller.text).join();
    
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isVerifying = true;
    });

    try {
      // Verify OTP - use formatted phone number if available, otherwise use original
      final phoneToVerify = _formattedPhoneNumber ?? widget.phoneNumber;
      print('Attempting to verify OTP: $otp for phone: $phoneToVerify');
      final isValid = await SmsOtpService.verifyOtp(phoneToVerify, otp);
      
      if (!isValid) {
        setState(() {
          _isLoading = false;
          _isVerifying = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid or expired OTP. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          // Don't clear OTP fields - let user correct the mistake
          // Just shake or highlight the error
        }
        return;
      }

      // OTP verified successfully!
      print('OTP verified, proceeding to create account...');
      
      // OTP verified, create account with phone number
      // Since Supabase phone auth requires specific providers (not iprogsms),
      // we use email format but store actual phone in metadata
      String phoneDigits = widget.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      // Remove leading zero if present (email can't start with 0)
      if (phoneDigits.startsWith('0')) {
        phoneDigits = phoneDigits.substring(1);
      }
      // If it starts with country code 63, keep it; otherwise add it
      if (!phoneDigits.startsWith('63')) {
        phoneDigits = '63$phoneDigits';
      }
      final formattedPhone = '+$phoneDigits';
      // Use a more standard email format that Supabase will accept
      final email = 'user.$phoneDigits@nutriplan.app'; // Email format with dot separator
      
      try {
        print('Creating Supabase account with email: $email (phone: $formattedPhone)');
        final response = await Supabase.instance.client.auth.signUp(
          email: email, // Use email format (phone auth not available with iprogsms)
          password: widget.password,
          data: {
            'full_name': widget.fullName,
            'phone': formattedPhone, // Store actual phone in metadata
          },
        );

        // Supabase sometimes requires email confirmation and doesn't automatically set currentUser.
        // Use the response user directly and handle the null case gracefully.
        final user = response.user ?? Supabase.instance.client.auth.currentUser;
        if (user == null) {
          print('Supabase signUp succeeded but no user returned.');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isVerifying = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created, but we could not complete setup. Please try logging in.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
          return;
        }

        print('Account created, inserting profile...');
        // Insert profile row
        try {
          await Supabase.instance.client
            .from('profiles')
            .insert({
              'id': user.id,
              'username': widget.fullName,
            });
          print('Profile inserted successfully');
        } catch (e) {
          print('Error inserting profile (may already exist): $e');
          // Continue even if profile insert fails (might already exist)
        }
        
        // Auto-confirm email for phone accounts via database function
        try {
          await Supabase.instance.client.rpc('confirm_phone_email', params: {'user_email': email});
          print('Email auto-confirmed for phone account');
        } catch (e) {
          print('Note: Auto-confirm function not available. You may need to create it in Supabase: $e');
          // Continue anyway - user is already signed in
        }
        
        // Account created successfully
        setState(() {
          _isVerified = true;
          _isLoading = false;
          _isVerifying = false;
        });
        
        // Sign out the user so they need to log in
        await Supabase.instance.client.auth.signOut();
        
        // Navigate to login page with success message
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Account created successfully! Please log in to continue.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      } catch (e) {
        print('Error creating account: $e');
        setState(() {
          _isLoading = false;
          _isVerifying = false;
        });
        
        String errorMessage = 'Error creating account';
        if (e.toString().contains('already registered') || e.toString().contains('already exists')) {
          errorMessage = 'This phone number is already registered. Please log in instead.';
          // Navigate to login if account already exists
          if (mounted) {
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account already exists. Please log in.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isVerifying = false;
      });
      
      String errorMessage = 'Error verifying OTP';
      if (e.toString().contains('already registered')) {
        errorMessage = 'This phone number is already registered. Please log in instead.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimerInstance?.cancel();
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
                  'Verify Phone Number',
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
                                'Phone verified! Redirecting to login...',
                                style: TextStyle(fontSize: 18),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              const Icon(Icons.phone_android, color: Color(0xFF4CAF50), size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'We\'ve sent a verification code to:',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.phoneNumber,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // OTP Input Fields
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  // Calculate responsive size based on screen width
                                  final screenWidth = MediaQuery.of(context).size.width;
                                  final availableWidth = screenWidth - 48 - 40; // padding + card padding
                                  final spacing = 8.0; // Space between boxes
                                  final totalSpacing = spacing * 5; // 5 spaces between 6 boxes
                                  final boxWidth = ((availableWidth - totalSpacing) / 6).clamp(40.0, 50.0);
                                  final boxHeight = (boxWidth * 1.2).clamp(48.0, 60.0);
                                  final fontSize = (boxWidth * 0.5).clamp(20.0, 28.0);
                                  
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: List.generate(6, (index) {
                                      return SizedBox(
                                        width: boxWidth,
                                        height: boxHeight, 
                                        child: TextField(
                                          controller: _otpControllers[index],
                                          focusNode: _focusNodes[index],
                                          textAlign: TextAlign.center,
                                          textAlignVertical: TextAlignVertical.center,
                                          keyboardType: TextInputType.number,
                                          maxLength: 1,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(1),
                                          ],
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                            height: 1.0, // Fixed height to prevent overflow
                                          ),
                                          decoration: InputDecoration(
                                            counterText: '',
                                            contentPadding: EdgeInsets.zero, // Remove default padding
                                            isDense: true,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                                            ),
                                          ),
                                      onChanged: (value) {
                                        _onOtpChanged(index, value);
                                      },
                                      onTap: () {
                                        // Allow user to tap and edit any field
                                        _focusNodes[index].requestFocus();
                                        // Select all text when tapped for easy replacement
                                        if (_otpControllers[index].text.isNotEmpty) {
                                          _otpControllers[index].selection = TextSelection(
                                            baseOffset: 0,
                                            extentOffset: _otpControllers[index].text.length,
                                          );
                                        }
                                      },
                                      // Add listener to focus node to handle backspace on empty field
                                      onEditingComplete: () {
                                        // When user finishes editing, handle backspace if field is empty
                                        if (_otpControllers[index].text.isEmpty && index > 0) {
                                          _handleBackspace(index);
                                        }
                                      },
                                    ),
                                  );
                                    }),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              if (_isLoading)
                                const Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Verifying OTP...'),
                                  ],
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    onPressed: _verifyOtp,
                                    child: const Text(
                                      'Verify OTP',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Didn\'t receive the code? ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Flexible(
                                    child: TextButton(
                                      onPressed: _canResend ? _resendOtp : null,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: _isResending
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Text(
                                              _canResend ? 'Resend' : 'Resend in $_resendTimer s',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _canResend ? const Color(0xFF4CAF50) : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
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

