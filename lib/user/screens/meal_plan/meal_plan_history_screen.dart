import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipes.dart';
import '../recipes/recipe_info_screen.dart';

class MealPlanHistoryScreen extends StatefulWidget {
  const MealPlanHistoryScreen({super.key});

  @override
  State<MealPlanHistoryScreen> createState() => _MealPlanHistoryScreenState();
}

class _MealPlanHistoryScreenState extends State<MealPlanHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
      setState(() {
        _history = [];
        _loading = false;
      });
      }
      return;
    }
    final response = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
        .eq('user_id', user.id)
        .order('completed_at', ascending: false);
    if (mounted) {
    setState(() {
      _history = List<Map<String, dynamic>>.from(response);
      _loading = false;
      });
    }
  }

  // Return all history (date filter removed)
  List<Map<String, dynamic>> _filterByDate() => _history;

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _filterByDate();

    String formatTime(DateTime? dt) {
      if (dt == null) return '';
      int hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $ampm';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
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
                    'Meal Plan History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF388E3C),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
        children: [
          // Main content
          Expanded(
            child: _loading
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(i == DateTime.now().second % 3 ? 1 : 0.4),
                    shape: BoxShape.circle,
                  ),
                                ),
                              ),
              ),
            )
                        : filteredHistory.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/widgets/no_mea.gif',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                                      const Text(
                          'No completed meals yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                                          color: Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 12),
                                      const Text(
                          'Complete your meal plans to see them here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                                          color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                            : () {
                                // Group meals by date (descending)
                                final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
                                for (final meal in filteredHistory) {
                                  final dt = meal['completed_at'] != null
                                      ? DateTime.parse(meal['completed_at']).toLocal()
                                      : null;
                                  if (dt == null) continue;
                                  final dateOnly = DateTime(dt.year, dt.month, dt.day);
                                  grouped.putIfAbsent(dateOnly, () => []).add(meal);
                                }
                                final dateKeys = grouped.keys.toList()
                                  ..sort((a, b) => b.compareTo(a));

                                String formatDate(DateTime d) {
                                  const months = [
                                    'January',
                                    'February',
                                    'March',
                                    'April',
                                    'May',
                                    'June',
                                    'July',
                                    'August',
                                    'September',
                                    'October',
                                    'November',
                                    'December'
                                  ];
                                  return '${months[d.month - 1]} ${d.day}, ${d.year}';
                                }

                                return ListView.builder(
        padding: const EdgeInsets.all(20),
                                  itemCount: dateKeys.length,
                                  itemBuilder: (context, idx) {
                                    final dateKey = dateKeys[idx];
                                    final mealsForDate = grouped[dateKey] ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                                        Text(
                                          formatDate(dateKey),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
          ),
                        ),
                                        const SizedBox(height: 8),
                                        ...mealsForDate.map((meal) {
                          final dt = meal['completed_at'] != null
                            ? DateTime.parse(meal['completed_at']).toLocal()
                            : null;
                          final timeStr = formatTime(dt);
                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: meal['image_url'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            meal['image_url'],
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                                  : const Icon(Icons.restaurant, color: Colors.green),
                                              title: Text(meal['title'] ?? meal['recipe_name'] ?? 'Meal'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(timeStr, style: const TextStyle(fontSize: 15)),
                                      if (meal['calories'] != null)
                                                    Text('${meal['calories']} kcal',
                                                        style: const TextStyle(color: Colors.black54)),
                                    ],
                                  ),
                                  onTap: () async {
                                    final recipe = Recipe(
                                      id: (meal['recipe_id'] ?? '').toString(),
                                      title: meal['title'] ?? meal['recipe_name'] ?? 'Unknown Recipe',
                                      imageUrl: meal['image_url'] ?? meal['recipe_image_url'] ?? '',
                                      shortDescription: meal['description'] ?? meal['recipe_description'] ?? '',
                                      calories: meal['calories'] ?? 0,
                                      ingredients: List<String>.from(meal['ingredients'] ?? []),
                                      instructions: List<String>.from(meal['instructions'] ?? []),
                                      macros: {
                                        'protein': (meal['protein'] ?? 0).toDouble(),
                                        'carbs': (meal['carbs'] ?? 0).toDouble(),
                                        'fat': (meal['fat'] ?? 0).toDouble(),
                                      },
                                      allergyWarning: meal['allergy_warning'] ?? '',
                                      tags: List<String>.from(meal['tags'] ?? []),
                                      cost: (meal['cost'] ?? 0.0).toDouble(),
                                      notes: meal['notes'] ?? '',
                                    );
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                                    builder: (context) => RecipeInfoScreen(recipe: recipe),
                                      ),
                                    );
                                  },
                                ),
                          );
                        }),
                                        const SizedBox(height: 16),
                      ],
                    );
                  },
                                );
                              }(),
              ),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }
} 