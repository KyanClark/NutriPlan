import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../recipes/recipe_info_screen.dart';
import '../../models/recipes.dart';
import '../../widgets/loading_skeletons.dart';
import 'interface/meal_planner_widgets.dart';

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
  bool _isLoading = true;
  String _selectedFilter = 'All';
  bool _isDeleteMode = false;
  final Set<String> _selectedMealsForDeletion = {};

  @override
  void initState() {
    super.initState();
      _fetchSupabaseMealPlans();
    
    // Set up timer for periodic refresh
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
      _fetchSupabaseMealPlans();
    }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MealPlannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceRefresh != oldWidget.forceRefresh && widget.forceRefresh) {
      _fetchSupabaseMealPlans();
    }
  }

  Future<void> _fetchSupabaseMealPlans() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      // Fetch from meal_plans table with recipe details
      final plansResponse = await Supabase.instance.client
          .from('meal_plans')
          .select('*, recipes(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      List<Map<String, dynamic>> allMeals = [];
      
      // Process each meal plan record
      for (final meal in plansResponse) {
        allMeals.add({
          ...meal,
          'plan_id': meal['id'],
          'is_legacy_format': false,
        });
      }
      
      if (mounted) {
        setState(() {
          supabaseMealPlans = allMeals;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching meal plans: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Get filtered meals based on selected filter
  List<Map<String, dynamic>> get _filteredMeals {
    if (_selectedFilter == 'All') {
      return supabaseMealPlans;
    }
    
    return supabaseMealPlans.where((meal) {
      final mealType = meal['meal_type']?.toString().toLowerCase();
      return mealType == _selectedFilter.toLowerCase();
    }).toList();
  }

  /// Delete selected meals
  Future<void> _deleteSelectedMeals() async {
    if (_selectedMealsForDeletion.isEmpty) return;

    try {
      // Delete from Supabase
      await Supabase.instance.client
          .from('meal_plans')
          .delete()
          .inFilter('id', _selectedMealsForDeletion.toList());

      // Show success message
      final deletedCount = _selectedMealsForDeletion.length;
      String message;
      if (deletedCount == 1) {
        // Find the name of the single deleted meal
        final deletedMeal = supabaseMealPlans.firstWhere(
          (meal) => meal['id']?.toString() == _selectedMealsForDeletion.first,
          orElse: () => {'title': 'Unknown'},
        );
        message = '${deletedMeal['title']} deleted successfully';
      } else {
        message = '$deletedCount meals deleted successfully';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Refresh data and exit delete mode
      setState(() {
        _isDeleteMode = false;
        _selectedMealsForDeletion.clear();
      });
      
      await _fetchSupabaseMealPlans();
      
      // Notify parent widget of changes
      widget.onChanged?.call();
      
    } catch (e) {
      print('Error deleting meals: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meals: $e'),
            backgroundColor: const Color(0xFFFF6961),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToRecipe(BuildContext context, String mealId) async {
    final navigatorContext = context;
    final response = await Supabase.instance.client
        .from('recipes')
        .select()
        .eq('id', mealId)
        .maybeSingle();
    if (response == null) return;
    final recipe = Recipe.fromMap(response);
    await Navigator.of(navigatorContext).push(
      MaterialPageRoute(
        builder: (builderContext) => RecipeInfoScreen(
          recipe: recipe,
          showStartCooking: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    
    // iPhone 8 dimensions: 375x667 points
    final isSmallScreen = screenWidth <= 375;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: SafeArea(
            child: Column(
              children: [
            // Enhanced Header with gradient background - Always visible
                          Container(
              width: double.infinity,
                            decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF4CAF50),
                  ],
                ),
                              boxShadow: [
                                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header with title and delete button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meal Planner',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Plan smarter, eat better',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Delete mode toggle button
                        IconButton(
                              onPressed: () {
                                setState(() {
                              _isDeleteMode = !_isDeleteMode;
                              if (!_isDeleteMode) {
                                    _selectedMealsForDeletion.clear();
                                  }
                                });
                              },
                          icon: Icon(
                            _isDeleteMode ? Icons.close : Icons.delete_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                              tooltip: _isDeleteMode ? 'Cancel Delete' : 'Delete Meals',
                            ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Filter buttons with enhanced design
                    if (supabaseMealPlans.isNotEmpty)
                      MealPlannerFilterButtons(
                        selectedFilter: _selectedFilter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        isSmallScreen: isSmallScreen,
                          ),
                      ],
                    ),
                  ),
            ),
            // Content area with loading state
            Expanded(
              child: _isLoading 
                  ? RecipeListSkeleton(
                      itemCount: 6,
                      loadingMessage: 'Loading your meal plans...',
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                            // Delete mode controls
                        if (_isDeleteMode) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6961).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF6961).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: const Color(0xFFFF6961),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${_selectedMealsForDeletion.length} meal${_selectedMealsForDeletion.length != 1 ? 's' : ''} selected for deletion',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFFF6961),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                      ],
                    ),
                  ),
                              const SizedBox(height: 20),
                            ],
                            // Meal grid
                if (supabaseMealPlans.isNotEmpty)
                              if (_filteredMeals.isNotEmpty)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isSmallScreen ? 1 : 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: isSmallScreen ? 1.2 : 0.8,
                                  ),
                          itemCount: _filteredMeals.length,
                                  itemBuilder: (context, index) {
                                    final meal = _filteredMeals[index];
                                    final mealId = meal['id']?.toString() ?? '';
                                    final isSelected = _selectedMealsForDeletion.contains(mealId);
                                    
                                    // Extract recipe data from nested structure
                                    final recipeData = meal['recipes'];
                                    final recipeId = recipeData?['id']?.toString() ?? mealId;
                                    
                                    return MealPlannerRecipeCard(
                                      recipe: Recipe(
                                        id: recipeId,
                                        title: recipeData?['title'] ?? meal['title'] ?? 'Unknown Recipe',
                                        shortDescription: recipeData?['short_description'] ?? '',
                                        ingredients: List<String>.from(recipeData?['ingredients'] ?? []),
                                        instructions: List<String>.from(recipeData?['instructions'] ?? []),
                                        macros: Map<String, dynamic>.from(recipeData?['macros'] ?? {}),
                                        allergyWarning: recipeData?['allergy_warning'] ?? '',
                                        calories: recipeData?['calories'] ?? 0,
                                        dietTypes: List<String>.from(recipeData?['diet_types'] ?? []),
                                        cost: (recipeData?['cost'] ?? 0).toDouble(),
                                        imageUrl: recipeData?['image_url'] ?? '',
                                      ),
                                      mealType: meal['meal_type'],
                                      mealTime: meal['meal_time'],
                                      isSmallScreen: isSmallScreen,
                                      isDeleteMode: _isDeleteMode,
                                      isSelected: isSelected,
                                      onTap: () {
                                         if (_isDeleteMode) {
                                           setState(() {
                                            if (isSelected) {
                                               _selectedMealsForDeletion.remove(mealId);
                                             } else {
                                               _selectedMealsForDeletion.add(mealId);
                                             }
                                           });
                                        } else {
                                          _navigateToRecipe(context, recipeId);
                                        }
                                      },
                                    );
                                  },
                                )
                              else
                                const MealPlannerEmptyFilterState()
                            else
                              const MealPlannerEmptyState(),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      floatingActionButton: _isDeleteMode
        ? Padding(
         padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton.extended(
               onPressed: _selectedMealsForDeletion.isEmpty ? null : _deleteSelectedMeals,
               icon: const Icon(Icons.delete, color: Colors.white),
               label: const Text(
                 'Delete',
                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
               ),
               backgroundColor: const Color(0xFFFF6961),
            ),
          )
        : null, // Removed "Add Meal Plan" button - now using elevated plus button in bottom navigation
    );
  }
} 