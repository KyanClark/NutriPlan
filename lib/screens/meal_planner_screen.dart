import 'package:flutter/material.dart';
import 'dart:async';
import 'recipes_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'recipe_info_screen.dart';
import '../models/recipes.dart';
import 'recipes_page.dart'; // Import _RecipeCard for use in meal planner

class MealPlannerScreen extends StatefulWidget {
  final bool forceRefresh;
  final VoidCallback? onChanged;
  const MealPlannerScreen({super.key, this.forceRefresh = false, this.onChanged});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  DateTime selectedDate = DateTime.now();
  final int _selectedMealTypeIndex = 0;
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  // Add state for Supabase meal plans
  List<Map<String, dynamic>> supabaseMealPlans = [];

  final List<String> mealTypeLabels = ['Breakfast', 'Lunch', 'Dinner'];

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.forceRefresh) {
      _fetchSupabaseMealPlans();
    } else {
      _fetchSupabaseMealPlans();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh meal plans every time the screen is shown
    _fetchSupabaseMealPlans();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        // Only update selectedDate if it's today's date (not manually selected)
        final now = DateTime.now();
        if (selectedDate.year == now.year && 
            selectedDate.month == now.month && 
            selectedDate.day == now.day) {
          selectedDate = now;
        }
      });
    });
  }

  Future<void> _fetchSupabaseMealPlans() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final response = await Supabase.instance.client
        .from('meal_plans')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    if (mounted) {
    setState(() {
        supabaseMealPlans = List<Map<String, dynamic>>.from(response);
      });
    }
  }



  List<DateTime> get _weekDates {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1E7AF),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
        children: [
          // Centered and padded 'My Meal Plan' text
          Padding(
                padding: const EdgeInsets.symmetric(vertical: 13.0),
                child: Center(
                                child: Text(
                    'My Meal Plan',
                                  style: TextStyle(
                      fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
              // Display Supabase meal plans below
              if (supabaseMealPlans.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8, // More square, less tall
                    ),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: supabaseMealPlans.fold<int>(0, (sum, plan) => (sum ?? 0) + ((plan['meals'] as List?)?.length ?? 0)),
                    itemBuilder: (context, idx) {
                      int runningIdx = 0;
                      for (final plan in supabaseMealPlans) {
                        final meals = List<Map<String, dynamic>>.from(plan['meals'] ?? []);
                        for (final meal in meals) {
                          if (runningIdx == idx) {
                            final planId = plan['id'];
                            return Stack(
                              children: [
                                Column(
                                  children: [
                                    _RecipeCard(
                                      recipe: Recipe(
                                        id: meal['recipe_id'] ?? '',
                                        title: meal['title'] ?? '',
                                        imageUrl: meal['image_url'] ?? '',
                                        calories: 0,
                                        cost: 0,
                                        shortDescription: '',
                                        dietTypes: [],
                                        macros: {},
                                        allergyWarning: '',
                                        ingredients: [],
                                        instructions: [],
                                      ),
                                      isFavorite: false,
                                      onTap: () async {
                                        final recipeId = meal['recipe_id'] ?? '';
                                        if (recipeId.isEmpty) return;
                                        final response = await Supabase.instance.client
                                          .from('recipes')
                                          .select()
                                          .eq('id', recipeId)
                                          .maybeSingle();
                                        if (response == null) return;
                                        final recipe = Recipe.fromMap(response);
                                        if (!mounted) return;
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RecipeInfoScreen(
                                              recipe: recipe,
                                              showStartCooking: true,
                                            ),
                                          ),
                                        );
                                        if (result == true) {
                                          await _fetchSupabaseMealPlans();
                                          if (widget.onChanged != null) widget.onChanged!();
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete Meal Plan',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Meal'),
                                          content: const Text('Are you sure you want to delete this meal from your plan?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm != true) return;
                                      final planMeals = List<Map<String, dynamic>>.from(meals);
                                      final mealIdToDelete = meal['recipe_id'];
                                      planMeals.removeWhere((m) => m['recipe_id'] == mealIdToDelete);
                                      if (planMeals.isEmpty) {
                                        // Delete the whole meal plan row if no meals left
                                        await Supabase.instance.client.from('meal_plans').delete().eq('id', planId);
                                        if (!mounted) return;
                                        setState(() {
                                          supabaseMealPlans.removeWhere((p) => p['id'] == planId);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Meal Plan deleted'), duration: Duration(seconds: 3)),
                                        );
                                      } else {
                                        // Update the meal plan row with the new meals array
                                        await Supabase.instance.client.from('meal_plans').update({'meals': planMeals}).eq('id', planId);
                                        if (!mounted) return;
                                        setState(() {
                                          final planIdx = supabaseMealPlans.indexWhere((p) => p['id'] == planId);
                                          if (planIdx != -1) {
                                            supabaseMealPlans[planIdx]['meals'] = planMeals;
                                          }
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Meal removed from plan'), duration: Duration(seconds: 3)),
                                        );
                                      }
                                      if (widget.onChanged != null) widget.onChanged!();
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                          runningIdx++;
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => RecipesPage(onChanged: widget.onChanged),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.ease;
                  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
            if (widget.onChanged != null) widget.onChanged!();
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Create Meal Plan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color.fromARGB(255, 81, 209, 87),
        ),
      ),
    );
  }

  String _fullDate(DateTime date) {
    final weekday = _weekdayLong(date);
    final month = _monthShort(date);
    return '$month ${date.day}, $weekday';
  }

  String _getCurrentTime() {
    final now = _currentTime;
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _monthShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }

  String _weekdayShort(DateTime date) {
    const weekdays = [
      'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
    ];
    return weekdays[date.weekday - 1];
  }
  String _weekdayLong(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }
  String _monthLong(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

}

  @override
 

// Paste the _RecipeCard widget here for use in meal planner
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;
  const _RecipeCard({required this.recipe, this.isFavorite = false, this.onFavoriteToggle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 220 ? constraints.maxWidth : 200.0;
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
                borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
          ),
        ],
      ),
              child: Stack(
                children: [
                  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        child: Image.network(
                          recipe.imageUrl,
                          height: 120, // Match see_all_recipe
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0), // Match see_all_recipe
                        child: Text(
                          recipe.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 