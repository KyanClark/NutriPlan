import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DishesLikeSelectionPage extends StatefulWidget {
  final List<String> initialSelections;
  
  const DishesLikeSelectionPage({
    super.key,
    required this.initialSelections,
  });

  @override
  State<DishesLikeSelectionPage> createState() => _DishesLikeSelectionPageState();
}

class _DishesLikeSelectionPageState extends State<DishesLikeSelectionPage> {
  late Set<String> _selectedDishes;
  bool _saving = false;

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

  @override
  void initState() {
    super.initState();
    _selectedDishes = Set<String>.from(widget.initialSelections);
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('user_preferences')
            .upsert({
              'user_id': user.id,
              'like_dishes': _selectedDishes.toList(),
            });
        
        if (!mounted) return;
        Navigator.of(context).pop(_selectedDishes.toList());
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: $e')),
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
        title: const Text('Dishes I Like'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select all dishes you like',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._dishOptions.map((dish) => _buildDishCard(dish)).toList(),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _savePreferences,
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
                    : Text(
                        'Save (${_selectedDishes.length} selected)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(Map<String, dynamic> dish) {
    final isSelected = _selectedDishes.contains(dish['key']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedDishes.add(dish['key']);
            } else {
              _selectedDishes.remove(dish['key']);
            }
          });
        },
        title: Text(
          dish['title'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
          ),
        ),
        subtitle: Text(
          dish['desc'],
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        activeColor: const Color(0xFF4CAF50),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

