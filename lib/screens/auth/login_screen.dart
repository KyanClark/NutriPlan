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
      setState(() { _isLoading = true; });
      
      // Store context before async operations
      final navigatorContext = context;
      
      try {
        // Check if Supabase client is properly initialized
        if (Supabase.instance.client.auth.currentUser != null) {
          await Supabase.instance.client.auth.signOut();
        }
        
        // Save email to login history on successful login
        await LoginHistoryService.saveEmailToHistory(_emailController.text);
        
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        
        if (!mounted) return;
        setState(() { _isLoading = false; });
        
        if (response.user != null) {
          final user = response.user;
          
          if (user?.emailConfirmedAt == null) {
            // Email not verified
            ScaffoldMessenger.of(navigatorContext).showSnackBar(
              const SnackBar(content: Text('Please verify your email before logging in.')),
            );
            await Supabase.instance.client.auth.signOut();
            return;
          }
          
          // Check if user has completed onboarding
          final prefs = await Supabase.instance.client
              .from('user_preferences')
              .select()
              .eq('user_id', user!.id)
              .maybeSingle();
              
          if (!mounted) return;
          
          if (prefs == null) {
            // Navigate to onboarding
            await Navigator.pushReplacement(
              navigatorContext,
              MaterialPageRoute(builder: (context) => const DietTypePage()),
            );
          } else {
            // Navigate to home
            await Navigator.pushReplacement(
              navigatorContext,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          // If no user, show a generic error
          ScaffoldMessenger.of(navigatorContext).showSnackBar(
            const SnackBar(content: Text('Login failed. Please try again.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() { _isLoading = false; });
        
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

  /// Load email suggestions based on current input
  Future<void> _loadEmailSuggestions(String input) async {
    final suggestions = await LoginHistoryService.getFilteredHistory(input);
    setState(() {
      _emailSuggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty && input.isNotEmpty;
    });
  }

  /// Handle email selection from suggestions
  void _selectEmail(String email) {
    setState(() {
      _emailController.text = email;
      _showSuggestions = false;
    });
    // Move focus to password field
    FocusScope.of(context).nextFocus();
  }

  /// Hide suggestions
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
    final double horizontalPadding = MediaQuery.of(context).size.width < 430 ? 16.0 : 24.0;
    final double verticalPadding = MediaQuery.of(context).size.height < 900 ? 16.0 : 24.0;

    return Scaffold(
      body: DecorativeAuthBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AnimatedLogo(),
                    const SizedBox(height: 32),
                    // Move the Login title just above the card
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 20.0, top: 50, bottom: 16.0),
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: GestureDetector(
                          onTap: _hideSuggestions,
                          child: Form(
                            key: _formKey,
                            child: Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      labelText: 'Email address',
                                      prefixIcon: const Icon(Icons.email),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: (value) {
                                      _loadEmailSuggestions(value);
                                    },
                                    onTap: () {
                                      if (_emailController.text.isNotEmpty) {
                                        _loadEmailSuggestions(_emailController.text);
                                      }
                                    },
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
                                  // Email suggestions dropdown
                                  if (_showSuggestions && _emailSuggestions.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: _emailSuggestions.map((email) => 
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => _selectEmail(email),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(
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
                                        ).toList(),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
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
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4CAF50),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        onPressed: _login,
                                        child: const Text('Login', style: TextStyle(fontSize: 18)),
                                      ),
                                    ),
                            ],
                          ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: const Color(0xFF4CAF50),
                          ),
                          child: const Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
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