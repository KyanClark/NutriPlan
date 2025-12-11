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
    // Test/development recipes
    'test', 'test1', 'test2', 'test3', 'testing', 'sample', 'demo',
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
  /// Helper function to safely convert a value to List<String>
  static List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    
    // If it's already a List, convert it
    if (value is List) {
      try {
        return value.map((e) => e.toString()).toList();
      } catch (_) {
        return [];
      }
    }
    
    // If it's a String, try to parse it
    if (value is String) {
      if (value.isEmpty) return [];
      try {
        // Try to parse as JSON array
        if (value.startsWith('[') && value.endsWith(']')) {
          // Remove brackets and quotes, split by comma
          final cleaned = value
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll("'", '')
              .trim();
          if (cleaned.isEmpty) return [];
          return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        // If it's a single string value, return as single-item list
        return [value.trim()];
      } catch (_) {
        // If parsing fails, return as single-item list
        return [value.toString()];
      }
    }
    
    return [];
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
      return _safeStringList(response?['allergies']);
    } catch (_) {
      return [];
    }
  }

  /// Fetch user diet types from preferences
  static Future<List<String>> fetchUserDietTypes(String? userId) async {
    if (userId == null) return [];
    try {
      final response = await Supabase.instance.client
          .from('user_preferences')
          .select('diet_type')
          .eq('user_id', userId)
          .maybeSingle();
      return _safeStringList(response?['diet_type']);
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

  /// Check if a recipe is vegetarian (no meat as main ingredient)
  static bool _isVegetarianRecipe(Recipe recipe) {
    // Meat keywords to check (English and Filipino)
    final meatKeywords = [
      // English
      'chicken', 'pork', 'beef', 'meat', 'poultry', 'turkey', 'duck', 'lamb', 'mutton',
      'bacon', 'ham', 'sausage', 'hotdog', 'hot dog', 'chorizo', 'longganisa',
      // Filipino
      'manok', 'baboy', 'baka', 'karne', 'lechon', 'adobo', 'sinigang', 'tinola',
      'nilaga', 'bulalo', 'kare-kare', 'kaldereta', 'menudo', 'afritada',
      // Fish and seafood (excluded for strict vegetarian)
      'fish', 'tilapia', 'bangus', 'salmon', 'tuna', 'mackerel', 'sardine',
      'shrimp', 'prawn', 'crab', 'lobster', 'squid', 'octopus', 'shellfish',
      'hipon', 'alimango', 'pusit', 'tulya', 'tahong',
    ];

    final lowerTitle = recipe.title.toLowerCase();
    final lowerDescription = recipe.shortDescription.toLowerCase();
    final allText = [lowerTitle, lowerDescription, ...recipe.tags.map((t) => t.toLowerCase())].join(' ');

    // Check if title/description contains meat keywords
    if (meatKeywords.any((keyword) => allText.contains(keyword))) {
      return false;
    }

    // Check ingredients for meat (only required ingredients, not optional)
    for (final ingredient in recipe.ingredients) {
      final lowerIngredient = ingredient.toLowerCase();
      final isOptional = _isOptionalIngredient(ingredient);
      
      // Skip optional ingredients
      if (isOptional) continue;

      // Check if ingredient contains meat keywords
      if (meatKeywords.any((keyword) => lowerIngredient.contains(keyword))) {
        return false;
      }
    }

    // If recipe has Vegetarian or Vegan tag, it's vegetarian
    if (recipe.tags.any((tag) => 
        tag.toLowerCase() == 'vegetarian' || 
        tag.toLowerCase() == 'vegan')) {
      return true;
    }

    // If no meat found, consider it vegetarian
    return true;
  }

  /// Filter recipes by diet type
  static List<Recipe> filterRecipesByDietType(List<Recipe> recipes, List<String> dietTypes) {
    if (dietTypes.isEmpty) return recipes;
    final normalized = dietTypes.map((e) => e.toLowerCase()).toList();

    // Keto: very low carbs, avoid grain/sugar-heavy ingredients
    if (normalized.contains('keto')) {
      const carbLimit = 20; // grams per recipe serving
      const sugarLimit = 8; // grams per recipe serving
      const disallowedKeywords = [
        'rice',
        'noodle',
        'pasta',
        'bread',
        'bun',
        'tortilla',
        'corn',
        'flour',
        'sugar',
        'honey',
        'syrup',
        'sweetened',
        'cake',
        'dessert',
        'cookie',
      ];

      recipes = recipes.where((recipe) {
        final carbs = (recipe.macros['carbs'] ?? 0).toDouble();
        final sugar = (recipe.macros['sugar'] ?? 0).toDouble();
        if (carbs > carbLimit || sugar > sugarLimit) return false;

        final haystack = ([
          recipe.title,
          recipe.shortDescription,
          ...recipe.ingredients,
          ...recipe.tags,
        ]).join(' ').toLowerCase();
        if (disallowedKeywords.any((kw) => haystack.contains(kw))) return false;

        return true;
      }).toList();
    }

    // Vegetarian: allow dairy/eggs, exclude meat/fish/shellfish
    if (normalized.contains('vegetarian')) {
      return recipes.where((recipe) => _isVegetarianRecipe(recipe)).toList();
    }

    // Vegan: strict vegetarian + no dairy/eggs
    if (normalized.contains('vegan')) {
      return recipes.where((recipe) {
        if (!_isVegetarianRecipe(recipe)) return false;
        
        // Also exclude dairy and eggs
        final nonVeganKeywords = [
          'milk', 'cheese', 'butter', 'cream', 'yogurt', 'dairy', 'egg', 'eggs',
          'mozzarella', 'cheddar', 'keso', 'gatas', 'itlog',
        ];

        // Check if any required ingredient contains non-vegan keywords
        for (final ingredient in recipe.ingredients) {
          final isOptional = _isOptionalIngredient(ingredient);
          if (isOptional) continue;
          
          final lowerIngredient = ingredient.toLowerCase();
          if (nonVeganKeywords.any((keyword) => lowerIngredient.contains(keyword))) {
            return false;
          }
        }

        return true;
      }).toList();
    }

    // Pescatarian: allow fish/seafood, exclude meat/poultry
    if (normalized.contains('pescatarian')) {
      final meatKeywords = ['chicken', 'pork', 'beef', 'turkey', 'duck', 'lamb', 'mutton', 'meat', 'poultry'];
      recipes = recipes.where((recipe) {
        final title = recipe.title.toLowerCase();
        final tags = recipe.tags.map((t) => t.toLowerCase()).toList();
        final hasMeat = meatKeywords.any((kw) => title.contains(kw) || tags.any((t) => t.contains(kw)));
        return !hasMeat;
      }).toList();
    }

    // Dairy-Free: exclude dairy keywords
    if (normalized.contains('dairy-free')) {
      final dairyKw = ['milk', 'cheese', 'butter', 'cream', 'yogurt', 'keso', 'mozzarella', 'cheddar', 'dairy'];
      recipes = recipes.where((recipe) {
        final hay = (recipe.title + ' ' + recipe.shortDescription + ' ' + recipe.ingredients.join(' ') + ' ' + recipe.tags.join(' ')).toLowerCase();
        return !dairyKw.any((kw) => hay.contains(kw));
      }).toList();
    }

    // Gluten-Free: exclude wheat/gluten keywords
    if (normalized.contains('gluten-free')) {
      final glutenKw = ['gluten', 'wheat', 'flour', 'bread', 'pasta', 'noodle', 'batter', 'breadcrumbs'];
      recipes = recipes.where((recipe) {
        final hay = (recipe.title + ' ' + recipe.shortDescription + ' ' + recipe.ingredients.join(' ') + ' ' + recipe.tags.join(' ')).toLowerCase();
        return !glutenKw.any((kw) => hay.contains(kw));
      }).toList();
    }

    // Low Carb: carbs <= 30g per serving
    if (normalized.contains('low carb')) {
      recipes = recipes.where((r) {
        final carbs = (r.macros['carbs'] ?? 0).toDouble();
        return carbs <= 30;
      }).toList();
    }

    // Low Fat: fat <= 15g per serving
    if (normalized.contains('low fat')) {
      recipes = recipes.where((r) {
        final fat = (r.macros['fat'] ?? 0).toDouble();
        return fat <= 15;
      }).toList();
    }

    // High Protein: protein >= 25g per serving
    if (normalized.contains('high protein')) {
      recipes = recipes.where((r) {
        final protein = (r.macros['protein'] ?? 0).toDouble();
        return protein >= 25;
      }).toList();
    }

    // Balance Diet or Flexitarian: no extra filtering (return remaining)
    return recipes;
  }

  static Future<List<Recipe>> fetchRecipes({String? userId}) async {
    final response = await Supabase.instance.client
        .from('recipes')
        .select()
        .then((data) => data);

    // If using the latest supabase_flutter, .select() returns a Future<List<Map<String, dynamic>>>
    // So we can map directly:
    var allRecipes = (response as List)
        .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
        .toList();

    // Filter by diet type first (if userId provided)
    if (userId != null) {
      final dietTypes = await fetchUserDietTypes(userId);
      allRecipes = filterRecipesByDietType(allRecipes, dietTypes);
    }

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

    // Filter by diet type first (if userId provided)
    if (userId != null) {
      final dietTypes = await fetchUserDietTypes(userId);
      recipes = filterRecipesByDietType(recipes, dietTypes);
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