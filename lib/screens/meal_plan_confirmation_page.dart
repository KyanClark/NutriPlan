import 'package:flutter/material.dart';

class MealPlanConfirmationPage extends StatefulWidget {
  const MealPlanConfirmationPage({Key? key}) : super(key: key);

  @override
  State<MealPlanConfirmationPage> createState() => _MealPlanConfirmationPageState();
}

class _MealPlanConfirmationPageState extends State<MealPlanConfirmationPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _goToMealPlanner();
    });
  }

  void _goToMealPlanner() {
    Navigator.of(context).popUntil((route) {
      // Find the first route that is MealPlannerScreen
      return route.settings.name == '/meal_planner_screen' || route.isFirst;
    });
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
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 80),
                SizedBox(height: 24),
                Text(
                  'Meal Plan added!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
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