import 'package:flutter/material.dart';
import '../models/recipes.dart';
import '../services/recipe_service.dart';
import '../screens/recipe_info_screen.dart'; // Added import for RecipeInfoScreen
import 'package:supabase_flutter/supabase_flutter.dart';
import 'see_all_recipe.dart';
import '../screens/meal_summary_page.dart'; // Added import for MealSummaryPage
import '../screens/meal_plan_confirmation_page.dart'; // Added import for MealPlanConfirmationPage
import '../screens/home_page.dart'; // Added import for HomePage

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  Set<String> favoriteRecipeIds = {};

  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  String _sortOption = 'None';

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

  void _showFilterSheet(List<Recipe> recipes, void Function(List<Recipe>) onSort) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Price (Low to High)'),
                onTap: () {
                  onSort(List.from(recipes)..sort((a, b) => a.cost.compareTo(b.cost)));
                  setState(() => _sortOption = 'Price (Low to High)');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Price (High to Low)'),
                onTap: () {
                  onSort(List.from(recipes)..sort((a, b) => b.cost.compareTo(a.cost)));
                  setState(() => _sortOption = 'Price (High to Low)');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: const Text('Calories (Low to High)'),
                onTap: () {
                  onSort(List.from(recipes)..sort((a, b) => a.calories.compareTo(b.calories)));
                  setState(() => _sortOption = 'Calories (Low to High)');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: const Text('Calories (High to Low)'),
                onTap: () {
                  onSort(List.from(recipes)..sort((a, b) => b.calories.compareTo(a.calories)));
                  setState(() => _sortOption = 'Calories (High to Low)');
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Quickest to Prepare'),
                onTap: () {
                  // Placeholder
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Most Popular'),
                onTap: () {
                  // Placeholder
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.eco),
                title: const Text('Diet Type'),
                onTap: () {
                  // Placeholder
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Highest Protein'),
                onTap: () {
                  onSort(List.from(recipes)..sort((a, b) => ((b.macros['protein'] ?? 0) as num).compareTo((a.macros['protein'] ?? 0) as num)));
                  setState(() => _sortOption = 'Highest Protein');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.no_food),
                title: const Text('Lowest Carbs'),
                onTap: () {
                  onSort(List.from(recipes)..sort((a, b) => ((a.macros['carbs'] ?? 0) as num).compareTo((b.macros['carbs'] ?? 0) as num)));
                  setState(() => _sortOption = 'Lowest Carbs');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: const Text('Allergy Friendly'),
                onTap: () {
                  onSort(List.from(recipes).where((r) => (r.allergyWarning.isEmpty)).toList() as List<Recipe>);
                  setState(() => _sortOption = 'Allergy Friendly');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.new_releases),
                title: const Text('Recently Added'),
                onTap: () {
                  // Placeholder
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.format_list_numbered),
                title: const Text('Fewest Ingredients'),
                onTap: () {
                  // Placeholder
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.child_care),
                title: const Text('Kid Friendly'),
                onTap: () {
                  // Placeholder
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events),
                title: const Text('Chef’s Choice'),
                onTap: () {
                  // Placeholder
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    if (userId == null) return;
    final isFav = favoriteRecipeIds.contains(recipe.id);
    await RecipeService.toggleFavorite(userId!, recipe.id, isFav);
    if (!mounted) return;
    await _fetchFavorites();
  }

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        // Removed AppBar, added custom back button
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom back button at the top left
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose your Meal Plan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter/Sort button
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter/Sort'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[100],
                            foregroundColor: Colors.green[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // Fetch recipes and show filter sheet
                            RecipeService.fetchRecipes().then((recipes) {
                              _showFilterSheet(recipes, (sorted) {
                                setState(() {
                                  // This is a simple demo; in a real app, store sorted recipes in state
                                });
                              });
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'For Breakfast',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SeeAllRecipePage(
                                addedRecipeIds: _mealsForPlan.map((r) => r.id).toList(),
                              ),
                            ),
                          );
                          if (!mounted) return;
                          if (result is Recipe) {
                            Recipe fullRecipe = result;
                            if (fullRecipe.imageUrl.isEmpty) {
                              final response = await Supabase.instance.client
                                .from('recipes')
                                .select()
                                .eq('id', result.id)
                                .maybeSingle();
                              if (response != null) {
                                fullRecipe = Recipe.fromMap(response);
                              }
                            }
                            setState(() {
                              if (!_mealsForPlan.any((r) => r.id == fullRecipe.id)) {
                                _mealsForPlan.add(fullRecipe);
                                _scaffoldMessengerKey.currentState?.showSnackBar(
                                  SnackBar(
                                    content: Text('${fullRecipe.title} is added to your Meal Plan'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            });
                          }
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: FutureBuilder<List<Recipe>>(
                      future: RecipeService.fetchRecipes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: \\${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No recipes found.'));
                        }
                        final recipes = snapshot.data!;
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recipes.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 24),
                          itemBuilder: (context, index) {
                            final recipe = recipes[index];
                            return _RecipeCard(
                              recipe: recipe,
                              isFavorite: favoriteRecipeIds.contains(recipe.id),
                              onFavoriteToggle: () => _toggleFavorite(recipe),
                              onTap: () async {
                                // If the recipe already has an imageUrl, use it directly
                                Recipe recipeToAdd = recipe;
                                if (recipeToAdd.imageUrl.isEmpty) {
                                  final response = await Supabase.instance.client
                                    .from('recipes')
                                    .select()
                                    .eq('id', recipe.id)
                                    .maybeSingle();
                                  if (response != null) {
                                    recipeToAdd = Recipe.fromMap(response);
                                  }
                                }
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeInfoScreen(recipe: recipeToAdd, addedRecipeIds: _mealsForPlan.map((r) => r.id).toList()),
                                  ),
                                );
                                if (!mounted) return;
                                if (result is Recipe) {
                                  // Always fetch the full recipe before adding, to ensure imageUrl is present
                                  Recipe fullRecipe = result;
                                  if (fullRecipe.imageUrl.isEmpty) {
                                    final response = await Supabase.instance.client
                                      .from('recipes')
                                      .select()
                                      .eq('id', result.id)
                                      .maybeSingle();
                                    if (response != null) {
                                      fullRecipe = Recipe.fromMap(response);
                                    }
                                  }
                                  setState(() {
                                    if (!_mealsForPlan.any((r) => r.id == fullRecipe.id)) {
                                      _mealsForPlan.add(fullRecipe);
                                      _scaffoldMessengerKey.currentState?.showSnackBar(
                                        SnackBar(
                                          content: Text('${fullRecipe.title} is added to your Meal Plan'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  });
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Fixed bottom bar for added recipes (shows all added, as chips, with Build Meal Plan button)
            if (_mealsForPlan.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 145, 240, 145),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      height: 70,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _mealsForPlan.map((meal) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text(meal.title),
                                    onDeleted: () {
                                      setState(() {
                                        _mealsForPlan.removeWhere((r) => r.id == meal.id);
                                      });
                                    },
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MealSummaryPage(
                                    meals: _mealsForPlan,
                                    onBuildMealPlan: (mealsWithTime) async {
                                      // Insert each meal as a separate meal plan row in Supabase
                                      final userId = Supabase.instance.client.auth.currentUser?.id;
                                      if (userId != null) {
                                        for (final m in mealsWithTime) {
                                          final mealJson = {
                                            'recipe_id': m.recipe.id,
                                            'title': m.recipe.title,
                                            'image_url': m.recipe.imageUrl,
                                            'time': m.time?.format(context) ?? '',
                                          };
                                          await Supabase.instance.client.from('meal_plans').insert({
                                            'user_id': userId,
                                            'meals': [mealJson], // Each row has a single meal in the array
                                            'date': DateTime.now().toIso8601String().substring(0, 10),
                                          });
                                        }
                                      }
                                      // Show confirmation page
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => MealPlanConfirmationPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text(
                              'Build Meal Plan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${recipe.calories} kcal',
                                    style: TextStyle(fontSize: 13, color: Colors.black54),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.attach_money, color: Colors.green, size: 16),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    recipe.cost.toStringAsFixed(2),
                                    style: TextStyle(fontSize: 13, color: Colors.black54),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
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