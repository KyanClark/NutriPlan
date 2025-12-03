import 'meal_history_entry.dart';
import 'user_nutrition_goals.dart';
import 'recipes.dart';

/// Smart meal suggestion with reasoning
class SmartMealSuggestion {
  final Recipe recipe;
  final SuggestionType type;
  final String reasoning;
  final double relevanceScore;
  final Map<String, double> nutritionalBenefits;
  final List<String> tags;

  SmartMealSuggestion({
    required this.recipe,
    required this.type,
    required this.reasoning,
    required this.relevanceScore,
    required this.nutritionalBenefits,
    required this.tags,
  });
}

/// Types of smart suggestions
enum SuggestionType {
  fillGap,        // Addresses nutritional deficiencies
  perfectTiming,  // Suited for current meal time
  userFavorites,  // Similar to frequently eaten meals
  trySomethingNew, // Expands variety
  healthBoost,    // Supports health conditions
  budgetFriendly, // Cost-effective options
  quickPrep,      // Fast to prepare
}

/// User eating patterns analysis
class UserEatingPatterns {
  final Map<MealCategory, List<DateTime>> averageMealTimes; // Category -> times
  final List<String> favoriteCategories;
  final List<String> leastLikedIngredients;
  final Map<String, double> weeklyPatterns; // Day -> frequency
  final Map<String, double> seasonalPreferences;
  final List<String> mostFrequentRecipes;
  final double averageMealFrequency;
  final Map<MealCategory, double> categoryPreferences;
  final double mealConsistencyScore;
  final double mealVarietyScore;

  UserEatingPatterns({
    required this.averageMealTimes,
    required this.favoriteCategories,
    required this.leastLikedIngredients,
    required this.weeklyPatterns,
    required this.seasonalPreferences,
    required this.mostFrequentRecipes,
    required this.averageMealFrequency,
    required this.categoryPreferences,
    this.mealConsistencyScore = 0.0,
    this.mealVarietyScore = 0.0,
  });
}

/// Current nutrition status for a day
class CurrentDayNutrition {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double totalSugar;
  final double totalSodium;
  final double totalCholesterol;
  final int mealCount;
  final Map<MealCategory, double> caloriesByMeal;
  final DateTime date;

  CurrentDayNutrition({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSugar,
    required this.totalSodium,
    required this.totalCholesterol,
    required this.mealCount,
    required this.caloriesByMeal,
    required this.date,
  });

  /// Calculate remaining calories for the day
  double getRemainingCalories(double dailyGoal) {
    return dailyGoal - totalCalories;
  }

  /// Calculate remaining protein for the day
  double getRemainingProtein(double dailyGoal) {
    return dailyGoal - totalProtein;
  }

  /// Calculate remaining fiber for the day
  double getRemainingFiber(double dailyGoal) {
    return dailyGoal - totalFiber;
  }
}

/// Nutritional gap analysis
class NutritionalGap {
  final String nutrient;
  final double current;
  final double target;
  final double gap;
  final double percentage;
  final Priority priority;

  NutritionalGap({
    required this.nutrient,
    required this.current,
    required this.target,
    required this.gap,
    required this.percentage,
    required this.priority,
  });
}

enum Priority {
  critical, // < 50% of target
  high,     // 50-70% of target
  medium,   // 70-90% of target
  low,      // 90-100% of target
  excess,   // > 100% of target
}

/// Suggestion context for generating recommendations
class SuggestionContext {
  final DateTime targetTime;
  final MealCategory mealCategory;
  final String userId;
  final CurrentDayNutrition currentNutrition;
  final UserNutritionGoals userGoals;
  final UserEatingPatterns userPatterns;
  final List<NutritionalGap> nutritionalGaps;

  SuggestionContext({
    required this.targetTime,
    required this.mealCategory,
    required this.userId,
    required this.currentNutrition,
    required this.userGoals,
    required this.userPatterns,
    required this.nutritionalGaps,
  });
}

/// Suggestion result with metadata
class SuggestionResult {
  final List<SmartMealSuggestion> suggestions;
  final String primaryReason;
  final Map<String, double> nutritionalImpact;
  final DateTime generatedAt;
  final SuggestionContext context;

  SuggestionResult({
    required this.suggestions,
    required this.primaryReason,
    required this.nutritionalImpact,
    required this.generatedAt,
    required this.context,
  });
}
