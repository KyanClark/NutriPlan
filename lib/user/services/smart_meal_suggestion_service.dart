import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/smart_suggestion_models.dart';
import '../models/meal_history_entry.dart';
import '../models/user_nutrition_goals.dart';
import '../models/recipes.dart';
import 'recipe_service.dart';
import '../utils/app_logger.dart';
// Gemini integration removed

class SmartMealSuggestionService {
  static final SupabaseClient _client = Supabase.instance.client;
  // Read from .env via flutter_dotenv (fallback to --dart-define)
  static String get _groqApiKey =>
      (dotenv.env['GROQ_API_KEY'] ?? const String.fromEnvironment('GROQ_API_KEY', defaultValue: ''));

  /// Get smart meal suggestions for a specific meal category
  static Future<List<SmartMealSuggestion>> getSmartSuggestions({
    required String userId,
    required MealCategory mealCategory,
    DateTime? targetTime,
    bool useAI = true,
  }) async {
    try {
      final time = targetTime ?? DateTime.now();
      
      // 1. Get current day nutrition
      final currentNutrition = await _getCurrentDayNutrition(userId, time);
      
      // 2. Get user goals
      final userGoals = await _getUserNutritionGoals(userId);
      if (userGoals == null) {
        return await _getFallbackSuggestions(mealCategory, userId: userId);
      }
      
      // 3. Get user eating patterns
      final userPatterns = await _getUserEatingPatterns(userId);
      
      // 4. Calculate nutritional gaps first
      final nutritionalGaps = _calculateNutritionalGaps(currentNutrition, userGoals);
      
      final context = SuggestionContext(
        targetTime: time,
        mealCategory: mealCategory,
        userId: userId,
        currentNutrition: currentNutrition,
        userGoals: userGoals,
        userPatterns: userPatterns,
        nutritionalGaps: nutritionalGaps,
      );
      
      // 5. Try AI-powered suggestions first (if enabled)
      if (useAI) {
        try {
          final aiSuggestions = await _getAIPoweredSuggestions(context);
          if (aiSuggestions.isNotEmpty) {
            return aiSuggestions;
          }
        } catch (e) {
          AppLogger.warning('AI suggestions failed, falling back to rule-based', e);
        }
      }
      
      // 6. Fallback to rule-based suggestions
      return await _generateSmartSuggestions(context);
      
    } catch (e) {
      AppLogger.error('Error generating smart suggestions', e);
      return await _getFallbackSuggestions(mealCategory, userId: userId);
    }
  }

