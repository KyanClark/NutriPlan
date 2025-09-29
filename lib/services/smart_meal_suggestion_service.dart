import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/smart_suggestion_models.dart';
import '../models/meal_history_entry.dart';
import '../models/user_nutrition_goals.dart';
import '../models/recipes.dart';
import 'recipe_service.dart';
import 'gemini_meal_suggestion_service.dart';

class SmartMealSuggestionService {
  static final SupabaseClient _client = Supabase.instance.client;

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
        return await _getFallbackSuggestions(mealCategory);
      }
      
      // 3. Get user eating patterns
      final userPatterns = await _getUserEatingPatterns(userId);
      
      // 4. Try AI-powered suggestions first (if enabled)
      if (useAI) {
        try {
          final aiSuggestions = await GeminiMealSuggestionService.getAISuggestions(
            userId: userId,
            mealCategory: mealCategory,
            userGoals: userGoals,
            currentNutrition: currentNutrition,
            userPatterns: userPatterns,
            targetTime: time,
          );
          
          if (aiSuggestions.isNotEmpty) {
            print('AI suggestions generated successfully: ${aiSuggestions.length}');
            return aiSuggestions;
          }
        } catch (e) {
          print('AI suggestions failed, falling back to rule-based: $e');
        }
      }
      
      // 5. Fallback to rule-based suggestions
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
      
      return await _generateSmartSuggestions(context);
      
    } catch (e) {
      print('Error generating smart suggestions: $e');
      return await _getFallbackSuggestions(mealCategory);
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
      print('Error fetching user goals: $e');
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
      print('Error analyzing user patterns: $e');
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

  /// Generate smart suggestions based on context
  static Future<List<SmartMealSuggestion>> _generateSmartSuggestions(
    SuggestionContext context,
  ) async {
    final allRecipes = await RecipeService.fetchRecipes();
    final suggestions = <SmartMealSuggestion>[];

    // 1. Fill Gap suggestions (highest priority)
    final fillGapSuggestions = await _generateFillGapSuggestions(
      allRecipes, 
      context
    );
    suggestions.addAll(fillGapSuggestions);

    // 2. Perfect Timing suggestions
    final timingSuggestions = await _generateTimingSuggestions(
      allRecipes, 
      context
    );
    suggestions.addAll(timingSuggestions);

    // 3. User Favorites suggestions
    final favoriteSuggestions = await _generateFavoriteSuggestions(
      allRecipes, 
      context
    );
    suggestions.addAll(favoriteSuggestions);

    // 4. Try Something New suggestions
    final newSuggestions = await _generateNewSuggestions(
      allRecipes, 
      context
    );
    suggestions.addAll(newSuggestions);

    // Sort by relevance score and return top suggestions
    suggestions.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return suggestions.take(6).toList();
  }

  /// Generate suggestions to fill nutritional gaps
  static Future<List<SmartMealSuggestion>> _generateFillGapSuggestions(
    List<Recipe> recipes,
    SuggestionContext context,
  ) async {
    final suggestions = <SmartMealSuggestion>[];
    final criticalGaps = context.nutritionalGaps
        .where((gap) => gap.priority == Priority.critical || gap.priority == Priority.high)
        .toList();

    for (final gap in criticalGaps) {
      List<Recipe> suitableRecipes;
      
      switch (gap.nutrient) {
        case 'protein':
          suitableRecipes = recipes
              .where((r) => _getNutrientValue(r, 'protein') >= 15 && _getNutrientValue(r, 'protein') <= gap.gap * 1.5)
              .toList();
          break;
        case 'fiber':
          suitableRecipes = recipes
              .where((r) => _getNutrientValue(r, 'fiber') >= 5 && _getNutrientValue(r, 'fiber') <= gap.gap * 1.5)
              .toList();
          break;
        case 'calories':
          suitableRecipes = recipes
              .where((r) => r.calories <= gap.gap * 1.2 && r.calories >= 200)
              .toList();
          break;
        default:
          continue;
      }

      for (final recipe in suitableRecipes.take(2)) {
        suggestions.add(SmartMealSuggestion(
          recipe: recipe,
          type: SuggestionType.fillGap,
          reasoning: 'Helps fill your ${gap.nutrient} gap (${gap.gap.toStringAsFixed(1)}g remaining)',
          relevanceScore: 0.9 - (gap.percentage / 100) * 0.3,
          nutritionalBenefits: {gap.nutrient: _getNutrientValue(recipe, gap.nutrient)},
          tags: ['nutritional-gap', gap.nutrient],
        ));
      }
    }

    return suggestions;
  }

  /// Generate timing-based suggestions
  static Future<List<SmartMealSuggestion>> _generateTimingSuggestions(
    List<Recipe> recipes,
    SuggestionContext context,
  ) async {
    final suggestions = <SmartMealSuggestion>[];
    final hour = context.targetTime.hour;
    
    List<Recipe> suitableRecipes;
    String timingReason;

    switch (context.mealCategory) {
      case MealCategory.breakfast:
        if (hour < 7) {
          suitableRecipes = recipes.where((r) => r.calories <= 400).toList();
          timingReason = 'Light breakfast for early morning';
        } else {
          suitableRecipes = recipes.where((r) => r.calories >= 300 && r.calories <= 600).toList();
          timingReason = 'Balanced breakfast for your morning routine';
        }
        break;
      case MealCategory.lunch:
        suitableRecipes = recipes.where((r) => r.calories >= 400 && r.calories <= 800).toList();
        timingReason = 'Satisfying lunch to fuel your afternoon';
        break;
      case MealCategory.dinner:
        suitableRecipes = recipes.where((r) => r.calories >= 500 && r.calories <= 900).toList();
        timingReason = 'Hearty dinner to end your day';
        break;
      case MealCategory.snack:
        suitableRecipes = recipes.where((r) => r.calories <= 300).toList();
        timingReason = 'Light snack to keep you energized';
        break;
    }

    for (final recipe in suitableRecipes.take(2)) {
      suggestions.add(SmartMealSuggestion(
        recipe: recipe,
        type: SuggestionType.perfectTiming,
        reasoning: timingReason,
        relevanceScore: 0.8,
        nutritionalBenefits: {},
        tags: ['timing', context.mealCategory.name],
      ));
    }

    return suggestions;
  }

  /// Generate suggestions based on user favorites
  static Future<List<SmartMealSuggestion>> _generateFavoriteSuggestions(
    List<Recipe> recipes,
    SuggestionContext context,
  ) async {
    final suggestions = <SmartMealSuggestion>[];
    final favoriteCategories = context.userPatterns.favoriteCategories;

    for (final category in favoriteCategories.take(2)) {
      final categoryRecipes = recipes
          .where((r) => r.dietTypes.any((diet) => diet.toLowerCase().contains(category.toLowerCase())))
          .toList();

      for (final recipe in categoryRecipes.take(1)) {
        suggestions.add(SmartMealSuggestion(
          recipe: recipe,
          type: SuggestionType.userFavorites,
          reasoning: 'Similar to your favorite ${category} dishes',
          relevanceScore: 0.7,
          nutritionalBenefits: {},
          tags: ['favorite', category],
        ));
      }
    }

    return suggestions;
  }

  /// Generate suggestions for trying something new
  static Future<List<SmartMealSuggestion>> _generateNewSuggestions(
    List<Recipe> recipes,
    SuggestionContext context,
  ) async {
    final suggestions = <SmartMealSuggestion>[];
    final frequentRecipes = context.userPatterns.mostFrequentRecipes;

    // Find recipes user hasn't tried recently
    final newRecipes = recipes
        .where((r) => !frequentRecipes.contains(r.title))
        .toList();

    for (final recipe in newRecipes.take(2)) {
      suggestions.add(SmartMealSuggestion(
        recipe: recipe,
        type: SuggestionType.trySomethingNew,
        reasoning: 'Try something new to expand your palate',
        relevanceScore: 0.6,
        nutritionalBenefits: {},
        tags: ['new', 'variety'],
      ));
    }

    return suggestions;
  }

  /// Get fallback suggestions when smart logic fails
  static Future<List<SmartMealSuggestion>> _getFallbackSuggestions(
    MealCategory mealCategory,
  ) async {
    final recipes = await RecipeService.fetchRecipes();
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
      case 'snack':
        return MealCategory.snack;
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
      return await GeminiMealSuggestionService.testConnection();
    } catch (e) {
      print('AI integration test failed: $e');
      return false;
    }
  }

  /// Get AI-powered suggestions only (for testing)
  static Future<List<SmartMealSuggestion>> getAISuggestionsOnly({
    required String userId,
    required MealCategory mealCategory,
    DateTime? targetTime,
  }) async {
    return await getSmartSuggestions(
      userId: userId,
      mealCategory: mealCategory,
      targetTime: targetTime,
      useAI: true,
    );
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
