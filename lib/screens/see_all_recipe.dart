import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipes.dart';
import '../services/recipe_service.dart';
import 'recipe_info_screen.dart';

class SeeAllRecipePage extends StatefulWidget {
  final List<String> addedRecipeIds;
  const SeeAllRecipePage({super.key, this.addedRecipeIds = const []});

  @override
  State<SeeAllRecipePage> createState() => _SeeAllRecipePageState();
}

class _SeeAllRecipePageState extends State<SeeAllRecipePage> {
  List<Recipe> allRecipes = [];
  Set<String> favoriteRecipeIds = {};
  String searchQuery = '';
  bool isLoading = true;
  bool showSearch = false;

  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => isLoading = true);
    final recipes = await RecipeService.fetchRecipes();
    if (!mounted) return;
    if (userId != null) {
      final favs = await RecipeService.fetchFavoriteRecipeIds(userId!);
      if (!mounted) return;
      setState(() {
        allRecipes = recipes;
        favoriteRecipeIds = favs.toSet();
        isLoading = false;
      });
    } else {
      setState(() {
        allRecipes = recipes;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    if (userId == null) return;
    final isFav = favoriteRecipeIds.contains(recipe.id);
    await RecipeService.toggleFavorite(userId!, recipe.id, isFav);
    if (!mounted) return;
    await _fetchAll();
  }

  List<Recipe> get filteredRecipes {
    if (searchQuery.isEmpty) return allRecipes;
    return allRecipes.where((r) => r.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32, left: 8, right: 8, bottom: 8),
                  child: showSearch
                      ? Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => setState(() => showSearch = false),
                            ),
                            Expanded(
                              child: TextField(
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Search recipes...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onChanged: (val) => setState(() => searchQuery = val),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'All Recipes',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => setState(() => showSearch = true),
                            ),
                          ],
                        ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeInfoScreen(
                                recipe: recipe,
                                addedRecipeIds: widget.addedRecipeIds,
                              ),
                            ),
                          );
                          if (!mounted) return;
                          if (result is Recipe) {
                            Navigator.pop(context, result);
                          }
                        },
                        child: Stack(
                          children: [
                            Container(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      topRight: Radius.circular(14),
                                    ),
                                    child: Image.network(
                                      recipe.imageUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recipe.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        if (recipe.cost > 0)
                                          Text('₱${recipe.cost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: GestureDetector(
                                onTap: () => _toggleFavorite(recipe),
                                child: Icon(
                                  favoriteRecipeIds.contains(recipe.id) ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.redAccent,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
} 