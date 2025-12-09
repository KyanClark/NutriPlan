import 'package:flutter/material.dart';
import '../../models/recipes.dart';
import '../../services/recipe_service.dart';
import 'package:nutriplan/user/screens/recipes/recipe_info_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      case 'pasta':
        return _getPastaRecipes(recipes);
      case 'fish':
      case 'fish_seafood':
        return _getFishRecipes(recipes);
      case 'pork':
        return _getPorkRecipes(recipes);
      
      case 'poultry':
      case 'chicken':
        return _getChickenRecipes(recipes);
      case 'beef':
        return _getBeefRecipes(recipes);
      case 'desserts':
        return _getDessertsRecipes(recipes);
      case 'vegetarian':
      case 'vegetable':
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

  List<Recipe> _getPastaRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.tags.contains('Pasta') ||
      recipe.tags.contains('Noodles') ||
      recipe.title.toLowerCase().contains('pasta') ||
      recipe.title.toLowerCase().contains('spaghetti') ||
      recipe.title.toLowerCase().contains('pancit') ||
      recipe.title.toLowerCase().contains('bihon') ||
      recipe.title.toLowerCase().contains('canton') ||
      recipe.title.toLowerCase().contains('miki') ||
      recipe.title.toLowerCase().contains('noodles') ||
      recipe.ingredients.any((ingredient) => 
        ingredient.toLowerCase().contains('pasta') ||
        ingredient.toLowerCase().contains('noodles') ||
        ingredient.toLowerCase().contains('spaghetti') ||
        ingredient.toLowerCase().contains('pancit') ||
        ingredient.toLowerCase().contains('bihon')
      )
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
    return recipes.where((recipe) {
      final title = recipe.title.toLowerCase();
      final ingredients = recipe.ingredients.map((i) => i.toLowerCase()).join(' ');
      
      // STRICTLY EXCLUDE recipes with beef or chicken
      if (title.contains('beef') || title.contains('baka') || 
          title.contains('chicken') || title.contains('manok')) {
        return false;
      }
      
      // Check ingredients - exclude if contains beef or chicken
      if (ingredients.contains('beef') || ingredients.contains('baka') ||
          ingredients.contains('chicken') || ingredients.contains('manok')) {
        return false;
      }
      
      // Include pork-specific recipes
      return title.contains('pork') ||
          title.contains('baboy') ||
          title.contains('lechon') ||
          (title.contains('sisig') && !title.contains('chicken') && !title.contains('beef')) ||
          (title.contains('adobo') && !title.contains('chicken') && !title.contains('beef')) ||
          (title.contains('kaldereta') && !title.contains('chicken') && !title.contains('beef')) ||
          (title.contains('afritada') && !title.contains('chicken') && !title.contains('beef')) ||
          (title.contains('menudo') && !title.contains('chicken') && !title.contains('beef')) ||
          ingredients.contains('pork') ||
          ingredients.contains('baboy');
    }).toList();
  }


  // New protein-based filtering methods
  List<Recipe> _getChickenRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) {
      final title = recipe.title.toLowerCase();
      final ingredients = recipe.ingredients.map((i) => i.toLowerCase()).join(' ');
      
      // STRICTLY EXCLUDE recipes with beef or pork
      if (title.contains('beef') || title.contains('baka') || 
          title.contains('pork') || title.contains('baboy')) {
        return false;
      }
      
      // Exclude recipes that are clearly not chicken-based
      if (title.contains('pusit') ||
          title.contains('kangkong') ||
          title.contains('bam i') ||
          title.contains('sotanghon') ||
          title.contains('egg noodle') ||
          title.contains('pancit lomi') ||
          title.contains('pancit bihon') ||
          title.contains('chop suey') ||
          title.contains('talong') ||
          title.contains('tofu') ||
          title.contains('pancit canton') ||
          title.contains('ginisang monggo') ||
          title.contains('ginisang munggo')) {
        return false;
      }
      
      // Check ingredients - exclude if contains beef or pork
      if (ingredients.contains('beef') || ingredients.contains('baka') ||
          ingredients.contains('pork') || ingredients.contains('baboy')) {
        return false;
      }
      
      // Include chicken-specific recipes
      return (title.contains('chicken') && !title.contains('beef') && !title.contains('pork')) ||
          title.contains('manok') ||
          (title.contains('tinola') && !title.contains('beef') && !title.contains('pork')) ||
          (title.contains('inasal') && !title.contains('beef') && !title.contains('pork')) ||
          title.contains('fried chicken') ||
          (title.contains('kare') && title.contains('chicken')) || // Chicken kare kare
          (title.contains('adobo') && (title.contains('chicken') || title.contains('manok'))) ||
          (title.contains('kaldereta') && (title.contains('chicken') || title.contains('manok'))) ||
          recipe.ingredients.any((ingredient) {
            final ing = ingredient.toLowerCase();
            return (ing.contains('chicken') || ing.contains('manok')) &&
                   !ing.contains('beef') && !ing.contains('baka') &&
                   !ing.contains('pork') && !ing.contains('baboy');
          });
    }).toList();
  }

  List<Recipe> _getBeefRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) {
      final title = recipe.title.toLowerCase();
      final ingredients = recipe.ingredients.map((i) => i.toLowerCase()).join(' ');
      
      // STRICTLY EXCLUDE recipes with pork or chicken
      if (title.contains('pork') || title.contains('baboy') || 
          title.contains('chicken') || title.contains('manok')) {
        return false;
      }
      
      // Exclude chicken-based recipes that might contain beef-related keywords
      if (title.contains('chicken') && (title.contains('kare') || title.contains('kaldereta'))) {
        return false; // Chicken kare kare, chicken kaldereta should not be in beef
      }
      
      // Exclude ginisang monggo (it's a vegetable/legume dish, not beef)
      if (title.contains('ginisang monggo') || title.contains('ginisang munggo')) {
        return false;
      }
      
      // Check ingredients - exclude if contains pork or chicken
      if (ingredients.contains('pork') || ingredients.contains('baboy') ||
          ingredients.contains('chicken') || ingredients.contains('manok')) {
        return false;
      }
      
      // Include beef-specific recipes
      return title.contains('beef') ||
          title.contains('baka') ||
          (title.contains('tapa') && !title.contains('chicken') && !title.contains('pork')) ||
          title.contains('bulalo') ||
          (title.contains('kare-kare') && !title.contains('chicken') && !title.contains('pork')) ||
          (title.contains('kare kare') && !title.contains('chicken') && !title.contains('pork')) ||
          (title.contains('kaldereta') && !title.contains('chicken') && !title.contains('pork')) ||
          (title.contains('adobo') && (title.contains('beef') || title.contains('baka'))) ||
          recipe.ingredients.any((ingredient) {
            final ing = ingredient.toLowerCase();
            return (ing.contains('beef') || ing.contains('baka')) &&
                   !ing.contains('chicken') && !ing.contains('manok') &&
                   !ing.contains('pork') && !ing.contains('baboy');
          });
    }).toList();
  }

  List<Recipe> _getVegetarianRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) {
      final title = recipe.title.toLowerCase();
      final ingredients = recipe.ingredients.map((i) => i.toLowerCase()).join(' ');
      
      // STRICTLY EXCLUDE any meat ingredients
      final meatKeywords = [
        'beef', 'baka', 'pork', 'baboy', 'chicken', 'manok',
        'fish', 'isda', 'seafood', 'shrimp', 'hipon', 'crab', 'alimango',
        'meat', 'karne', 'turkey', 'duck', 'bibe', 'lamb', 'kordero'
      ];
      
      // Exclude if title contains meat keywords
      if (meatKeywords.any((keyword) => title.contains(keyword))) {
        return false;
      }
      
      // Exclude if ingredients contain meat keywords
      if (meatKeywords.any((keyword) => ingredients.contains(keyword))) {
        return false;
      }
      
      // Include vegetarian-specific recipes
      return recipe.tags.contains('Vegetarian') ||
          recipe.tags.contains('Vegan') ||
          title.contains('vegetarian') ||
          title.contains('vegan') ||
          title.contains('pinakbet') ||
          title.contains('laing') ||
          title.contains('ginataang gulay') ||
          title.contains('ginisang monggo') ||
          title.contains('ginisang munggo') ||
          title.contains('tofu') ||
          title.contains('chop suey') ||
          title.contains('kangkong') ||
          title.contains('talong') ||
          title.contains('sitaw') ||
          title.contains('okra') ||
          title.contains('ampalaya') ||
          title.contains('kalabasa') ||
          recipe.ingredients.any((ingredient) {
            final ing = ingredient.toLowerCase();
            return (ing.contains('tofu') || ing.contains('vegetable') || 
                    ing.contains('gulay') || ing.contains('monggo') || 
                    ing.contains('munggo')) &&
                   !meatKeywords.any((keyword) => ing.contains(keyword));
          });
    }).toList();
  }

  // New category filtering methods
  List<Recipe> _getDessertsRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.title.toLowerCase().contains('dessert') ||
      recipe.title.toLowerCase().contains('cake') ||
      recipe.title.toLowerCase().contains('pie') ||
      recipe.title.toLowerCase().contains('cookie') ||
      recipe.title.toLowerCase().contains('ice cream') ||
      recipe.title.toLowerCase().contains('pudding') ||
      recipe.title.toLowerCase().contains('flan') ||
      recipe.title.toLowerCase().contains('leche flan') ||
      recipe.title.toLowerCase().contains('halo-halo') ||
      recipe.title.toLowerCase().contains('turon') ||
      recipe.title.toLowerCase().contains('buko pandan') ||
      recipe.title.toLowerCase().contains('maja blanca') ||
      recipe.title.toLowerCase().contains('bibingka') ||
      recipe.title.toLowerCase().contains('puto') ||
      recipe.title.toLowerCase().contains('kakanin') ||
      recipe.title.toLowerCase().contains('sweet') ||
      recipe.tags.contains('Dessert')
    ).toList();
  }


  // Health-oriented filtering methods
  List<Recipe> _getHealthyRecipes(List<Recipe> recipes) {
    return recipes.where((recipe) => 
      recipe.calories < 400 &&
      (recipe.tags.contains('Healthy') ||
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
      recipe.tags.contains('Keto') ||
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

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      itemCount: 6, // Show 6 skeleton cards
      itemBuilder: (context, index) {
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image skeleton
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title skeleton
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Description skeleton
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 180,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Calorie skeleton
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Favorite button skeleton
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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


  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFC1E7AF),
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
                future: RecipeService.fetchRecipes(userId: userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeletonLoader();
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

                  // Recipes are already filtered by diet type and allergies via RecipeService.fetchRecipes()
                  // Now filter by category (e.g., pasta, chicken, etc.)
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      final isFavorite = favoriteRecipeIds.contains(recipe.id);

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
                                  addedRecipeIds: [],
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
                                      Text(
                                        '${recipe.calories} kcal',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF90EE90), // Light green
                                          fontSize: 14,
                                        ),
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
      ),
    );
  }
}
