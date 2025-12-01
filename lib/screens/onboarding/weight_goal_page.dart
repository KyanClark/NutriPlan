import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'health_conditions_page.dart';
import '../../services/nutrition_calculator_service.dart';
import '../../utils/onboarding_transitions.dart';

class WeightGoalPage extends StatefulWidget {
  final int age;
  final String gender;
  final double? heightCm;
  final double? weightKg;
  final String activityLevel;
  
  const WeightGoalPage({
    super.key,
    required this.age,
    required this.gender,
    this.heightCm,
    this.weightKg,
    required this.activityLevel,
  });

  @override
  State<WeightGoalPage> createState() => _WeightGoalPageState();
}

class _WeightGoalPageState extends State<WeightGoalPage> {
  String? selectedGoal;
  
  final List<Map<String, String>> weightGoals = [
    {
      'value': 'lose_weight',
      'title': '🔥 Lose Weight',
      'desc': 'Create a calorie deficit to lose 0.5-1 kg per week',
      'icon': '🔥',
      'color': 'orange',
    },
    {
      'value': 'maintain_weight',
      'title': '⚖️ Maintain Weight',
      'desc': 'Keep your current weight with balanced nutrition',
      'icon': '⚖️',
      'color': 'green',
    },
    {
      'value': 'gain_weight',
      'title': '💪 Gain Weight',
      'desc': 'Create a calorie surplus to gain 0.5-1 kg per week',
      'icon': '💪',
      'color': 'blue',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF388E3C)),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 16),
              Text(
                'What\'s your goal?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF388E3C),
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'ll calculate your personalized nutrition targets based on your goal.',
                style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 20),
              // BMI Display
              _buildBMICard(),
              const SizedBox(height: 20),
              // Goal Selection
              Expanded(
              child: ListView.separated(
                itemCount: weightGoals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final goal = weightGoals[index];
                  final isSelected = selectedGoal == goal['value'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedGoal = goal['value'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ] : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                goal['icon']!,
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
                                  goal['title']!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  goal['desc']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected ? Colors.white70 : Colors.black54,
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
                },
              ),
              ),
              const SizedBox(height: 24),
              // Continue Button
              SizedBox(
                width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: selectedGoal != null ? () async {
                  // Calculate nutrition goals
                  final nutritionGoals = NutritionCalculatorService.calculateGoals(
                    age: widget.age,
                    gender: widget.gender,
                    heightCm: widget.heightCm ?? 170.0, // Default height if null
                    weightKg: widget.weightKg ?? 70.0,  // Default weight if null
                    activityLevel: widget.activityLevel,
                    weightGoal: selectedGoal!,
                  );
                  
                  // Save to database - save all profile data together
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    await Supabase.instance.client
                      .from('user_preferences')
                      .upsert({
                        'user_id': user.id,
                        'age': widget.age,
                        'gender': widget.gender,
                        'height_cm': widget.heightCm,
                        'weight_kg': widget.weightKg,
                        'activity_level': widget.activityLevel,
                        'weight_goal': selectedGoal,
                        'calorie_goal': nutritionGoals['calories'],
                        'protein_goal': nutritionGoals['protein'],
                        'carb_goal': nutritionGoals['carbs'],
                        'fat_goal': nutritionGoals['fat'],
                        'fiber_goal': nutritionGoals['fiber'],
                        'sugar_goal': nutritionGoals['sugar'],
                        'cholesterol_goal': nutritionGoals['cholesterol'],
                        'sodium_limit': nutritionGoals['sodium'],
                        'iron_goal': nutritionGoals['iron_goal'],
                        'vitamin_c_goal': nutritionGoals['vitamin_c_goal'],
                      });
                  }
                  
                  Navigator.push(
                    context,
                    OnboardingPageRoute(
                      page: HealthConditionsPage(
                        baseNutritionGoals: nutritionGoals,
                      ),
                    ),
                  );
                } : null,
                child: const Text('Calculate My Goals', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
      )
    );
  }
  
  Widget _buildBMICard() {
    if (widget.heightCm == null || widget.weightKg == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Colors.grey, size: 18),
            SizedBox(width: 8),
            Text(
              'BMI requires height & weight',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    final bmi = widget.weightKg! / ((widget.heightCm! / 100) * (widget.heightCm! / 100));
    String bmiCategory;
    Color bmiColor;
    
    if (bmi < 18.5) {
      bmiCategory = 'Underweight';
      bmiColor = Colors.blue;
    } else if (bmi < 25) {
      bmiCategory = 'Normal weight';
      bmiColor = Colors.green;
    } else if (bmi < 30) {
      bmiCategory = 'Overweight';
      bmiColor = Colors.orange;
    } else {
      bmiCategory = 'Obese';
      bmiColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bmiColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bmiColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bmiColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '📊',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BMI: ${bmi.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: bmiColor,
                ),
              ),
              Text(
                bmiCategory,
                style: TextStyle(
                  fontSize: 12,
                  color: bmiColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
