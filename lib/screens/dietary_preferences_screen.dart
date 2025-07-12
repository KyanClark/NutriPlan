import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DietaryPreferencesScreen extends StatefulWidget {
  @override
  _DietaryPreferencesScreenState createState() => _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> {
  String? _dietType;
  List<String> _allergies = [];
  int? _servings;
  bool _loading = true;
  bool _saving = false;

  // Available options
  final List<String> _dietTypes = [
    'Balance Diet',
    'Vegan',
    'Vegetarian',
    'Keto/ Low Carbs Diet',
    'Dairy-Free Diet',
    'High Protein Diet',
    'Gluten-Free',
    'Pescatarian',
    'Flexitarian Diet',
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

  final List<String> _servingOptions = [
    '1 serving',
    '2 servings',
    '3 servings',
    '4 servings or more',
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
            _dietType = data['diet_type'] as String?;
            _allergies = List<String>.from(data['allergies'] ?? []);
            _servings = data['servings'] as int?;
          });
        }
      } catch (e) {
        print('Error fetching user preferences: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
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
              'diet_type': _dietType,
              'allergies': _allergies,
              'servings': _servings,
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

  void _showDietTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Diet Type'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _dietTypes.length,
            itemBuilder: (context, index) {
              final dietType = _dietTypes[index];
              return ListTile(
                title: Text(dietType),
                trailing: _dietType == dietType ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() => _dietType = dietType);
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

  void _showAllergiesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Allergies'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _allergyOptions.length,
                itemBuilder: (context, index) {
                  final allergy = _allergyOptions[index];
                  return CheckboxListTile(
                    title: Text(allergy),
                    value: _allergies.contains(allergy),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          _allergies.add(allergy);
                        } else {
                          _allergies.remove(allergy);
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
              setState(() {}); // Update main screen
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showServingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Servings'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _servingOptions.length,
            itemBuilder: (context, index) {
              final serving = _servingOptions[index];
              final servingNumber = index + 1;
              return ListTile(
                title: Text(serving),
                trailing: _servings == servingNumber ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  setState(() => _servings = servingNumber);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Preferences'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveUserPreferences,
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Personal Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Diet Type
                Card(
                  child: ListTile(
                    title: const Text('Diet Type'),
                    subtitle: Text(_dietType ?? 'Not set'),
                    leading: const Icon(Icons.restaurant_menu, color: Colors.green),
                    trailing: const Icon(Icons.edit),
                    onTap: _showDietTypeDialog,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Allergies
                Card(
                  child: ListTile(
                    title: const Text('Allergies and Restrictions'),
                    subtitle: Text(_allergies.isEmpty ? 'None selected' : _allergies.join(', ')),
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    trailing: const Icon(Icons.edit),
                    onTap: _showAllergiesDialog,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Servings
                Card(
                  child: ListTile(
                    title: const Text('Meal Servings'),
                    subtitle: Text(_servings != null ? '$_servings serving${_servings == 1 ? '' : 's'}' : 'Not set'),
                    leading: const Icon(Icons.restaurant, color: Colors.blue),
                    trailing: const Icon(Icons.edit),
                    onTap: _showServingsDialog,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveUserPreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }
} 