  /// Get current day nutrition status
  static Future<CurrentDayNutrition> _getCurrentDayNutrition(
    String userId, 
    DateTime date
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('meal_plan_history')
        .select()
        .eq('user_id', userId)
        .gte('completed_at', startOfDay.toUtc().toIso8601String())
        .lt('completed_at', endOfDay.toUtc().toIso8601String())
        .order('completed_at', ascending: true);

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;
    double totalCholesterol = 0;
    int mealCount = 0;
    final caloriesByMeal = <MealCategory, double>{};

    for (final meal in response) {
      totalCalories += _parseDouble(meal['calories']);
      totalProtein += _parseDouble(meal['protein']);
      totalCarbs += _parseDouble(meal['carbs']);
      totalFat += _parseDouble(meal['fat']);
      totalFiber += _parseDouble(meal['fiber']);
      totalSugar += _parseDouble(meal['sugar']);
      totalSodium += _parseDouble(meal['sodium']);
      totalCholesterol += _parseDouble(meal['cholesterol']);
      mealCount++;

      final category = _parseMealCategory(meal['meal_category'] ?? 'dinner');
      caloriesByMeal[category] = (caloriesByMeal[category] ?? 0) + 
          _parseDouble(meal['calories']);
    }

    return CurrentDayNutrition(
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalFiber: totalFiber,
      totalSugar: totalSugar,
      totalSodium: totalSodium,
      totalCholesterol: totalCholesterol,
      mealCount: mealCount,
      caloriesByMeal: caloriesByMeal,
      date: date,
    );
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

  /// Get user eating patterns (simplified version)
  static Future<UserEatingPatterns> _getUserEatingPatterns(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final response = await _client
          .from('meal_plan_history')
          .select()
          .eq('user_id', userId)
          .gte('completed_at', thirtyDaysAgo.toUtc().toIso8601String())
          .order('completed_at', ascending: true);

      final averageMealTimes = <MealCategory, List<DateTime>>{};
      final categoryCount = <String, int>{};
      final recipeCount = <String, int>{};
      final weeklyPatterns = <String, double>{};
      final categoryPreferences = <MealCategory, double>{}; 

      for (final meal in response) {
        final completedAt = DateTime.parse(meal['completed_at']);
        final category = meal['meal_category'] ?? 'dinner';
        final recipeTitle = meal['title'] ?? 'Unknown';

        // Track meal times by category
        final mealCategory = _parseMealCategory(category);
        if (!averageMealTimes.containsKey(mealCategory)) {
          averageMealTimes[mealCategory] = [];
        }
        averageMealTimes[mealCategory]!.add(completedAt);
        
        // Count categories
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        
        // Count recipes
        recipeCount[recipeTitle] = (recipeCount[recipeTitle] ?? 0) + 1;
        
        // Weekly patterns
        final dayOfWeek = _getDayOfWeek(completedAt.weekday);
        weeklyPatterns[dayOfWeek] = (weeklyPatterns[dayOfWeek] ?? 0) + 1;
        
        // Category preferences
        categoryPreferences[mealCategory] = (categoryPreferences[mealCategory] ?? 0) + 1;
      }

      // Get top categories and recipes
      final sortedCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final favoriteCategories = sortedCategories.take(5).map((e) => e.key).toList();

      final sortedRecipes = recipeCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final mostFrequentRecipes = sortedRecipes.take(5).map((e) => e.key).toList();

      return UserEatingPatterns(
        averageMealTimes: averageMealTimes,
        favoriteCategories: favoriteCategories,
        leastLikedIngredients: [], // TODO: Implement ingredient analysis
        weeklyPatterns: weeklyPatterns,
        seasonalPreferences: {}, // TODO: Implement seasonal analysis
        mostFrequentRecipes: mostFrequentRecipes,
        averageMealFrequency: response.length / 30.0,
        categoryPreferences: categoryPreferences,
        mealConsistencyScore: _calculateMealConsistency(response),
        mealVarietyScore: _calculateMealVariety(response),
      );
    } catch (e) {
      AppLogger.error('Error analyzing user patterns',  e);
      return UserEatingPatterns(
        averageMealTimes: {},
        favoriteCategories: [],
        leastLikedIngredients: [],
        weeklyPatterns: {},
        seasonalPreferences: {},
        mostFrequentRecipes: [],
        averageMealFrequency: 0.0,
        categoryPreferences: {},
        mealConsistencyScore: 0.0,
        mealVarietyScore: 0.0,
      );
    }
  }

  /// Calculate nutritional gaps
  static List<NutritionalGap> _calculateNutritionalGaps(
    CurrentDayNutrition current,
    UserNutritionGoals goals,
  ) {
    final gaps = <NutritionalGap>[];

    // Calorie gap
    final calorieGap = goals.calorieGoal - current.totalCalories;
    final caloriePercentage = (current.totalCalories / goals.calorieGoal) * 100;
    gaps.add(NutritionalGap(
      nutrient: 'calories',
      current: current.totalCalories,
      target: goals.calorieGoal,
      gap: calorieGap,
      percentage: caloriePercentage,
      priority: _getPriority(caloriePercentage),
    ));

    // Protein gap
    final proteinGap = goals.proteinGoal - current.totalProtein;
    final proteinPercentage = (current.totalProtein / goals.proteinGoal) * 100;
    gaps.add(NutritionalGap(
      nutrient: 'protein',
      current: current.totalProtein,
      target: goals.proteinGoal,
      gap: proteinGap,
      percentage: proteinPercentage,
      priority: _getPriority(proteinPercentage),
    ));

    // Fiber gap
    final fiberGap = goals.fiberGoal - current.totalFiber;
    final fiberPercentage = (current.totalFiber / goals.fiberGoal) * 100;
    gaps.add(NutritionalGap(
      nutrient: 'fiber',
      current: current.totalFiber,
      target: goals.fiberGoal,
      gap: fiberGap,
      percentage: fiberPercentage,
      priority: _getPriority(fiberPercentage),
    ));

    return gaps;
  }

