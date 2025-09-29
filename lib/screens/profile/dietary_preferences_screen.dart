import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/nutrition_calculator_service.dart';

class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  _DietaryPreferencesScreenState createState() => _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  // New comprehensive user data
  List<String> _dishPreferences = [];
  List<String> _allergies = [];
  List<String> _healthConditions = [];
  
  // User profile data
  int? _age;
  String? _gender;
  double? _heightCm;
  double? _weightKg;
  String? _activityLevel;
  String? _weightGoal;
  
  // Nutrition goals (calculated)
  Map<String, double>? _nutritionGoals;
  
  bool _loading = true;
  bool _saving = false;

  // Available options
  final List<Map<String, dynamic>> _dishOptions = [
    {'key': 'fish_seafood', 'title': '🐟 Fish & Seafood', 'desc': 'Bangus, tilapia, shrimp, crab, squid'},
    {'key': 'meat_poultry', 'title': '🥩 Meat & Poultry', 'desc': 'Chicken, pork, beef, turkey'},
    {'key': 'soups_stews', 'title': '🍲 Soups & Stews', 'desc': 'Sinigang, tinola, bulalo, nilaga'},
    {'key': 'rice_dishes', 'title': '🍚 Rice Dishes', 'desc': 'Fried rice, silog meals, biryani'},
    {'key': 'vegetables', 'title': '🥗 Vegetables', 'desc': 'Adobong kangkong, pinakbet, chopsuey'},
    {'key': 'noodles_pasta', 'title': '🍜 Noodles & Pasta', 'desc': 'Pancit, spaghetti, bihon, mami'},
    {'key': 'adobo_braised', 'title': '🥘 Adobo & Braised', 'desc': 'Chicken adobo, pork adobo, humba'},
    {'key': 'egg_dishes', 'title': '🍳 Egg Dishes', 'desc': 'Tortang talong, scrambled eggs, omelet'},
    {'key': 'spicy_food', 'title': '🌶️ Spicy Food', 'desc': 'Bicol express, sisig, spicy wings'},
  ];

  final List<String> _allergyOptions = [
    'Dairy (Milk)',
    'Eggs',
    'Peanuts',
    'Tree Nuts',
    'Soy',
    'Wheat / Gluten',
    'Fish',
    'Shellfish',
    'Sesame',
  ];

  final List<Map<String, dynamic>> _healthOptions = [
    {'key': 'none', 'title': '✅ None', 'desc': 'No specific health conditions'},
    {'key': 'diabetes', 'title': '🩺 Diabetes / High Blood Sugar', 'desc': 'Lower carbs, higher fiber'},
    {'key': 'stroke_recovery', 'title': '🧠 Stroke Recovery', 'desc': 'Low sodium, heart-healthy fats'},
    {'key': 'hypertension', 'title': '🫀 High Blood Pressure', 'desc': 'Very low sodium, DASH diet'},
    {'key': 'fitness_enthusiast', 'title': '💪 Fitness Enthusiast', 'desc': 'High protein, increased calories'},
    {'key': 'kidney_disease', 'title': '🫘 Kidney Disease', 'desc': 'Controlled protein, low sodium'},
    {'key': 'heart_disease', 'title': '❤️ Heart Disease', 'desc': 'Low saturated fat, omega-3 rich'},
    {'key': 'elderly', 'title': '👴 Senior (65+)', 'desc': 'Higher protein, calcium, vitamin D'},
    {'key': 'anemia', 'title': '🩸 Anemia / Low Iron', 'desc': 'Iron-rich foods, vitamin C'},
    {'key': 'fatty_liver', 'title': '🍺 Fatty Liver Disease', 'desc': 'Very low sugar, reduced fats'},
    {'key': 'malnutrition', 'title': '🌾 Malnutrition / Underweight', 'desc': 'High calories, nutrient-dense foods'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserPreferences();
  }

  Future<void> _fetchUserPreferences() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('user_preferences')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        if (data != null) {
          setState(() {
            // Dish preferences and health data
            _dishPreferences = List<String>.from(data['dish_preferences'] ?? []);
            _allergies = List<String>.from(data['allergies'] ?? []);
            _healthConditions = List<String>.from(data['health_conditions'] ?? []);
            
            // User profile data
            _age = data['age'] as int?;
            _gender = data['gender'] as String?;
            _heightCm = data['height_cm']?.toDouble();
            _weightKg = data['weight_kg']?.toDouble();
            _activityLevel = data['activity_level'] as String?;
            _weightGoal = data['weight_goal'] as String?;
            
            // Nutrition goals
            if (_age != null && _gender != null && _heightCm != null && _weightKg != null && 
                _activityLevel != null && _weightGoal != null) {
              _nutritionGoals = {
                'calories': data['calorie_goal']?.toDouble() ?? 2000.0,
                'protein': data['protein_goal']?.toDouble() ?? 150.0,
                'carbs': data['carb_goal']?.toDouble() ?? 250.0,
                'fat': data['fat_goal']?.toDouble() ?? 70.0,
                'fiber': data['fiber_goal']?.toDouble() ?? 30.0,
                'sugar': data['sugar_goal']?.toDouble() ?? 50.0,
                'cholesterol': data['cholesterol_goal']?.toDouble() ?? 300.0,
                'sodium': data['sodium_limit']?.toDouble() ?? 2300.0,
                'iron_goal': data['iron_goal']?.toDouble() ?? 18.0,
                'vitamin_c_goal': data['vitamin_c_goal']?.toDouble() ?? 90.0,
              };
            }
          });
        }
      } catch (e) {
        print('Error fetching user preferences: $e');
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
        }
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveUserPreferences() async {
    setState(() => _saving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Recalculate nutrition goals if profile data changed
        Map<String, double>? updatedGoals;
        if (_age != null && _gender != null && _heightCm != null && _weightKg != null && 
            _activityLevel != null && _weightGoal != null) {
          updatedGoals = NutritionCalculatorService.calculateGoals(
            age: _age!,
            gender: _gender!,
            heightCm: _heightCm!,
            weightKg: _weightKg!,
            activityLevel: _activityLevel!,
            weightGoal: _weightGoal!,
          );
          
          // Apply health condition adjustments
          if (_healthConditions.isNotEmpty && !_healthConditions.contains('none')) {
            updatedGoals = _applyHealthAdjustments(updatedGoals);
          }
        }

        await Supabase.instance.client
            .from('user_preferences')
            .upsert({
              'user_id': user.id,
              'dish_preferences': _dishPreferences,
              'allergies': _allergies,
              'health_conditions': _healthConditions,
              'age': _age,
              'gender': _gender,
              'height_cm': _heightCm,
              'weight_kg': _weightKg,
              'activity_level': _activityLevel,
              'weight_goal': _weightGoal,
              if (updatedGoals != null) ...{
                'calorie_goal': updatedGoals['calories'],
                'protein_goal': updatedGoals['protein'],
                'carb_goal': updatedGoals['carbs'],
                'fat_goal': updatedGoals['fat'],
                'fiber_goal': updatedGoals['fiber'],
                'sugar_goal': updatedGoals['sugar'],
                'cholesterol_goal': updatedGoals['cholesterol'],
                'sodium_limit': updatedGoals['sodium'],
                'iron_goal': updatedGoals['iron_goal'],
                'vitamin_c_goal': updatedGoals['vitamin_c_goal'],
              },
            });
        
        if (updatedGoals != null) {
          setState(() {
            _nutritionGoals = updatedGoals;
          });
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences updated successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update preferences: $e')),
        );
      }
    }
    setState(() => _saving = false);
  }

  Map<String, double> _applyHealthAdjustments(Map<String, double> baseGoals) {
    Map<String, double> adjustedGoals = Map.from(baseGoals);
    
    for (String condition in _healthConditions) {
      switch (condition) {
        case 'diabetes':
          adjustedGoals['carbs'] = adjustedGoals['carbs']! * 0.7;
          adjustedGoals['fiber'] = adjustedGoals['fiber']! * 1.5;
          adjustedGoals['sugar'] = adjustedGoals['sugar']! * 0.5;
          adjustedGoals['protein'] = adjustedGoals['protein']! * 1.2;
          break;
        case 'fatty_liver':
          adjustedGoals['sugar'] = adjustedGoals['sugar']! * 0.3;
          adjustedGoals['fat'] = adjustedGoals['fat']! * 0.8;
          adjustedGoals['calories'] = adjustedGoals['calories']! * 0.9;
          adjustedGoals['fiber'] = adjustedGoals['fiber']! * 1.4;
          break;
        case 'malnutrition':
          adjustedGoals['calories'] = adjustedGoals['calories']! * 1.4;
          adjustedGoals['protein'] = adjustedGoals['protein']! * 1.3;
          adjustedGoals['fat'] = adjustedGoals['fat']! * 1.4;
          break;
        case 'anemia':
          adjustedGoals['iron_goal'] = adjustedGoals['iron_goal']! * 2.0;
          adjustedGoals['vitamin_c_goal'] = adjustedGoals['vitamin_c_goal']! * 1.5;
          break;
        case 'fitness_enthusiast':
          adjustedGoals['protein'] = adjustedGoals['protein']! * 1.5;
          adjustedGoals['calories'] = adjustedGoals['calories']! * 1.2;
          break;
        case 'hypertension':
        case 'stroke_recovery':
        case 'heart_disease':
          adjustedGoals['sodium'] = 2000.0;
          break;
      }
    }
    
    adjustedGoals.forEach((key, value) {
      adjustedGoals[key] = value.round().toDouble();
    });
    
    return adjustedGoals;
  }

  String _getDisplayText(List<String> items, List<Map<String, dynamic>> options, String keyField) {
    if (items.isEmpty) return 'None selected';
    return items.map((item) {
      final option = options.firstWhere((opt) => opt[keyField] == item, orElse: () => {keyField: item, 'title': item});
      return option['title'].toString().replaceAll(RegExp(r'[🐟🥩🍲🍚🥗🍜🥘🍳🌶️✅🩺🧠🫀💪🫘❤️👴🩸🍺🌾]\s*'), '');
    }).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Summary Card
                  if (_nutritionGoals != null) ...[
                    Card(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                              '📊 Your Current Goals',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF388E3C)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('🔥 ${_nutritionGoals!['calories']!.toInt()} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('Calories', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('🥩 ${_nutritionGoals!['protein']!.toInt()}g', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('Protein', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('🍚 ${_nutritionGoals!['carbs']!.toInt()}g', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('Carbs', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('🥑 ${_nutritionGoals!['fat']!.toInt()}g', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const Text('Fat', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Preferences Section
                  const Text(
                    'Food Preferences',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                  const SizedBox(height: 12),
                  
                  // Dish Preferences
                  Card(
                    child: ListTile(
                      title: const Text('Favorite Dishes'),
                      subtitle: Text(_getDisplayText(_dishPreferences, _dishOptions, 'key')),
                      leading: const Icon(Icons.restaurant_menu, color: Color(0xFF4CAF50)),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _showMultiSelectDialog(
                        'Dish Preferences',
                        _dishOptions,
                        _dishPreferences,
                        'key',
                        (selected) => setState(() => _dishPreferences = selected),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Health Conditions
                Card(
                  child: ListTile(
                      title: const Text('Health Conditions'),
                      subtitle: Text(_getDisplayText(_healthConditions, _healthOptions, 'key')),
                      leading: const Icon(Icons.medical_services, color: Colors.red),
                    trailing: const Icon(Icons.edit),
                      onTap: () => _showMultiSelectDialog(
                        'Health Conditions',
                        _healthOptions,
                        _healthConditions,
                        'key',
                        (selected) => setState(() => _healthConditions = selected),
                        allowMultiple: true,
                        hasNoneOption: true,
                      ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Allergies
                Card(
                  child: ListTile(
                      title: const Text('Allergies & Restrictions'),
                    subtitle: Text(_allergies.isEmpty ? 'None selected' : _allergies.join(', ')),
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    trailing: const Icon(Icons.edit),
                      onTap: () => _showSimpleMultiSelectDialog(
                        'Allergies & Restrictions',
                        _allergyOptions,
                        _allergies,
                        (selected) => setState(() => _allergies = selected),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Profile Section
                  const Text(
                    'Profile Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Basic Info Row
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => _showAgeDialog(),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(Icons.cake, color: Color(0xFF4CAF50)),
                                  const SizedBox(height: 8),
                                  Text('${_age ?? "Not set"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Age', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => _showGenderDialog(),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(_gender == 'male' ? Icons.male : _gender == 'female' ? Icons.female : Icons.person, 
                                       color: const Color(0xFF4CAF50)),
                                  const SizedBox(height: 8),
                                  Text(_gender?.toUpperCase() ?? "Not set", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Gender', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                
                  // Height/Weight Row
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => _showHeightDialog(),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(Icons.height, color: Color(0xFF4CAF50)),
                                  const SizedBox(height: 8),
                                  Text('${_heightCm?.toInt() ?? "Not set"}${_heightCm != null ? " cm" : ""}', 
                                       style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Height', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => _showWeightDialog(),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(Icons.monitor_weight, color: Color(0xFF4CAF50)),
                                  const SizedBox(height: 8),
                                  Text('${_weightKg?.toInt() ?? "Not set"}${_weightKg != null ? " kg" : ""}', 
                                       style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Weight', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Activity Level & Weight Goal Row
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => _showActivityLevelDialog(),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(Icons.fitness_center, color: Color(0xFF4CAF50)),
                                  const SizedBox(height: 8),
                                  Text(_activityLevel?.replaceAll('_', ' ').split(' ').map((word) => 
                                    word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ') ?? "Not set", 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Activity Level', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: InkWell(
                            onTap: () => _showWeightGoalDialog(),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Icon(Icons.trending_up, color: Color(0xFF4CAF50)),
                                  const SizedBox(height: 8),
                                  Text(_weightGoal?.replaceAll('_', ' ').split(' ').map((word) => 
                                    word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ') ?? "Not set", 
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('Weight Goal', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveUserPreferences,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Saving...'),
                            ],
                          )
                          : const Text('Save All Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showMultiSelectDialog(
    String title,
    List<Map<String, dynamic>> options,
    List<String> selected,
    String keyField,
    Function(List<String>) onChanged, {
    bool allowMultiple = true,
    bool hasNoneOption = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selected.contains(option[keyField]);
                  
                  return CheckboxListTile(
                    title: Text(option['title']),
                    subtitle: option['desc'] != null ? Text(option['desc']) : null,
                    value: isSelected,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (hasNoneOption && index == 0) {
                          // Handle "None" option
                          if (value == true) {
                            selected.clear();
                            selected.add(option[keyField]);
                          } else {
                            selected.remove(option[keyField]);
                          }
                        } else {
                          if (value == true) {
                            if (hasNoneOption) selected.remove('none');
                            selected.add(option[keyField]);
                          } else {
                            selected.remove(option[keyField]);
                          }
                        }
                      });
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onChanged(selected);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSimpleMultiSelectDialog(
    String title,
    List<String> options,
    List<String> selected,
    Function(List<String>) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selected.contains(option);
                  
                  return CheckboxListTile(
                    title: Text(option),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          selected.add(option);
                        } else {
                          selected.remove(option);
                        }
                      });
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onChanged(selected);
              Navigator.pop(context);
            },
            child: const Text('Done'),
                ),
              ],
            ),
    );
  }

  void _showAgeDialog() {
    final TextEditingController ageController = TextEditingController(text: _age?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Age'),
        content: TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'Enter your age',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final age = int.tryParse(ageController.text);
              if (age != null && age > 0 && age < 150) {
                setState(() {
                  _age = age;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid age (1-149)')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGenderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Male'),
              value: 'male',
              groupValue: _gender,
              onChanged: (value) {
                setState(() {
                  _gender = value;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Female'),
              value: 'female',
              groupValue: _gender,
              onChanged: (value) {
                setState(() {
                  _gender = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showHeightDialog() {
    final TextEditingController heightController = TextEditingController(text: _heightCm?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Height'),
        content: TextField(
          controller: heightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            hintText: 'Enter your height in centimeters',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final height = double.tryParse(heightController.text);
              if (height != null && height > 50 && height < 300) {
                setState(() {
                  _heightCm = height;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid height (50-300 cm)')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog() {
    final TextEditingController weightController = TextEditingController(text: _weightKg?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Weight'),
        content: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            hintText: 'Enter your weight in kilograms',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              if (weight != null && weight > 20 && weight < 300) {
                setState(() {
                  _weightKg = weight;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid weight (20-300 kg)')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showActivityLevelDialog() {
    final List<Map<String, dynamic>> activityOptions = [
      {'key': 'sedentary', 'title': 'Sedentary', 'desc': 'Little to no exercise'},
      {'key': 'lightly_active', 'title': 'Lightly Active', 'desc': 'Light exercise 1-3 days/week'},
      {'key': 'moderately_active', 'title': 'Moderately Active', 'desc': 'Moderate exercise 3-5 days/week'},
      {'key': 'very_active', 'title': 'Very Active', 'desc': 'Heavy exercise 6-7 days/week'},
      {'key': 'extremely_active', 'title': 'Extremely Active', 'desc': 'Very heavy exercise, physical job'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Activity Level'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: activityOptions.length,
            itemBuilder: (context, index) {
              final option = activityOptions[index];
              
              return RadioListTile<String>(
                title: Text(option['title']),
                subtitle: Text(option['desc']),
                value: option['key'],
                groupValue: _activityLevel,
                onChanged: (value) {
                  setState(() {
                    _activityLevel = value;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showWeightGoalDialog() {
    final List<Map<String, dynamic>> weightGoalOptions = [
      {'key': 'lose_weight', 'title': 'Lose Weight', 'desc': 'Create a calorie deficit'},
      {'key': 'maintain_weight', 'title': 'Maintain Weight', 'desc': 'Keep current weight'},
      {'key': 'gain_weight', 'title': 'Gain Weight', 'desc': 'Create a calorie surplus'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Weight Goal'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: weightGoalOptions.length,
            itemBuilder: (context, index) {
              final option = weightGoalOptions[index];
              
              return RadioListTile<String>(
                title: Text(option['title']),
                subtitle: Text(option['desc']),
                value: option['key'],
                groupValue: _weightGoal,
                onChanged: (value) {
                  setState(() {
                    _weightGoal = value;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 
