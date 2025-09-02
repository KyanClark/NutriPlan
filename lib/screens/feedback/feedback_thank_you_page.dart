import 'package:flutter/material.dart';
import 'dart:async';
import '../home/home_page.dart';

class FeedbackThankYouPage extends StatefulWidget {
  final String recipeTitle;
  
  const FeedbackThankYouPage({super.key, required this.recipeTitle});

  @override
  State<FeedbackThankYouPage> createState() => _FeedbackThankYouPageState();
}

class _FeedbackThankYouPageState extends State<FeedbackThankYouPage> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });
        
        if (_countdown <= 0) {
          timer.cancel();
          _navigateToHome();
        }
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToHome,
      child: Scaffold(
        backgroundColor: const Color(0xFF4CAF50),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Thank You Text
                  const Text(
                    'Thank You!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    'Your feedback for "${widget.recipeTitle}" has been submitted successfully.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tap anywhere hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      'Tap anywhere to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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