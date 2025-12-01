import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/smart_suggestion_models.dart';
import '../models/meal_history_entry.dart';
import '../utils/app_logger.dart';

class BehavioralAnalysisService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Analyze user's eating patterns over a period
  static Future<UserEatingPatterns> analyzeUserPatterns({
    required String userId,
    int daysBack = 30,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: daysBack));

      final response = await _client
          .from('meal_plan_history')
          .select()
          .eq('user_id', userId)
          .gte('completed_at', startDate.toUtc().toIso8601String())
          .lte('completed_at', endDate.toUtc().toIso8601String())
          .order('completed_at', ascending: true);

      if (response.isEmpty) {
        return _getEmptyPatterns();
      }

      return _analyzeMealData(response, daysBack);
    } catch (e) {
      AppLogger.error('Error analyzing user patterns', e);
      return _getEmptyPatterns();
    }
  }

  /// Analyze meal data to extract patterns
  static UserEatingPatterns _analyzeMealData(List<dynamic> meals, int daysBack) {
    final mealTimes = <String, int>{};
    final categoryCount = <String, int>{};
    final recipeCount = <String, int>{};
    final weeklyPatterns = <String, double>{};
    final categoryPreferences = <MealCategory, double>{};
    final ingredientCount = <String, int>{};
    final seasonalData = <String, int>{};
    final averageMealTimes = <MealCategory, List<DateTime>>{};
    for (final meal in meals) {
      final completedAt = DateTime.parse(meal['completed_at']);
      final hour = completedAt.hour.toString();
      final category = meal['meal_category'] ?? 'dinner';
      final recipeTitle = meal['title'] ?? 'Unknown';
      final ingredients = meal['ingredients'] as String? ?? '';

      // Count meal times (hourly patterns)
      mealTimes[hour] = (mealTimes[hour] ?? 0) + 1;
      
      // Count categories
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      
      // Count recipes
      recipeCount[recipeTitle] = (recipeCount[recipeTitle] ?? 0) + 1;
      
      // Track average meal times by category
      final mealCategory = _parseMealCategory(category);
      if (!averageMealTimes.containsKey(mealCategory)) {
        averageMealTimes[mealCategory] = [];
      }
      averageMealTimes[mealCategory]!.add(completedAt);
      
      // Weekly patterns (day of week)
      final dayOfWeek = _getDayOfWeek(completedAt.weekday);
      weeklyPatterns[dayOfWeek] = (weeklyPatterns[dayOfWeek] ?? 0) + 1;
      
      // Category preferences
      categoryPreferences[mealCategory] = (categoryPreferences[mealCategory] ?? 0) + 1;

      // Analyze ingredients (simple keyword extraction)
      _analyzeIngredients(ingredients, ingredientCount);

      // Seasonal analysis (month-based)
      final month = completedAt.month.toString();
      seasonalData[month] = (seasonalData[month] ?? 0) + 1;
    }

    // Process and rank the data
    final favoriteCategories = _getTopItems(categoryCount, 5);
    final mostFrequentRecipes = _getTopItems(recipeCount, 5);
    final leastLikedIngredients = _getLeastLikedIngredients(ingredientCount);
    final seasonalPreferences = _processSeasonalData(seasonalData);
    
    // Calculate meal consistency and variety scores
    final mealConsistencyScore = _calculateMealConsistency(meals, daysBack);
    final mealVarietyScore = _calculateMealVariety(meals);

    return UserEatingPatterns(
      averageMealTimes: averageMealTimes,
      favoriteCategories: favoriteCategories,
      leastLikedIngredients: leastLikedIngredients,
      weeklyPatterns: weeklyPatterns,
      seasonalPreferences: seasonalPreferences,
      mostFrequentRecipes: mostFrequentRecipes,
      averageMealFrequency: meals.length / daysBack,
      categoryPreferences: categoryPreferences,
      mealConsistencyScore: mealConsistencyScore,
      mealVarietyScore: mealVarietyScore,
    );
  }

  /// Get user's meal timing preferences
  static Future<Map<String, double>> getMealTimingPreferences(String userId) async {
    try {
      final patterns = await analyzeUserPatterns(userId: userId);
      final totalMeals = patterns.averageMealTimes.values.fold(0, (sum, times) => sum + times.length);
      
      if (totalMeals == 0) return {};

      final preferences = <String, double>{};
      patterns.averageMealTimes.forEach((category, times) {
        final hour = category.name;
        preferences[hour] = times.length / totalMeals;
      });

      return preferences;
    } catch (e) {
      AppLogger.error('Error getting meal timing preferences', e);
      return {};
    }
  }

  /// Get user's category preferences
  static Future<Map<MealCategory, double>> getCategoryPreferences(String userId) async {
    try {
      final patterns = await analyzeUserPatterns(userId: userId);
      final totalMeals = patterns.categoryPreferences.values.fold(0.0, (sum, count) => sum + count);
      
      if (totalMeals == 0) return {};

      final preferences = <MealCategory, double>{};
      patterns.categoryPreferences.forEach((category, count) {
        preferences[category] = count / totalMeals;
      });

      return preferences;
    } catch (e) {
      AppLogger.error('Error getting category preferences', e);
      return {};
    }
  }

  /// Get user's weekly eating patterns
  static Future<Map<String, double>> getWeeklyPatterns(String userId) async {
    try {
      final patterns = await analyzeUserPatterns(userId: userId);
      final totalMeals = patterns.weeklyPatterns.values.fold(0.0, (sum, count) => sum + count);
      
      if (totalMeals == 0) return {};

      final preferences = <String, double>{};
      patterns.weeklyPatterns.forEach((day, count) {
        preferences[day] = count / totalMeals;
      });

      return preferences;
    } catch (e) {
      AppLogger.error('Error getting weekly patterns', e);
      return {};
    }
  }

  /// Predict optimal meal time for a category
  static Future<DateTime?> predictOptimalMealTime(
    String userId, 
    MealCategory category
  ) async {
    try {
      final timingPreferences = await getMealTimingPreferences(userId);
      if (timingPreferences.isEmpty) return null;

      // Find the most common hour for this category
      final categoryMeals = await _getCategoryMeals(userId, category);
      final categoryTiming = <String, int>{};

      for (final meal in categoryMeals) {
        final completedAt = DateTime.parse(meal['completed_at']);
        final hour = completedAt.hour.toString();
        categoryTiming[hour] = (categoryTiming[hour] ?? 0) + 1;
      }

      if (categoryTiming.isEmpty) return null;

      final sortedTiming = categoryTiming.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final optimalHour = int.parse(sortedTiming.first.key);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, optimalHour);
    } catch (e) {
      AppLogger.error('Error predicting optimal meal time', e);
      return null;
    }
  }

  /// Get user's dietary consistency score
  static Future<double> getConsistencyScore(String userId) async {
    try {
      final patterns = await analyzeUserPatterns(userId: userId);
      
      if (patterns.averageMealFrequency == 0) return 0.0;

      // Calculate consistency based on:
      // 1. Regular meal frequency
      // 2. Consistent meal times
      // 3. Balanced category distribution

      double frequencyScore = 0.0;
      if (patterns.averageMealFrequency >= 2.5) {
        frequencyScore = 1.0;
      } else if (patterns.averageMealFrequency >= 2.0) {
        frequencyScore = 0.8;
      } else if (patterns.averageMealFrequency >= 1.5) {
        frequencyScore = 0.6;
      } else {
        frequencyScore = 0.4;
      }

      // Time consistency (how spread out meal times are)
      double timeConsistency = 0.0;
      if (patterns.averageMealTimes.isNotEmpty) {
        final totalMeals = patterns.averageMealTimes.values.fold(0, (sum, times) => sum + times.length);
        final maxMealsAtOneTime = patterns.averageMealTimes.values.fold(0, (max, times) => times.length > max ? times.length : max);
        timeConsistency = totalMeals > 0 ? maxMealsAtOneTime / totalMeals : 0.0;
      }

      // Category balance
      double categoryBalance = 0.0;
      if (patterns.categoryPreferences.isNotEmpty) {
        final totalMeals = patterns.categoryPreferences.values.fold(0.0, (sum, count) => sum + count);
        final expectedPerCategory = totalMeals / patterns.categoryPreferences.length;
        double variance = 0.0;
        for (var count in patterns.categoryPreferences.values) {
          variance += (count - expectedPerCategory) * (count - expectedPerCategory);
        }
        categoryBalance = 1.0 - (variance / totalMeals);
      }

      return (frequencyScore + timeConsistency + categoryBalance) / 3.0;
    } catch (e) {
      AppLogger.error('Error calculating consistency score', e);
      return 0.0;
    }
  }

  /// Get user's dietary variety score
  static Future<double> getVarietyScore(String userId) async {
    try {
      final patterns = await analyzeUserPatterns(userId: userId);
      
      if (patterns.mostFrequentRecipes.isEmpty) return 0.0;

      // Calculate variety based on:
      // 1. Number of unique recipes
      // 2. Distribution of recipe frequency
      // 3. Category diversity

      final totalRecipes = patterns.mostFrequentRecipes.length;
      double recipeVariety = totalRecipes / 20.0; // Normalize to 20 recipes
      if (recipeVariety > 1.0) recipeVariety = 1.0;

      final categoryCount = patterns.favoriteCategories.length;
      double categoryVariety = categoryCount / 5.0; // Normalize to 5 categories
      if (categoryVariety > 1.0) categoryVariety = 1.0;

      return (recipeVariety + categoryVariety) / 2.0;
    } catch (e) {
      AppLogger.error('Error calculating variety score', e);
      return 0.0;
    }
  }

  // Helper methods
  static UserEatingPatterns _getEmptyPatterns() {
    return UserEatingPatterns(
      averageMealTimes: {},
      favoriteCategories: [],
      leastLikedIngredients: [],
      weeklyPatterns: {},
      seasonalPreferences: {},
      mostFrequentRecipes: [],
      averageMealFrequency: 0,
      categoryPreferences: {},
    );
  }

  static List<String> _getTopItems(Map<String, int> items, int count) {
    final sorted = items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).map((e) => e.key).toList();
  }

  static List<String> _getLeastLikedIngredients(Map<String, int> ingredients) {
    // For now, return empty list. In the future, this could analyze
    // ingredients that appear in recipes the user doesn't complete
    return [];
  }

  static Map<String, double> _processSeasonalData(Map<String, int> seasonalData) {
    final preferences = <String, double>{};
    final total = seasonalData.values.fold(0, (sum, count) => sum + count);
    
    if (total == 0) return preferences;

    seasonalData.forEach((month, count) {
      preferences[month] = count / total;
    });

    return preferences;
  }

  static void _analyzeIngredients(String ingredients, Map<String, int> ingredientCount) {
    // Simple keyword extraction - in a real implementation, this would be more sophisticated
    final commonIngredients = [
      'chicken', 'pork', 'beef', 'fish', 'rice', 'noodles', 'vegetables',
      'onion', 'garlic', 'tomato', 'potato', 'carrot', 'egg', 'milk',
      'cheese', 'bread', 'pasta', 'soup', 'salad'
    ];

    final lowerIngredients = ingredients.toLowerCase();
    for (final ingredient in commonIngredients) {
      if (lowerIngredients.contains(ingredient)) {
        ingredientCount[ingredient] = (ingredientCount[ingredient] ?? 0) + 1;
      }
    }
  }

  static Future<List<dynamic>> _getCategoryMeals(String userId, MealCategory category) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final response = await _client
        .from('meal_plan_history')
        .select()
        .eq('user_id', userId)
        .eq('meal_category', category.name)
        .gte('completed_at', thirtyDaysAgo.toUtc().toIso8601String())
        .order('completed_at', ascending: true);

    return response;
  }

  static String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// Calculate meal consistency score (0.0 to 1.0)
  static double _calculateMealConsistency(List<dynamic> meals, int daysBack) {
    if (meals.isEmpty) return 0.0;
    
    // Count unique days with meals
    final uniqueDays = meals.map((meal) {
      final date = DateTime.parse(meal['completed_at']);
      return DateTime(date.year, date.month, date.day);
    }).toSet().length;
    
    // Consistency score based on how many days have meals
    return uniqueDays / daysBack;
  }

  /// Calculate meal variety score (0.0 to 1.0)
  static double _calculateMealVariety(List<dynamic> meals) {
    if (meals.isEmpty) return 0.0;
    
    // Count unique recipes
    final uniqueRecipes = meals.map((meal) => meal['recipe_id'] ?? meal['title']).toSet().length;
    
    // Variety score based on unique recipes vs total meals
    return uniqueRecipes / meals.length;
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
}