  /// Get user's last meal from history
  static Future<Map<String, dynamic>?> _getLastMeal(String userId) async {
    try {
      final response = await _client
          .from('meal_plan_history')
          .select()
          .eq('user_id', userId)
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) return null;
      
      return {
        'calories': _parseDouble(response['calories']),
        'protein': _parseDouble(response['protein']),
        'carbs': _parseDouble(response['carbs']),
        'fat': _parseDouble(response['fat']),
        'fiber': _parseDouble(response['fiber']),
        'sugar': _parseDouble(response['sugar']),
        'sodium': _parseDouble(response['sodium']),
        'cholesterol': _parseDouble(response['cholesterol']),
        'title': response['title'] ?? '',
        'completed_at': response['completed_at'],
      };
    } catch (e) {
      AppLogger.error('Error fetching last meal', e);
      return null;
    }
  }

  /// Filter recipes based on health conditions
  static bool _isRecipeHealthyForConditions(Recipe recipe, List<String>? healthConditions) {
    if (healthConditions == null || healthConditions.isEmpty || healthConditions.contains('none')) {
      return true; // No restrictions if no health conditions
    }

    final carbs = (recipe.macros['carbs'] ?? 0).toDouble();
    final fiber = (recipe.macros['fiber'] ?? 0).toDouble();
    final sugar = (recipe.macros['sugar'] ?? 0).toDouble();
    final sodium = (recipe.macros['sodium'] ?? 0).toDouble();
    final cholesterol = (recipe.macros['cholesterol'] ?? 0).toDouble();
    final ingredients = recipe.ingredients.map((i) => i.toLowerCase()).toList();

    bool containsMeat() {
      const meatKeywords = [
        'pork',
        'chicken',
        'beef',
        'meat',
        'bacon',
        'ham',
        'sausage',
        'ribs',
        'steak',
        'drumstick',
        'wings',
        'ground beef',
        'ground pork',
        'ground meat',
        'liver',
      ];
      return meatKeywords.any((kw) => ingredients.any((ing) => ing.contains(kw)));
    }

    bool hasGreenVegetable() {
      const greenVegKeywords = [
        'spinach',
        'kale',
        'lettuce',
        'broccoli',
        'bok choy',
        'pechay',
        'cabbage',
        'malunggay',
        'moringa',
        'ampalaya',
        'bitter gourd',
        'okra',
        'kangkong',
        'water spinach',
        'green beans',
        'string beans',
        'peas',
        'chayote',
        'sayote',
      ];
      return greenVegKeywords.any((kw) => ingredients.any((ing) => ing.contains(kw)));
    }

    // Check each health condition
    for (final condition in healthConditions) {
      switch (condition.toLowerCase()) {
        case 'diabetes':
          // Low carbs, high fiber, low sugar
          if (carbs > 60 || sugar > 15 || fiber < 3) return false;
          break;
        case 'hypertension':
        case 'high_blood_pressure':
          // Hypertension: Very low sodium (<500mg), avoid meats, prefer greens
          if (sodium > 500) return false;
          if (containsMeat()) return false;
          if (!hasGreenVegetable()) return false;
          break;
        case 'high_cholesterol':
        case 'cholesterol':
          // High cholesterol: avoid meats and keep cholesterol low
          if (cholesterol > 75) return false;
          if (containsMeat()) return false;
          break;
        default:
          // For unknown conditions, apply general healthy criteria
          if (sugar > 30 || sodium > 1000) return false;
          break;
      }
    }

    return true;
  }

  /// Check if recipe is generally healthy
  static bool _isRecipeHealthy(Recipe recipe) {
    final calories = recipe.calories.toDouble();
    final protein = (recipe.macros['protein'] ?? 0).toDouble();
    final sugar = (recipe.macros['sugar'] ?? 0).toDouble();
    final sodium = (recipe.macros['sodium'] ?? 0).toDouble();
    final fiber = (recipe.macros['fiber'] ?? 0).toDouble();

    // Healthy criteria:
    // - Reasonable calories (200-800 for a meal)
    // - Not too high in sugar (< 30g)
    // - Not too high in sodium (< 1000mg)
    // - Has some protein (> 5g) or fiber (> 2g)
    if (calories < 200 || calories > 800) return false;
    if (sugar > 30) return false;
    if (sodium > 1000) return false;
    if (protein < 5 && fiber < 2) return false;

    // Exclude obviously unhealthy items
    final titleLower = recipe.title.toLowerCase();
    final unhealthyKeywords = ['deep fried', 'fried', 'crispy', 'sugar', 'syrup', 'candy', 'soda'];
    if (unhealthyKeywords.any((kw) => titleLower.contains(kw) && sugar > 20)) return false;

    return true;
  }

  /// Generate smart suggestions based on context
  static Future<List<SmartMealSuggestion>> _generateSmartSuggestions(
    SuggestionContext context,
  ) async {
    // Fetch recipes with allergy and diet-type filtering applied
    var allRecipes = await RecipeService.fetchRecipes(userId: context.userId);
    // Filter out disallowed items (e.g., chicken feet, blood, intestines)
    final beforeCount = allRecipes.length;
    allRecipes = allRecipes.where((r) => !RecipeService.isRecipeDisallowed(r)).toList();
    
    // Get user's health conditions
    final userGoals = await _getUserNutritionGoals(context.userId);
    final healthConditions = userGoals?.healthConditions;
    
    // Filter by health conditions and ensure only healthy meals
    allRecipes = allRecipes.where((r) {
      return _isRecipeHealthy(r) && _isRecipeHealthyForConditions(r, healthConditions);
    }).toList();
    
    final filteredOut = beforeCount - allRecipes.length;
    if (filteredOut > 0) {
      AppLogger.debug('Smart suggestions: filtered $filteredOut recipes (disallowed/unhealthy/health conditions)');
    }

    // Get last meal to base suggestions on
    final lastMeal = await _getLastMeal(context.userId);

    // Recent history to reduce repeats
    final recentIdsOrTitles = await _getRecentRecipeIdentifiers(context.userId, days: 7);

    // Pre-compute timing band
    final hour = context.targetTime.hour;
    double timingBandScore(Recipe r) {
      switch (context.mealCategory) {
        case MealCategory.breakfast:
          if (hour < 7) return r.calories <= 400 ? 1.0 : 0.4;
          return (r.calories >= 300 && r.calories <= 600) ? 1.0 : 0.5;
        case MealCategory.lunch:
          return (r.calories >= 400 && r.calories <= 800) ? 1.0 : 0.5;
        case MealCategory.dinner:
          return (r.calories >= 500 && r.calories <= 900) ? 1.0 : 0.5;
      }
    }

    // Preference score: tag/category/title match
    double preferenceScore(Recipe r) {
      final likedDishes = (context.userGoals.dishPreferences ?? [])
          .map((e) => e.toLowerCase())
          .toList();
      final favCats = context.userPatterns.favoriteCategories.map((e) => e.toLowerCase()).toList();
      final title = r.title.toLowerCase();
      final tags = r.tags.map((t) => t.toLowerCase()).toList();
      final matchesTitle = favCats.any((c) => title.contains(c)) ? 1.0 : 0.0;
      final matchesTag = favCats.any((c) => tags.any((t) => t.contains(c))) ? 1.0 : 0.0;
      final isFavoriteRecipe = context.userPatterns.mostFrequentRecipes.any((t) => t.toLowerCase() == title) ? 0.8 : 0.0;
      final matchesLikedDish = likedDishes.any((d) {
        final normalized = d.replaceAll('_', ' ').trim();
        return normalized.isNotEmpty &&
            (title.contains(normalized) || tags.any((t) => t.contains(normalized)));
      }) ? 1.0 : 0.0;

      // Weight favorite categories/tags and give a stronger bump for explicit likes
      return (matchesTitle * 0.6) + (matchesTag * 0.6) + isFavoriteRecipe + (matchesLikedDish * 1.2);
    }

    // Last meal complement score: how well it complements the last meal
    double lastMealComplementScore(Recipe r) {
      final meal = lastMeal;
      if (meal == null) return 0.0; // No last meal, can't complement
      double score = 0.0;
      final lastProtein = meal['protein'] ?? 0.0;
      final lastCarbs = meal['carbs'] ?? 0.0;
      final lastFat = meal['fat'] ?? 0.0;
      final lastFiber = meal['fiber'] ?? 0.0;
      final lastCalories = meal['calories'] ?? 0.0;
      
      final rProtein = _getNutrientValue(r, 'protein');
      final rCarbs = _getNutrientValue(r, 'carbs');
      final rFat = _getNutrientValue(r, 'fat');
      final rFiber = _getNutrientValue(r, 'fiber');
      final rCalories = r.calories.toDouble();
      
      // If last meal was high in carbs, suggest protein/fiber rich meals
      if (lastCarbs > 50) {
        if (rProtein >= 20) score += 1.5;
        if (rFiber >= 5) score += 1.0;
        if (rCarbs < 40) score += 0.8; // Lower carb complement
      }
      
      // If last meal was high in protein, suggest balanced meals with carbs/fiber
      if (lastProtein > 30) {
        if (rCarbs >= 30 && rCarbs <= 60) score += 1.2;
        if (rFiber >= 5) score += 0.8;
      }
      
      // If last meal was low in fiber, prioritize high-fiber meals
      if (lastFiber < 5) {
        if (rFiber >= 8) score += 1.5;
      }
      
      // If last meal was high in calories, suggest lighter meals
      if (lastCalories > 600) {
        if (rCalories < 500) score += 1.0;
      }
      
      // If last meal was low in calories, can suggest more substantial meals
      if (lastCalories < 400) {
        if (rCalories >= 400 && rCalories <= 700) score += 0.8;
      }
      
      // Balance: if last meal was high in fat, suggest lower fat meals
      if (lastFat > 30) {
        if (rFat < 25) score += 0.7;
      }
      
      return score;
    }

    // Gap fit score: how much it helps with critical gaps (secondary to last meal)
    double gapFitScore(Recipe r) {
      double score = 0.0;
      for (final gap in context.nutritionalGaps) {
        if (gap.priority == Priority.critical || gap.priority == Priority.high) {
          switch (gap.nutrient) {
            case 'protein':
              final v = _getNutrientValue(r, 'protein');
              if (v >= 15) score += (v / (gap.gap.abs() + 1)).clamp(0.0, 1.0) * 0.8;
              break;
            case 'fiber':
              final v2 = _getNutrientValue(r, 'fiber');
              if (v2 >= 5) score += (v2 / (gap.gap.abs() + 1)).clamp(0.0, 1.0) * 0.6;
              break;
            case 'calories':
              final kc = r.calories.toDouble();
              if (kc >= 200) score += (kc / (gap.gap.abs() + 200)).clamp(0.0, 1.0) * 0.5;
              break;
          }
        }
      }
      return score;
    }

    // Recency penalty: downweight items eaten in last 7 days
    double recencyPenalty(Recipe r) {
      final title = r.title.toLowerCase();
      return recentIdsOrTitles.contains(title) ? -0.8 : 0.0;
    }

    // Composite scoring - prioritize last meal complement over gaps
    final scored = allRecipes.map((r) {
      final lastMealScore = lastMealComplementScore(r);
      final gapScore = gapFitScore(r);
      final prefScore = preferenceScore(r);
      final timingScore = timingBandScore(r);
      final recencyScore = 1.0 + recencyPenalty(r);
      
      // Weighted scoring: last meal complement is most important (50%), then gaps (20%), preferences (15%), timing (10%), recency (5%)
      final score = 
          (lastMeal != null ? 0.5 * lastMealScore : 0.0) +
          0.2 * gapScore +
          0.15 * prefScore +
          0.1 * timingScore +
          0.05 * recencyScore;
      
      // Generate reasoning based on last meal
      String reasoning = 'Healthy meal recommendation';
      final meal = lastMeal;
      if (meal != null) {
        final lastTitle = meal['title'] ?? 'your last meal';
        if (lastMealScore > 1.0) {
          reasoning = 'Complements $lastTitle nutritionally';
        } else if (gapScore > 0.5) {
          reasoning = 'Helps meet your nutrition goals';
        } else {
          reasoning = 'Balanced healthy option';
        }
      } else {
        reasoning = 'Healthy meal based on your goals';
      }
      
      return SmartMealSuggestion(
        recipe: r,
        type: SuggestionType.fillGap,
        reasoning: reasoning,
        relevanceScore: score,
        nutritionalBenefits: {
          'protein': _getNutrientValue(r, 'protein'),
          'fiber': _getNutrientValue(r, 'fiber'),
          'calories': r.calories.toDouble(),
        },
        tags: ['personalized', 'healthy'],
      );
    }).toList();

    // Sort and enforce diversity by title prefix and primary tag
    scored.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    final picked = <SmartMealSuggestion>[];
    final seenBuckets = <String>{};
    for (final s in scored) {
      final bucket = (s.recipe.tags.isNotEmpty ? s.recipe.tags.first.toLowerCase() : '') + '|' + s.recipe.title.split(' ').first.toLowerCase();
      if (seenBuckets.contains(bucket)) continue;
      seenBuckets.add(bucket);
      picked.add(s);
      if (picked.length >= 6) break;
    }
    return picked;
  }

  // Legacy generators removed; logic consolidated into composite scoring

  /// Get fallback suggestions when smart logic fails
  static Future<List<SmartMealSuggestion>> _getFallbackSuggestions(
    MealCategory mealCategory, {
    String? userId,
  }) async {
    final recipes = await RecipeService.fetchRecipes(userId: userId);
    final suggestions = <SmartMealSuggestion>[];

    for (final recipe in recipes.take(3)) {
      suggestions.add(SmartMealSuggestion(
        recipe: recipe,
        type: SuggestionType.trySomethingNew,
        reasoning: 'Popular choice for ${mealCategory.name}',
        relevanceScore: 0.5,
        nutritionalBenefits: {},
        tags: ['popular', mealCategory.name],
      ));
    }

    return suggestions;
  }

  // Helper methods
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static MealCategory _parseMealCategory(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return MealCategory.breakfast;
      case 'lunch':
        return MealCategory.lunch;
      case 'dinner':
        return MealCategory.dinner;
      default:
        return MealCategory.dinner;
    }
  }

  static String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  static Priority _getPriority(double percentage) {
    if (percentage < 50) return Priority.critical;
    if (percentage < 70) return Priority.high;
    if (percentage < 90) return Priority.medium;
    if (percentage <= 100) return Priority.low;
    return Priority.excess;
  }

  static double _getNutrientValue(Recipe recipe, String nutrient) {
    switch (nutrient) {
      case 'protein':
        return (recipe.macros['protein'] ?? 0).toDouble();
      case 'carbs':
        return (recipe.macros['carbs'] ?? 0).toDouble();
      case 'fat':
        return (recipe.macros['fat'] ?? 0).toDouble();
      case 'fiber':
        return (recipe.macros['fiber'] ?? 0).toDouble();
      case 'calories':
        return recipe.calories.toDouble();
      default:
        return 0.0;
    }
  }

  /// Test AI integration
  static Future<bool> testAIIntegration() async {
    try {
      if (_groqApiKey.isEmpty) {
        AppLogger.warning('AI Integration Test: GROQ_API_KEY not set');
        return false;
      }

      // Test with a simple API call
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'user', 'content': 'Test connection'}
          ],
          'max_tokens': 10,
        }),
      );

      final success = response.statusCode == 200;
      AppLogger.info('AI Integration Test: ${success ? "SUCCESS" : "FAILED"} (${response.statusCode})');
      
      if (!success) {
        AppLogger.debug('AI Integration Test: Response body: ${response.body}');
      }
      
      return success;
    } catch (e) {
      AppLogger.error('AI Integration Test: ERROR', e);
      return false;
    }
  }

  /// Get AI-powered suggestions using GROQ
  static Future<List<SmartMealSuggestion>> _getAIPoweredSuggestions(SuggestionContext context) async {
    try {
      if (_groqApiKey.isEmpty) {
        return [];
      }
      
      // Build context for AI
      final prompt = await _buildAIPrompt(context);
      
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        
        // Parse AI response and map to existing recipes only (allergy-filtered)
        final parsed = _parseAIResponse(aiResponse, context);
        if (parsed.isEmpty) return [];
        // Get all recipes (allergy-filtered), then remove disallowed
        var allRecipes = await RecipeService.fetchRecipes(userId: context.userId);
        allRecipes = allRecipes.where((r) => !RecipeService.isRecipeDisallowed(r)).toList();
        final byTitle = {for (final r in allRecipes) r.title.toLowerCase(): r};
        final mapped = <SmartMealSuggestion>[];
        for (final s in parsed) {
          final key = s.recipe.title.toLowerCase();
          final match = byTitle[key];
          if (match != null) {
            mapped.add(SmartMealSuggestion(
              recipe: match,
              type: s.type,
              reasoning: s.reasoning,
              relevanceScore: s.relevanceScore,
              nutritionalBenefits: s.nutritionalBenefits,
              tags: s.tags,
            ));
          }
        }
        return mapped;
      } else {
        AppLogger.error('AI API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      AppLogger.error('AI suggestions error', e);
      return [];
    }
  }

  /// Get recent recipe identifiers (titles) from history to penalize repeats
  static Future<Set<String>> _getRecentRecipeIdentifiers(String userId, {int days = 7}) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final res = await _client
          .from('meal_plan_history')
          .select('title')
          .eq('user_id', userId)
          .gte('completed_at', since.toUtc().toIso8601String());
      final set = <String>{};
      for (final m in res) {
        final t = (m['title'] ?? '').toString().toLowerCase();
        if (t.isNotEmpty) set.add(t);
      }
      return set;
    } catch (_) {
      return <String>{};
    }
  }

  /// Build prompt for AI suggestions with enhanced anti-repetition and recipe selection
  static Future<String> _buildAIPrompt(SuggestionContext context) async {
    final mealType = context.mealCategory.name.toLowerCase();
    final timeOfDay = context.targetTime.hour < 12 ? 'morning' : 
                     context.targetTime.hour < 17 ? 'afternoon' : 'evening';
    final likedDishes = (context.userGoals.dishPreferences ?? [])
        .where((d) => d.trim().isNotEmpty)
        .toList();
    
    // Get last meal
    final lastMeal = await _getLastMeal(context.userId);
    final lastMealInfo = lastMeal != null 
        ? '''
Last meal consumed: ${lastMeal['title']}
- Calories: ${lastMeal['calories']}g
- Protein: ${lastMeal['protein']}g
- Carbs: ${lastMeal['carbs']}g
- Fat: ${lastMeal['fat']}g
- Fiber: ${lastMeal['fiber']}g

IMPORTANT: Suggest meals that COMPLEMENT the last meal nutritionally. If last meal was high in carbs, suggest protein/fiber-rich meals. If last meal was high in protein, suggest balanced meals with carbs.
'''
        : 'No previous meal logged today.';
    
    // Get recent meals to avoid repetition
    final recentMeals = await _getRecentRecipeIdentifiers(context.userId, days: 14);
    final recentMealsList = recentMeals.take(15).join(', ');
    
    // Get available recipes for this meal category
    var allRecipes = await RecipeService.fetchRecipes(userId: context.userId);
    allRecipes = allRecipes.where((r) => !RecipeService.isRecipeDisallowed(r)).toList();
    
    // Filter by health conditions
    final healthConditions = context.userGoals.healthConditions ?? [];
    if (healthConditions.isNotEmpty && !healthConditions.contains('none')) {
      allRecipes = allRecipes.where((r) {
        return _isRecipeHealthyForConditions(r, healthConditions);
      }).toList();
    }
    
    // Filter healthy recipes
    allRecipes = allRecipes.where((r) => _isRecipeHealthy(r)).toList();
    
    // Build available recipes list (limit to 50 for token efficiency)
    final recipesList = allRecipes.take(50).map((r) {
      final protein = (r.macros['protein'] ?? 0).toDouble();
      final carbs = (r.macros['carbs'] ?? 0).toDouble();
      final fat = (r.macros['fat'] ?? 0).toDouble();
      final fiber = (r.macros['fiber'] ?? 0).toDouble();
      final sugar = (r.macros['sugar'] ?? 0).toDouble();
      final sodium = (r.macros['sodium'] ?? 0).toDouble();
      return '- ${r.title} (ID: ${r.id}) | Calories: ${r.calories} | Protein: ${protein}g | Carbs: ${carbs}g | Fat: ${fat}g | Fiber: ${fiber}g | Sugar: ${sugar}g | Sodium: ${sodium}mg';
    }).join('\n');
    
    // Get health conditions info
    final healthInfo = healthConditions.isNotEmpty && !healthConditions.contains('none')
        ? '''
CRITICAL HEALTH CONDITIONS (STRICTLY ENFORCE):
${healthConditions.map((c) {
  switch (c.toLowerCase()) {
    case 'diabetes': return '- Diabetes: Low carbs (<60g per meal), high fiber (>3g), low sugar (<15g). AVOID: high-carb recipes, sugary foods, low-fiber meals';
    case 'hypertension':
    case 'high_blood_pressure': return '- Hypertension: Very low sodium (<500mg per meal). AVOID: high-sodium recipes, processed foods, salty dishes';
    default: return '- $c: Apply general healthy criteria';
  }
}).join('\n')}

ONLY suggest recipes that meet ALL health condition requirements. NEVER suggest recipes that violate these restrictions.
'''
        : '';
    
    final likedDishesInfo = likedDishes.isNotEmpty
        ? '''
USER-LIKED DISHES (PREFER THESE WHEN THEY MEET HEALTH RULES):
- ${likedDishes.join(', ')}
'''
        : 'USER-LIKED DISHES: None specified';
    
    return '''
You are an expert Filipino nutritionist. Analyze the user's data and suggest 3 HEALTHY Filipino recipes for $mealType in the $timeOfDay.

$lastMealInfo

Current nutrition status:
- Protein: ${context.currentNutrition.totalProtein}g (goal: ${context.userGoals.proteinGoal}g) - ${((context.currentNutrition.totalProtein / context.userGoals.proteinGoal) * 100).toStringAsFixed(0)}%
- Carbs: ${context.currentNutrition.totalCarbs}g (goal: ${context.userGoals.carbGoal}g) - ${((context.currentNutrition.totalCarbs / context.userGoals.carbGoal) * 100).toStringAsFixed(0)}%
- Fat: ${context.currentNutrition.totalFat}g (goal: ${context.userGoals.fatGoal}g) - ${((context.currentNutrition.totalFat / context.userGoals.fatGoal) * 100).toStringAsFixed(0)}%
- Calories: ${context.currentNutrition.totalCalories} (goal: ${context.userGoals.calorieGoal}) - ${((context.currentNutrition.totalCalories / context.userGoals.calorieGoal) * 100).toStringAsFixed(0)}%
- Fiber: ${context.currentNutrition.totalFiber}g (recommended: 25-30g)

$healthInfo

$likedDishesInfo

CRITICAL ANTI-REPETITION REQUIREMENT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The following meals were consumed in the last 14 days. You MUST AVOID selecting these to ensure variety:
${recentMealsList.isEmpty ? 'None (user has no recent meals)' : recentMealsList}

AVAILABLE RECIPES (SELECT FROM THESE ONLY):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$recipesList

REQUIREMENTS:
1. SELECT recipes ONLY from the "AVAILABLE RECIPES" list above - use EXACT recipe titles
2. Meals must COMPLEMENT the last meal nutritionally (if last meal provided)
3. STRICTLY AVOID meals from the "Recent Meals" list - prioritize variety
4. STRICTLY follow health condition restrictions (if any)
5. Prefer user-liked dishes when they satisfy health rules and fit the meal type
6. Are appropriate for $mealType
7. Help address nutritional gaps: ${context.nutritionalGaps.map((g) => '${g.nutrient} (${g.priority.name})').join(', ')}
8. Ensure variety - no repetitive suggestions

Format your response as JSON:
{
  "suggestions": [
    {
      "title": "EXACT recipe title from available recipes list",
      "reasoning": "Why this recipe complements the last meal, addresses nutritional gaps, and ensures variety",
      "cost": 120,
      "calories": 350,
      "protein": 25,
      "carbs": 30,
      "fat": 15,
      "fiber": 5,
      "sugar": 10,
      "sodium": 400
    }
  ]
}

IMPORTANT: Use EXACT recipe titles from the available recipes list. Do not create new recipes.
''';
  }

  /// Parse AI response and convert to SmartMealSuggestion objects
  static List<SmartMealSuggestion> _parseAIResponse(String aiResponse, SuggestionContext context) {
    try {
      // Extract JSON from AI response
      final jsonMatch = RegExp(r'\{.*\}', multiLine: true, dotAll: true).firstMatch(aiResponse);
      if (jsonMatch == null) {
        AppLogger.warning('No JSON found in AI response');
        return [];
      }
      
      final jsonStr = jsonMatch.group(0)!;
      final data = jsonDecode(jsonStr);
      final suggestions = data['suggestions'] as List;
      
      return suggestions.map((suggestion) {
        // Create a mock Recipe object for the suggestion
        final recipe = Recipe(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          title: suggestion['title'],
          imageUrl: '',
          shortDescription: suggestion['reasoning'],
          ingredients: [],
          instructions: [],
          macros: {
            'protein': suggestion['protein']?.toDouble() ?? 0.0,
            'carbs': suggestion['carbs']?.toDouble() ?? 0.0,
            'fat': suggestion['fat']?.toDouble() ?? 0.0,
          },
          allergyWarning: '',
          calories: suggestion['calories'] ?? 0,
          tags: [],
          cost: suggestion['cost']?.toDouble() ?? 0.0,
          notes: '',
        );
        
        return SmartMealSuggestion(
          recipe: recipe,
          type: SuggestionType.fillGap,
          reasoning: suggestion['reasoning'],
          relevanceScore: 0.9, // High relevance for AI suggestions
          nutritionalBenefits: {
            'protein': suggestion['protein']?.toDouble() ?? 0.0,
            'carbs': suggestion['carbs']?.toDouble() ?? 0.0,
            'fat': suggestion['fat']?.toDouble() ?? 0.0,
          },
          tags: context.nutritionalGaps.map((gap) => gap.nutrient).toList(),
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Error parsing AI response', e);
      return [];
    }
  }

  /// Get rule-based suggestions only (for testing)
  static Future<List<SmartMealSuggestion>> getRuleBasedSuggestionsOnly({
    required String userId,
    required MealCategory mealCategory,
    DateTime? targetTime,
  }) async {
    return await getSmartSuggestions(
      userId: userId,
      mealCategory: mealCategory,
      targetTime: targetTime,
      useAI: false,
    );
  }

  /// Calculate meal consistency score (0.0 to 1.0)
  static double _calculateMealConsistency(List<dynamic> meals) {
    if (meals.isEmpty) return 0.0;
    
    // Count unique days with meals
    final uniqueDays = meals.map((meal) {
      final date = DateTime.parse(meal['completed_at']);
      return DateTime(date.year, date.month, date.day);
    }).toSet().length;
    
    // Consistency score based on how many days have meals
    return uniqueDays / 30.0; // Assuming 30-day analysis period
  }

  /// Calculate meal variety score (0.0 to 1.0)
  static double _calculateMealVariety(List<dynamic> meals) {
    if (meals.isEmpty) return 0.0;
    
    // Count unique recipes
    final uniqueRecipes = meals.map((meal) => meal['recipe_id'] ?? meal['title']).toSet().length;
    
    // Variety score based on unique recipes vs total meals
    return uniqueRecipes / meals.length;
  }
}
