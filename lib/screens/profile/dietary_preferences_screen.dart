import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        await Supabase.instance.client
            .from('user_preferences')
            .upsert({
              'user_id': user.id,
              'dish_preferences': _dishPreferences,
              'allergies': _allergies,
              'health_conditions': _healthConditions,
            });
        
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
                  // Preferences Section
                  const Text(
                    'Food Preferences',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                  const SizedBox(height: 12),
                  
                  // Dish Preferences
                  Card(
                    child: ListTile(
                      title: const Text('Dishes I like'),
                      subtitle: Text(_getDisplayText(_dishPreferences, _dishOptions, 'key')),
                      leading: const Icon(Icons.restaurant_menu, color: Color(0xFF4CAF50)),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _showMultiSelectDialog(
                        'Dishes I like',
                        _dishOptions,
                        _dishPreferences,
                        'key',
                        (selected) => setState(() => _dishPreferences = selected),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Nutrition Needs
                Card(
                  child: ListTile(
                      title: const Text('Nutrition Needs'),
                      subtitle: Text(_getDisplayText(_healthConditions, _healthOptions, 'key')),
                      leading: const Icon(Icons.favorite, color: Colors.blue),
                    trailing: const Icon(Icons.edit),
                      onTap: () => _showMultiSelectDialog(
                        'Nutrition Needs',
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

} 
