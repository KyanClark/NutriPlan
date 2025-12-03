import 'package:supabase_flutter/supabase_flutter.dart';
import '../../user/models/recipes.dart';
import '../../user/utils/app_logger.dart';
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

    // Check if user is authenticated
    final user = Supabase.instance.client.auth.currentUser;
    AppLogger.info('Fetching recipes. Authenticated user: ${user?.email ?? "none"}, User ID: ${user?.id ?? "none"}');

    if (user == null) {
      AppLogger.error('No authenticated user found');
      throw Exception('Not authenticated. Please log out and log back in.');
    }

    try {
      // Try with order by created_at first
      AppLogger.info('Attempting to fetch recipes with order by created_at...');
      final response = await Supabase.instance.client
          .from('recipes')
          .select()
          .order('created_at', ascending: false);

      AppLogger.info('Recipes fetched successfully: ${(response as List).length} recipes');
      return (response as List)
          .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching recipes with order by created_at: $e');
      
      // Try without order clause as fallback
      try {
        AppLogger.info('Retrying without order clause...');
        final response = await Supabase.instance.client
            .from('recipes')
            .select();

        AppLogger.info('Recipes fetched successfully (no order): ${(response as List).length} recipes');
        final recipes = (response as List)
            .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
            .toList();
        
        // Sort manually by title (since Recipe model doesn't have createdAt)
        recipes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        
        return recipes;
      } catch (e2) {
        AppLogger.error('Error fetching recipes without order: $e2');
        
        // Provide detailed error message
        final errorMsg = e.toString().toLowerCase();
        final errorMsg2 = e2.toString().toLowerCase();
        
        if (errorMsg.contains('permission') || errorMsg.contains('policy') || errorMsg.contains('rls') || errorMsg.contains('row-level') ||
            errorMsg2.contains('permission') || errorMsg2.contains('policy') || errorMsg2.contains('rls') || errorMsg2.contains('row-level')) {
          throw Exception('Permission denied (RLS). Please ensure RLS policies allow authenticated users to read recipes.\nCurrent user: ${user.email}\nUser ID: ${user.id}\n\nError: $e');
        }
        if (errorMsg.contains('jwt') || errorMsg.contains('token') || errorMsg.contains('unauthorized') ||
            errorMsg2.contains('jwt') || errorMsg2.contains('token') || errorMsg2.contains('unauthorized')) {
          throw Exception('Authentication failed. Please log out and log back in.\nError: $e');
        }
        throw Exception('Failed to fetch recipes.\nFirst error: $e\nSecond error: $e2');
      }
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

