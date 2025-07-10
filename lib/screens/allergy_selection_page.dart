import 'package:flutter/material.dart';
import 'servings_selection_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AllergySelectionPage extends StatefulWidget {
  const AllergySelectionPage({Key? key}) : super(key: key);

  @override
  State<AllergySelectionPage> createState() => _AllergySelectionPageState();
}

class _AllergySelectionPageState extends State<AllergySelectionPage> {
  final List<Map<String, String>> allergies = [
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
      'title': 'Sesame',
      'desc': 'Sesame seeds, tahini, some breads or snacks',
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
      appBar: AppBar(
        title: const Text('Allergies'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Food Allergies \n& Intolerance',
                  style: TextStyle( 
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                    letterSpacing: 1.1,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showTooltip(context),
                  child: const Icon(Icons.info_outline, color: Color(0xFF388E3C)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Personalize your meals by telling us what ingredients to leave out.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
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
                        if (isSelected) {
                          selectedIndexes.remove(index);
                        } else {
                          selectedIndexes.add(index);
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
                                  if (isSelected) {
                                    selectedIndexes.remove(index);
                                  } else {
                                    selectedIndexes.add(index);
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
                      final selectedAllergies = selectedIndexes.map((i) => allergies[i]['title']).toList();
                      await Supabase.instance.client
                        .from('user_preferences')
                        .upsert({
                          'user_id': user.id,
                          'allergies': selectedAllergies,
                        });
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ServingsSelectionPage()),
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