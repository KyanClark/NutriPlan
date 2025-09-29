import 'package:flutter/material.dart';
import '../onboarding/health_conditions_page.dart';

class NutritionGoalsSummaryPage extends StatelessWidget {
  final Map<String, double> nutritionGoals;
  
  const NutritionGoalsSummaryPage({
    super.key,
    required this.nutritionGoals,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Nutrition Goals'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            
            // Header
            const Text(
              'Your Personalized Goals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Based on your profile, here are your daily nutrition targets:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            
            // Calories Card
            _buildMainGoalCard(
              title: 'Daily Calories',
              value: '${nutritionGoals['calories']!.toInt()}',
              unit: 'kcal',
              icon: '🔥',
              color: Colors.orange,
              subtitle: 'Your daily energy target',
            ),
            
            const SizedBox(height: 24),
            
            // Macronutrients Grid
            const Text(
              'Macronutrients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMacroCard(
                    title: 'Protein',
                    value: '${nutritionGoals['protein']!.toInt()}g',
                    icon: '🥩',
                    color: Colors.red,
                    percentage: _calculateMacroPercentage('protein'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroCard(
                    title: 'Carbs',
                    value: '${nutritionGoals['carbs']!.toInt()}g',
                    icon: '🍚',
                    color: Colors.blue,
                    percentage: _calculateMacroPercentage('carbs'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroCard(
                    title: 'Fat',
                    value: '${nutritionGoals['fat']!.toInt()}g',
                    icon: '🥑',
                    color: Colors.green,
                    percentage: _calculateMacroPercentage('fat'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Other Nutrients
            const Text(
              'Other Nutrients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildNutrientRow(
              title: 'Fiber',
              value: '${nutritionGoals['fiber']!.toInt()}g',
              icon: '🌾',
              subtitle: 'For digestive health',
            ),
            
            _buildNutrientRow(
              title: 'Sugar',
              value: '< ${nutritionGoals['sugar']!.toInt()}g',
              icon: '🍯',
              subtitle: 'Daily limit for added sugars',
            ),
            
            _buildNutrientRow(
              title: 'Cholesterol',
              value: '< ${nutritionGoals['cholesterol']!.toInt()}mg',
              icon: '🧈',
              subtitle: 'Daily cholesterol limit',
            ),
            
            const SizedBox(height: 32),
            
            // BMR/TDEE Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metabolism Info',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BMR: ${nutritionGoals['bmr']!.toInt()} kcal',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Calories burned at rest',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TDEE: ${nutritionGoals['tdee']!.toInt()} kcal',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Total daily energy needs',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HealthConditionsPage(
                        baseNutritionGoals: nutritionGoals,
                      ),
                    ),
                  );
                },
                child: const Text('Continue Setup', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMainGoalCard({
    required String title,
    required String value,
    required String unit,
    required String icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF43A047),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF43A047),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroCard({
    required String title,
    required String value,
    required String icon,
    required Color color,
    required int percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutrientRow({
    required String title,
    required String value,
    required String icon,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF388E3C),
            ),
          ),
        ],
      ),
    );
  }
  
  int _calculateMacroPercentage(String macro) {
    final calories = nutritionGoals['calories']!;
    final macroValue = nutritionGoals[macro]!;
    
    double macroCalories;
    if (macro == 'fat') {
      macroCalories = macroValue * 9; // 9 calories per gram of fat
    } else {
      macroCalories = macroValue * 4; // 4 calories per gram for protein/carbs
    }
    
    return ((macroCalories / calories) * 100).round();
  }
}
