import 'package:flutter/material.dart';
import '../../models/recipes.dart';
import '../../services/recipe_service.dart';
import 'package:nutriplan/screens/recipes/recipe_info_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nutriplan/screens/meal_plan/meal_summary_page.dart';
import 'package:nutriplan/screens/meal_plan/meal_plan_confirmation_page.dart';

class FilteredRecipesPage extends StatefulWidget {
  final String category;
  final String categoryName;
  final VoidCallback? onChanged;

  const FilteredRecipesPage({
    super.key,
    required this.category,
    required this.categoryName,
    this.onChanged,
  });

  @override
  State<FilteredRecipesPage> createState() => _FilteredRecipesPageState();
}

class _FilteredRecipesPageState extends State<FilteredRecipesPage> {
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
  }

  List<Recipe> _applySearchAndSort(List<Recipe> recipes) {
    List<Recipe> filtered = recipes;
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((r) => r.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    switch (_sortOption) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.cost.compareTo(b.cost));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.cost.compareTo(a.cost));
        break;
      case 'Calories: Low to High':
        filtered.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case 'Calories: High to Low':
        filtered.sort((a, b) => b.calories.compareTo(a.calories));
        break;
      case 'Protein: High to Low':
        filtered.sort((a, b) => ((b.macros['protein'] ?? 0) as num).compareTo((a.macros['protein'] ?? 0) as num));
        break;
      case 'Carbs: Low to High':
        filtered.sort((a, b) => ((a.macros['carbs'] ?? 0) as num).compareTo((b.macros['carbs'] ?? 0) as num));
        break;
      case 'No Allergens':
        filtered = filtered.where((r) => (r.allergyWarning.isEmpty)).toList();
        break;
    }
    return filtered;
  }

  List<Recipe> _getFilteredRecipes(List<Recipe> recipes) {
    switch (widget.category) {
      // Original categories
      case 'soup':
        return _getSoupRecipes(recipes);
      case 'fish':
      case 'fish_seafood':
        return _getFishRecipes(recipes);
      case 'pork':
        return _getPorkRecipes(recipes);
      case 'silog':
      case 'egg_silog':
        return _getSilogRecipes(recipes);
      
      // New protein-based categories
      case 'poultry':
      case 'chicken':
        return _getChickenRecipes(recipes);
      case 'beef':
        return _getBeefRecipes(recipes);
      case 'vegetarian':
        return _getVegetarianRecipes(recipes);
      
      // Health-oriented categories
      case 'healthy_low_cal':
        return _getHealthyRecipes(recipes);
      case 'high_protein':
        return _getHighProteinRecipes(recipes);
      case 'low_carb':
        return _getLowCarbRecipes(recipes);
      case 'heart_healthy':
        return _getHeartHealthyRecipes(recipes);
      case 'low_sodium':
        return _getLowSodiumRecipes(recipes);
      case 'diabetic_friendly':
        return _getDiabeticFriendlyRecipes(recipes);
      case 'weight_loss':
        return _getWeightLossRecipes(recipes);
      
      default:
        return recipes;
    }
  }

  List<Recipe> _getSoupRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.dietTypes.contains('Soup') ||
      recipe.title.toLowerCase().contains('sinigang') ||
      recipe.title.toLowerCase().contains('tinola') ||
      recipe.title.toLowerCase().contains('monggo') ||
      recipe.title.toLowerCase().contains('soup') ||
      recipe.title.toLowerCase().contains('nilaga') ||
      recipe.title.toLowerCase().contains('bulalo')
    ).toList();
  }

  List<Recipe> _getFishRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('fish') ||
      recipe.title.toLowerCase().contains('bangus') ||
      recipe.title.toLowerCase().contains('tilapia') ||
      recipe.title.toLowerCase().contains('salmon') ||
      recipe.title.toLowerCase().contains('tuna') ||
      recipe.title.toLowerCase().contains('lapu-lapu') ||
      recipe.title.toLowerCase().contains('galunggong') ||
      recipe.title.toLowerCase().contains('tamban')
    ).toList();
  }

  List<Recipe> _getPorkRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('pork') ||
      recipe.title.toLowerCase().contains('baboy') ||
      recipe.title.toLowerCase().contains('lechon') ||
      recipe.title.toLowerCase().contains('sisig') ||
      recipe.title.toLowerCase().contains('adobo') ||
      recipe.title.toLowerCase().contains('kaldereta') ||
      recipe.title.toLowerCase().contains('afritada') ||
      recipe.title.toLowerCase().contains('menudo')
    ).toList();
  }

  List<Recipe> _getSilogRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('silog') ||
      recipe.title.toLowerCase().contains('tapsilog') ||
      recipe.title.toLowerCase().contains('tocilog') ||
      recipe.title.toLowerCase().contains('longsilog') ||
      recipe.title.toLowerCase().contains('bangsilog') ||
      recipe.title.toLowerCase().contains('hotsilog') ||
      recipe.title.toLowerCase().contains('cornsilog') ||
      recipe.title.toLowerCase().contains('spamsilog')
    ).toList();
  }

  // New protein-based filtering methods
  List<Recipe> _getChickenRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('chicken') ||
      recipe.title.toLowerCase().contains('manok') ||
      recipe.title.toLowerCase().contains('adobo') ||
      recipe.title.toLowerCase().contains('tinola') ||
      recipe.title.toLowerCase().contains('inasal') ||
      recipe.title.toLowerCase().contains('fried chicken') ||
      recipe.ingredients.any((ingredient) => 
        ingredient.toLowerCase().contains('chicken') ||
        ingredient.toLowerCase().contains('manok')
      )
    ).toList();
  }

  List<Recipe> _getBeefRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('beef') ||
      recipe.title.toLowerCase().contains('baka') ||
      recipe.title.toLowerCase().contains('tapa') ||
      recipe.title.toLowerCase().contains('bulalo') ||
      recipe.title.toLowerCase().contains('kare-kare') ||
      recipe.title.toLowerCase().contains('kaldereta') ||
      recipe.ingredients.any((ingredient) => 
        ingredient.toLowerCase().contains('beef') ||
        ingredient.toLowerCase().contains('baka')
      )
    ).toList();
  }

  List<Recipe> _getVegetarianRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.dietTypes.contains('Vegetarian') ||
      recipe.dietTypes.contains('Vegan') ||
      recipe.title.toLowerCase().contains('vegetarian') ||
      recipe.title.toLowerCase().contains('vegan') ||
      recipe.title.toLowerCase().contains('pinakbet') ||
      recipe.title.toLowerCase().contains('laing') ||
      recipe.title.toLowerCase().contains('ginataang gulay') ||
      recipe.title.toLowerCase().contains('tofu') ||
      recipe.ingredients.any((ingredient) => 
        ingredient.toLowerCase().contains('tofu') ||
        ingredient.toLowerCase().contains('vegetable')
      )
    ).toList();
  }

  // Health-oriented filtering methods
  List<Recipe> _getHealthyRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.calories < 400 &&
      (recipe.dietTypes.contains('Healthy') ||
       recipe.title.toLowerCase().contains('healthy') ||
       recipe.title.toLowerCase().contains('light') ||
       recipe.title.toLowerCase().contains('grilled') ||
       recipe.title.toLowerCase().contains('steamed'))
    ).toList();
  }

  List<Recipe> _getHighProteinRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      (recipe.macros['protein'] ?? 0.0) > 20.0
    ).toList();
  }

  List<Recipe> _getLowCarbRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      (recipe.macros['carbs'] ?? 0.0) < 30.0 ||
      recipe.dietTypes.contains('Keto') ||
      recipe.title.toLowerCase().contains('keto')
    ).toList();
  }

  List<Recipe> _getHeartHealthyRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      (recipe.macros['sodium'] ?? 0.0) < 600 &&
      (recipe.macros['fat'] ?? 0.0) < 15.0 &&
      (recipe.macros['cholesterol'] ?? 0.0) < 100
    ).toList();
  }

  List<Recipe> _getLowSodiumRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      (recipe.macros['sodium'] ?? 0.0) < 400
    ).toList();
  }

  List<Recipe> _getDiabeticFriendlyRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      (recipe.macros['sugar'] ?? 0.0) < 10.0 &&
      (recipe.macros['carbs'] ?? 0.0) < 50.0
    ).toList();
  }

  List<Recipe> _getWeightLossRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.calories < 350 &&
      (recipe.macros['protein'] ?? 0.0) > 15.0 &&
      (recipe.macros['fiber'] ?? 0.0) > 5.0
    ).toList();
  }

  void _toggleFavorite(String recipeId) async {
    if (userId == null) return;

    final isCurrentlyFavorite = favoriteRecipeIds.contains(recipeId);
    try {
      if (isCurrentlyFavorite) {
        await RecipeService.removeFavorite(userId!, recipeId);
      } else {
        await RecipeService.addFavorite(userId!, recipeId);
      }

      if (!mounted) return;
      setState(() {
        if (isCurrentlyFavorite) {
          favoriteRecipeIds.remove(recipeId);
        } else {
          favoriteRecipeIds.add(recipeId);
        }
      });

      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Failed to update favorite: $e')),
      );
    }
  }

  void _addToMealPlan(Recipe recipe) {
    setState(() {
      if (!_mealsForPlan.any((meal) => meal.id == recipe.id)) {
        _mealsForPlan.add(recipe);
      }
    });
  }

  void _removeFromMealPlan(String recipeId) {
    setState(() {
      _mealsForPlan.removeWhere((meal) => meal.id == recipeId);
    });
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
          title: Text(
            widget.categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(showSearch ? Icons.close : Icons.search, color: Colors.black87),
              onPressed: () {
                setState(() {
                  showSearch = !showSearch;
                  if (!showSearch) searchQuery = '';
                });
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort, color: Colors.black87),
              onSelected: (value) {
                setState(() {
                  _sortOption = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'None', child: Text('None')),
                const PopupMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
                const PopupMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
                const PopupMenuItem(value: 'Calories: Low to High', child: Text('Calories: Low to High')),
                const PopupMenuItem(value: 'Calories: High to Low', child: Text('Calories: High to Low')),
                const PopupMenuItem(value: 'Protein: High to Low', child: Text('Protein: High to Low')),
                const PopupMenuItem(value: 'Carbs: Low to High', child: Text('Carbs: Low to High')),
                const PopupMenuItem(value: 'No Allergens', child: Text('No Allergens')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            if (showSearch)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
            Expanded(
              child: FutureBuilder<List<Recipe>>(
                future: RecipeService.fetchRecipes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final allRecipes = snapshot.data ?? [];
                  final categoryRecipes = _getFilteredRecipes(allRecipes);
                  final filteredRecipes = _applySearchAndSort(categoryRecipes);

                  if (filteredRecipes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No ${widget.categoryName.toLowerCase()} recipes found',
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      final isFavorite = favoriteRecipeIds.contains(recipe.id);
                      final isInMealPlan = _mealsForPlan.any((meal) => meal.id == recipe.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => RecipeInfoScreen(
                                  recipe: recipe,
                                  addedRecipeIds: _mealsForPlan.map((m) => m.id).toList(),
                                ),
                              ),
                            );
                            _fetchFavorites();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: recipe.imageUrl.isNotEmpty
                                      ? Image.network(
                                          recipe.imageUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                        )
                                      : Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.ramen_dining, color: Colors.grey),
                                        ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        recipe.shortDescription,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            '₱${recipe.cost.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '${recipe.calories} cal',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () => _toggleFavorite(recipe.id),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isInMealPlan ? Icons.remove_circle : Icons.add_circle,
                                        color: isInMealPlan ? Colors.orange : Colors.blue,
                                      ),
                                      onPressed: () {
                                        if (isInMealPlan) {
                                          _removeFromMealPlan(recipe.id);
                                        } else {
                                          _addToMealPlan(recipe);
                                        }
                                      },
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
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _mealsForPlan.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MealSummaryPage(
                        meals: _mealsForPlan,
                        onBuildMealPlan: (confirmedMeals) async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MealPlanConfirmationPage(),
                            ),
                          );
                          widget.onChanged?.call();
                          setState(() {
                            _mealsForPlan.clear();
                          });
                        },
                        onChanged: widget.onChanged,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu),
                label: Text('Meal Plan (${_mealsForPlan.length})'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }
}
