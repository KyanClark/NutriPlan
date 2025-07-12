import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipes.dart';
import '../services/recipe_service.dart';
import 'recipe_info_screen.dart';

class FavoritesPage extends StatefulWidget {
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Recipe> favoriteRecipes = [];
  bool isLoading = true;

  String? get userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteRecipes();
  }

  Future<void> _fetchFavoriteRecipes() async {
    if (userId == null) return;
    final ids = await RecipeService.fetchFavoriteRecipeIds(userId!);
    final allRecipes = await RecipeService.fetchRecipes();
    setState(() {
      favoriteRecipes = allRecipes.where((r) => ids.contains(r.id)).toList();
      isLoading = false;
    });
  }

  Future<void> _toggleFavorite(Recipe recipe) async {
    if (userId == null) return;
    await RecipeService.toggleFavorite(userId!, recipe.id, true);
    await _fetchFavoriteRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteRecipes.isEmpty
              ? const Center(child: Text('No favorite meals yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteRecipes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final recipe = favoriteRecipes[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeInfoScreen(recipe: recipe),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              recipe.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                            ),
                          ),
                          title: Text(recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.redAccent),
                            onPressed: () => _toggleFavorite(recipe),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 