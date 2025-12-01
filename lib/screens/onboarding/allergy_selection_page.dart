import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile_page.dart';
import '../../utils/onboarding_transitions.dart';

class AllergySelectionPage extends StatefulWidget {
  const AllergySelectionPage({super.key});

  @override
  State<AllergySelectionPage> createState() => _AllergySelectionPageState();
}

class _AllergySelectionPageState extends State<AllergySelectionPage> {
  final List<Map<String, String>> allergies = [
    {
      'title': 'None',
      'desc': 'No allergies or intolerances',
    },
    {
      'title': 'Dairy (Milk)',
      'desc': 'Milk, cheese, yogurt, butter',
    },
    {
      'title': 'Eggs',
      'desc': 'Scrambled eggs, baked goods, mayo',
    },
    {
      'title': 'Peanuts',
      'desc': 'Peanut butter, peanut oil, sauces',
    },
    {
      'title': 'Tree Nuts',
      'desc': 'Almonds, cashews, walnuts, hazelnuts',
    },
    {
      'title': 'Soy',
      'desc': 'Tofu, soy sauce, soy milk, processed foods',
    },
    {
      'title': 'Wheat / Gluten',
      'desc': 'Bread, noodles, flour, some sauces',
    },
    {
      'title': 'Fish',
      'desc': 'Bangus, tilapia, tuna, sardines',
    },
    {
      'title': 'Shellfish',
      'desc': 'Shrimp, crab, squid, mussels',
    },
    {
      'title': 'Chicken',
      'desc': 'Chicken meat, chicken broth, chicken-based dishes',
    },
    {
      'title': 'Pork',
      'desc': 'Pork meat, pork products, lard',
    },
    {
      'title': 'Beef',
      'desc': 'Beef meat, beef broth, beef-based dishes',
    },
    {
      'title': 'Sesame',
      'desc': 'Sesame seeds, tahini, some breads or snacks',
    },
    {
      'title': 'Corn',
      'desc': 'Corn, cornstarch, corn syrup, corn-based products',
    },
    {
      'title': 'Tomatoes',
      'desc': 'Tomatoes, tomato sauce, ketchup',
    },
  ];

  final Set<int> selectedIndexes = {};

  void _showTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why select allergies?'),
        content: const Text(
          'This section lets you filter out foods that may trigger allergic reactions or intolerances, such as dairy, peanuts, shellfish, or gluten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF388E3C)),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Food Allergies & Intolerance',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF388E3C),
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showTooltip(context),
                    child: const Icon(Icons.info_outline, color: Color(0xFF388E3C)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalize your meals by telling us what ingredients to leave out.',
                style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 24),
              Expanded(
              child: ListView.separated(
                itemCount: allergies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final isSelected = selectedIndexes.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (index == 0) { // 'None' selected
                        if (isSelected) {
                          selectedIndexes.remove(index);
                          } else {
                            selectedIndexes.clear();
                            selectedIndexes.add(0);
                          }
                        } else {
                          if (isSelected) {
                            selectedIndexes.remove(index);
                          } else {
                            selectedIndexes.remove(0); // Deselect 'None'
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
                                  if (index == 0) { // 'None' selected
                                  if (isSelected) {
                                    selectedIndexes.remove(index);
                                    } else {
                                      selectedIndexes.clear();
                                      selectedIndexes.add(0);
                                    }
                                  } else {
                                    if (isSelected) {
                                      selectedIndexes.remove(index);
                                    } else {
                                      selectedIndexes.remove(0); // Deselect 'None'
                                    selectedIndexes.add(index);
                                    }
                                  }
                                });
                              },
                              activeColor: const Color(0xFF388E3C),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    allergies[index]['title']!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    allergies[index]['desc']!,
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
                      // Get selected allergy titles
                      List<String> selectedAllergies;
                      if (selectedIndexes.contains(0)) {
                        selectedAllergies = [];
                      } else {
                        selectedAllergies = selectedIndexes.map((i) => allergies[i]['title']).whereType<String>().toList();
                      }
                      await Supabase.instance.client
                        .from('user_preferences')
                        .upsert({
                          'user_id': user.id,
                          'allergies': selectedAllergies,
                        });
                    }
                    
                    // Navigate to user profile page (age, gender) to continue onboarding
                    Navigator.push(
                      context,
                      OnboardingPageRoute(page: const UserProfilePage()),
                    );
                  } : null,
                  child: const Text('Confirm', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
      )
    );
  }
} 