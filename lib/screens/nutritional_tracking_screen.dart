import 'package:flutter/material.dart';

class NutritionalTrackingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutritional Tracking'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Text(
          'Nutritional Tracking Features Coming Soon!',
          style: TextStyle(fontSize: 18, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 