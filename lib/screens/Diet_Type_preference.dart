import 'package:flutter/material.dart';
import 'allergy_selection_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DietTypePreferencePage extends StatefulWidget {
  const DietTypePreferencePage({Key? key}) : super(key: key);

  @override
  State<DietTypePreferencePage> createState() => _DietTypePreferencePageState();
}

class _DietTypePreferencePageState extends State<DietTypePreferencePage> {
  final List<Map<String, String>> dietTypes = [
    {
      'title': 'Balance Diet',
      'desc': 'Provides the right amounts of all the essential nutrients your body needs to function properly',
    },
    {
      'title': 'Vegan',
      'desc': '100% plant-based, no animal products',
    },
    {
      'title': 'Vegetarian',
      'desc': 'No meat, may include eggs/dairy',
    },
    {
      'title': 'Keto/ Low Carbs Diet',
      'desc': 'For Fat-loss & Definition',
    },
    {
      'title': 'Dairy-Free Diet',
      'desc': 'Excludes all forms of dairy: milk, cheese, butter, cream, yogurt, etc.',
    },
    {
      'title': 'High Protein Diet',
      'desc': 'For Gym Fitness',
    },
    {
      'title': 'Gluten-Free',
      'desc': 'No wheat, barley, or rye (for allergies or preference)',
    },
    {
      'title': 'Pescatarian',
      'desc': 'Vegetarian + fish/seafood (Balanced option with lean protein)',
    },
    {
      'title': 'Flexitarian Diet',
      'desc': 'Mostly plant-based, but allows occasional meat',
    },
  ];

  int? selectedIndex;
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'What is your diet type?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: dietTypes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final isSelected = selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dietTypes[index]['title']!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dietTypes[index]['desc']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.white70 : Colors.black54,
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
                  onPressed: selectedIndex != null ? () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null && selectedIndex != null) {
                      final selectedDiet = dietTypes[selectedIndex!]['title'];
                      await Supabase.instance.client
                        .from('user_preferences')
                        .upsert({
                          'user_id': user.id,
                          'diet_type': selectedDiet,
                        });
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllergySelectionPage()),
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