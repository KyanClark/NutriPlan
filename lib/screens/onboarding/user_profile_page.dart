import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'weight_goal_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedActivityLevel;
  
  final List<Map<String, String>> genderOptions = [
    {'value': 'male', 'label': 'Male', 'icon': '👨'},
    {'value': 'female', 'label': 'Female', 'icon': '👩'},
  ];
  
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
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF388E3C),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This helps us calculate your personalized nutrition goals.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              
              // Age Input
              _buildNumberField(
                controller: _ageController,
                label: 'Age',
                hint: 'Enter your age',
                suffix: 'years old',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 13 || age > 100) {
                    return 'Please enter a valid age (13-100)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Gender Selection
              const Text(
                'Gender',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF388E3C),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: genderOptions.map((option) {
                  final isSelected = _selectedGender == option['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGender = option['value'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              option['icon']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              option['label']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Height Input
              _buildNumberField(
                controller: _heightController,
                label: 'Height',
                hint: 'Enter your height',
                suffix: 'cm',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height < 100 || height > 250) {
                    return 'Please enter a valid height (100-250 cm)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Weight Input
              _buildNumberField(
                controller: _weightController,
                label: 'Weight',
                hint: 'Enter your weight',
                suffix: 'kg',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight < 30 || weight > 300) {
                    return 'Please enter a valid weight (30-300 kg)';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Activity Level Selection
              const Text(
                'Activity Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF388E3C),
                ),
              ),
              const SizedBox(height: 12),
              ...activityLevels.map((option) {
                final isSelected = _selectedActivityLevel == option['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedActivityLevel = option['value'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          option['icon']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option['label']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option['desc']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              
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
                  onPressed: _canContinue() ? () async {
                    if (_formKey.currentState!.validate()) {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user != null) {
                        await Supabase.instance.client
                          .from('user_preferences')
                          .upsert({
                            'user_id': user.id,
                            'age': int.parse(_ageController.text),
                            'gender': _selectedGender,
                            'height_cm': double.parse(_heightController.text),
                            'weight_kg': double.parse(_weightController.text),
                            'activity_level': _selectedActivityLevel,
                          });
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeightGoalPage(
                            age: int.parse(_ageController.text),
                            gender: _selectedGender!,
                            heightCm: double.parse(_heightController.text),
                            weightKg: double.parse(_weightController.text),
                            activityLevel: _selectedActivityLevel!,
                          ),
                        ),
                      );
                    }
                  } : null,
                  child: const Text('Continue', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  bool _canContinue() {
    return _ageController.text.isNotEmpty &&
           _selectedGender != null &&
           _heightController.text.isNotEmpty &&
           _weightController.text.isNotEmpty &&
           _selectedActivityLevel != null;
  }
  
  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF388E3C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}
