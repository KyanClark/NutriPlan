import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipes.dart';
import '../models/user_nutrition_goals.dart';
import 'ai_meal_plan_service.dart';
import 'recipe_service.dart';
import '../utils/app_logger.dart';

/// Service for auto-generating meal plans based on user preferences
/// Uses TikTok-like algorithm: learns from user's meal history, preferences, and health conditions
class AutoMealPlanService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Generate a complete meal plan using AI to analyze and select the best meals
  /// This is the enhanced version that uses AI to intelligently choose meals
  static Future<List<Map<String, dynamic>>> generateMealPlanWithAI({
    required String userId,
    required DateTime targetDate,
    bool includeBreakfast = true,
    bool includeLunch = true,
    bool includeDinner = true,
    List<String>? excludeRecipeIds, // Exclude these recipe IDs (for "Generate Again")
  }) async {
    try {
      // Get all necessary user data
      final mealHistory = await _getUserMealHistory(userId, days: 30);
      final userPrefs = await _getUserPreferences(userId);
      final userGoals = await _getUserNutritionGoals(userId);
      
      // Get all available recipes (already filtered by allergies and diet type)
      var allRecipes = await RecipeService.fetchRecipes(userId: userId);
      // Filter out disallowed recipes and test recipes
      allRecipes = allRecipes.where((r) {
        if (RecipeService.isRecipeDisallowed(r)) return false;
        // Also filter out test recipes explicitly
        final titleLower = r.title.toLowerCase();
        if (titleLower.contains('test') || titleLower.contains('sample') || titleLower.contains('demo')) {
          return false;
        }
        // Ensure recipe has valid title and calories
        if (r.title.trim().isEmpty || r.calories <= 0) return false;
        return true;
      }).toList();
      
      // Filter out excluded recipe IDs
      if (excludeRecipeIds != null && excludeRecipeIds.isNotEmpty) {
        allRecipes = allRecipes.where((r) => !excludeRecipeIds.contains(r.id)).toList();
      }
      
      // Get recent meals to avoid repetition (last 14 days)
      final recentMeals = await _getRecentMealTitles(userId, days: 14);
      
      // Get current day nutrition
      final currentNutrition = await _getCurrentDayNutrition(userId, targetDate);
      
      // Use dedicated AI meal plan service (separate from smart meal suggestions)
      final aiMeals = await AIMealPlanService.generateMealPlan(
        userId: userId,
        targetDate: targetDate,
        allRecipes: allRecipes,
        mealHistory: mealHistory,
        userPrefs: userPrefs,
        userGoals: userGoals,
        currentNutrition: currentNutrition,
        recentMeals: recentMeals,
        includeBreakfast: includeBreakfast,
        includeLunch: includeLunch,
        includeDinner: includeDinner,
      );
      
      if (aiMeals.isNotEmpty) {
        return aiMeals;
      }
      
      // Fallback to rule-based if AI fails
      AppLogger.warning('AI meal plan generation failed, falling back to rule-based');
      return await generateMealPlan(
        userId: userId,
        targetDate: targetDate,
        includeBreakfast: includeBreakfast,
        includeLunch: includeLunch,
        includeDinner: includeDinner,
        excludeRecipeIds: excludeRecipeIds,
        useAI: false, // Prevent infinite loop
      );
    } catch (e) {
      AppLogger.error('Error generating AI meal plan', e);
      // Fallback to rule-based
      return await generateMealPlan(
        userId: userId,
        targetDate: targetDate,
        includeBreakfast: includeBreakfast,
        includeLunch: includeLunch,
        includeDinner: includeDinner,
        excludeRecipeIds: excludeRecipeIds,
      );
    }
  }

  /// Generate a complete meal plan for a specific date
  /// Returns a list of recipes with meal types and times
  /// Ensures different meals for breakfast, lunch, and dinner
  /// Now uses AI by default for intelligent meal selection
  static Future<List<Map<String, dynamic>>> generateMealPlan({
    required String userId,
    required DateTime targetDate,
    bool includeBreakfast = true,
    bool includeLunch = true,
    bool includeDinner = true,
    List<String>? excludeRecipeIds, // Exclude these recipe IDs (for "Generate Again")
    bool useAI = true, // Use AI-powered generation by default
  }) async {
    // Try AI-powered generation first if enabled
    if (useAI) {
      try {
        final aiResult = await generateMealPlanWithAI(
          userId: userId,
          targetDate: targetDate,
          includeBreakfast: includeBreakfast,
          includeLunch: includeLunch,
          includeDinner: includeDinner,
          excludeRecipeIds: excludeRecipeIds,
        );
        if (aiResult.isNotEmpty) {
          return aiResult;
        }
      } catch (e) {
        AppLogger.warning('AI meal plan generation failed, falling back to rule-based', e);
      }
    }
    
    // Fallback to rule-based generation
    try {
      final List<Map<String, dynamic>> mealPlan = [];
      final Set<String> usedRecipeIds = {}; // Track used recipes to ensure uniqueness

      // Get user's meal history for learning patterns (TikTok-like algorithm)
      final mealHistory = await _getUserMealHistory(userId, days: 30);
      
      // Get user preferences
      final userPrefs = await _getUserPreferences(userId);
      
      // Get all available recipes (already filtered by allergies and diet type)
      var allRecipes = await RecipeService.fetchRecipes(userId: userId);
      
      // Filter out disallowed recipes and test recipes
      allRecipes = allRecipes.where((r) {
        if (RecipeService.isRecipeDisallowed(r)) return false;
        // Also filter out test recipes explicitly
        final titleLower = r.title.toLowerCase();
        if (titleLower.contains('test') || titleLower.contains('sample') || titleLower.contains('demo')) {
          return false;
        }
        // Ensure recipe has valid title and calories
        if (r.title.trim().isEmpty || r.calories <= 0) return false;
        return true;
      }).toList();
      
      // Filter out excluded recipe IDs (for "Generate Again" feature)
      if (excludeRecipeIds != null && excludeRecipeIds.isNotEmpty) {
        allRecipes = allRecipes.where((r) => !excludeRecipeIds.contains(r.id)).toList();
      }

      // Check health conditions
      final healthConditions = userPrefs['health_conditions'] as List<dynamic>? ?? [];
      final hasHealthConditions = healthConditions.isNotEmpty && !healthConditions.contains('none');
      
      // Build recipe scores based on user patterns (TikTok algorithm)
      final recipeScores = _buildRecipeScores(allRecipes, mealHistory, userPrefs);
      
      // Separate recipes into healthy and all recipes
      final healthyRecipes = allRecipes.where((r) {
        final protein = (r.macros['protein'] ?? 0).toDouble();
        final fiber = (r.macros['fiber'] ?? 0).toDouble();
        final sugar = (r.macros['sugar'] ?? 0).toDouble();
        final sodium = (r.macros['sodium'] ?? 0).toDouble();
        final calories = r.calories.toDouble();
        
        // Healthy criteria: reasonable calories, low sugar, low sodium, has protein or fiber
        if (calories < 200 || calories > 800) return false;
        if (sugar > 30) return false;
        if (sodium > 1000) return false;
        if (protein < 5 && fiber < 2) return false;
        
        // Check health conditions if any
        if (hasHealthConditions) {
          return _isRecipeHealthyForConditions(r, healthConditions.map((e) => e.toString()).toList());
        }
        return true;
      }).toList();

      // Generate meals: 1 random + 2 healthy (if no health conditions), or all healthy (if health conditions)
      final mealsToGenerate = <Map<String, String>>[];
      if (includeBreakfast) mealsToGenerate.add({'type': 'breakfast', 'time': '8:00'});
      if (includeLunch) mealsToGenerate.add({'type': 'lunch', 'time': '12:30'});
      if (includeDinner) mealsToGenerate.add({'type': 'dinner', 'time': '19:00'});
      
      // Shuffle for randomness
      final random = Random();
      mealsToGenerate.shuffle(random);
      
      int randomMealCount = 0;
      for (final mealInfo in mealsToGenerate) {
        final mealType = mealInfo['type']!;
        final mealTime = mealInfo['time']!.split(':');
        final hour = int.parse(mealTime[0]);
        final minute = int.parse(mealTime[1]);
        final targetTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
        
        Recipe? selectedRecipe;
        
        // If no health conditions: 1 random + 2 healthy
        // If health conditions: all healthy
        if (!hasHealthConditions && randomMealCount == 0 && mealsToGenerate.length > 1) {
          // First meal: random from all recipes
          final availableRecipes = allRecipes.where((r) => !usedRecipeIds.contains(r.id)).toList();
          if (availableRecipes.isNotEmpty) {
            availableRecipes.shuffle(random);
            selectedRecipe = availableRecipes.first;
            randomMealCount++;
          }
        } else {
          // Healthy meal: prioritize healthy recipes
          final availableHealthy = healthyRecipes.where((r) => !usedRecipeIds.contains(r.id)).toList();
          if (availableHealthy.isNotEmpty) {
            // Sort by score for better selection
            availableHealthy.sort((a, b) => (recipeScores[b.id] ?? 0).compareTo(recipeScores[a.id] ?? 0));
            selectedRecipe = availableHealthy.first;
          } else {
            // Fallback to any available recipe
            final availableRecipes = allRecipes.where((r) => !usedRecipeIds.contains(r.id)).toList();
            if (availableRecipes.isNotEmpty) {
              availableRecipes.shuffle(random);
              selectedRecipe = availableRecipes.first;
            }
          }
        }
        
        if (selectedRecipe != null) {
          usedRecipeIds.add(selectedRecipe.id);
          mealPlan.add({
            'recipe': selectedRecipe,
            'meal_type': mealType,
            'meal_time': _formatTime(targetTime),
            'date': targetTime,
          });
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

  /// Get user nutrition goals
  static Future<UserNutritionGoals?> _getUserNutritionGoals(String userId) async {
    try {
      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null ? UserNutritionGoals.fromMap(response) : null;
    } catch (e) {
      AppLogger.error('Error fetching user goals', e);
      return null;
    }
  }

  /// Get current day nutrition
  static Future<Map<String, double>> _getCurrentDayNutrition(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final response = await _client
          .from('meal_plan_history')
          .select()
          .eq('user_id', userId)
          .gte('completed_at', startOfDay.toUtc().toIso8601String())
          .lt('completed_at', endOfDay.toUtc().toIso8601String());
      
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalFiber = 0;
      
      for (final meal in response) {
        totalCalories += _parseDouble(meal['calories']);
        totalProtein += _parseDouble(meal['protein']);
        totalCarbs += _parseDouble(meal['carbs']);
        totalFat += _parseDouble(meal['fat']);
        totalFiber += _parseDouble(meal['fiber']);
      }
      
      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'fiber': totalFiber,
      };
    } catch (e) {
      AppLogger.error('Error fetching current day nutrition', e);
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0, 'fiber': 0};
    }
  }

  /// Get recent meal titles to avoid repetition
  static Future<Set<String>> _getRecentMealTitles(String userId, {int days = 14}) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('meal_plan_history')
          .select('title')
          .eq('user_id', userId)
          .gte('completed_at', since.toUtc().toIso8601String());
      return response.map((m) => (m['title'] ?? '').toString().toLowerCase()).where((t) => t.isNotEmpty).toSet();
    } catch (e) {
      AppLogger.error('Error fetching recent meals', e);
      return <String>{};
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

