import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipes.dart';
import '../../services/auto_meal_plan_service.dart';
import 'meal_summary_page.dart';
import '../../utils/app_logger.dart';

class AutoGenerateMealPlanPage extends StatefulWidget {
  final DateTime? initialDate;
  
  const AutoGenerateMealPlanPage({super.key, this.initialDate});

  @override
  State<AutoGenerateMealPlanPage> createState() => _AutoGenerateMealPlanPageState();
}

class _AutoGenerateMealPlanPageState extends State<AutoGenerateMealPlanPage> {
  // Lock to current day only
  DateTime get _selectedDate => DateTime.now();
  bool _includeBreakfast = true;
  bool _includeLunch = true;
  bool _includeDinner = true;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _generatedMeals = [];

  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> _generateMealPlan() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to generate meal plans')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedMeals = [];
    });

    try {
      final meals = await AutoMealPlanService.generateMealPlan(
        userId: userId!,
        targetDate: _selectedDate,
        includeBreakfast: _includeBreakfast,
        includeLunch: _includeLunch,
        includeDinner: _includeDinner,
      );

      if (!mounted) return;

      setState(() {
        _generatedMeals = meals;
        _isGenerating = false;
      });

      if (meals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No meals could be generated. Please try again or select meals manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error generating meal plan', e);
      if (!mounted) return;
      
      setState(() {
        _isGenerating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating meal plan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveMealPlan() async {
    if (userId == null || _generatedMeals.isEmpty) return;

    if (!mounted) return;

    // Navigate to meal summary page (meals will be saved there after rice selection)
    final meals = _generatedMeals.map((m) => m['recipe'] as Recipe).toList();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MealSummaryPage(
          meals: meals,
          onBuildMealPlan: (mealsWithTime) async {
            // Save meals after user completes meal summary (including rice selection)
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId == null) return;
            
            final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
            
            for (final m in mealsWithTime) {
              try {
                final Map<String, dynamic> mealData = {
                  'user_id': userId,
                  'recipe_id': m.recipe.id,
                  'title': m.recipe.title,
                  'meal_type': m.mealType ?? 'dinner',
                  'meal_time': m.time != null ? '${m.time!.hour.toString().padLeft(2, '0')}:${m.time!.minute.toString().padLeft(2, '0')}:00' : null,
                  'date': dateStr,
                };
                
                // Add rice data if included
                if (m.includeRice && m.riceServing != null) {
                  mealData['include_rice'] = true;
                  mealData['rice_serving'] = m.riceServing!.label;
                } else {
                  mealData['include_rice'] = false;
                  mealData['rice_serving'] = null;
                }
                
                await Supabase.instance.client
                    .from('meal_plans')
                    .insert(mealData);
              } catch (e) {
                print('Error saving meal plan: $e');
              }
            }
          },
          isAdvancePlanning: _selectedDate.isAfter(DateTime.now()),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generate Meal Plan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Meals are generated based on your preferences, health conditions, and eating patterns - just like TikTok learns what you like!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Date display (locked to today)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: const Text('Date'),
                  subtitle: Text(
                    'Today - ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.lock, color: Colors.grey[400], size: 20),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Meal type selection
              Card(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.restaurant, color: Color(0xFF4CAF50)),
                          SizedBox(width: 12),
                          Text(
                            'Meal Types',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Breakfast'),
                      subtitle: const Text('8:00 AM'),
                      value: _includeBreakfast,
                      onChanged: (value) {
                        setState(() {
                          _includeBreakfast = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Lunch'),
                      subtitle: const Text('12:30 PM'),
                      value: _includeLunch,
                      onChanged: (value) {
                        setState(() {
                          _includeLunch = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Dinner'),
                      subtitle: const Text('7:00 PM'),
                      value: _includeDinner,
                      onChanged: (value) {
                        setState(() {
                          _includeDinner = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Generate button
              ElevatedButton(
                onPressed: (_isGenerating || (!_includeBreakfast && !_includeLunch && !_includeDinner))
                    ? null
                    : _generateMealPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome),
                          SizedBox(width: 8),
                          Text(
                            'Generate Meal Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              
              // Generated meals preview
              if (_generatedMeals.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text(
                  'Generated Meals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._generatedMeals.map((meal) {
                  final recipe = meal['recipe'] as Recipe;
                  final mealType = meal['meal_type'] as String;
                  final mealTime = meal['meal_time'] as String;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                        child: Text(
                          mealType[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        recipe.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$mealType • $mealTime'),
                      trailing: Text(
                        '₱${recipe.cost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  );
                }),
                
                const SizedBox(height: 24),
                
                // Save button
                ElevatedButton(
                  onPressed: _saveMealPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text(
                        'Save Meal Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

