import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../recipes/recipe_info_screen.dart';
import '../../models/recipes.dart';
import 'backend/meal_planner_service.dart';
import 'interface/meal_planner_widgets.dart';
import 'cubit/meal_plan_cubit.dart';

class MealPlannerScreen extends StatefulWidget {
  final bool forceRefresh;
  final VoidCallback? onChanged;
  const MealPlannerScreen({super.key, this.forceRefresh = false, this.onChanged});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {

  // Add state for Supabase meal plans
  List<Map<String, dynamic>> supabaseMealPlans = [];
  
  // Add filter state
  String _selectedFilter = 'all'; // 'all', 'breakfast', 'lunch', 'dinner'
  
  // Delete mode and selection now managed by MealPlanCubit
  
  // Add loading state
  bool _isLoading = true;

  // Handle meals from both meal_plan_history and meal_plans tables
  List<Map<String, dynamic>> get _flattenedMeals {
    List<Map<String, dynamic>> allMeals = [];
    
    for (final meal in supabaseMealPlans) {
      // Each meal is already a separate record from either table
          allMeals.add({
            ...meal,
        'plan_id': meal['id'], // Use the meal's own ID as plan_id for deletion
          'is_legacy_format': false,
        });
    }
    
    return allMeals;
  }

  // Get filtered meals based on selected filter
  List<Map<String, dynamic>> get _filteredMeals {
    return MealPlannerService.getFilteredMeals(_flattenedMeals, _selectedFilter);
   }

  /// Delete selected meals
  Future<void> _deleteSelectedMeals() async {
    final selectedIdSet = context.read<MealPlanCubit>().state.selectedMealIds;
    if (selectedIdSet.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Meals'),
        content: Text('Are you sure you want to delete ${selectedIdSet.length} meal(s) from your plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6961)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Capture selection details BEFORE clearing
    final selectedIds = context.read<MealPlanCubit>().state.selectedMealIds.toList();
    final selectedCount = selectedIds.length;
    String? singleDeletedName;
    if (selectedCount == 1) {
      final selectedId = selectedIds.first;
      final matching = _flattenedMeals.firstWhere(
        (m) => m['id'] == selectedId,
        orElse: () => {},
      );
      singleDeletedName = (matching['title'] ?? matching['recipe_name'])?.toString();
    }

    final success = await MealPlannerService.deleteSelectedMeals(selectedIds);

    if (mounted) {
      // Build message using captured info
      final message = success
          ? (selectedCount == 1 && (singleDeletedName != null && singleDeletedName.trim().isNotEmpty)
              ? '"$singleDeletedName" deleted successfully'
              : '$selectedCount meal(s) deleted successfully')
          : 'Error deleting meals';

      context.read<MealPlanCubit>().setDeleteMode(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : const Color(0xFFFF6961),
        ),
      );

      // Refresh meal plans after deletion
      await _fetchSupabaseMealPlans();
      if (widget.onChanged != null) widget.onChanged!();
    }
  }

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  Future<void> _fetchSupabaseMealPlans() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    final meals = await MealPlannerService.fetchMealPlans();
      
      if (mounted) {
        setState(() {
        supabaseMealPlans = meals;
        _isLoading = false;
      });
    }
  }





  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    
    // iPhone 8 dimensions: 375x667 points
    final isSmallScreen = screenWidth <= 375;
    
    return BlocProvider(
      create: (_) => MealPlanCubit(),
      child: Scaffold(
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
                    Color(0xFF4CAF50),
                    Color(0xFF66BB6A),
                    Color(0xFF81C784),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
                     child: Padding(
                  padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                      // Header with title and delete button
                      Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                              'My Meal Plan',
                              style: TextStyle(
                                    fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${supabaseMealPlans.length} meal${supabaseMealPlans.length != 1 ? 's' : ''} planned',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                          ),
                        ),
                        if (supabaseMealPlans.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                context.read<MealPlanCubit>().state.isDeleteMode ? Icons.close : Icons.delete_outline,
                                  color: Colors.white,
                                  size: 22,
                              ),
                              onPressed: () {
                                final cubit = context.read<MealPlanCubit>();
                                final current = cubit.state.isDeleteMode;
                                cubit.setDeleteMode(!current);
                              },
                              tooltip: context.read<MealPlanCubit>().state.isDeleteMode ? 'Cancel Delete' : 'Delete Meals',
                            ),
                          ),
                      ],
                    ),
                      const SizedBox(height: 20),
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Delete mode controls
                        if (context.watch<MealPlanCubit>().state.isDeleteMode) ...[
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
                                    '${context.watch<MealPlanCubit>().state.selectedMealIds.length} meal${context.watch<MealPlanCubit>().state.selectedMealIds.length != 1 ? 's' : ''} selected for deletion',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFF6961),
                                    ),
                                  ),
                                ),
                      ],
                    ),
                  ),
                            const SizedBox(height: 20),
                          ],
                          // Display Supabase meal plans
                if (supabaseMealPlans.isNotEmpty)
                  _filteredMeals.isNotEmpty
                              ? GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isSmallScreen ? 1 : 2,
                                    crossAxisSpacing: 16,
                            mainAxisSpacing: 20,
                                    childAspectRatio: isSmallScreen ? 1.3 : 0.8,
                          ),
                          shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredMeals.length,
                          itemBuilder: (context, idx) {
                            final meal = _filteredMeals[idx];
                            final planId = meal['plan_id'];
                            return Stack(
                              key: ValueKey('${meal['recipe_id']}_$planId'),
                              children: [
                                        MealPlannerRecipeCard(
                                      recipe: Recipe(
                                        id: meal['recipe_id'] ?? '',
                                        title: meal['title'] ?? 'Unknown Recipe',
                                        imageUrl: meal['recipes']?['image_url'] ?? '',
                                        calories: meal['recipes']?['calories'] ?? 0,
                                        cost: (meal['recipes']?['cost'] ?? 0.0).toDouble(),
                                        shortDescription: meal['recipes']?['short_description'] ?? '',
                                        dietTypes: List<String>.from(meal['recipes']?['diet_types'] ?? []),
                                        macros: Map<String, dynamic>.from(meal['recipes']?['macros'] ?? {
                                          'protein': 0.0,
                                          'carbs': 0.0,
                                          'fat': 0.0,
                                          'fiber': 0.0,
                                          'sugar': 0.0,
                                          'sodium': 0.0,
                                          'cholesterol': 0.0,
                                        }),
                                        allergyWarning: meal['recipes']?['allergy_warning'] ?? '',
                                        ingredients: List<String>.from(meal['recipes']?['ingredients'] ?? []),
                                        instructions: List<String>.from(meal['recipes']?['instructions'] ?? []),
                                      ),
                                          mealType: meal['meal_type'] ?? 'dinner',
                                          mealTime: meal['meal_time'] != null ? MealPlannerService.formatMealTime(meal['meal_time']) : null,
                                      isFavorite: false,
                                      isSmallScreen: isSmallScreen,
                                          isDeleteMode: context.watch<MealPlanCubit>().state.isDeleteMode,
                                          isSelected: context.watch<MealPlanCubit>().state.selectedMealIds.contains(meal['id']),
                                                                             onTap: () async {
                                         if (context.read<MealPlanCubit>().state.isDeleteMode) {
                                           final mealId = meal['id'];
                                           context.read<MealPlanCubit>().toggleSelect(mealId);
                                           return;
                                         }
                                         
                                         final recipeId = meal['recipe_id'];
                                         if (recipeId == null || recipeId.isEmpty) return;
                                         
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
                                         await _fetchSupabaseMealPlans();
                                         if (widget.onChanged != null) widget.onChanged!();
                                       },
                                    ),
                              ],
                            );
                          },
                                )
                              : const MealPlannerEmptyFilterState()
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
             floatingActionButton: context.watch<MealPlanCubit>().state.isDeleteMode
           ? Padding(
         padding: const EdgeInsets.only(bottom: 16.0),
               child: FloatingActionButton.extended(
               onPressed: context.read<MealPlanCubit>().state.selectedMealIds.isEmpty ? null : _deleteSelectedMeals,
               icon: const Icon(Icons.delete, color: Colors.white),
               label: const Text(
                 'Delete',
                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
               ),
               backgroundColor: const Color(0xFFFF6961),
               ),
             )
           : null, // Removed "Add Meal Plan" button - now using elevated plus button in bottom navigation
    ),
    );
  }
} 