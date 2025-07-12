import 'package:flutter/material.dart';

class MealTrackerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Tracker'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text('Meal Tracker functionality coming soon!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
} 