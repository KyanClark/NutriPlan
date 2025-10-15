import 'package:flutter/material.dart';
import 'package:nutriplan/screens/home/home_page.dart';
import 'signup_screen.dart';
import '../../widgets/animated_logo.dart';
import '../../widgets/decorative_auth_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../onboarding/diet_type.dart';
import '../../services/login_history_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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

  @override
  void initState() {
    super.initState();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final navigatorContext = context;

      try {
        if (Supabase.instance.client.auth.currentUser != null) {
          await Supabase.instance.client.auth.signOut();
        }

        await LoginHistoryService.saveEmailToHistory(_emailController.text);

        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        if (response.user != null) {
          final user = response.user;

          if (user?.emailConfirmedAt == null) {
            ScaffoldMessenger.of(navigatorContext).showSnackBar(
              const SnackBar(
                content: Text('Please verify your email before logging in.'),
              ),
            );
            await Supabase.instance.client.auth.signOut();
            return;
          }

          final prefs = await Supabase.instance.client
              .from('user_preferences')
              .select()
              .eq('user_id', user!.id)
              .maybeSingle();

          if (!mounted) return;

          if (prefs == null) {
            await Navigator.pushReplacement(
              navigatorContext,
              MaterialPageRoute(builder: (context) => const DietTypePage()),
            );
          } else {
            await Navigator.pushReplacement(
              navigatorContext,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          ScaffoldMessenger.of(navigatorContext).showSnackBar(
            const SnackBar(content: Text('Login failed. Please try again.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        String errorMsg = e.toString().toLowerCase();
        String userMsg;

        if (errorMsg.contains('invalid login credentials')) {
          userMsg = 'Incorrect email or password. Please try again.';
        } else if (errorMsg.contains('email')) {
          userMsg = 'This email is not registered.';
        } else if (errorMsg.contains('password')) {
          userMsg = 'Incorrect password. Please try again.';
        } else if (errorMsg.contains('network')) {
          userMsg = 'Network error. Please check your connection.';
        } else if (errorMsg.contains('timeout')) {
          userMsg = 'Request timeout. Please try again.';
        } else {
          userMsg = 'Login failed: $e';
        }

        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(content: Text(userMsg)),
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

    return Scaffold(
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AnimatedLogo(),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding:
                            EdgeInsets.only(left: 20.0, top: 50, bottom: 16.0),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
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
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email address',
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
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (value) {
                                    _loadEmailSuggestions(value);
                                  },
                                  onTap: () {
                                    if (_emailController.text.isNotEmpty) {
                                      _loadEmailSuggestions(
                                            _emailController.text);
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                              r'^[^@\s]+@[^@\s]+\.[^@\s]+')
                                          .hasMatch(value)) {
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
                              decoration: InputDecoration(
                                labelText: 'Password',
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
                            _isLoading
                                ? const CircularProgressIndicator()
                                : SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.8,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF4CAF50),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                              vertical: 18,
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
                                    MediaQuery.of(context).size.width * 0.8,
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
