import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipes.dart';
import '../../services/recipe_service.dart';
import 'recipe_info_screen.dart';

class SeeAllRecipePage extends StatefulWidget {
  final List<String> addedRecipeIds;
  final Function(Recipe)? onAddToMealPlan;
  const SeeAllRecipePage({super.key, this.addedRecipeIds = const [], this.onAddToMealPlan});

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
      await _fetchAll();

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
                              icon: const Icon(Icons.arrow_back_ios),
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
                              icon: const Icon(Icons.arrow_back_ios),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount: 2,
                       crossAxisSpacing: 16,
                       mainAxisSpacing: 16,
                       childAspectRatio: 0.7,
                     ),
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      return GestureDetector(
                        onTap: () async {
                          // Navigate directly to recipe info
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeInfoScreen(
                                recipe: recipe,
                                addedRecipeIds: widget.addedRecipeIds,
                                onAddToMealPlan: widget.onAddToMealPlan,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 200,
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
                                            favoriteRecipeIds.contains(recipe.id) ? Icons.favorite : Icons.favorite_border,
                                            color: favoriteRecipeIds.contains(recipe.id) ? const Color(0xFFFF6961) : Colors.grey,
                                            size: 25,
                                          ),
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
            ),
    );
  }
} 