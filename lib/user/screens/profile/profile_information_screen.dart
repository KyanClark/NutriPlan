import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/nutrition_calculator_service.dart';

class ProfileInformationScreen extends StatefulWidget {
  const ProfileInformationScreen({super.key});

  @override
  _ProfileInformationScreenState createState() => _ProfileInformationScreenState();
}

class _ProfileInformationScreenState extends State<ProfileInformationScreen> {
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
  bool _caloriesManuallyEditedThisSession = false; // Track if calories were manually edited in this session

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('user_preferences')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        if (!mounted) return;
        if (data != null) {
          setState(() {
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
        print('Error fetching user profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: $e')),
          );
        }
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _saveUserProfile() async {
    if (!mounted) return;
    setState(() => _saving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Recalculate nutrition goals if profile data is complete
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
          
          // Only preserve manually set calorie goal if it was edited in this session
          // Otherwise, recalculate calories when profile data changes
          if (_nutritionGoals != null && _nutritionGoals!['calories'] != null) {
            final currentCalories = _nutritionGoals!['calories']!;
            final calculatedCalories = updatedGoals['calories']!;
            
            // Only preserve calories if they were manually edited in this session
            if (_caloriesManuallyEditedThisSession) {
              updatedGoals['calories'] = currentCalories;
              print('Preserving manually set calorie goal from this session: $currentCalories (calculated: $calculatedCalories)');
            } else {
              // Use calculated calories when profile data changes
              updatedGoals['calories'] = calculatedCalories;
              print('Recalculating calorie goal based on new profile data: $calculatedCalories');
            }
          }
        }

        await Supabase.instance.client
            .from('user_preferences')
            .upsert({
              'user_id': user.id,
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
        
        if (!mounted) return;
        if (updatedGoals != null) {
          setState(() {
            _nutritionGoals = updatedGoals;
            _caloriesManuallyEditedThisSession = false; // Reset flag after saving
          });
        }
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Custom header with back button and title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF388E3C)),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        // Centered title
                        const Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF388E3C),
                            letterSpacing: 0.5,
                          ),
                        ),
                        // Saving indicator on the right
                        if (_saving)
                          Align(
                            alignment: Alignment.centerRight,
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF4CAF50),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nutrition Goals Summary Card
                  if (_nutritionGoals != null) ...[
                    Card(
                      color: const Color(0xFF2E7D32),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Your Current Goals',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            // Calorie goal - separate row
                            InkWell(
                              onTap: () => _showCaloriePicker(),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '🔥 ${_nutritionGoals!['calories']!.toInt()} kcal',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.edit, size: 16, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Calories',
                                      style: TextStyle(fontSize: 14, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Macros - separate row (protein, carbs, fat)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '🥩 ${_nutritionGoals!['protein']!.toInt()}g',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Protein', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '🍚 ${_nutritionGoals!['carbs']!.toInt()}g',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Carbs', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '🥑 ${_nutritionGoals!['fat']!.toInt()}g',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Fat', style: TextStyle(fontSize: 12, color: Colors.white70)),
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

                  // Profile Section
                  // Friendly reminder about height and weight
                  if (_heightCm == null || _weightKg == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Complete Your Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'To provide you with the most accurate nutrition recommendations, please make sure to set your height and weight. These measurements help us calculate your personalized daily calorie and nutrient needs based on your body composition and goals.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
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
                            onTap: () => _showAgePicker(),
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
                            onTap: () => _showHeightPicker(),
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
                            onTap: () => _showWeightPicker(),
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
                    onPressed: _saving ? null : _saveUserProfile,
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
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showAgePicker() async {
    const minAge = 10;
    const maxAge = 100;
    final initialAge = (_age ?? 25).clamp(minAge, maxAge);
    final selected = await _showCupertinoNumberPicker(
      title: 'Select Age',
      min: minAge,
      max: maxAge,
      initialValue: initialAge,
      unitSuffix: ' yrs',
    );
    if (selected != null && mounted) {
      setState(() => _age = selected);
    }
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
                if (mounted) {
                  setState(() {
                    _gender = value;
                  });
                }
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Female'),
              value: 'female',
              groupValue: _gender,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _gender = value;
                  });
                }
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

  Future<void> _showHeightPicker() async {
    const minHeight = 100;
    const maxHeight = 220;
    final initialHeight = (_heightCm?.round() ?? 165).clamp(minHeight, maxHeight);
    final selected = await _showCupertinoNumberPicker(
      title: 'Select Height',
      min: minHeight,
      max: maxHeight,
      initialValue: initialHeight,
      unitSuffix: ' cm',
    );
    if (selected != null && mounted) {
      setState(() => _heightCm = selected.toDouble());
    }
  }

  Future<void> _showWeightPicker() async {
    const minWeight = 30;
    const maxWeight = 200;
    final initialWeight = (_weightKg?.round() ?? 60).clamp(minWeight, maxWeight);
    final selected = await _showCupertinoNumberPicker(
      title: 'Select Weight',
      min: minWeight,
      max: maxWeight,
      initialValue: initialWeight,
      unitSuffix: ' kg',
    );
    if (selected != null && mounted) {
      setState(() => _weightKg = selected.toDouble());
    }
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
                  if (mounted) {
                    setState(() {
                      _activityLevel = value;
                    });
                  }
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

  Future<int?> _showCupertinoNumberPicker({
    required String title,
    required int min,
    required int max,
    required int initialValue,
    String unitSuffix = '',
  }) async {
    int tempValue = initialValue.clamp(min, max);
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final controller = FixedExtentScrollController(initialItem: tempValue - min);
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, tempValue),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  scrollController: controller,
                  itemExtent: 36,
                  magnification: 1.1,
                  useMagnifier: true,
                  onSelectedItemChanged: (index) {
                    tempValue = min + index;
                  },
                  children: List.generate(
                    max - min + 1,
                    (index) => Center(
                      child: Text(
                        '${min + index}$unitSuffix',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                  if (mounted) {
                    setState(() {
                      _weightGoal = value;
                    });
                  }
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

  Future<void> _showCaloriePicker() async {
    if (_nutritionGoals == null || _nutritionGoals!['calories'] == null) return;
    
    const minCalories = 1000;
    const maxCalories = 5000;
    const step = 50; // Interval of 50 calories
    final initialCalories = _nutritionGoals!['calories']!.toInt();
    
    // Round initial value to nearest 50
    final roundedInitial = ((initialCalories / step).round() * step).clamp(minCalories, maxCalories);
    
    // Generate list of calorie values with step of 50
    final calorieValues = <int>[];
    for (int i = minCalories; i <= maxCalories; i += step) {
      calorieValues.add(i);
    }
    
    int tempValue = roundedInitial;
    final initialIndex = calorieValues.indexOf(roundedInitial);
    
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final controller = FixedExtentScrollController(
          initialItem: initialIndex >= 0 ? initialIndex : 0,
        );
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const Text(
                      'Set Calorie Goal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, tempValue),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoPicker(
                  scrollController: controller,
                  itemExtent: 36,
                  magnification: 1.1,
                  useMagnifier: true,
                  onSelectedItemChanged: (index) {
                    tempValue = calorieValues[index];
                  },
                  children: calorieValues.map((value) {
                    return Center(
                      child: Text(
                        '$value kcal',
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
    
    if (selected != null && mounted && _nutritionGoals != null) {
      setState(() {
        _nutritionGoals!['calories'] = selected.toDouble();
        _caloriesManuallyEditedThisSession = true; // Mark as manually edited
      });
    }
  }
}

