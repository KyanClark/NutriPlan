import 'package:flutter/material.dart';

class DietaryPreferencesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Preferences'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Personal Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Diet Type'),
            subtitle: const Text('Vegetarian'),
            leading: const Icon(Icons.restaurant_menu),
          ),
          ListTile(
            title: const Text('Allergies and Restrictions'),
            subtitle: const Text('Peanuts, Gluten'),
            leading: const Icon(Icons.warning_amber_rounded),
          ),
          ListTile(
            title: const Text('Meal Servings'),
            subtitle: const Text('2'),
            leading: const Icon(Icons.restaurant),
          ),
        ],
      ),
    );
  }
} 