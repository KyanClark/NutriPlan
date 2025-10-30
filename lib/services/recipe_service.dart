import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipes.dart';

class RecipeService {
  static Future<List<Recipe>> fetchRecipes() async {
    final response = await Supabase.instance.client
        .from('recipes')
        .select()
        .then((data) => data);

    // If using the latest supabase_flutter, .select() returns a Future<List<Map<String, dynamic>>>
    // So we can map directly:
    return (response as List)
        .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Recipe>> fetchRecentlyAdded({int limit = 50}) async {
    try {
      final response = await Supabase.instance.client
          .from('recipes')
          .select()
          .order('updated_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final response = await Supabase.instance.client
          .from('recipes')
          .select()
          .order('id', ascending: false)
          .limit(limit);
      return (response as List)
          .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
          .toList();
    }
  }

  static Future<List<String>> fetchFavoriteRecipeIds(String userId) async {
    final response = await Supabase.instance.client
        .from('meal_favorites')
        .select('recipe_id')
        .eq('user_id', userId);
    return (response as List)
        .map((item) => item['recipe_id'].toString())
        .toList();
  }

  static Future<void> addFavorite(String userId, String recipeId) async {
    await Supabase.instance.client
        .from('meal_favorites')
        .insert({'user_id': userId, 'recipe_id': recipeId});
  }

  static Future<void> removeFavorite(String userId, String recipeId) async {
    await Supabase.instance.client
        .from('meal_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('recipe_id', recipeId);
  }

  static Future<void> toggleFavorite(String userId, String recipeId, bool isFavorite) async {
    if (isFavorite) {
      await removeFavorite(userId, recipeId);
    } else {
      await addFavorite(userId, recipeId);
    }
  }
} 