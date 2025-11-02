import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipes.dart';

class RecipeService {
  /// Disallowed keywords for suggestions (bizarre/off-putting for most users)
  static const List<String> _disallowedKeywords = [
    // English/common
    'chicken feet', 'feet', 'intestine', 'tripe', 'blood', 'offal', 'gizzard', 'liver', 'brain',
    // Filipino street-food colloquialisms
    'adidas', // chicken feet
    'isaw',   // intestines
    'betamax', // coagulated blood
    'helmet', // chicken head
    'dinuguan', // pork blood stew
  ];

  /// Returns true if the recipe should be disallowed in smart suggestions
  static bool isRecipeDisallowed(Recipe recipe) {
    final haystack = ([
      recipe.title,
      recipe.shortDescription,
      recipe.allergyWarning,
      ...recipe.ingredients,
      ...recipe.instructions,
      ...recipe.tags,
    ]).join(' ').toLowerCase();
    return _disallowedKeywords.any((kw) => haystack.contains(kw.toLowerCase()));
  }
  /// Fetch user allergies from preferences
  static Future<List<String>> fetchUserAllergies(String? userId) async {
    if (userId == null) return [];
    try {
      final response = await Supabase.instance.client
          .from('user_preferences')
          .select('allergies')
          .eq('user_id', userId)
          .maybeSingle();
      return List<String>.from(response?['allergies'] ?? []);
    } catch (_) {
      return [];
    }
  }

  /// Check if ingredient is optional (robust detection of optional markers)
  static bool _isOptionalIngredient(String ingredient) {
    final lower = ingredient.toLowerCase().trim();
    // Common patterns: "(optional)", "optional", "- optional", "optional:", "opt.", "(opt)"
    final patterns = [
      RegExp(r'\(\s*optional\s*\)$'),
      RegExp(r'\boptional\b'),
      RegExp(r'\(\s*opt\.?\s*\)$'),
      RegExp(r'[-–—]\s*optional\b'),
      RegExp(r'\boptional\s*[:\-]'),
      RegExp(r'\[\s*optional\s*\]'),
    ];
    return patterns.any((p) => p.hasMatch(lower));
  }

  /// Find which ingredients match an allergen and return them with their optional status
  static Map<String, dynamic> _findMatchingIngredients(Recipe recipe, String allergy) {
    final lowerAllergy = allergy.toLowerCase().trim();
    // Canonicalize common allergy labels and broaden keyword coverage
    final keywordMap = {
      'egg': ['egg', 'eggs', 'egg white', 'egg whites', 'egg yolk', 'egg yolks', 'mayonnaise', 'mayo'],
      'eggs': ['egg', 'eggs', 'egg white', 'egg whites', 'egg yolk', 'egg yolks', 'mayonnaise', 'mayo'],
      'dairy': ['milk', 'cheese', 'butter', 'cream', 'yogurt', 'dairy', 'mozzarella', 'cheddar', 'keso'],
      'milk': ['milk', 'cheese', 'butter', 'cream', 'yogurt', 'dairy', 'mozzarella', 'cheddar', 'keso'],
      'peanut': ['peanut', 'peanuts', 'peanut butter'],
      'peanuts': ['peanut', 'peanuts', 'peanut butter'],
      'tree nuts': ['almond', 'walnut', 'cashew', 'pistachio', 'hazelnut', 'pecan', 'macadamia', 'nut'],
      'nut': ['almond', 'walnut', 'cashew', 'pistachio', 'hazelnut', 'pecan', 'macadamia', 'nut'],
      'soy': ['soy', 'soya', 'soybean', 'tofu', 'tempeh', 'miso', 'soy sauce'],
      'wheat': ['wheat', 'gluten', 'flour', 'bread', 'pasta', 'noodle'],
      'gluten': ['wheat', 'gluten', 'flour', 'bread', 'pasta', 'noodle'],
      'wheat / gluten': ['wheat', 'gluten', 'flour', 'bread', 'pasta', 'noodle'],
      'fish': ['fish', 'salmon', 'tuna', 'tilapia', 'bangus', 'mackerel', 'sardine'],
      'shellfish': ['shrimp', 'prawn', 'crab', 'lobster', 'shellfish', 'crab meat', 'shrimp paste'],
      'sesame': ['sesame', 'tahini'],
    };

    final keywords = keywordMap[lowerAllergy] ?? [lowerAllergy];
    final matchingIngredients = <String>[];
    bool hasRequiredMatch = false;
    bool hasOptionalMatch = false;

    // Check ingredients
    for (final ingredient in recipe.ingredients) {
      final lowerIngredient = ingredient.toLowerCase();
      final isOptional = _isOptionalIngredient(ingredient);
      final matches = keywords.any((keyword) => lowerIngredient.contains(keyword));
      
      if (matches) {
        matchingIngredients.add(ingredient);
        if (isOptional) {
          hasOptionalMatch = true;
        } else {
          hasRequiredMatch = true;
        }
      }
    }

    // Do NOT elevate to required match based on title/description labels alone.
    // We only consider actual ingredient lines for required vs optional classification.

    return {
      'hasMatch': matchingIngredients.isNotEmpty || hasRequiredMatch,
      'hasRequiredMatch': hasRequiredMatch,
      'hasOptionalMatch': hasOptionalMatch && !hasRequiredMatch,
      'matchingIngredients': matchingIngredients,
    };
  }


