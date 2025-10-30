import 'package:flutter/material.dart';
import '../../models/recipes.dart';
import '../../services/recipe_service.dart';
import 'package:nutriplan/screens/recipes/recipe_info_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'see_all_recipe.dart';
import 'package:nutriplan/screens/meal_plan/meal_summary_page.dart';
import 'package:nutriplan/screens/meal_plan/meal_plan_confirmation_page.dart';
import 'package:nutriplan/screens/meal_plan/meal_planning_options_page.dart';
import '../../widgets/loading_skeletons.dart';

class RecipesPage extends StatefulWidget {
  final VoidCallback? onChanged;
  final bool isAdvancePlanning;
  const RecipesPage({super.key, this.onChanged, this.isAdvancePlanning = false});

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
  late Future<List<Recipe>> _recentlyAddedFuture;

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
    _recentlyAddedFuture = RecipeService.fetchRecentlyAdded(limit: 20);
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
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add favorites')),
      );
      return;
    }

    final isFav = favoriteRecipeIds.contains(recipe.id);
    
    try {
      await RecipeService.toggleFavorite(userId!, recipe.id, isFav);
      
      if (!mounted) return;
      await _fetchFavorites();
      if (widget.onChanged != null) widget.onChanged!();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isFav 
              ? '${recipe.title} added to favorites!' 
              : '${recipe.title} removed from favorites!',
            style: const TextStyle(fontFamily: 'Geist'),
          ),
          backgroundColor: !isFav ? Colors.green : Colors.grey,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 2),
          elevation: 8,
        ),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '${recipe.title} added to meal plan!',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
        elevation: 8,
      ),
    );
  }

  void _removeFromMealPlan(Recipe recipe) {
    setState(() {
      _mealsForPlan.removeWhere((meal) => meal.id == recipe.id);
    });
  }

  // Helper methods for recipe categorization
  
  // Silog Meals (Breakfast Classics)
  List<Recipe> _getSilogRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('silog')
    ).toList();
  }

  // Kainang Pamilya (Family Favorites)
  List<Recipe> _getFamilyFavorites(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('adobo') ||
      recipe.title.toLowerCase().contains('sinigang') ||
      recipe.title.toLowerCase().contains('kaldereta') ||
      recipe.title.toLowerCase().contains('afritada') ||
      recipe.title.toLowerCase().contains('menudo') ||
      recipe.title.toLowerCase().contains('mechado') ||
      recipe.title.toLowerCase().contains('kare-kare') ||
      recipe.title.toLowerCase().contains('pinakbet') ||
      recipe.title.toLowerCase().contains('laing') ||
      recipe.title.toLowerCase().contains('ginataang')
    ).toList();
  }

  // Lutong Bahay (Home-cooked Comfort)
  List<Recipe> _getHomeCookedRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('tinola') ||
      recipe.title.toLowerCase().contains('nilaga') ||
      recipe.title.toLowerCase().contains('bulalo') ||
      recipe.title.toLowerCase().contains('monggo') ||
      recipe.title.toLowerCase().contains('ginisang') ||
      recipe.title.toLowerCase().contains('pritong') ||
      recipe.title.toLowerCase().contains('ginataang') ||
      recipe.title.toLowerCase().contains('pakbet') ||
      recipe.title.toLowerCase().contains('dinuguan') ||
      recipe.title.toLowerCase().contains('pancit')
    ).toList();
  }

  // Quick & Easy Meals
  List<Recipe> _getQuickEasyRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('quick') ||
      recipe.title.toLowerCase().contains('easy') ||
      recipe.title.toLowerCase().contains('simple') ||
      recipe.title.toLowerCase().contains('fast') ||
      recipe.title.toLowerCase().contains('ginisang') ||
      recipe.title.toLowerCase().contains('pritong') ||
      recipe.title.toLowerCase().contains('scrambled') ||
      recipe.title.toLowerCase().contains('fried') ||
      recipe.title.toLowerCase().contains('instant') ||
      recipe.title.toLowerCase().contains('one-pot') ||
      recipe.title.toLowerCase().contains('30-minute') ||
      recipe.title.toLowerCase().contains('15-minute')
    ).toList();
  }

  // Healthy Pinoy
  List<Recipe> _getHealthyPinoyRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.tags.contains('Healthy') ||
      recipe.tags.contains('Low Calorie') ||
      recipe.tags.contains('Vegetarian') ||
      recipe.title.toLowerCase().contains('steamed') ||
      recipe.title.toLowerCase().contains('boiled') ||
      recipe.title.toLowerCase().contains('fresh') ||
      recipe.title.toLowerCase().contains('salad') ||
      recipe.title.toLowerCase().contains('vegetable') ||
      recipe.title.toLowerCase().contains('fish') ||
      recipe.title.toLowerCase().contains('chicken breast')
    ).toList();
  }

  // Sabaw & Nilaga (Soups & Stews) - Updated
  List<Recipe> _getSoupRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.tags.contains('Soup') ||
      recipe.title.toLowerCase().contains('sinigang') ||
      recipe.title.toLowerCase().contains('tinola') ||
      recipe.title.toLowerCase().contains('monggo') ||
      recipe.title.toLowerCase().contains('nilaga') ||
      recipe.title.toLowerCase().contains('bulalo') ||
      recipe.title.toLowerCase().contains('soup') ||
      recipe.title.toLowerCase().contains('sabaw') ||
      recipe.title.toLowerCase().contains('batchoy') ||
      recipe.title.toLowerCase().contains('mami')
    ).toList();
  }


  // New creative category methods
  List<Recipe> _getPersonalizedRecipes(List<Recipe> recipes) {
    // Personalized recommendations based on user preferences and favorites
    final favoriteRecipes = recipes.where((recipe) => 
      favoriteRecipeIds.contains(recipe.id)
    ).toList();
    
    // If user has favorites, show them; otherwise show popular recipes
    if (favoriteRecipes.isNotEmpty) {
      return favoriteRecipes.take(6).toList();
    } else {
      // Show popular Filipino dishes
    return recipes.where((recipe) => 
        recipe.title.toLowerCase().contains('adobo') ||
        recipe.title.toLowerCase().contains('sinigang') ||
        recipe.title.toLowerCase().contains('kare-kare') ||
        recipe.title.toLowerCase().contains('lechon') ||
        recipe.title.toLowerCase().contains('sisig') ||
        recipe.title.toLowerCase().contains('nilaga') ||
        recipe.title.toLowerCase().contains('tinola')
      ).take(6).toList();
    }
  }

  List<Recipe> _getComfortClassicsRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('adobo') ||
      recipe.title.toLowerCase().contains('sinigang') ||
      recipe.title.toLowerCase().contains('kare-kare') ||
      recipe.title.toLowerCase().contains('nilaga') ||
      recipe.title.toLowerCase().contains('tinola') ||
      recipe.title.toLowerCase().contains('bulalo') ||
      recipe.title.toLowerCase().contains('pancit') ||
      recipe.title.toLowerCase().contains('lumpia') ||
      recipe.title.toLowerCase().contains('lechon') ||
      recipe.title.toLowerCase().contains('sisig') ||
      recipe.title.toLowerCase().contains('crispy pata') ||
      recipe.title.toLowerCase().contains('bicol express')
    ).toList();
  }

  List<Recipe> _getFusionFlavorsRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('fusion') ||
      recipe.title.toLowerCase().contains('asian') ||
      recipe.title.toLowerCase().contains('western') ||
      recipe.title.toLowerCase().contains('italian') ||
      recipe.title.toLowerCase().contains('chinese') ||
      recipe.title.toLowerCase().contains('japanese') ||
      recipe.title.toLowerCase().contains('korean') ||
      recipe.title.toLowerCase().contains('thai') ||
      recipe.title.toLowerCase().contains('indian') ||
      recipe.title.toLowerCase().contains('mexican') ||
      recipe.title.toLowerCase().contains('spanish') ||
      recipe.title.toLowerCase().contains('american')
    ).toList();
  }

  List<Recipe> _getOnePotWondersRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('sinigang') ||
      recipe.title.toLowerCase().contains('nilaga') ||
      recipe.title.toLowerCase().contains('tinola') ||
      recipe.title.toLowerCase().contains('bulalo') ||
      recipe.title.toLowerCase().contains('kare-kare') ||
      recipe.title.toLowerCase().contains('caldereta') ||
      recipe.title.toLowerCase().contains('menudo') ||
      recipe.title.toLowerCase().contains('afritada') ||
      recipe.title.toLowerCase().contains('pochero') ||
      recipe.title.toLowerCase().contains('paella') ||
      recipe.title.toLowerCase().contains('risotto') ||
      recipe.title.toLowerCase().contains('casserole') ||
      recipe.title.toLowerCase().contains('stew') ||
      recipe.title.toLowerCase().contains('pot')
    ).toList();
  }

  List<Recipe> _getWeekendSpecialsRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('lechon') ||
      recipe.title.toLowerCase().contains('crispy pata') ||
      recipe.title.toLowerCase().contains('kare-kare') ||
      recipe.title.toLowerCase().contains('caldereta') ||
      recipe.title.toLowerCase().contains('paella') ||
      recipe.title.toLowerCase().contains('roast') ||
      recipe.title.toLowerCase().contains('barbecue') ||
      recipe.title.toLowerCase().contains('bbq') ||
      recipe.title.toLowerCase().contains('grilled') ||
      recipe.title.toLowerCase().contains('inihaw') ||
      recipe.title.toLowerCase().contains('special') ||
      recipe.title.toLowerCase().contains('feast') ||
      recipe.title.toLowerCase().contains('celebration') ||
      recipe.title.toLowerCase().contains('party') ||
      recipe.title.toLowerCase().contains('occasion')
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                recipe.imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey[600]!,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.restaurant,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  );
                                },
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
                          if (widget.isAdvancePlanning) {
                            // Navigate back to meal planning options page
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const MealPlanningOptionsPage(),
                              ),
                            );
                          } else {
                            Navigator.pop(context);
                          }
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
              if (widget.isAdvancePlanning) {
                // Navigate back to meal planning options page
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MealPlanningOptionsPage(),
                  ),
                );
              } else {
                Navigator.pop(context);
              }
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
                  return RecipeListSkeleton(
                    itemCount: 6,
                  );
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
                
                // Track shown recipe IDs to avoid duplicates across sections
                final Set<String> shownRecipeIds = {};
                
                // Helper function to get unique recipes for a section
                List<Recipe> getUniqueRecipes(List<Recipe> recipes, {int limit = 10}) {
                  return recipes.where((recipe) {
                    if (shownRecipeIds.contains(recipe.id)) {
                      return false; // Skip if already shown
                    }
                    shownRecipeIds.add(recipe.id); // Mark as shown
                    return true;
                  }).take(limit).toList();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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

                      // Recently Added Recipes (from DB order by created_at desc)
                      FutureBuilder<List<Recipe>>(
                        future: _recentlyAddedFuture,
                        builder: (context, recentSnap) {
                          if (recentSnap.connectionState == ConnectionState.waiting) {
                            // Avoid nested unbounded scrollables; show a simple placeholder instead
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Recently Added',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (recentSnap.hasError || !recentSnap.hasData) {
                            return const SizedBox.shrink();
                          }
                          // Optionally apply current search filter
                          final List<Recipe> recent = searchQuery.isEmpty
                              ? recentSnap.data!
                              : recentSnap.data!
                                  .where((r) => r.title.toLowerCase().contains(searchQuery.toLowerCase()))
                                  .toList();
                          return _buildRecipeSection(
                            'Recently Added',
                            getUniqueRecipes(recent),
                            recent.length,
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Silog Meals (Breakfast Classics)
                      _buildRecipeSection(
                        'Silog Meals',
                        getUniqueRecipes(_getSilogRecipes(filteredRecipes)),
                        _getSilogRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Kainang Pamilya (Family Favorites)
                      _buildRecipeSection(
                        'Kainang Pamilya',
                        getUniqueRecipes(_getFamilyFavorites(filteredRecipes)),
                        _getFamilyFavorites(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Lutong Bahay (Home-cooked Comfort)
                      _buildRecipeSection(
                        'Lutong Bahay',
                        getUniqueRecipes(_getHomeCookedRecipes(filteredRecipes)),
                        _getHomeCookedRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Just for You (Personalized Recommendations)
                      _buildRecipeSection(
                        'Just for You',
                        getUniqueRecipes(_getPersonalizedRecipes(filteredRecipes)),
                        _getPersonalizedRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Quick & Easy Meals
                      _buildRecipeSection(
                        'Quick & Easy Meals',
                        getUniqueRecipes(_getQuickEasyRecipes(filteredRecipes)),
                        _getQuickEasyRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Healthy Pinoy
                      _buildRecipeSection(
                        'Healthy Pinoy',
                        getUniqueRecipes(_getHealthyPinoyRecipes(filteredRecipes)),
                        _getHealthyPinoyRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Sabaw & Nilaga (Soups & Stews)
                      _buildRecipeSection(
                        'Sabaw & Nilaga',
                        getUniqueRecipes(_getSoupRecipes(filteredRecipes)),
                        _getSoupRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Comfort Classics
                      _buildRecipeSection(
                        'Comfort Classics',
                        getUniqueRecipes(_getComfortClassicsRecipes(filteredRecipes)),
                        _getComfortClassicsRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Fusion Flavors
                      _buildRecipeSection(
                        'Fusion Flavors',
                        getUniqueRecipes(_getFusionFlavorsRecipes(filteredRecipes)),
                        _getFusionFlavorsRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // One-Pot Wonders
                      _buildRecipeSection(
                        'One-Pot Wonders',
                        getUniqueRecipes(_getOnePotWondersRecipes(filteredRecipes)),
                        _getOnePotWondersRecipes(filteredRecipes).length,
                      ),

                      const SizedBox(height: 24),

                      // Weekend Specials
                      _buildRecipeSection(
                        'Weekend Specials',
                        getUniqueRecipes(_getWeekendSpecialsRecipes(filteredRecipes)),
                        _getWeekendSpecialsRecipes(filteredRecipes).length,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => _removeFromMealPlan(meal),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF6961),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
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
                  Container(
                    margin: const EdgeInsets.only(left: 16),
                    child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => MealSummaryPage(
                            meals: _mealsForPlan,
                            isAdvancePlanning: widget.isAdvancePlanning,
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
                                          'date': (m.scheduledDate ?? DateTime.now()).toUtc().toIso8601String().split('T').first,
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