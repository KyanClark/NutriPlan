import 'package:flutter/material.dart';
import '../models/recipes.dart';
import '../services/recipe_service.dart';
import '../screens/recipe_info_screen.dart'; // Added import for RecipeInfoScreen
import 'package:supabase_flutter/supabase_flutter.dart';
import 'see_all_recipe.dart';

class RecipesPage extends StatefulWidget {
  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  Set<String> favoriteRecipeIds = {};

  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  String _sortOption = 'None';

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
    return Scaffold(
      // Removed AppBar, added custom back button
      body: Padding(
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
            Row(
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
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => SeeAllRecipePage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
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
              height: 240, // Try increasing this value
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

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  const _RecipeCard({required this.recipe, this.isFavorite = false, this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          print('Recipe card tapped: ${recipe.title}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeInfoScreen(recipe: recipe),
            ),
          );
        },
        child: Container(
          width: 200,
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
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Text(
                      recipe.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
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
  }
} 