  /// Filter recipes by user allergies (exclude if required ingredients, keep with warning if optional only)
  static List<Recipe> filterRecipesByAllergies(List<Recipe> recipes, List<String> allergies) {
    if (allergies.isEmpty) return recipes;
    return recipes.where((recipe) {
      // Exclude if ANY allergy matches in required ingredients
      return !allergies.any((allergy) {
        final result = _findMatchingIngredients(recipe, allergy);
        return result['hasRequiredMatch'] == true;
      });
    }).toList();
  }

  /// Get recipes that have allergen warnings (optional ingredients only)
  static List<Map<String, dynamic>> getRecipesWithWarnings(List<Recipe> recipes, List<String> allergies) {
    if (allergies.isEmpty) return [];
    final warnings = <Map<String, dynamic>>[];
    
    for (final recipe in recipes) {
      for (final allergy in allergies) {
        final result = _findMatchingIngredients(recipe, allergy);
        if (result['hasOptionalMatch'] == true && result['hasRequiredMatch'] != true) {
          warnings.add({
            'recipe': recipe,
            'allergy': allergy,
            'matchingIngredients': result['matchingIngredients'] as List<String>,
          });
          break; // Only one warning per recipe
        }
      }
    }
    
    return warnings;
  }

  /// Get matching ingredients for a recipe and allergy (for highlighting)
  static List<String> getMatchingIngredients(Recipe recipe, String allergy) {
    final result = _findMatchingIngredients(recipe, allergy);
    return result['matchingIngredients'] as List<String>;
  }

  static Future<List<Recipe>> fetchRecipes({String? userId}) async {
    final response = await Supabase.instance.client
        .from('recipes')
        .select()
        .then((data) => data);

    // If using the latest supabase_flutter, .select() returns a Future<List<Map<String, dynamic>>>
    // So we can map directly:
    final allRecipes = (response as List)
        .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
        .toList();

    // Filter by allergies if userId provided
    if (userId != null) {
      final allergies = await fetchUserAllergies(userId);
      return filterRecipesByAllergies(allRecipes, allergies);
    }

    return allRecipes;
  }

  static Future<List<Recipe>> fetchRecentlyAdded({int limit = 50, String? userId}) async {
    List<Recipe> recipes;
    try {
      final response = await Supabase.instance.client
          .from('recipes')
          .select()
          .order('updated_at', ascending: false)
          .limit(limit);
      recipes = (response as List)
          .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final response = await Supabase.instance.client
          .from('recipes')
          .select()
          .order('id', ascending: false)
          .limit(limit);
      recipes = (response as List)
          .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    // Filter by allergies if userId provided
    if (userId != null) {
      final allergies = await fetchUserAllergies(userId);
      return filterRecipesByAllergies(recipes, allergies);
    }

    return recipes;
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