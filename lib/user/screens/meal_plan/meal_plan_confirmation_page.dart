import 'package:flutter/material.dart';
import '../home/home_page.dart'; // Import HomePage for navigation with tab
import 'dart:async';
import 'package:lottie/lottie.dart';

class MealPlanConfirmationPage extends StatefulWidget {
  const MealPlanConfirmationPage({super.key});

  @override
  State<MealPlanConfirmationPage> createState() => _MealPlanConfirmationPageState();
}

class _MealPlanConfirmationPageState extends State<MealPlanConfirmationPage> {
  Timer? _redirectTimer;
  @override
  void initState() {
    super.initState();
    _redirectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _goToMealPlanner();
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _goToMealPlanner() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage(initialTab: 1, forceMealPlanRefresh: true)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _goToMealPlanner,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Lottie.asset(
                    'assets/widgets/Checked.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Meal Plan added!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your meal plan has been set. You will be redirected shortly.\nTap anywhere to go back now.',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 