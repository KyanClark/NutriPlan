import 'package:flutter/material.dart';
import 'user_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DietTypePage extends StatefulWidget {
  const DietTypePage({super.key});

  @override
  State<DietTypePage> createState() => _DietTypePreferencePageState();
}

class _DietTypePreferencePageState extends State<DietTypePage> {
  final List<Map<String, dynamic>> dishPreferences = [
    {
      'title': '🐟 Fish & Seafood',
      'desc': 'Bangus, tilapia, shrimp, crab, squid',
      'icon': '🐟',
      'key': 'fish_seafood',
    },
    {
      'title': '🥩 Meat & Poultry',
      'desc': 'Chicken, pork, beef, turkey',
      'icon': '🥩',
      'key': 'meat_poultry',
    },
    {
      'title': '🍲 Soups & Stews',
      'desc': 'Sinigang, tinola, bulalo, nilaga',
      'icon': '🍲',
      'key': 'soups_stews',
    },
    {
      'title': '🍚 Rice Dishes',
      'desc': 'Fried rice, silog meals, biryani',
      'icon': '🍚',
      'key': 'rice_dishes',
    },
    {
      'title': '🥗 Vegetables',
      'desc': 'Adobong kangkong, pinakbet, chopsuey',
      'icon': '🥗',
      'key': 'vegetables',
    },
    {
      'title': '🍜 Noodles & Pasta',
      'desc': 'Pancit, spaghetti, bihon, mami',
      'icon': '🍜',
      'key': 'noodles_pasta',
    },
    {
      'title': '🥘 Adobo & Braised',
      'desc': 'Chicken adobo, pork adobo, humba',
      'icon': '🥘',
      'key': 'adobo_braised',
    },
    {
      'title': '🍳 Egg Dishes',
      'desc': 'Tortang talong, scrambled eggs, omelet',
      'icon': '🍳',
      'key': 'egg_dishes',
    },
    {
      'title': '🌶️ Spicy Food',
      'desc': 'Bicol express, sisig, spicy wings',
      'icon': '🌶️',
      'key': 'spicy_food',
    },
  ];

  final Set<int> selectedIndexes = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    // Each card has a fixed height + separator (16+12)
    final double cardHeight = 16 + 12 + 72; // padding + separator + estimated card height
    _scrollController.animateTo(
      index * cardHeight,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'What dishes do you enjoy?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select your favorite types of dishes. This helps us recommend recipes you\'ll love!',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: dishPreferences.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final isSelected = selectedIndexes.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIndexes.remove(index);
                        } else {
                          selectedIndexes.add(index);
                        }
                      });
                      _scrollToIndex(index);
                    },
                    child: Card(
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                      elevation: isSelected ? 6 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF388E3C) : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (isSelected) {
                                    selectedIndexes.remove(index);
                                  } else {
                                    selectedIndexes.add(index);
                                  }
                                });
                              },
                              activeColor: const Color(0xFF388E3C),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dishPreferences[index]['title']!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    dishPreferences[index]['desc']!,
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
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
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
                  onPressed: selectedIndexes.isNotEmpty ? () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      final selectedDishes = selectedIndexes.map((i) => dishPreferences[i]['key']).toList();
                      await Supabase.instance.client
                        .from('user_preferences')
                        .upsert({
                          'user_id': user.id,
                          'dish_preferences': selectedDishes,
                        });
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserProfilePage()),
                    );
                  } : null,
                  child: const Text('Confirm', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 