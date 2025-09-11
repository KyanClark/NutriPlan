import 'package:flutter/material.dart';
import '../../models/recipes.dart';
import '../../services/recipe_service.dart';
import 'package:nutriplan/screens/recipes/recipe_info_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'see_all_recipe.dart';
import 'package:nutriplan/screens/meal_plan/meal_summary_page.dart';
import 'package:nutriplan/screens/meal_plan/meal_plan_confirmation_page.dart';
// import 'package:nutriplan/screens/home/home_page.dart';

class RecipesPage extends StatefulWidget {
  final VoidCallback? onChanged;
  // Optional: preselect meals so the bottom bar is populated on open
  final List<Recipe> preselectedMeals;
  const RecipesPage({super.key, this.onChanged, this.preselectedMeals = const []});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  Set<String> favoriteRecipeIds = {};
  String? get userId => Supabase.instance.client.auth.currentUser?.id;
  String _sortOption = 'None';
  String searchQuery = '';
  bool showSearch = false;

  // State for recipes added to meal plan (multiple supported)
  final List<Recipe> _mealsForPlan = [];

  // GlobalKey for ScaffoldMessenger
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> _fetchFavorites() async {
    if (userId == null) return;
    final ids = await RecipeService.fetchFavoriteRecipeIds(userId!);
    if (!mounted) return;
    setState(() {
      favoriteRecipeIds = ids.toSet();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
    // Preload any preselected meals into the plan builder
    if (widget.preselectedMeals.isNotEmpty) {
      _mealsForPlan.addAll(widget.preselectedMeals);
    }
  }

  List<Recipe> _applySearchAndSort(List<Recipe> recipes) {
    List<Recipe> filtered = recipes;
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((r) => r.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    switch (_sortOption) {
      case 'Price (Low to High)':
        filtered.sort((a, b) => a.cost.compareTo(b.cost));
        break;
      case 'Price (High to Low)':
        filtered.sort((a, b) => b.cost.compareTo(a.cost));
        break;
      case 'Calories (Low to High)':
        filtered.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case 'Calories (High to Low)':
        filtered.sort((a, b) => b.calories.compareTo(a.calories));
        break;
      case 'Highest Protein':
        filtered.sort((a, b) => ((b.macros['protein'] ?? 0) as num).compareTo((a.macros['protein'] ?? 0) as num));
        break;
      case 'Lowest Carbs':
        filtered.sort((a, b) => ((a.macros['carbs'] ?? 0) as num).compareTo((b.macros['carbs'] ?? 0) as num));
        break;
      case 'Allergy Friendly':
        filtered = filtered.where((r) => (r.allergyWarning.isEmpty)).toList();
        break;
      default:
        break;
    }
    return filtered;
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    if (userId == null) return;
    final isFav = favoriteRecipeIds.contains(recipe.id);
    await RecipeService.toggleFavorite(userId!, recipe.id, isFav);
    if (!mounted) return;
    await _fetchFavorites();
    if (widget.onChanged != null) widget.onChanged!();
  }

  void _addToMealPlan(Recipe recipe) {
    // Check if recipe is already in meal plan
    if (_mealsForPlan.any((meal) => meal.id == recipe.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${recipe.title} is already in your meal plan!',
            style: const TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Add recipe to meal plan
    setState(() {
      _mealsForPlan.add(recipe);
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${recipe.title} added to meal plan!',
          style: const TextStyle(fontFamily: 'Geist'),
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View Plan',
          textColor: Colors.white,
          onPressed: () {
            // Scroll to bottom to show the Build Meal Plan button
            // This will be handled by the UI automatically
          },
        ),
      ),
    );
  }

  void _removeFromMealPlan(Recipe recipe) {
    setState(() {
      _mealsForPlan.removeWhere((meal) => meal.id == recipe.id);
    });

    // Show removal message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${recipe.title} removed from meal plan',
          style: const TextStyle(fontFamily: 'Geist'),
        ),
                       backgroundColor: const Color(0xFFFF6961),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _mealsForPlan.add(recipe);
            });
          },
        ),
      ),
    );
  }

  // Helper methods for recipe categorization
  List<Recipe> _getFilipinoRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.dietTypes.contains('Filipino Cuisine') ||
      recipe.title.toLowerCase().contains('sinigang') ||
      recipe.title.toLowerCase().contains('adobo') ||
      recipe.title.toLowerCase().contains('sisig') ||
      recipe.title.toLowerCase().contains('kaldereta') ||
      recipe.title.toLowerCase().contains('tinola') ||
      recipe.title.toLowerCase().contains('monggo') ||
      recipe.title.toLowerCase().contains('afritada')
    ).toList();
  }

  List<Recipe> _getSoupRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.dietTypes.contains('Soup') ||
      recipe.title.toLowerCase().contains('sinigang') ||
      recipe.title.toLowerCase().contains('tinola') ||
      recipe.title.toLowerCase().contains('monggo') ||
      recipe.title.toLowerCase().contains('soup')
    ).toList();
  }

  List<Recipe> _getMeatSeafoodRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.dietTypes.contains('High Protein') ||
      recipe.title.toLowerCase().contains('chicken') ||
      recipe.title.toLowerCase().contains('beef') ||
      recipe.title.toLowerCase().contains('pork') ||
      recipe.title.toLowerCase().contains('shrimp') ||
      recipe.title.toLowerCase().contains('fish') ||
      recipe.title.toLowerCase().contains('bangus') ||
      recipe.title.toLowerCase().contains('hipon')
    ).toList();
  }

  Widget _buildRecipeSection(String title, List<Recipe> recipes, int totalCount) {
    if (recipes.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Text(
              title,
              style: const TextStyle(
                    fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Geist',
              ),
            ),
            Row(
              children: [
                Text(
                  '${recipes.length} recipes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Geist',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => SeeAllRecipePage(
                          addedRecipeIds: _mealsForPlan.map((m) => m.id).toList(),
                          onAddToMealPlan: _addToMealPlan,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);
                          
                          return SlideTransition(
                            position: offsetAnimation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Geist',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Horizontal scrolling recipe list
            SizedBox(
          height: 280,
          child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
              final isFavorite = favoriteRecipeIds.contains(recipe.id);
              
              return GestureDetector(
                onTap: () {
                  // Navigate directly to recipe info
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeInfoScreen(
                        recipe: recipe,
                        addedRecipeIds: _mealsForPlan.map((m) => m.id).toList(),
                        onAddToMealPlan: _addToMealPlan,
                      ),
                    ),
                  );
                },

                      // RECIPE CARD //

                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipe image
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                  decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: NetworkImage(recipe.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Heart icon
                            Positioned(
                              top: 20,
                              right: 20,
                              child: GestureDetector(
                                onTap: () => _toggleFavorite(recipe),
                    child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? const Color(0xFFFF6961) : Colors.grey,
                                    size: 25,
                                  ),
                              ),
                            ),
                          ),
                            // Meal Plan indicator (if recipe is in meal plan)
                            if (_mealsForPlan.any((meal) => meal.id == recipe.id))
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            // Calories and cost overlay
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${recipe.calories} kcal',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Geist',
                                      ),
                                    ),
                                    Text(
                                      '₱${recipe.cost.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Geist',
                                      ),
                                    ),
                        ],
                      ),
                    ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Recipe title
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            recipe.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontFamily: 'Geist',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                  ),
              ),
            ),
          ],
        ),
      ),
    );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
  return ScaffoldMessenger(
    key: _scaffoldMessengerKey,
    child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // Check if there are active meals and show confirmation dialog
            if (_mealsForPlan.isNotEmpty) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text(
                      'Unsaved Changes',
                      style: TextStyle(fontFamily: 'Geist'),
                    ),
                    content: const Text(
                      'You have meals added to your plan. Are you sure you want to go back? Your changes will be lost.',
                      style: TextStyle(fontFamily: 'Geist'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontFamily: 'Geist'),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Go Back',
                          style: TextStyle(fontFamily: 'Geist'),
                        ),
                      ),
                    ],
                  );
                },
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Choose your Meal Plan',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Geist',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () => setState(() => showSearch = !showSearch),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, color: Colors.black),
            onSelected: (String value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'None',
                child: Text('None', style: TextStyle(fontFamily: 'Geist')),
              ),
              const PopupMenuItem(
                value: 'Price (Low to High)',
                child: Text('Price (Low to High)', style: TextStyle(fontFamily: 'Geist')),
              ),
              const PopupMenuItem(
                value: 'Price (High to Low)',
                child: Text('Price (High to Low)', style: TextStyle(fontFamily: 'Geist')),
              ),
              const PopupMenuItem(
                value: 'Calories (Low to High)',
                child: Text('Calories (Low to High)', style: TextStyle(fontFamily: 'Geist')),
              ),
              const PopupMenuItem(
                value: 'Calories (High to Low)',
                child: Text('Calories (High to Low)', style: TextStyle(fontFamily: 'Geist')),
              ),
              const PopupMenuItem(
                value: 'Highest Protein',
                child: Text('Highest Protein', style: TextStyle(fontFamily: 'Geist')),
              ),
              const PopupMenuItem(
                value: 'Lowest Carbs',
                child: Text('Lowest Carbs', style: TextStyle(fontFamily: 'Geist')),
              ),
              const PopupMenuItem(
                value: 'Allergy Friendly',
                child: Text('Allergy Friendly', style: TextStyle(fontFamily: 'Geist')),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (if shown)
          if (showSearch)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                autofocus: true,
                style: const TextStyle(fontFamily: 'Geist'),
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  hintStyle: const TextStyle(fontFamily: 'Geist'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (val) => setState(() => searchQuery = val),
              ),
            ),

          // Main content
          Expanded(
            child: FutureBuilder<List<Recipe>>(
              future: RecipeService.fetchRecipes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(fontFamily: 'Geist'),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No recipes found',
                      style: TextStyle(fontFamily: 'Geist'),
                    ),
                  );
                }

                final allRecipes = snapshot.data!;
                final filteredRecipes = _applySearchAndSort(allRecipes);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // All Recipes header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Recipes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontFamily: 'Geist',
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${allRecipes.length} recipes',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: 'Geist',
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          SeeAllRecipePage(
                                        addedRecipeIds: _mealsForPlan.map((m) => m.id).toList(),
                                        onAddToMealPlan: _addToMealPlan,
                                      ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOut;

                                        var tween = Tween(begin: begin, end: end).chain(
                                          CurveTween(curve: curve),
                                        );
                                        var offsetAnimation = animation.drive(tween);

                                        return SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(milliseconds: 300),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'See All',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Geist',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 50),

                      // Recently Added Recipes - Horizontal Scroll
                      _buildRecipeSection(
                        'Recently Added',
                        filteredRecipes.take(10).toList(),
                        allRecipes.length,
                      ),

                      const SizedBox(height: 24),

                      // Filipino Favorites
                      _buildRecipeSection(
                        'Filipino Favorites',
                        _getFilipinoRecipes(filteredRecipes),
                        _getFilipinoRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Soups & Stews
                      _buildRecipeSection(
                        'Soups & Stews',
                        _getSoupRecipes(filteredRecipes),
                        _getSoupRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Meat & Seafood
                      _buildRecipeSection(
                        'Meat & Seafood',
                        _getMeatSeafoodRecipes(filteredRecipes),
                        _getMeatSeafoodRecipes(filteredRecipes).length,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Build Meal Plan button (only if meals are added)
          if (_mealsForPlan.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left side: scrollable meal images
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _mealsForPlan.map(
                        (meal) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  meal.imageUrl,
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.restaurant, color: Colors.grey, size: 20),
                                  ),
                                ),
                              ),
                              // Remove button overlay - positioned to overlap with image edge like a badge
                              Positioned(
                                top: -8,
                                right: -8,
                                child: GestureDetector(
                                  onTap: () => _removeFromMealPlan(meal),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: const Color(0xFFFF6961),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                      ),
                    ),
                  ),
                  // Right side: Build Meal Plan button
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MealSummaryPage(
                            meals: _mealsForPlan,
                            onBuildMealPlan: (mealsWithTime) async {
                              final userId = Supabase.instance.client.auth.currentUser?.id;
                              if (userId != null) {
                                for (final m in mealsWithTime) {
                                  try {
                                    // Insert one row per meal (new format) with required date and time
                                    await Supabase.instance.client
                                        .from('meal_plans')
                                        .insert({
                                          'user_id': userId,
                                          'recipe_id': m.recipe.id,
                                          'title': m.recipe.title,
                                          'meal_type': m.mealType ?? 'dinner',
                                          'meal_time': m.time != null ? '${m.time!.hour.toString().padLeft(2, '0')}:${m.time!.minute.toString().padLeft(2, '0')}:00' : null,
                                          'date': DateTime.now().toUtc().toIso8601String().split('T').first,
                                        });
                                    print('Successfully saved meal to plans: ${m.recipe.title}');
                                  } catch (e) {
                                    print('Failed to save meal to plans ${m.recipe.title}: $e');
                                  }
                                }

                                // Clear the meal plan
                                setState(() {
                                  _mealsForPlan.clear();
                                });

                                // Navigate to confirmation page, which will redirect to planner
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MealPlanConfirmationPage(),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 39, 230, 80),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Build Meal Plan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Geist',
                      ),
                    ),
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