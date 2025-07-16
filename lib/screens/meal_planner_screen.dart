import 'package:flutter/material.dart';
import 'dart:async';
import '../models/meal.dart';
import '../models/meal_plan.dart';
import '../services/meal_service.dart';
import 'recipes_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'recipe_info_screen.dart';
import '../models/recipes.dart';
import 'recipes_page.dart'; // Import _RecipeCard for use in meal planner

class MealPlannerScreen extends StatefulWidget {

  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  List<MealPlan> mealPlans = [];
  List<Meal> mealSuggestions = [];
  DateTime selectedDate = DateTime.now();
  final int _selectedMealTypeIndex = 0;
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  // Add state for Supabase meal plans
  List<Map<String, dynamic>> supabaseMealPlans = [];

  final List<MealType> mealTypes = [MealType.breakfast, MealType.lunch, MealType.dinner];
  final List<String> mealTypeLabels = ['Breakfast', 'Lunch', 'Dinner'];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _fetchSupabaseMealPlans();
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


  void _addMealToPlan(Meal meal, MealType mealType, DateTime date) {
    final mealPlan = MealPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      mealType: mealType,
      meal: meal,
    );
    setState(() {
      mealPlans.add(mealPlan);
    });
  }

  void _editMeal(MealPlan mealPlan) {
    // TODO: Implement edit meal functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit meal functionality coming soon!')),
    );
  }

  List<MealPlan> _getMealsForType(MealType mealType) {
    return mealPlans.where((plan) =>
      plan.date.year == selectedDate.year &&
      plan.date.month == selectedDate.month &&
      plan.date.day == selectedDate.day &&
      plan.mealType == mealType
    ).toList();
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
              // Calendar container and Meal Plan button row
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: [
                      // Calendar container
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fullDate(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getCurrentTime(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null && picked != selectedDate) {
                                    setState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 22),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RecipeInfoScreen(
                                          recipe: recipe,
                                          showStartCooking: true,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Delete Meal Plan',
                                    onPressed: () async {
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
                                          const SnackBar(content: Text('Meal Plan deleted')),
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
                                          const SnackBar(content: Text('Meal removed from plan')),
                                        );
                                      }
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
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => RecipesPage(),
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

  double _getMealTypeUnderlinePosition() {
    double position = 0;
    for (int i = 0; i < _selectedMealTypeIndex; i++) {
      position += mealTypeLabels[i].length * 9.0 + 24;
    }
    return position;
  }

  Widget _buildMealSection(MealType mealType, String label) {
    final meals = _getMealsForType(mealType);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (meals.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                'No meal planned',
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ),
            )
          else
            ...meals.map((plan) => _buildMealCard(plan)),
        ],
      ),
    );
  }

  Widget _buildMealCard(MealPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.meal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1 serving',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 22),
            onPressed: () => _editMeal(plan),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMealTypeOption(MealType.breakfast),
            _buildMealTypeOption(MealType.lunch),
            _buildMealTypeOption(MealType.dinner),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeOption(MealType mealType) {
    return ListTile(
      leading: Icon(
        _getMealTypeIcon(mealType),
        color: _getMealTypeColor(mealType),
      ),
      title: Text(
        _getMealTypeDisplay(mealType),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _getMealTypeColor(mealType),
        ),
      ),
      onTap: () {
        Navigator.of(context).pop(); // Close the dialog
        _showMealSuggestions(mealType);
      },
    );
  }

  void _showMealSuggestions(MealType mealType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suggestions for ${_getMealTypeDisplay(mealType)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: mealSuggestions.isEmpty
              ? const Text('No suggestions found for this meal type.')
              : ListView(
                  shrinkWrap: true,
                  children: mealSuggestions.map((meal) => ListTile(
                    leading: Icon(
                      _getMealTypeIcon(mealType),
                      color: _getMealTypeColor(mealType),
                    ),
                    title: Text(meal.name),
                            onTap: () {
                      Navigator.of(context).pop(); // Close the dialog
                              _addMealToPlan(meal, mealType, selectedDate);
                    },
                  )).toList(),
          ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getMealTypeDisplay(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  IconData _getMealTypeIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.restaurant;
      case MealType.dinner:
        return Icons.nights_stay;
      case MealType.snack:
        return Icons.coffee;
    }
  }

  Color _getMealTypeColor(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Colors.orange;
      case MealType.lunch:
        return Colors.green;
      case MealType.dinner:
        return Colors.purple;
      case MealType.snack:
        return Colors.blue;
    }
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

  int _getTotalCaloriesForDate() {
    final mealsForDate = mealPlans.where((plan) =>
      plan.date.year == selectedDate.year &&
      plan.date.month == selectedDate.month &&
      plan.date.day == selectedDate.day
    ).toList();
    
    final nutritionalTotals = MealService.calculateNutritionalTotals(mealsForDate);
    return nutritionalTotals['calories']?.toInt() ?? 0;
  }

  int _getTotalMealsForDate() {
    return mealPlans.where((plan) =>
      plan.date.year == selectedDate.year &&
      plan.date.month == selectedDate.month &&
      plan.date.day == selectedDate.day
    ).length;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 

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