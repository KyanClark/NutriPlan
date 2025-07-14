import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServingsSelectionPage extends StatefulWidget {
  const ServingsSelectionPage({super.key});

  @override
  State<ServingsSelectionPage> createState() => _ServingsSelectionPageState();
}

class _ServingsSelectionPageState extends State<ServingsSelectionPage> {
  final List<Map<String, String>> servingsOptions = [
    {
      'title': '1 serving',
      'desc': 'Just for you',
    },
    {
      'title': '2 servings',
      'desc': 'For you and a friend',
    },
    {
      'title': '3 servings',
      'desc': 'Small family or group',
    },
    {
      'title': '4 servings or more',
      'desc': 'Family-sized or meal prep',
    },
  ];

  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = MediaQuery.of(context).size.width < 430 ? 16.0 : 24.0;
    final double verticalPadding = MediaQuery.of(context).size.height < 900 ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servings'),
        centerTitle: true,
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'How many servings do you usually prepare?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF388E3C),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This helps us scale recipes and meal plans for you.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: servingsOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  servingsOptions[index]['title']!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  servingsOptions[index]['desc']!,
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
                          int servings = selectedIndex! + 1;
                          await Supabase.instance.client
                            .from('user_preferences')
                            .upsert({
                              'user_id': user.id,
                              'servings': servings,
                            });
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                        );
                      } : null,
                      child: const Text('Continue', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 