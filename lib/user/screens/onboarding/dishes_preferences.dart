import 'package:flutter/material.dart';
import 'allergy_selection_page.dart';
import 'welcome_experience_page.dart';
import '../../utils/onboarding_transitions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DietTypePage extends StatefulWidget {
  const DietTypePage({super.key});

  @override
  State<DietTypePage> createState() => _DietTypePreferencePageState();
}

class _DietTypePreferencePageState extends State<DietTypePage> {
  final List<Map<String, dynamic>> dishPreferences = [
    {
      'title': '✅ All of them',
      'desc': 'I enjoy all types of dishes',
      'icon': '✅',
      'key': 'all',
    },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button - navigate to welcome experience last slide
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF388E3C)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    OnboardingPageRoute(
                      page: const WelcomeExperiencePage(),
                      slideFromRight: false, // Slide from left when going back
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 16),
              Text(
                'What dishes do you usually like?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF388E3C),
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the dishes you usually eat. This helps us recommend recipes you\'ll love!',
                style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: dishPreferences.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final isSelected = selectedIndexes.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (index == 0) {
                          // "All of them" selected
                          if (isSelected) {
                            selectedIndexes.remove(index);
                          } else {
                            selectedIndexes.clear();
                            selectedIndexes.add(0);
                          }
                        } else {
                          // Regular dish selected
                          if (isSelected) {
                            selectedIndexes.remove(index);
                          } else {
                            selectedIndexes.remove(0); // Remove "all" if it was selected
                            selectedIndexes.add(index);
                          }
                        }
                      });
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
                                  if (index == 0) {
                                    // "All of them" selected
                                    if (isSelected) {
                                      selectedIndexes.remove(index);
                                    } else {
                                      selectedIndexes.clear();
                                      selectedIndexes.add(0);
                                    }
                                  } else {
                                    // Regular dish selected
                                    if (isSelected) {
                                      selectedIndexes.remove(index);
                                    } else {
                                      selectedIndexes.remove(0); // Remove "all" if it was selected
                                      selectedIndexes.add(index);
                                    }
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
                      List<String> selectedDishes;
                      if (selectedIndexes.contains(0)) {
                        // If "all" is selected, select all dish keys except "all"
                        selectedDishes = dishPreferences
                            .where((dish) => dish['key'] != 'all')
                            .map((dish) => dish['key'] as String)
                            .toList();
                      } else {
                        selectedDishes = selectedIndexes.map((i) => dishPreferences[i]['key'] as String).toList();
                      }
                      await Supabase.instance.client
                        .from('user_preferences')
                        .upsert({
                          'user_id': user.id,
                          'like_dishes': selectedDishes,
                        });
                    }
                    Navigator.push(
                      context,
                      OnboardingPageRoute(page: const AllergySelectionPage()),
                    );
                  } : null,
                  child: const Text('Confirm', style: TextStyle(fontSize: 18)),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 