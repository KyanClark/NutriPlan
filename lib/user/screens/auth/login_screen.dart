import 'package:flutter/material.dart';
import 'package:nutriplan/user/screens/home/home_page.dart';
import 'signup_screen.dart';
import '../../widgets/animated_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../onboarding/welcome_experience_page.dart';
import '../../services/login_history_service.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/decorative_auth_background.dart';

class LoginScreen extends StatefulWidget {
  final String? initialInput;
  const LoginScreen({super.key, this.initialInput});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  List<String> _emailSuggestions = [];
  bool _showSuggestions = false;
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill email/phone if provided (e.g., from saved account)
    if (widget.initialInput != null && widget.initialInput!.isNotEmpty) {
      _emailController.text = widget.initialInput!;
    }
  }

  void _login() async {
    // Dismiss keyboard / input cursor when login is pressed
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _showSuccessAnimation = false;
      });

      final navigatorContext = context;

      // Determine if input is email or phone number (declare outside try for catch block access)
      final input = _emailController.text.trim();
      
      // Check if input is a phone number (contains only digits, +, spaces, dashes)
      final phoneRegex = RegExp(r'^[\d\s\+\-\(\)]+$');
      final isPhoneNumber = phoneRegex.hasMatch(input) && 
                            input.replaceAll(RegExp(r'[^\d]'), '').length >= 10;
      
      bool isPhoneLogin = false;
      
      try {
        if (Supabase.instance.client.auth.currentUser != null) {
          await Supabase.instance.client.auth.signOut();
        }
        
        dynamic response;
        
        if (isPhoneNumber) {
          // Format phone number to match signup email format
          // Since Supabase phone auth isn't available, we use email format
          String phoneDigits = input.replaceAll(RegExp(r'[^\d]'), '');
          // Remove leading zero if present
          if (phoneDigits.startsWith('0')) {
            phoneDigits = phoneDigits.substring(1);
          }
          // If it starts with country code 63, keep it; otherwise add it
          if (!phoneDigits.startsWith('63')) {
            phoneDigits = '63$phoneDigits';
          }
          final loginEmail = 'user.$phoneDigits@nutriplan.app'; // Match signup format (with dot separator)
          
          print('Phone number detected, logging in with email: $loginEmail');
          isPhoneLogin = true;
          
          // Use email authentication (phone auth not available with iprogsms)
          response = await Supabase.instance.client.auth.signInWithPassword(
            email: loginEmail,
            password: _passwordController.text,
          );
        } else {
          // Use email authentication
          await LoginHistoryService.saveEmailToHistory(input);
          print('Attempting login with email: $input');
          
          response = await Supabase.instance.client.auth.signInWithPassword(
            email: input,
          password: _passwordController.text,
        );
        }

        print('Login response received. User: ${response.user?.id}');
        print('Email confirmed: ${response.user?.emailConfirmedAt}');

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        if (response.user != null) {
          final user = response.user;

          // Skip email verification check for phone-based accounts (already verified via OTP)
          // Phone accounts use @nutriplan.app email format
          final isPhoneAccount = user?.email?.endsWith('@nutriplan.app') ?? false;
          
          // For phone accounts, we skip email verification since OTP already verified them
          if (isPhoneAccount || isPhoneLogin) {
            print('Phone account detected, skipping email verification check');
            // Continue to login flow
          } else if (user?.emailConfirmedAt == null) {
            // Only check email verification for regular email accounts
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _showSuccessAnimation = false;
            });
            ScaffoldMessenger.of(navigatorContext).showSnackBar(
              SnackBar(
                content: const Text('Please verify your email before logging in. Check your inbox for the verification link.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Resend',
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await Supabase.instance.client.auth.resend(
                        type: OtpType.signup,
                        email: input,
                      );
            ScaffoldMessenger.of(navigatorContext).showSnackBar(
              const SnackBar(
                          content: Text('Verification email sent! Please check your inbox.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(navigatorContext).showSnackBar(
                        SnackBar(
                          content: Text('Failed to resend email: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            );
            await Supabase.instance.client.auth.signOut();
            return;
          }

          // Show success animation
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _showSuccessAnimation = true;
          });

          // Wait for animation to complete (animation is ~1 second, op: 63 frames at 24fps)
          await Future.delayed(const Duration(milliseconds: 1500));

          if (!mounted) return;

          final prefs = await Supabase.instance.client
              .from('user_preferences')
              .select()
              .eq('user_id', user!.id)
              .maybeSingle();

          if (!mounted) return;

          if (prefs == null) {
            await Navigator.pushReplacement(
              navigatorContext,
              MaterialPageRoute(builder: (context) => const WelcomeExperiencePage()),
            );
          } else {
            await Navigator.pushReplacement(
              navigatorContext,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _showSuccessAnimation = false;
          });
          ScaffoldMessenger.of(navigatorContext).showSnackBar(
            const SnackBar(content: Text('Login failed. Please try again.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _showSuccessAnimation = false;
        });

        // Log the full error for debugging
        print('Login error: $e');
        print('Error type: ${e.runtimeType}');

        String errorMsg = e.toString().toLowerCase();
        String userMsg;

        // Check for specific Supabase Auth errors
        if (e is AuthException) {
          final authError = e;
          print('Auth error message: ${authError.message}');
          
          if (authError.message.toLowerCase().contains('invalid login credentials') ||
              authError.message.toLowerCase().contains('invalid_credentials')) {
            userMsg = 'Incorrect email/phone or password. Please check your credentials and try again.';
          } else if (authError.message.toLowerCase().contains('email not confirmed') ||
                     authError.message.toLowerCase().contains('email_not_confirmed')) {
            // For phone accounts, try to auto-confirm via database function
            if (isPhoneLogin) {
              try {
                final phoneDigits = input.replaceAll(RegExp(r'[^\d]'), '');
                String cleanedPhone = phoneDigits;
                if (cleanedPhone.startsWith('0')) {
                  cleanedPhone = cleanedPhone.substring(1);
                }
                if (!cleanedPhone.startsWith('63')) {
                  cleanedPhone = '63$cleanedPhone';
                }
                final loginEmail = 'user.$cleanedPhone@nutriplan.app';
                
                // Try to auto-confirm via database function
                await Supabase.instance.client.rpc('confirm_phone_email', params: {'user_email': loginEmail});
                
                // Retry login after confirmation
                await Future.delayed(const Duration(milliseconds: 500));
                final retryResponse = await Supabase.instance.client.auth.signInWithPassword(
                  email: loginEmail,
                  password: _passwordController.text,
                );
                
                if (retryResponse.user != null) {
                  // Success - continue with normal login flow
                  final user = retryResponse.user;
                  setState(() {
                    _isLoading = false;
                    _showSuccessAnimation = true;
                  });
                  
                  await Future.delayed(const Duration(milliseconds: 1500));
                  
                  if (!mounted) return;
                  final prefs = await Supabase.instance.client
                      .from('user_preferences')
                      .select()
                      .eq('user_id', user!.id)
                      .maybeSingle();
                  
                  if (!mounted) return;
                  
                  if (prefs == null) {
                    await Navigator.pushReplacement(
                      navigatorContext,
                      MaterialPageRoute(builder: (context) => const WelcomeExperiencePage()),
                    );
                  } else {
                    await Navigator.pushReplacement(
                      navigatorContext,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  }
                  return;
                }
              } catch (confirmError) {
                print('Auto-confirm failed: $confirmError');
              }
            }
            userMsg = 'Please verify your email before logging in. Check your inbox for the verification link.';
          } else if (authError.message.toLowerCase().contains('too many requests')) {
            userMsg = 'Too many login attempts. Please wait a few minutes and try again.';
          } else {
            userMsg = 'Login failed: ${authError.message}';
          }
        } else if (errorMsg.contains('invalid login credentials') ||
                   errorMsg.contains('invalid_credentials')) {
          userMsg = 'Incorrect email/phone or password. Please check your credentials and try again.';
        } else if (errorMsg.contains('email not confirmed') ||
                   errorMsg.contains('email_not_confirmed')) {
          userMsg = 'Please verify your email before logging in. Check your inbox for the verification link.';
        } else if (errorMsg.contains('network') || errorMsg.contains('socket')) {
          userMsg = 'Network error. Please check your internet connection and try again.';
        } else if (errorMsg.contains('timeout')) {
          userMsg = 'Request timeout. Please check your connection and try again.';
        } else if (errorMsg.contains('connection')) {
          userMsg = 'Cannot connect to server. Please check your internet connection.';
        } else {
          userMsg = 'Login failed: ${e.toString()}';
        }

        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: Text(userMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadEmailSuggestions(String input) async {
    final suggestions = await LoginHistoryService.getFilteredHistory(input);
    if (mounted) {
    setState(() {
      _emailSuggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty && input.isNotEmpty;
    });
    }
  }

  void _selectEmail(String email) {
    setState(() {
      _emailController.text = email;
      _showSuggestions = false;
    });
    FocusScope.of(context).nextFocus();
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                      const SizedBox(height: 10),
                      const AnimatedLogo(),
                      const SizedBox(height: 10),
                      // Centered tagline directly under the NutriPlan logo for readability
                      Padding(
                        padding: EdgeInsets.only(
                          top: isKeyboardVisible ? 0.0 : 4.0,
                          bottom: isKeyboardVisible ? 24.0 : 160.0,
                        ),
                        child: const Text(
                          'Healthy recipes, smarter planning.\nLog in to continue your NutriPlan journey.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: Color.fromARGB(230, 255, 255, 255),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _hideSuggestions,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.75,
                                    child: TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number/Email address',
                                      labelStyle: const TextStyle(fontSize: 13),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Builder(
                                          builder: (context) {
                                            // Show phone icon if input looks like phone, email icon otherwise
                                            final text = _emailController.text;
                                            final phoneRegex = RegExp(r'^[\d\s\+\-\(\)]+$');
                                            final isPhone = phoneRegex.hasMatch(text) && 
                                                           text.replaceAll(RegExp(r'[^\d]'), '').length >= 10 &&
                                                           !text.contains('@');
                                            return Icon(
                                              isPhone ? Icons.phone : Icons.email,
                                          size: 20,
                                          color: Colors.grey[600],
                                            );
                                          },
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                  ),
                                  keyboardType: TextInputType.text, // Allow both email and phone
                                  onChanged: (value) {
                                    // Only load email suggestions if it looks like an email
                                    if (value.contains('@')) {
                                      _loadEmailSuggestions(value);
                                    } else {
                                      setState(() {
                                        _emailSuggestions = [];
                                        _showSuggestions = false;
                                      });
                                    }
                                  },
                                  onTap: () {
                                    if (_emailController.text.isNotEmpty && _emailController.text.contains('@')) {
                                      _loadEmailSuggestions(_emailController.text);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email or phone number';
                                    }
                                    
                                    // Check if it's a phone number
                                    final phoneRegex = RegExp(r'^[\d\s\+\-\(\)]+$');
                                    final cleanedPhone = value.replaceAll(RegExp(r'[^\d]'), '');
                                    final isPhoneNumber = phoneRegex.hasMatch(value) && cleanedPhone.length >= 10;
                                    
                                    // Check if it's a valid email
                                    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value);
                                    
                                    if (!isPhoneNumber && !isEmail) {
                                      return 'Please enter a valid email or phone number';
                                    }
                                    
                                    return null;
                                  },
                                ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.75,
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
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              ),
                                  ),
                                  const SizedBox(height: 24),
                                  _showSuccessAnimation
                                      ? SizedBox(
                                          width: MediaQuery.of(context).size.width * 0.75,
                                          child: Center(
                                            child: SizedBox(
                                              width: 70,
                                              height: 70,
                                              child: Lottie.asset(
                                                'assets/widgets/Checked.json',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        )
                                      : _isLoading
                                          ? SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.75,
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            )
                                          : SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.75,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF4CAF50),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                                ),
                                                onPressed: _login,
                                                child: const Text(
                                                  'Login',
                                                  style: TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            ),
                                ],
                              ),
                            ),
                            if (_showSuggestions &&
                                _emailSuggestions.isNotEmpty)
                              Positioned(
                                top: 60,
                                left: 0,
                                right: 0,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.75,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: _emailSuggestions
                                        .map(
                                          (email) => Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => _selectEmail(email),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.email_outlined,
                                                      size: 20,
                                                      color: Colors.grey,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        email,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                          ],
                          ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           const Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: Color.fromARGB(255, 112, 110, 110),
                                fontWeight: FontWeight.bold,
                              ),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: const Color(0xFF4CAF50),
                            ),
                            child: const Text(
                              'Sign Up',
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
              ),
            ),
          ),
      ),
    );
  }
}
