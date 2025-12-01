import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipes.dart';
import '../../utils/app_logger.dart';
import 'admin_service.dart';

class AdminRecipeService {
  /// Create a new recipe
  static Future<Recipe> createRecipe({
    required String title,
    required String imageUrl,
    required String shortDescription,
    required List<String> ingredients,
    required List<String> instructions,
    required Map<String, dynamic> macros,
    required String allergyWarning,
    required int calories,
    required List<String> tags,
    required double cost,
    required String notes,
  }) async {
    await AdminService.requireAdmin();

    try {
      final response = await Supabase.instance.client
          .from('recipes')
          .insert({
            'title': title,
            'image_url': imageUrl,
            'short_description': shortDescription,
            'ingredients': ingredients,
            'instructions': instructions,
            'macros': macros,
            'allergy_warning': allergyWarning,
            'calories': calories,
            'tags': tags,
            'cost': cost,
            'notes': notes,
          })
          .select()
          .single();

      return Recipe.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      AppLogger.error('Error creating recipe', e);
      throw Exception('Failed to create recipe: $e');
    }
  }

  /// Update an existing recipe
  static Future<Recipe> updateRecipe({
    required String id,
    String? title,
    String? imageUrl,
    String? shortDescription,
    List<String>? ingredients,
    List<String>? instructions,
    Map<String, dynamic>? macros,
    String? allergyWarning,
    int? calories,
    List<String>? tags,
    double? cost,
    String? notes,
  }) async {
    await AdminService.requireAdmin();

    try {
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (shortDescription != null) updateData['short_description'] = shortDescription;
      if (ingredients != null) updateData['ingredients'] = ingredients;
      if (instructions != null) updateData['instructions'] = instructions;
      if (macros != null) updateData['macros'] = macros;
      if (allergyWarning != null) updateData['allergy_warning'] = allergyWarning;
      if (calories != null) updateData['calories'] = calories;
      if (tags != null) updateData['tags'] = tags;
      if (cost != null) updateData['cost'] = cost;
      if (notes != null) updateData['notes'] = notes;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await Supabase.instance.client
          .from('recipes')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Recipe.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      AppLogger.error('Error updating recipe', e);
      throw Exception('Failed to update recipe: $e');
    }
  }

  /// Delete a recipe
  static Future<void> deleteRecipe(String id) async {
    await AdminService.requireAdmin();

    try {
      await Supabase.instance.client
          .from('recipes')
          .delete()
          .eq('id', id);
    } catch (e) {
      AppLogger.error('Error deleting recipe', e);
      throw Exception('Failed to delete recipe: $e');
    }
  }

  /// Get all recipes (admin view - no filtering)
  static Future<List<Recipe>> getAllRecipes() async {
    await AdminService.requireAdmin();

    try {
      final response = await Supabase.instance.client
          .from('recipes')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching all recipes', e);
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  /// Get a single recipe by ID
  static Future<Recipe?> getRecipeById(String id) async {
    await AdminService.requireAdmin();

    try {
      final response = await Supabase.instance.client
          .from('recipes')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Recipe.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      AppLogger.error('Error fetching recipe', e);
      throw Exception('Failed to fetch recipe: $e');
    }
  }

  /// Search recipes by title or description
  static Future<List<Recipe>> searchRecipes(String query) async {
    await AdminService.requireAdmin();

    try {
      final response = await Supabase.instance.client
          .from('recipes')
          .select()
          .or('title.ilike.%$query%,short_description.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error searching recipes', e);
      throw Exception('Failed to search recipes: $e');
    }
  }
}

