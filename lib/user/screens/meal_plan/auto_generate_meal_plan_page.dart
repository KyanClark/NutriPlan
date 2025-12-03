import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipes.dart';
import '../../services/auto_meal_plan_service.dart';
import 'meal_summary_page.dart';
import 'meal_plan_confirmation_page.dart';
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
  List<String> _previouslyGeneratedRecipeIds = []; // Track previously generated recipes
  
  // Loading overlay state
  int _currentLoadingMessageIndex = 0;
  Timer? _loadingMessageTimer;
  final List<String> _loadingMessages = [
    'Loading...',
    'Choosing the best meal for you',
    'Analyzing your preferences',
    'Finding perfect matches',
    'Creating your personalized plan',
    'Almost there...',
  ];

  String? get userId => Supabase.instance.client.auth.currentUser?.id;
  
  Widget _buildNutritionChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMealDescription(Map<String, dynamic> meal) {
    final recipe = meal['recipe'] as Recipe;
    final mealType = meal['meal_type'] as String;
    
    // Generate description based on meal type and recipe characteristics
    final calories = recipe.macros['calories'] ?? 0;
    final protein = recipe.macros['protein'] ?? 0;
    final carbs = recipe.macros['carbs'] ?? 0;
    
    String description = '';
    
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        if (protein > 15) {
          description = 'High-protein breakfast to keep you energized throughout the morning.';
        } else if (carbs > 30) {
          description = 'Carb-rich breakfast to fuel your day ahead.';
        } else {
          description = 'Light and balanced breakfast perfect to start your day.';
        }
        break;
      case 'lunch':
        if (calories > 400) {
          description = 'Satisfying lunch that will keep you full until dinner.';
        } else if (protein > 20) {
          description = 'Protein-packed lunch to maintain your energy levels.';
        } else {
          description = 'Well-balanced lunch tailored to your preferences.';
        }
        break;
      case 'dinner':
        if (calories < 300) {
          description = 'Light dinner option perfect for evening meals.';
        } else if (protein > 25) {
          description = 'Hearty dinner with high protein content for muscle recovery.';
        } else {
          description = 'Delicious dinner selected based on your eating patterns.';
        }
        break;
      default:
        description = 'Carefully selected based on your preferences and health goals.';
    }
    
    return description;
  }
  
  String _getRecommendationMessage() {
    if (_generatedMeals.isEmpty) return '';
    
    final mealCount = _generatedMeals.length;
    final mealTypes = _generatedMeals.map((m) => m['meal_type'] as String).toSet();
    
    if (mealCount == 1) {
      return 'We\'ve selected this meal based on your preferences and nutritional goals.';
    } else if (mealTypes.length == mealCount) {
      return 'These meals are carefully chosen to provide balanced nutrition throughout your day, tailored to your eating patterns and health goals.';
    } else {
      return 'These personalized recommendations are selected based on your preferences, nutritional needs, and past meal choices to help you achieve your health goals.';
    }
  }
  
  void _startLoadingMessages() {
    _currentLoadingMessageIndex = 0;
    _loadingMessageTimer?.cancel();
    _loadingMessageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _isGenerating) {
        setState(() {
          _currentLoadingMessageIndex = (_currentLoadingMessageIndex + 1) % _loadingMessages.length;
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  void _stopLoadingMessages() {
    _loadingMessageTimer?.cancel();
    _loadingMessageTimer = null;
  }
  
  @override
  void dispose() {
    _stopLoadingMessages();
    super.dispose();
  }

  Future<void> _generateMealPlan({bool generateAgain = false}) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to generate meal plans')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      if (!generateAgain) {
        _generatedMeals = [];
        _previouslyGeneratedRecipeIds = [];
      }
    });
    
    _startLoadingMessages();

    try {
      // Get all previously generated recipe IDs to exclude them
      final excludeRecipeIds = _previouslyGeneratedRecipeIds.toList();
      
      final meals = await AutoMealPlanService.generateMealPlan(
        userId: userId!,
        targetDate: _selectedDate,
        includeBreakfast: _includeBreakfast,
        includeLunch: _includeLunch,
        includeDinner: _includeDinner,
        excludeRecipeIds: excludeRecipeIds.isNotEmpty ? excludeRecipeIds : null,
      );

      if (!mounted) return;
      
      _stopLoadingMessages();

      // Track the newly generated recipe IDs
      final newRecipeIds = meals.map((m) => (m['recipe'] as Recipe).id).toList();
      _previouslyGeneratedRecipeIds.addAll(newRecipeIds);

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
      
      _stopLoadingMessages();
      
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
    // Pass meals with their meal types pre-set
    final mealsWithTypes = _generatedMeals.map((m) {
      final recipe = m['recipe'] as Recipe;
      final mealType = m['meal_type'] as String;
      return {'recipe': recipe, 'mealType': mealType};
    }).toList();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealSummaryPage(
          meals: mealsWithTypes.map((m) => m['recipe'] as Recipe).toList(),
          initialMealTypes: mealsWithTypes.map((m) => m['mealType'] as String).toList(),
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
                
                // Add rice data if included (only if columns exist in database)
                if (m.includeRice && m.riceServing != null) {
                  mealData['include_rice'] = true;
                  mealData['rice_serving'] = m.riceServing!.label;
                }
                
                await Supabase.instance.client
                    .from('meal_plans')
                    .insert(mealData);
              } catch (e) {
                // If error is due to missing rice columns, try again without rice data
                if (e.toString().contains('include_rice') || e.toString().contains('rice_serving') || (e.toString().contains('column') && e.toString().contains('does not exist'))) {
                  try {
                    final Map<String, dynamic> mealDataWithoutRice = {
                      'user_id': userId,
                      'recipe_id': m.recipe.id,
                      'title': m.recipe.title,
                      'meal_type': m.mealType ?? 'dinner',
                      'meal_time': m.time != null ? '${m.time!.hour.toString().padLeft(2, '0')}:${m.time!.minute.toString().padLeft(2, '0')}:00' : null,
                      'date': dateStr,
                    };
                    await Supabase.instance.client
                        .from('meal_plans')
                        .insert(mealDataWithoutRice);
                    print('Successfully saved meal to plans (without rice): ${m.recipe.title}');
                  } catch (e2) {
                    print('Error saving meal plan: $e2');
                  }
                } else {
                  print('Error saving meal plan: $e');
                }
              }
            }
            
            // Navigate to confirmation page after saving
            if (mounted) {
              // Close meal summary page, then show confirmation
              // The confirmation page will handle navigation back to meal planner
              Navigator.of(context).pop(); // Close meal summary page
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MealPlanConfirmationPage(),
                ),
              );
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Heading text - changes based on whether meals are generated
                  Text(
                    _generatedMeals.isEmpty 
                        ? 'Generate Meal Plan'
                        : 'Here are the generated meal plans for you!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Brief message - changes based on whether meals are generated
                  Text(
                    _generatedMeals.isEmpty
                        ? 'Too tired or too busy to decide your meals? Let us choose the best meals for you!'
                        : _getRecommendationMessage(),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Show meal type selection only if no meals generated yet
                  if (_generatedMeals.isEmpty) ...[
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
                            value: _includeBreakfast,
                            onChanged: (value) {
                              setState(() {
                                _includeBreakfast = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Lunch'),
                            value: _includeLunch,
                            onChanged: (value) {
                              setState(() {
                                _includeLunch = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Dinner'),
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
                    
                    // Generate button (green background, white text)
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
                      child: const Row(
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
                  ],
                  
                  // Generated meals (shown after generation)
                  if (_generatedMeals.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._generatedMeals.map((meal) {
                      final recipe = meal['recipe'] as Recipe;
                      final mealType = meal['meal_type'] as String;
                      final description = _getMealDescription(meal);
                      // Get serving size from macros or default to 1
                      final servingSize = recipe.macros['servings'] ?? recipe.macros['serving'] ?? 1;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Meal image
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.network(
                                recipe.imageUrl,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Meal type badge and serving size
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          mealType.toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.people, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${servingSize.toString()} ${servingSize == 1 ? 'serving' : 'servings'}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Description (why this meal was chosen) - above meal info
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            description,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue[900],
                                              height: 1.4,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Meal title
                                  Text(
                                    recipe.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Nutrition info
                                  Row(
                                    children: [
                                      _buildNutritionChip('${recipe.calories} kcal', Icons.local_fire_department),
                                      const SizedBox(width: 8),
                                      if (recipe.macros['protein'] != null)
                                        _buildNutritionChip('${recipe.macros['protein'].toStringAsFixed(0)}g protein', Icons.fitness_center),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 24),
                    
                    // Generate Again button (green)
                    ElevatedButton(
                      onPressed: _isGenerating ? null : () => _generateMealPlan(generateAgain: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.refresh),
                          const SizedBox(width: 8),
                          Text(
                            _isGenerating ? 'Generating...' : 'Generate Again',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Save button
                    ElevatedButton(
                      onPressed: _saveMealPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
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
          
          // Loading overlay
          if (_isGenerating)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rotating message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: Text(
                        _loadingMessages[_currentLoadingMessageIndex],
                        key: ValueKey<String>(_loadingMessages[_currentLoadingMessageIndex]),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // GIF animation
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.asset(
                        'assets/meal_plan_icons/generate_meal_plan.gif',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

