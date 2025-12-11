import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipes.dart';
import '../../services/recipe_service.dart';
import 'dishes_like_selection_page.dart';

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
  List<String> _dietTypes = [];
  List<String> _nutritionNeeds = [];
  
  bool _loading = true;
  bool _saving = false;
  
  /// Helper function to safely convert a value to List<String>
  /// Handles cases where the value might be a List, String (JSON), or null
  List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    
    // If it's already a List, convert it
    if (value is List) {
      try {
        return value.map((e) => e.toString()).toList();
      } catch (_) {
        return [];
      }
    }
    
    // If it's a String, try to parse it
    if (value is String) {
      if (value.isEmpty) return [];
      try {
        // Try to parse as JSON array
        if (value.startsWith('[') && value.endsWith(']')) {
          // Remove brackets and quotes, split by comma
          final cleaned = value
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll("'", '')
              .trim();
          if (cleaned.isEmpty) return [];
          return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        // If it's a single string value, return as single-item list
        return [value.trim()];
      } catch (_) {
        // If parsing fails, return as single-item list
        return [value.toString()];
      }
    }
    
    return [];
  }
  
  // Debug: Excluded recipes and warnings
  bool _loadingExcluded = false;
  List<Map<String, dynamic>> _excludedRecipes = []; // {recipe, matchedAllergen, matchingIngredients}
  List<Map<String, dynamic>> _warningRecipes = []; // {recipe, allergy, matchingIngredients}

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
    'Coconuts',
    'Soy',
    'Wheat / Gluten',
    'Fish',
    'Shellfish',
    'Chicken',
    'Pork',
    'Beef',
    'Sesame',
    'Corn',
    'Tomatoes',
  ];

  final List<Map<String, dynamic>> _healthOptions = [
    {'key': 'none', 'title': '✅ None', 'desc': 'No specific health conditions'},
    {'key': 'diabetes', 'title': '🩺 Diabetes / High Blood Sugar', 'desc': 'Lower carbs, higher fiber'},
    {'key': 'hypertension', 'title': '🫀 High Blood Pressure', 'desc': 'Very low sodium, DASH diet'},
  ];


  final List<Map<String, dynamic>> _dietTypeOptions = [
    {'key': 'none', 'title': '✅ None', 'desc': 'No specific diet preference'},
    {'key': 'High Protein', 'title': 'High Protein', 'desc': 'Prioritize 25g+ protein per meal'},
    {'key': 'Low Carb', 'title': 'Low Carb', 'desc': 'Keep carbs around or below 30g per meal'},
    {'key': 'Low Fat', 'title': 'Low Fat', 'desc': 'Keep fats around or below 15g per meal'},
    {'key': 'Vegetarian', 'title': 'Vegetarian', 'desc': 'No meat or fish; dairy/eggs allowed'},
    {'key': 'Vegan', 'title': 'Vegan', 'desc': 'No animal products, dairy, or eggs'},
    {'key': 'Dairy-Free', 'title': 'Dairy-Free', 'desc': 'No milk, cheese, butter, or yogurt'},
    {'key': 'Gluten-Free', 'title': 'Gluten-Free', 'desc': 'Avoid wheat, bread, pasta, and flour'},
    {'key': 'Pescatarian', 'title': 'Pescatarian', 'desc': 'Fish/seafood allowed; no meat/poultry'},
    {'key': 'Flexitarian', 'title': 'Flexitarian', 'desc': 'Mostly plant-based with occasional meat'},
    {'key': 'Keto', 'title': 'Keto', 'desc': 'Very low carbs (~20g), moderate protein, higher fat'},
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
            // Dish preferences and health data - safe conversion
            _dishPreferences = _safeStringList(data['like_dishes'] ?? data['dish_preferences'] ?? []);
            _allergies = _safeStringList(data['allergies'] ?? []);
            _healthConditions = _safeStringList(data['health_conditions'] ?? []);
            _dietTypes = _safeStringList(data['diet_type'] ?? []);
            _nutritionNeeds = [];
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
    if (user == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save preferences')),
      );
      return;
    }
    
    try {
      // Filter out "none" from health conditions
      final healthConditionsToSave = _healthConditions.where((h) => h != 'none').toList();
      final nutritionNeedsToSave = <String>[];
      
      // Fetch current sodium_limit to preserve it
      double? currentSodiumLimit;
      try {
        final currentData = await Supabase.instance.client
            .from('user_preferences')
            .select('sodium_limit')
            .eq('user_id', user.id)
            .maybeSingle();
        if (currentData != null && currentData['sodium_limit'] != null) {
          currentSodiumLimit = currentData['sodium_limit'].toDouble();
        }
      } catch (e) {
        print('Error fetching current sodium_limit: $e');
      }
      
      // Prepare data for upsert - ensure empty lists are saved as empty arrays
      final dataToSave = {
        'user_id': user.id,
        'like_dishes': _dishPreferences.isEmpty ? [] : _dishPreferences,
        'allergies': _allergies.isEmpty ? [] : _allergies,
        'health_conditions': healthConditionsToSave.isEmpty ? [] : healthConditionsToSave,
        'diet_type': _dietTypes.isEmpty ? [] : _dietTypes,
        'nutrition_needs': [],
        if (currentSodiumLimit != null) 'sodium_limit': currentSodiumLimit,
      };
      
      print('Saving preferences: $dataToSave');
      
      final response = await Supabase.instance.client
          .from('user_preferences')
          .upsert(dataToSave)
          .select();
      
      print('Save response: $response');
      
      if (!mounted) return;
      
      // Update local state to reflect saved values (without "none")
      setState(() {
        _healthConditions = healthConditionsToSave;
        _nutritionNeeds = nutritionNeedsToSave;
        _excludedRecipes = [];
        _warningRecipes = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences updated successfully!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e, stackTrace) {
      print('Error saving preferences: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update preferences: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
    final bool _showAllergyDebug = false; // hide excluded/allergen warning recipe lists
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
                          'Preferences',
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
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DishesLikeSelectionPage(
                              initialSelections: _dishPreferences,
                            ),
                          ),
                        );
                        if (result != null && result is List<String>) {
                          setState(() => _dishPreferences = result);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Diet Type
                  Card(
                    child: ListTile(
                      title: const Text('Diet Type'),
                      subtitle: Text(_dietTypes.isEmpty ? 'None selected' : _getDisplayText(_dietTypes, _dietTypeOptions, 'key')),
                      leading: const Icon(Icons.restaurant, color: Colors.blue),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _showMultiSelectDialog(
                        'Diet Type',
                        _dietTypeOptions,
                        _dietTypes,
                        'key',
                        (selected) => setState(() => _dietTypes = selected),
                        allowMultiple: true,
                        hasNoneOption: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Health Conditions
                Card(
                  child: ListTile(
                      title: const Text('Health Conditions'),
                      subtitle: Text(_getDisplayText(_healthConditions, _healthOptions, 'key')),
                      leading: const Icon(Icons.favorite, color: Colors.blue),
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
                        (selected) {
                          setState(() {
                            _allergies = selected;
                            _excludedRecipes = []; // Reset when allergies change
                            _warningRecipes = [];
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                // Debug Section: Excluded Recipes & Warnings (hidden unless enabled)
                // ignore: dead_code
                if (_showAllergyDebug) ...[
                    ExpansionTile(
                      initiallyExpanded: false,
                      title: const Text(
                        'Excluded Recipes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(_excludedRecipes.isEmpty 
                          ? 'Tap to check excluded recipes'
                          : '${_excludedRecipes.length} excluded, ${_warningRecipes.length} with warnings'),
                      onExpansionChanged: (expanded) {
                        if (expanded && _excludedRecipes.isEmpty) {
                          _checkExcludedRecipes();
                        }
                      },
                    children: [
                        if (_loadingExcluded)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_excludedRecipes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No recipes excluded based on your allergies.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        else
                          ..._excludedRecipes.map((item) {
                            final recipe = item['recipe'] as Recipe;
                            final allergen = item['matchedAllergen'] as String;
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.block, color: Colors.red, size: 20),
                              title: Text(
                                recipe.title,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                'Matched: $allergen',
                                style: TextStyle(fontSize: 12, color: Colors.red[700]),
                              ),
                              trailing: Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(recipe.title),
                                    content: SingleChildScrollView(
                              child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                children: [
                                          Text(
                                            'Excluded due to: $allergen',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Ingredients:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          ...recipe.ingredients.map((ing) {
                                            final matchingIngs = item['matchingIngredients'] as List<String>? ?? [];
                                            final isMatching = matchingIngs.any((mi) => ing.toLowerCase().contains(mi.toLowerCase()) || mi.toLowerCase().contains(ing.toLowerCase()));
                                            return Text.rich(
                                              TextSpan(
                                                children: [
                                                  const TextSpan(text: '• '),
                                                  TextSpan(
                                                    text: ing,
                                                    style: TextStyle(
                                                      fontWeight: isMatching ? FontWeight.bold : FontWeight.normal,
                                                      color: isMatching ? Colors.red[700] : Colors.black,
                                                      decoration: isMatching ? TextDecoration.underline : TextDecoration.none,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                    ],
                  ),
                const SizedBox(height: 12),
                
                    // Warnings Section (Optional Ingredients Only)
                    ExpansionTile(
                      initiallyExpanded: false,
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      title: const Text(
                        'Recipes with Allergen Warnings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(_warningRecipes.isEmpty 
                          ? 'Tap to check recipes with optional allergens'
                          : '${_warningRecipes.length} recipes (can still add)'),
                      onExpansionChanged: (expanded) {
                        if (expanded && _warningRecipes.isEmpty) {
                          _checkWarningRecipes();
                        }
                      },
                    children: [
                        if (_loadingExcluded)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_warningRecipes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No recipes with optional allergen ingredients.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        else
                          ..._warningRecipes.map((item) {
                            final recipe = item['recipe'] as Recipe;
                            final allergen = item['allergy'] as String;
                            final matchingIngs = item['matchingIngredients'] as List<String>;
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                              title: Text(
                                recipe.title,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                'Warning: $allergen (optional ingredients)',
                                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                              ),
                              trailing: Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(recipe.title),
                                    content: SingleChildScrollView(
                              child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.orange[200]!),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'This recipe contains $allergen in OPTIONAL ingredients. You can still add it, but be careful!',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.orange[900],
                                                      fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                                            ),
                  ),
                  const SizedBox(height: 12),
                                          const Text(
                                            'Ingredients:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          ...recipe.ingredients.map((ing) {
                                            final isMatching = matchingIngs.any((mi) {
                                              final miLower = mi.toLowerCase();
                                              final ingLower = ing.toLowerCase();
                                              return ingLower.contains(miLower) || miLower.contains(ingLower);
                                            });
                                            return Text.rich(
                                              TextSpan(
                    children: [
                                                  const TextSpan(text: '• '),
                                                  TextSpan(
                                                    text: ing,
                                                    style: TextStyle(
                                                      fontWeight: isMatching ? FontWeight.bold : FontWeight.normal,
                                                      color: isMatching ? Colors.orange[700] : Colors.black,
                                                      decoration: isMatching ? TextDecoration.underline : TextDecoration.none,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                ],
                              ),
                            ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                          ),
                                    ],
                        ),
                                );
                              },
                            );
                          }).toList(),
                    ],
                  ),
                    const SizedBox(height: 12),
                  ],
                
                const SizedBox(height: 20),
                
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

  Future<void> _checkExcludedRecipes() async {
    if (_allergies.isEmpty) {
      setState(() => _excludedRecipes = []);
      return;
    }

    setState(() => _loadingExcluded = true);

    try {
      // Fetch all recipes without filtering
      final allRecipes = await RecipeService.fetchRecipes(userId: null);
      
      final excluded = <Map<String, dynamic>>[];
      
      for (final recipe in allRecipes) {
        // Check which allergen matches in required ingredients (exclusion)
        String? matchedAllergen;
        List<String> matchingIngredients = [];
        
        for (final allergy in _allergies) {
          final result = RecipeService.getMatchingIngredients(recipe, allergy);
          // Check if it's excluded (has required match)
          final filtered = RecipeService.filterRecipesByAllergies([recipe], [allergy]);
          if (filtered.isEmpty && result.isNotEmpty) {
            matchedAllergen = allergy;
            matchingIngredients = result;
            break;
          }
        }
        
        if (matchedAllergen != null) {
          excluded.add({
            'recipe': recipe,
            'matchedAllergen': matchedAllergen,
            'matchingIngredients': matchingIngredients,
          });
        }
      }

      // Also check for warning recipes (optional ingredients only)
      final warnings = RecipeService.getRecipesWithWarnings(allRecipes, _allergies);

      if (mounted) {
                setState(() {
          _excludedRecipes = excluded;
          _warningRecipes = warnings;
          _loadingExcluded = false;
        });
      }
    } catch (e) {
      print('Error checking excluded recipes: $e');
      if (mounted) {
                setState(() {
          _loadingExcluded = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading excluded recipes: $e')),
        );
      }
    }
  }

  Future<void> _checkWarningRecipes() async {
    if (_allergies.isEmpty) {
      setState(() => _warningRecipes = []);
      return;
    }

    setState(() => _loadingExcluded = true);

    try {
      // Fetch all recipes
      final allRecipes = await RecipeService.fetchRecipes(userId: null);
      final warnings = RecipeService.getRecipesWithWarnings(allRecipes, _allergies);

      if (mounted) {
                  setState(() {
          _warningRecipes = warnings;
          _loadingExcluded = false;
        });
      }
    } catch (e) {
      print('Error checking warning recipes: $e');
      if (mounted) {
                  setState(() {
          _loadingExcluded = false;
        });
      }
    }
  }

} 
