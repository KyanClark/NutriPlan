import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../recipes/recipe_info_screen.dart';
import '../../models/recipes.dart';
import '../recipes/recipes_page.dart';

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
  
  // Add delete mode state
  bool _isDeleteMode = false;
  Set<String> _selectedMealsForDeletion = {};

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
    if (_selectedFilter == 'all') {
      return _flattenedMeals;
    }
    return _flattenedMeals.where((meal) => meal['meal_type'] == _selectedFilter).toList();
  }

  /// Build filter buttons for meal types
  Widget _buildFilterButtons(bool isSmallScreen) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'breakfast', 'label': 'Breakfast'},
      {'key': 'lunch', 'label': 'Lunch'},
      {'key': 'dinner', 'label': 'Dinner'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                filter['label'] as String,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              backgroundColor: Colors.white,
              selectedColor: Colors.grey[800],
              side: BorderSide(
                color: Colors.grey[400]!,
                width: 1.5,
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

     /// Build delete mode controls
   Widget _buildDeleteModeControls() {
     return Row(
       mainAxisAlignment: MainAxisAlignment.end,
       children: [
         Text(
           '${_selectedMealsForDeletion.length} meal(s) selected',
           style: const TextStyle(
             fontSize: 14,
             fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6961),
           ),
         ),
       ],
     );
   }

  /// Delete selected meals
  Future<void> _deleteSelectedMeals() async {
    if (_selectedMealsForDeletion.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Meals'),
        content: Text('Are you sure you want to delete ${_selectedMealsForDeletion.length} meal(s) from your plan?'),
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

    try {
      for (final mealId in _selectedMealsForDeletion) {
        await Supabase.instance.client.from('meal_plans').delete().eq('id', mealId);
      }

      if (mounted) {
        setState(() {
          _isDeleteMode = false;
          _selectedMealsForDeletion.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedMealsForDeletion.length} meal(s) deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh meal plans after deletion
        await _fetchSupabaseMealPlans();
        if (widget.onChanged != null) widget.onChanged!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meals: $e'),
                           backgroundColor: const Color(0xFFFF6961),
          ),
        );
      }
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
        });
      }
    } catch (e) {
      print('Error fetching meal plans: $e');
    }
  }

  /// Format meal time from database TIME format to readable string
  String? _formatMealTime(String? timeString) {
    if (timeString == null) return null;
    
    try {
      // Parse time string like "08:30:00" to "8:30 AM"
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        final timeOfDay = TimeOfDay(hour: hour, minute: minute);
        return timeOfDay.format(context);
      }
    } catch (e) {
      print('Error formatting meal time: $e');
    }
    
    return timeString; // Return original if parsing fails
  }



  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    
    // iPhone 8 dimensions: 375x667 points
    final isSmallScreen = screenWidth <= 375;
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 181, 243, 152),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
                     child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Column(
              children: [
                                                  // Header with 'My Meal Plan' text and delete button inline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              'My Meal Plan',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 22 : 24,
                                fontWeight: FontWeight.bold,
                              color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ),
                        if (supabaseMealPlans.isNotEmpty)
                          Container(
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
                              icon: Icon(
                                _isDeleteMode ? Icons.close : Icons.delete_outline,
                                color: _isDeleteMode ? const Color(0xFFFF6961) : Colors.grey[700],
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_isDeleteMode) {
                                    // Exit delete mode
                                    _isDeleteMode = false;
                                    _selectedMealsForDeletion.clear();
                                  } else {
                                    // Enter delete mode
                                    _isDeleteMode = true;
                                  }
                                });
                              },
                              tooltip: _isDeleteMode ? 'Cancel Delete' : 'Delete Meals',
                            ),
                          ),
                      ],
                    ),
                  ),
                                 // Filter buttons
                 if (supabaseMealPlans.isNotEmpty)
                   Padding(
                     padding: EdgeInsets.symmetric(
                       horizontal: isSmallScreen ? 12.0 : 16.0,
                       vertical: 4,
                     ),
                    child: Column(
                      children: [
                        _buildFilterButtons(isSmallScreen),
                        if (_isDeleteMode) ...[
                          const SizedBox(height: 12),
                          _buildDeleteModeControls(),
                        ],
                      ],
                    ),
                  ),
                // Display Supabase meal plans below
                if (supabaseMealPlans.isNotEmpty)
                  _filteredMeals.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12.0 : 20.0, 
                          vertical: 8
                        ),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isSmallScreen ? 1 : 2, // Single column on small screens
                            crossAxisSpacing: isSmallScreen ? 0 : 12,
                            mainAxisSpacing: 20,
                            childAspectRatio: isSmallScreen ? 1.4 : 0.8, // Fixed aspect ratio for consistent sizing
                          ),
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _filteredMeals.length,
                          itemBuilder: (context, idx) {
                            final meal = _filteredMeals[idx];
                            final planId = meal['plan_id'];
                            return Stack(
                              key: ValueKey('${meal['recipe_id']}_$planId'),
                              children: [
                                Column(
                                  children: [
                                    _RecipeCard(
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
                                      mealType: meal['meal_type'] ?? 'dinner', // Use actual meal type from database
                                      mealTime: meal['meal_time'] != null ? _formatMealTime(meal['meal_time']) : null,
                                      isFavorite: false,
                                      isSmallScreen: isSmallScreen,
                                                                             onTap: () async {
                                         // If in delete mode, handle selection instead of navigation
                                         if (_isDeleteMode) {
                                           setState(() {
                                             final mealId = meal['id'];
                                             if (_selectedMealsForDeletion.contains(mealId)) {
                                               _selectedMealsForDeletion.remove(mealId);
                                             } else {
                                               _selectedMealsForDeletion.add(mealId);
                                             }
                                           });
                                           return;
                                         }
                                         
                                         // Use recipe_id directly since we now have it
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
                                         // Always refresh after returning from the recipe page
                                         await _fetchSupabaseMealPlans();
                                         if (widget.onChanged != null) widget.onChanged!();
                                       },
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                                                                 // Show selection checkbox when in delete mode, otherwise show delete button
                                 if (_isDeleteMode)
                                   Positioned(
                                     top: 8,
                                     left: 8,
                                     child: Container(
                                       width: 24,
                                       height: 24,
                                       decoration: BoxDecoration(
                                         color: _selectedMealsForDeletion.contains(meal['id']) 
                                           ? const Color(0xFFFF6961) 
                                           : Colors.white,
                                         borderRadius: BorderRadius.circular(12),
                                         border: Border.all(
                                           color: const Color(0xFFFF6961),
                                           width: 2,
                                         ),
                                       ),
                                       child: _selectedMealsForDeletion.contains(meal['id'])
                                         ? const Icon(
                                             Icons.check,
                                             color: Colors.white,
                                             size: 16,
                                           )
                                         : null,
                                     ),
                                   )

                              ],
                            );
                          },
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12.0 : 16.0,
                          vertical: 32.0,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 30),
                              Text(
                                'No meals found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 54, 54, 54),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try changing the filter or add more meals',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                // Show empty state when no meal plans
                else
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12.0 : 16.0,
                      vertical: 32.0,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Meal Plans Added',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                                                      Text(
                              'Start planning your meals by adding recipes to your meal planner',
                              style: TextStyle(
                                fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                                                     const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
             floatingActionButton: Padding(
         padding: const EdgeInsets.only(bottom: 16.0),
         child: _isDeleteMode
           ? FloatingActionButton.extended(
               onPressed: _selectedMealsForDeletion.isEmpty ? null : _deleteSelectedMeals,
               icon: const Icon(Icons.delete, color: Colors.white),
               label: const Text(
                 'Delete',
                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
               ),
               backgroundColor: const Color(0xFFFF6961),
             )
           : FloatingActionButton.extended(
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
                 'Add Meal Plan',
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
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
                      height: isSmallScreen ? 160 : 130, // Fixed height for consistency
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: isSmallScreen ? 160 : 130,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, size: isSmallScreen ? 32 : 24),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
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
                          if (mealType != null && mealType!.isNotEmpty || mealTime != null && mealTime!.isNotEmpty) ...[
                            SizedBox(height: isSmallScreen ? 6 : 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (mealType != null && mealType!.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 6, 
                                      vertical: isSmallScreen ? 4 : 3
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getMealTypeColor(mealType!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      mealType!.capitalize(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 10 : 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (mealTime != null && mealTime!.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 6 : 5, 
                                      vertical: isSmallScreen ? 4 : 3
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time, 
                                          size: isSmallScreen ? 12 : 11, 
                                          color: Colors.grey[600]
                                        ),
                                        SizedBox(width: isSmallScreen ? 4 : 3),
                                        Text(
                                          mealTime!,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 11,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ] else ...[
                            SizedBox(height: isSmallScreen ? 6 : 4),
                            Text(
                              'No meal type/time set',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

extension MealPlannerStringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 