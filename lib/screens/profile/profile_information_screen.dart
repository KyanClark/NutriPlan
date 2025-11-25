import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
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
    setState(() => _loading = false);
  }

  Future<void> _saveUserProfile() async {
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
        
        if (updatedGoals != null) {
          setState(() {
            _nutritionGoals = updatedGoals;
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
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile Information'),
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
                  // Nutrition Goals Summary Card
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

