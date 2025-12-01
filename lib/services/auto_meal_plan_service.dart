import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipes.dart';
import '../models/meal_history_entry.dart';
import 'smart_meal_suggestion_service.dart';
import 'recipe_service.dart';
import '../utils/app_logger.dart';

/// Service for auto-generating meal plans based on user preferences
/// Uses TikTok-like algorithm: learns from user's meal history, preferences, and health conditions
class AutoMealPlanService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Generate a complete meal plan for a specific date
  /// Returns a list of recipes with meal types and times
  /// Ensures different meals for breakfast, lunch, and dinner
  static Future<List<Map<String, dynamic>>> generateMealPlan({
    required String userId,
    required DateTime targetDate,
    bool includeBreakfast = true,
    bool includeLunch = true,
    bool includeDinner = true,
  }) async {
    try {
      final List<Map<String, dynamic>> mealPlan = [];
      final Set<String> usedRecipeIds = {}; // Track used recipes to ensure uniqueness

      // Get user's meal history for learning patterns (TikTok-like algorithm)
      final mealHistory = await _getUserMealHistory(userId, days: 30);
      
      // Get user preferences
      final userPrefs = await _getUserPreferences(userId);
      
      // Get all available recipes (already filtered by allergies and diet type)
      var allRecipes = await RecipeService.fetchRecipes(userId: userId);
      
      // Filter out disallowed recipes
      allRecipes = allRecipes.where((r) => !RecipeService.isRecipeDisallowed(r)).toList();

      // Build recipe scores based on user patterns (TikTok algorithm)
      final recipeScores = _buildRecipeScores(allRecipes, mealHistory, userPrefs);

      // Generate breakfast
      if (includeBreakfast) {
        final breakfast = await _generateMealForType(
          userId: userId,
          mealType: 'breakfast',
          targetTime: DateTime(targetDate.year, targetDate.month, targetDate.day, 8, 0),
          recipeScores: recipeScores,
          allRecipes: allRecipes,
          usedRecipeIds: usedRecipeIds,
        );
        if (breakfast != null) {
          mealPlan.add(breakfast);
          usedRecipeIds.add((breakfast['recipe'] as Recipe).id);
        }
      }

      // Generate lunch
      if (includeLunch) {
        final lunch = await _generateMealForType(
          userId: userId,
          mealType: 'lunch',
          targetTime: DateTime(targetDate.year, targetDate.month, targetDate.day, 12, 30),
          recipeScores: recipeScores,
          allRecipes: allRecipes,
          usedRecipeIds: usedRecipeIds,
        );
        if (lunch != null) {
          mealPlan.add(lunch);
          usedRecipeIds.add((lunch['recipe'] as Recipe).id);
        }
      }

      // Generate dinner
      if (includeDinner) {
        final dinner = await _generateMealForType(
          userId: userId,
          mealType: 'dinner',
          targetTime: DateTime(targetDate.year, targetDate.month, targetDate.day, 19, 0),
          recipeScores: recipeScores,
          allRecipes: allRecipes,
          usedRecipeIds: usedRecipeIds,
        );
        if (dinner != null) {
          mealPlan.add(dinner);
          usedRecipeIds.add((dinner['recipe'] as Recipe).id);
        }
      }

      return mealPlan;
    } catch (e) {
      AppLogger.error('Error generating meal plan', e);
      return [];
    }
  }

  /// Get user's meal history for pattern learning
  static Future<List<Map<String, dynamic>>> _getUserMealHistory(String userId, {int days = 30}) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('meal_plan_history')
          .select('title, recipe_id, completed_at, meal_type')
          .eq('user_id', userId)
          .gte('completed_at', since.toUtc().toIso8601String())
          .order('completed_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Error fetching meal history', e);
      return [];
    }
  }

  /// Get user preferences
  static Future<Map<String, dynamic>> _getUserPreferences(String userId) async {
    try {
      final response = await _client
          .from('user_preferences')
          .select('like_dishes, health_conditions, diet_type, nutrition_needs')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return {};
      
      return {
        'like_dishes': _parseStringList(response['like_dishes']),
        'health_conditions': _parseStringList(response['health_conditions']),
        'diet_type': _parseStringList(response['diet_type']),
        'nutrition_needs': _parseStringList(response['nutrition_needs']),
      };
    } catch (e) {
      AppLogger.error('Error fetching user preferences', e);
      return {};
    }
  }

  /// Build recipe scores based on user patterns (TikTok-like algorithm)
  /// Higher score = more likely to be recommended
  static Map<String, double> _buildRecipeScores(
    List<Recipe> recipes,
    List<Map<String, dynamic>> mealHistory,
    Map<String, dynamic> userPrefs,
  ) {
    final scores = <String, double>{};
    
    // Initialize all recipes with base score
    for (final recipe in recipes) {
      scores[recipe.id] = 1.0;
    }

    // 1. Frequency-based scoring (TikTok: more views = more recommendations)
    // But with decay: recent meals get higher weight
    final now = DateTime.now();
    for (final meal in mealHistory) {
      final recipeId = meal['recipe_id']?.toString();
      final title = meal['title']?.toString().toLowerCase() ?? '';
      final completedAt = meal['completed_at'];
      
      if (recipeId == null && title.isEmpty) continue;
      
      // Calculate time decay (more recent = higher weight)
      double timeWeight = 1.0;
      if (completedAt != null) {
        try {
          final mealDate = DateTime.parse(completedAt);
          final daysAgo = now.difference(mealDate).inDays;
          timeWeight = 1.0 / (1.0 + daysAgo * 0.1); // Decay factor
        } catch (_) {}
      }
      
      // Boost score for frequently eaten recipes
      for (final recipe in recipes) {
        if (recipe.id == recipeId || recipe.title.toLowerCase() == title) {
          scores[recipe.id] = (scores[recipe.id] ?? 1.0) + (2.0 * timeWeight);
        }
      }
    }

    // 2. Preference-based scoring (liked dishes)
    final likedDishes = userPrefs['like_dishes'] as List<dynamic>? ?? [];
    for (final dish in likedDishes) {
      final dishStr = dish.toString().toLowerCase();
      for (final recipe in recipes) {
        if (recipe.title.toLowerCase().contains(dishStr.replaceAll('_', ' ')) ||
            recipe.tags.any((tag) => tag.toLowerCase().contains(dishStr))) {
          scores[recipe.id] = (scores[recipe.id] ?? 1.0) + 3.0;
        }
      }
    }

    // 3. Health condition matching
    final healthConditions = userPrefs['health_conditions'] as List<dynamic>? ?? [];
    if (healthConditions.isNotEmpty && !healthConditions.contains('none')) {
      for (final recipe in recipes) {
        if (_isRecipeHealthyForConditions(recipe, healthConditions.map((e) => e.toString()).toList())) {
          scores[recipe.id] = (scores[recipe.id] ?? 1.0) + 2.0;
        }
      }
    }

    // 4. Variety bonus: slightly penalize very recent meals to encourage variety
    final recentTitles = mealHistory
        .take(7)
        .map((m) => m['title']?.toString().toLowerCase() ?? '')
        .where((t) => t.isNotEmpty)
        .toSet();
    
    for (final recipe in recipes) {
      if (recentTitles.contains(recipe.title.toLowerCase())) {
        scores[recipe.id] = (scores[recipe.id] ?? 1.0) * 0.7; // Reduce score for recent meals
      }
    }

    return scores;
  }

  /// Generate a meal for a specific meal type
  /// Ensures the recipe is not already used in the meal plan
  static Future<Map<String, dynamic>?> _generateMealForType({
    required String userId,
    required String mealType,
    required DateTime targetTime,
    required Map<String, double> recipeScores,
    required List<Recipe> allRecipes,
    required Set<String> usedRecipeIds,
  }) async {
    try {
      // Use smart meal suggestion service for better recommendations
      final mealCategory = mealType == 'breakfast' 
          ? MealCategory.breakfast 
          : mealType == 'lunch' 
              ? MealCategory.lunch 
              : MealCategory.dinner;

      final suggestions = await SmartMealSuggestionService.getSmartSuggestions(
        userId: userId,
        mealCategory: mealCategory,
        targetTime: targetTime,
        useAI: true,
      );

      // Filter out already used recipes
      final availableSuggestions = suggestions.where((s) => !usedRecipeIds.contains(s.recipe.id)).toList();
      
      Recipe? selectedRecipe;
      
      if (availableSuggestions.isNotEmpty) {
        // Use the top available suggestion
        selectedRecipe = availableSuggestions.first.recipe;
      } else {
        // Fallback: use scored recipes that haven't been used
        final availableRecipes = allRecipes.where((r) => !usedRecipeIds.contains(r.id)).toList();
        if (availableRecipes.isEmpty) {
          // If all recipes are used, allow repeats but prefer unused ones
          final scoredRecipes = allRecipes.map((r) => MapEntry(r, recipeScores[r.id] ?? 1.0)).toList();
          scoredRecipes.sort((a, b) => b.value.compareTo(a.value));
          if (scoredRecipes.isEmpty) return null;
          selectedRecipe = scoredRecipes.first.key;
        } else {
          final scoredRecipes = availableRecipes.map((r) => MapEntry(r, recipeScores[r.id] ?? 1.0)).toList();
          scoredRecipes.sort((a, b) => b.value.compareTo(a.value));
          selectedRecipe = scoredRecipes.first.key;
        }
      }
      
      if (selectedRecipe == null) {
        return null;
      }
      
      final recipe = selectedRecipe;

      return {
        'recipe': recipe,
        'meal_type': mealType,
        'meal_time': _formatTime(targetTime),
        'date': targetTime,
      };
    } catch (e) {
      AppLogger.error('Error generating meal for type $mealType', e);
      return null;
    }
  }

  /// Check if recipe is healthy for user's health conditions
  static bool _isRecipeHealthyForConditions(Recipe recipe, List<String> healthConditions) {
    if (healthConditions.isEmpty || healthConditions.contains('none')) {
      return true;
    }

    final protein = (recipe.macros['protein'] ?? 0).toDouble();
    final carbs = (recipe.macros['carbs'] ?? 0).toDouble();
    final fiber = (recipe.macros['fiber'] ?? 0).toDouble();
    final sugar = (recipe.macros['sugar'] ?? 0).toDouble();
    final sodium = (recipe.macros['sodium'] ?? 0).toDouble();
    final calories = recipe.calories.toDouble();

    for (final condition in healthConditions) {
      switch (condition.toLowerCase()) {
        case 'diabetes':
          if (carbs > 60 || sugar > 15 || fiber < 3) return false;
          break;
        case 'hypertension':
          if (sodium > 500) return false;
          break;
        case 'stroke_recovery':
          if (sodium > 400) return false;
          break;
        case 'malnutrition':
          if (calories < 300 || protein < 15) return false;
          break;
        default:
          break;
      }
    }

    return true;
  }

  /// Format time as HH:MM
  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Parse string list from database
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      if (value.isEmpty) return [];
      if (value.startsWith('[') && value.endsWith(']')) {
        final cleaned = value
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .replaceAll("'", '')
            .trim();
        if (cleaned.isEmpty) return [];
        return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [value.trim()];
    }
    return [];
  }
}

