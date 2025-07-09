import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  const VerifyScreen({required this.email, Key? key}) : super(key: key);

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  Timer? _timer;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerification());
  }

  Future<void> _checkVerification() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    // Refresh the session to get the latest user info
    final response = await Supabase.instance.client.auth.refreshSession();
    final user = response.user;

    if (user != null && user.emailConfirmedAt != null) {
      _timer?.cancel();
      setState(() => _isVerified = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified! Please log in.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isVerified
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 64),
                  SizedBox(height: 16),
                  Text('Email verified! Redirecting to login...', style: TextStyle(fontSize: 18)),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    'A verification link has been sent to your email.\nPlease click the link to verify your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
      ),
    );
  }
}