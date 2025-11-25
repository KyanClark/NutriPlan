import 'package:flutter/material.dart';
import 'weight_goal_page.dart';

class ActivityLevelPage extends StatefulWidget {
  final int age;
  final String sex;
  final double? heightCm;
  final double? weightKg;
  
  const ActivityLevelPage({
    super.key,
    required this.age,
    required this.sex,
    this.heightCm,
    this.weightKg,
  });

  @override
  State<ActivityLevelPage> createState() => _ActivityLevelPageState();
}

class _ActivityLevelPageState extends State<ActivityLevelPage> {
  String? _selectedActivityLevel;
  
  final List<Map<String, String>> activityLevels = [
    {
      'value': 'sedentary',
      'label': 'Sedentary',
      'desc': 'Little to no exercise, desk job',
      'icon': '🪑',
    },
    {
      'value': 'lightly_active',
      'label': 'Lightly Active',
      'desc': 'Light exercise 1-3 days/week',
      'icon': '🚶',
    },
    {
      'value': 'moderately_active',
      'label': 'Moderately Active',
      'desc': 'Moderate exercise 3-5 days/week',
      'icon': '🏃',
    },
    {
      'value': 'very_active',
      'label': 'Very Active',
      'desc': 'Hard exercise 6-7 days/week',
      'icon': '💪',
    },
    {
      'value': 'extremely_active',
      'label': 'Extremely Active',
      'desc': 'Very hard exercise, physical job',
      'icon': '🏋️',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Level'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Activity Level',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How active are you? This helps us calculate your calorie needs.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            
            // Activity Level Options
            Expanded(
              child: ListView(
                children: activityLevels.map((option) {
                  final isSelected = _selectedActivityLevel == option['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedActivityLevel = option['value'];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                option['icon']!,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option['label']!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  option['desc']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected ? Colors.white70 : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedActivityLevel != null 
                      ? const Color(0xFF4CAF50) 
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _selectedActivityLevel != null ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeightGoalPage(
                        age: widget.age,
                        gender: widget.sex,
                        heightCm: widget.heightCm,
                        weightKg: widget.weightKg,
                        activityLevel: _selectedActivityLevel!,
                      ),
                    ),
                  );
                } : null,
                child: Text(
                  _selectedActivityLevel != null ? 'Continue' : 'Select Activity Level',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
