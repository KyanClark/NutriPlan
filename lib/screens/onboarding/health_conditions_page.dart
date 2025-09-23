import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'allergy_selection_page.dart';

class HealthConditionsPage extends StatefulWidget {
  final Map<String, double> baseNutritionGoals;
  
  const HealthConditionsPage({
    super.key,
    required this.baseNutritionGoals,
  });

  @override
  State<HealthConditionsPage> createState() => _HealthConditionsPageState();
}

class _HealthConditionsPageState extends State<HealthConditionsPage> {
  final Set<int> selectedIndexes = {};
  
  final List<Map<String, dynamic>> healthConditions = [
    {
      'key': 'none',
      'title': '✅ None',
      'desc': 'No specific health conditions',
      'icon': '✅',
      'color': Colors.green,
      'adjustments': {},
    },
    {
      'key': 'diabetes',
      'title': '🩺 Diabetes / High Blood Sugar',
      'desc': 'Lower carbs, higher fiber, controlled portions',
      'icon': '🩺',
      'color': Colors.red,
      'adjustments': {
        'carb_reduction': 0.3, // Reduce carbs by 30%
        'fiber_increase': 1.5, // Increase fiber by 50%
        'sugar_limit': 0.5, // Cut sugar limit in half
        'protein_increase': 1.2, // Increase protein by 20%
      },
    },
    {
      'key': 'stroke_recovery',
      'title': '🧠 Stroke Recovery',
      'desc': 'Low sodium, heart-healthy fats, controlled calories',
      'icon': '🧠',
      'color': Colors.purple,
      'adjustments': {
        'sodium_limit': 1500, // 1500mg sodium limit (very low)
        'calorie_reduction': 0.9, // Reduce calories by 10% for weight management
        'omega3_focus': true, // Focus on omega-3 rich foods
        'saturated_fat_limit': 0.7, // Reduce saturated fat by 30%
      },
    },
    {
      'key': 'hypertension',
      'title': '🫀 High Blood Pressure',
      'desc': 'Very low sodium, DASH diet principles',
      'icon': '🫀',
      'color': Colors.orange,
      'adjustments': {
        'sodium_limit': 2000, // 2000mg sodium limit
        'potassium_increase': 1.3, // Increase potassium by 30%
        'magnesium_focus': true,
        'saturated_fat_limit': 0.8, // Reduce saturated fat by 20%
      },
    },
    {
      'key': 'fitness_enthusiast',
      'title': '💪 Fitness Enthusiast',
      'desc': 'High protein, increased calories, performance nutrition',
      'icon': '💪',
      'color': Colors.blue,
      'adjustments': {
        'protein_increase': 1.5, // Increase protein by 50%
        'calorie_increase': 1.2, // Increase calories by 20%
        'carb_timing': true, // Focus on pre/post workout carbs
        'creatine_focus': true,
      },
    },
    {
      'key': 'kidney_disease',
      'title': '🫘 Kidney Disease',
      'desc': 'Controlled protein, low sodium, phosphorus limits',
      'icon': '🫘',
      'color': Colors.brown,
      'adjustments': {
        'protein_reduction': 0.7, // Reduce protein by 30%
        'sodium_limit': 2000, // 2000mg sodium limit
        'phosphorus_limit': 800, // 800mg phosphorus limit
        'potassium_limit': 2000, // 2000mg potassium limit
      },
    },
    {
      'key': 'heart_disease',
      'title': '❤️ Heart Disease',
      'desc': 'Low saturated fat, omega-3 rich, controlled sodium',
      'icon': '❤️',
      'color': Colors.pink,
      'adjustments': {
        'saturated_fat_limit': 0.6, // Reduce saturated fat by 40%
        'sodium_limit': 2000, // 2000mg sodium limit
        'omega3_focus': true,
        'fiber_increase': 1.3, // Increase fiber by 30%
      },
    },
    {
      'key': 'elderly',
      'title': '👴 Senior (65+)',
      'desc': 'Higher protein, calcium, vitamin D focus',
      'icon': '👴',
      'color': Colors.grey,
      'adjustments': {
        'protein_increase': 1.3, // Increase protein by 30% for muscle preservation
        'calcium_increase': 1.2, // Increase calcium by 20%
        'vitamin_d_focus': true,
        'calorie_reduction': 0.95, // Slight calorie reduction for slower metabolism
      },
    },
    {
      'key': 'anemia',
      'title': '🩸 Anemia / Low Iron',
      'desc': 'Iron-rich foods, vitamin C for absorption, avoid tea with meals',
      'icon': '🩸',
      'color': Colors.red.shade700,
      'adjustments': {
        'iron_increase': 2.0, // Double iron needs
        'vitamin_c_increase': 1.5, // +50% vitamin C for iron absorption
        'protein_focus': true, // Heme iron sources (meat, fish)
        'tea_coffee_limit': true, // Limit with meals (blocks iron)
        'folate_increase': 1.3, // +30% folate (B9)
      },
    },
    {
      'key': 'fatty_liver',
      'title': '🍺 Fatty Liver Disease',
      'desc': 'Very low sugar, reduced fats, weight management focus',
      'icon': '🍺',
      'color': Colors.orange.shade700,
      'adjustments': {
        'sugar_limit': 0.3, // Cut sugar by 70% (very strict)
        'saturated_fat_limit': 0.6, // Reduce saturated fat by 40%
        'total_fat_reduction': 0.8, // Reduce total fat by 20%
        'calorie_reduction': 0.9, // -10% for weight loss
        'fiber_increase': 1.4, // +40% fiber for liver health
        'alcohol_avoid': true,
      },
    },
    {
      'key': 'malnutrition',
      'title': '🌾 Malnutrition / Underweight',
      'desc': 'High calories, nutrient-dense foods, frequent small meals',
      'icon': '🌾',
      'color': Colors.green.shade700,
      'adjustments': {
        'calorie_increase': 1.4, // +40% calories for weight gain
        'protein_increase': 1.3, // +30% protein for muscle building
        'healthy_fats_increase': 1.4, // +40% healthy fats (calorie-dense)
        'micronutrient_focus': true, // Focus on vitamins/minerals
        'frequent_meals': true, // 5-6 small meals per day
        'calorie_dense_foods': true, // Nuts, oils, dairy
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Conditions'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Any health conditions?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select any health conditions that apply. We\'ll adjust your nutrition goals accordingly.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView.separated(
                itemCount: healthConditions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final condition = healthConditions[index];
                  final isSelected = selectedIndexes.contains(index);
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (index == 0) { // 'None' selected
                          if (isSelected) {
                            selectedIndexes.remove(index);
                          } else {
                            selectedIndexes.clear();
                            selectedIndexes.add(0);
                          }
                        } else {
                          if (isSelected) {
                            selectedIndexes.remove(index);
                          } else {
                            selectedIndexes.remove(0); // Deselect 'None'
                            selectedIndexes.add(index);
                          }
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? condition['color'].withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? condition['color'] : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: condition['color'].withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ] : [],
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (index == 0) { // 'None' selected
                                  if (isSelected) {
                                    selectedIndexes.remove(index);
                                  } else {
                                    selectedIndexes.clear();
                                    selectedIndexes.add(0);
                                  }
                                } else {
                                  if (isSelected) {
                                    selectedIndexes.remove(index);
                                  } else {
                                    selectedIndexes.remove(0); // Deselect 'None'
                                    selectedIndexes.add(index);
                                  }
                                }
                              });
                            },
                            activeColor: condition['color'],
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: condition['color'].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                condition['icon'],
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  condition['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? condition['color'] : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  condition['desc'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected ? condition['color'].withOpacity(0.8) : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
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
                onPressed: selectedIndexes.isNotEmpty ? () async {
                  // Apply health condition adjustments to nutrition goals
                  final adjustedGoals = _applyHealthAdjustments();
                  
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user != null) {
                    final selectedConditions = selectedIndexes.map((i) => healthConditions[i]['key']).toList();
                    
                    await Supabase.instance.client
                      .from('user_preferences')
                      .upsert({
                        'user_id': user.id,
                        'health_conditions': selectedConditions,
                        // Update nutrition goals with health adjustments
                        'calorie_goal': adjustedGoals['calories'],
                        'protein_goal': adjustedGoals['protein'],
                        'carb_goal': adjustedGoals['carbs'],
                        'fat_goal': adjustedGoals['fat'],
                        'fiber_goal': adjustedGoals['fiber'],
                        'sugar_goal': adjustedGoals['sugar'],
                        'sodium_limit': adjustedGoals['sodium'],
                      });
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllergySelectionPage()),
                  );
                } : null,
                child: const Text('Apply Health Adjustments', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Map<String, double> _applyHealthAdjustments() {
    Map<String, double> adjustedGoals = Map.from(widget.baseNutritionGoals);
    
    // If "None" is selected, return base goals unchanged
    if (selectedIndexes.contains(0)) {
      return adjustedGoals;
    }
    
    // Apply each selected condition's adjustments
    for (int index in selectedIndexes) {
      final condition = healthConditions[index];
      final adjustments = condition['adjustments'] as Map<String, dynamic>;
      
      // Apply calorie adjustments
      if (adjustments.containsKey('calorie_reduction')) {
        adjustedGoals['calories'] = adjustedGoals['calories']! * adjustments['calorie_reduction'];
      }
      if (adjustments.containsKey('calorie_increase')) {
        adjustedGoals['calories'] = adjustedGoals['calories']! * adjustments['calorie_increase'];
      }
      
      // Apply protein adjustments
      if (adjustments.containsKey('protein_increase')) {
        adjustedGoals['protein'] = adjustedGoals['protein']! * adjustments['protein_increase'];
      }
      if (adjustments.containsKey('protein_reduction')) {
        adjustedGoals['protein'] = adjustedGoals['protein']! * adjustments['protein_reduction'];
      }
      
      // Apply carb adjustments
      if (adjustments.containsKey('carb_reduction')) {
        adjustedGoals['carbs'] = adjustedGoals['carbs']! * adjustments['carb_reduction'];
      }
      
      // Apply fiber adjustments
      if (adjustments.containsKey('fiber_increase')) {
        adjustedGoals['fiber'] = adjustedGoals['fiber']! * adjustments['fiber_increase'];
      }
      
      // Apply sugar adjustments
      if (adjustments.containsKey('sugar_limit')) {
        adjustedGoals['sugar'] = adjustedGoals['sugar']! * adjustments['sugar_limit'];
      }
      
      // Apply fat adjustments
      if (adjustments.containsKey('saturated_fat_limit')) {
        adjustedGoals['fat'] = adjustedGoals['fat']! * adjustments['saturated_fat_limit'];
      }
      if (adjustments.containsKey('total_fat_reduction')) {
        adjustedGoals['fat'] = adjustedGoals['fat']! * adjustments['total_fat_reduction'];
      }
      if (adjustments.containsKey('healthy_fats_increase')) {
        adjustedGoals['fat'] = adjustedGoals['fat']! * adjustments['healthy_fats_increase'];
      }
      
      // Apply sodium limits
      if (adjustments.containsKey('sodium_limit')) {
        adjustedGoals['sodium'] = adjustments['sodium_limit'].toDouble();
      }
      
      // Apply iron and micronutrient adjustments (for display/tracking purposes)
      if (adjustments.containsKey('iron_increase')) {
        adjustedGoals['iron_goal'] = (adjustedGoals['iron_goal'] ?? 18.0) * adjustments['iron_increase'];
      }
      if (adjustments.containsKey('vitamin_c_increase')) {
        adjustedGoals['vitamin_c_goal'] = (adjustedGoals['vitamin_c_goal'] ?? 90.0) * adjustments['vitamin_c_increase'];
      }
    }
    
    // Round all values
    adjustedGoals.forEach((key, value) {
      adjustedGoals[key] = value.round().toDouble();
    });
    
    return adjustedGoals;
  }
}
