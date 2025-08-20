import 'package:flutter/material.dart';
import 'dart:async';
import 'recipes_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'recipe_info_screen.dart';
import '../models/recipes.dart';

class MealPlannerScreen extends StatefulWidget {
  final bool forceRefresh;
  final VoidCallback? onChanged;
  const MealPlannerScreen({super.key, this.forceRefresh = false, this.onChanged});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  DateTime selectedDate = DateTime.now();
  Timer? _timer;

  // Add state for Supabase meal plans
  List<Map<String, dynamic>> supabaseMealPlans = [];

  // Flattened list of meals for GridView
  List<Map<String, dynamic>> get _flattenedMeals {
    List<Map<String, dynamic>> meals = [];
    for (final plan in supabaseMealPlans) {
      final planMeals = List<Map<String, dynamic>>.from(plan['meals'] ?? []);
      for (final meal in planMeals) {
        meals.add({
          ...meal,
          'plan_id': plan['id'],
        });
      }
    }
    return meals;
  }

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
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
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



  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    
    // iPhone 8 dimensions: 375x667 points
    final isSmallScreen = screenWidth <= 375;
    
    return Scaffold(
      backgroundColor: const Color(0xFFC1E7AF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                        fontSize: isSmallScreen ? 22 : 24,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12.0 : 16.0, 
                      vertical: 8
                    ),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isSmallScreen ? 1 : 2, // Single column on small screens
                        crossAxisSpacing: isSmallScreen ? 0 : 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isSmallScreen ? 1.2 : 0.8, // Taller cards on small screens
                      ),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _flattenedMeals.length,
                      itemBuilder: (context, idx) {
                        final meal = _flattenedMeals[idx];
                        final planId = meal['plan_id'];
                        return Stack(
                          key: ValueKey('${meal['recipe_id']}_$planId'),
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
                                  mealType: meal['meal_type'],
                                  mealTime: meal['time'],
                                  isFavorite: false,
                                  isSmallScreen: isSmallScreen,
                                  onTap: () async {
                                    final recipeId = meal['recipe_id'] ?? '';
                                    if (recipeId.isEmpty) return;
                                    final navigatorContext = context;
                                    final response = await Supabase.instance.client
                                      .from('recipes')
                                      .select()
                                      .eq('id', recipeId)
                                      .maybeSingle();
                                    if (response == null) return;
                                    final recipe = Recipe.fromMap(response);
                                    if (!mounted) return;
                                    await Navigator.of(navigatorContext).push(
                                      MaterialPageRoute(
                                        builder: (builderContext) => RecipeInfoScreen(
                                          recipe: recipe,
                                          showStartCooking: true,
                                        ),
                                      ),
                                    );
                                    // Always refresh after returning from the recipe page
                                    await _fetchSupabaseMealPlans();
                                    if (widget.onChanged != null) widget.onChanged!();
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  tooltip: 'Delete Meal Plan',
                                  onPressed: () async {
                                    final dialogContext = context;
                                    final confirm = await showDialog<bool>(
                                      context: dialogContext,
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
                                    final planMeals = List<Map<String, dynamic>>.from(supabaseMealPlans.firstWhere((p) => p['id'] == planId)['meals'] ?? []);
                                    final mealIdToDelete = meal['recipe_id'];
                                    planMeals.removeWhere((m) => m['recipe_id'] == mealIdToDelete);
                                    if (planMeals.isEmpty) {
                                      // Delete the whole meal plan row if no meals left
                                      await Supabase.instance.client.from('meal_plans').delete().eq('id', planId);
                                      if (!mounted) return;
                                      setState(() {
                                        supabaseMealPlans.removeWhere((p) => p['id'] == planId);
                                      });
                                      ScaffoldMessenger.of(dialogContext).showSnackBar(
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
                                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                                        const SnackBar(content: Text('Meal removed from plan'), duration: Duration(seconds: 3)),
                                      );
                                    }
                                    if (widget.onChanged != null) widget.onChanged!();
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final navigatorContext = context;
            await Navigator.of(navigatorContext).push(
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
}

// Paste the _RecipeCard widget here for use in meal planner
class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String? mealType;
  final String? mealTime;
  final bool isFavorite;
  final VoidCallback? onTap;
  final bool isSmallScreen;
  const _RecipeCard({
    required this.recipe, 
    this.mealType, 
    this.mealTime, 
    this.isFavorite = false, 
    this.onTap,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isSmallScreen ? constraints.maxWidth * 0.95 : constraints.maxWidth < 220 ? constraints.maxWidth : 200.0;
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
                    color: Colors.black.withValues(alpha: 0.08),
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
                          height: isSmallScreen ? 140 : 120, // Taller image on small screens
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: isSmallScreen ? 140 : 120,
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image, size: isSmallScreen ? 32 : 24),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 16 : 18,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (mealType != null && mealType!.isNotEmpty) ...[
                              SizedBox(height: isSmallScreen ? 6 : 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 10 : 8, 
                                  vertical: isSmallScreen ? 6 : 4
                                ),
                                decoration: BoxDecoration(
                                  color: _getMealTypeColor(mealType!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  mealType!.capitalize(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 11 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (mealTime != null && mealTime!.isNotEmpty) ...[
                              SizedBox(height: isSmallScreen ? 6 : 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time, 
                                    size: isSmallScreen ? 16 : 14, 
                                    color: Colors.grey[600]
                                  ),
                                  SizedBox(width: isSmallScreen ? 6 : 4),
                                  Text(
                                    mealTime!,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if ((mealType == null || mealType!.isEmpty) && (mealTime == null || mealTime!.isEmpty)) ...[
                              SizedBox(height: isSmallScreen ? 6 : 4),
                              Text(
                                'No meal type/time set',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
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

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.amber;
      case 'dinner':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 