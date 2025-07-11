import 'package:flutter/material.dart';

class MealPlanHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan History'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: Icon(Icons.calendar_today, color: Colors.green),
            title: Text('April 20, 2024'),
            subtitle: Text('Breakfast'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.calendar_today, color: Colors.green),
            title: Text('April 19, 2024'),
            subtitle: Text('Lunch'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.calendar_today, color: Colors.green),
            title: Text('April 18, 2024'),
            subtitle: Text('Dinner'),
          ),
        ],
      ),
    );
  }
} 