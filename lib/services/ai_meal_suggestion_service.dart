import 'dart:math';
import '../models/meal_history_entry.dart';
import '../models/user_nutrition_goals.dart';
import '../models/recipes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealSuggestion {
  final Recipe recipe;
  final String reason;
  final double confidence;
  final List<String> benefits;
  final String mealType;
  final String timing;

  MealSuggestion({
    required this.recipe,
    required this.reason,
    required this.confidence,
    required this.benefits,
    required this.mealType,
    required this.timing,
  });
}

class UserEatingProfile {
  final List<String> favoriteCuisines;
  final List<String> dislikedIngredients;
  final List<String> allergies;
  final Map<String, double> macroPreferences;
  final List<String> dietaryRestrictions;
  final Map<String, int> mealTiming;
  final List<String> skippedMealTypes;

  UserEatingProfile({
    required this.favoriteCuisines,
    required this.dislikedIngredients,
    required this.allergies,
    required this.macroPreferences,
    required this.dietaryRestrictions,
    required this.mealTiming,
    required this.skippedMealTypes,
  });
}

class AIMealSuggestionService {
  static const List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  
  // AI-powered meal suggestion algorithm
  Future<List<MealSuggestion>> getPersonalizedMealSuggestions({
    required String userId,
    required String mealType,
    required DateTime targetTime,
    int limit = 5,
  }) async {
    try {
      // 1. Fetch user data and preferences
      final userProfile = await _getUserEatingProfile(userId);
      final recentMeals = await _getRecentMeals(userId, days: 7);
      final nutritionGoals = await _getUserNutritionGoals(userId);
      final availableRecipes = await _getAvailableRecipes();
      
      // 2. Analyze eating patterns
      final eatingPatterns = _analyzeEatingPatterns(recentMeals);
      final nutritionalGaps = _identifyNutritionalGaps(recentMeals, nutritionGoals);
      final mealContext = _analyzeMealContext(targetTime, mealType);
      
      // 3. Generate AI-powered suggestions
      final suggestions = await _generateAISuggestions(
        availableRecipes: availableRecipes,
        userProfile: userProfile,
        eatingPatterns: eatingPatterns,
        nutritionalGaps: nutritionalGaps,
        mealContext: mealContext,
        mealType: mealType,
        limit: limit,
      );
      
      return suggestions;
    } catch (e) {
      print('Error generating meal suggestions: $e');
      return [];
    }
  }

  // Get user's eating profile and preferences
  Future<UserEatingProfile> _getUserEatingProfile(String userId) async {
    final client = Supabase.instance.client;
    
    // Fetch user preferences from database
    final prefsResult = await client
        .from('user_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    // Fetch recent meal history to analyze patterns
    final mealHistory = await client
        .from('meal_plan_history')
        .select()
        .eq('user_id', userId)
        .gte('completed_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
        .order('completed_at', ascending: false);
    
    // Analyze patterns from meal history
    final favoriteCuisines = _extractFavoriteCuisines(mealHistory);
    final dislikedIngredients = _extractDislikedIngredients(mealHistory);
    final mealTiming = _analyzeMealTiming(mealHistory);
    final skippedMealTypes = _identifySkippedMealTypes(mealHistory);
    
    return UserEatingProfile(
      favoriteCuisines: favoriteCuisines,
      dislikedIngredients: dislikedIngredients,
      allergies: prefsResult?['allergies'] ?? [],
      macroPreferences: _extractMacroPreferences(prefsResult),
      dietaryRestrictions: prefsResult?['dietary_restrictions'] ?? [],
      mealTiming: mealTiming,
      skippedMealTypes: skippedMealTypes,
    );
  }

  // Analyze recent eating patterns
  Map<String, dynamic> _analyzeEatingPatterns(List<MealHistoryEntry> recentMeals) {
    if (recentMeals.isEmpty) return {};
    
    final patterns = <String, dynamic>{};
    
    // Analyze meal timing patterns
    final mealTimes = recentMeals.map((m) => m.completedAt.hour).toList();
    patterns['averageMealTime'] = mealTimes.reduce((a, b) => a + b) / mealTimes.length;
    patterns['mealTimeVariance'] = _calculateVariance(mealTimes);
    
    // Analyze nutritional patterns
    final avgCalories = recentMeals.map((m) => m.calories).reduce((a, b) => a + b) / recentMeals.length;
    patterns['averageCalories'] = avgCalories;
    
    // Analyze meal category preferences
    final categoryCounts = <MealCategory, int>{};
    for (final meal in recentMeals) {
      categoryCounts[meal.category] = (categoryCounts[meal.category] ?? 0) + 1;
    }
    patterns['categoryPreferences'] = categoryCounts;
    
    // Analyze macro balance
    final totalProtein = recentMeals.map((m) => m.protein).reduce((a, b) => a + b);
    final totalCarbs = recentMeals.map((m) => m.carbs).reduce((a, b) => a + b);
    final totalFat = recentMeals.map((m) => m.fat).reduce((a, b) => a + b);
    patterns['macroBalance'] = {
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
    
    return patterns;
  }

  // Identify nutritional gaps based on goals
  Map<String, dynamic> _identifyNutritionalGaps(
    List<MealHistoryEntry> recentMeals,
    UserNutritionGoals? goals,
  ) {
    if (goals == null || recentMeals.isEmpty) return {};
    
    final gaps = <String, dynamic>{};
    
    // Calculate daily averages
    final days = recentMeals.map((m) => m.completedAt.day).toSet().length;
    final dailyCalories = recentMeals.map((m) => m.calories).reduce((a, b) => a + b) / days;
    final dailyProtein = recentMeals.map((m) => m.protein).reduce((a, b) => a + b) / days;
    final dailyCarbs = recentMeals.map((m) => m.carbs).reduce((a, b) => a + b) / days;
    final dailyFat = recentMeals.map((m) => m.fat).reduce((a, b) => a + b) / days;
    
    // Identify gaps
    gaps['calorieGap'] = goals.calorieGoal - dailyCalories;
    gaps['proteinGap'] = goals.proteinGoal - dailyProtein;
    gaps['carbGap'] = goals.carbGoal - dailyCarbs;
    gaps['fatGap'] = goals.fatGoal - dailyFat;
    
    return gaps;
  }

  // Analyze meal context (time, season, etc.)
  Map<String, dynamic> _analyzeMealContext(DateTime targetTime, String mealType) {
    final context = <String, dynamic>{};
    
    // Time-based context
    context['hour'] = targetTime.hour;
    context['isWeekend'] = targetTime.weekday > 5;
    context['season'] = _getSeason(targetTime);
    
    // Meal-specific context
    context['mealType'] = mealType;
    context['isBreakfast'] = mealType == 'breakfast';
    context['isLunch'] = mealType == 'lunch';
    context['isDinner'] = mealType == 'dinner';
    context['isSnack'] = mealType == 'snack';
    
    return context;
  }

  // AI-powered suggestion generation
  Future<List<MealSuggestion>> _generateAISuggestions({
    required List<Recipe> availableRecipes,
    required UserEatingProfile userProfile,
    required Map<String, dynamic> eatingPatterns,
    required Map<String, dynamic> nutritionalGaps,
    required Map<String, dynamic> mealContext,
    required String mealType,
    required int limit,
  }) async {
    final suggestions = <MealSuggestion>[];
    
    // Score each recipe based on multiple factors
    final scoredRecipes = <Recipe, double>{};
    
    for (final recipe in availableRecipes) {
      double score = 0.0;
      
      // 1. Nutritional gap filling score (40% weight)
      score += _calculateNutritionalScore(recipe, nutritionalGaps, mealContext) * 0.4;
      
      // 2. User preference alignment score (30% weight)
      score += _calculatePreferenceScore(recipe, userProfile) * 0.3;
      
      // 3. Eating pattern alignment score (20% weight)
      score += _calculatePatternScore(recipe, eatingPatterns, mealContext) * 0.2;
      
      // 4. Seasonal and contextual score (10% weight)
      score += _calculateContextualScore(recipe, mealContext) * 0.1;
      
      scoredRecipes[recipe] = score;
    }
    
    // Sort by score and take top recipes
    final sortedRecipes = scoredRecipes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Generate suggestions for top recipes
    for (int i = 0; i < limit && i < sortedRecipes.length; i++) {
      final recipe = sortedRecipes[i].key;
      final score = sortedRecipes[i].value;
      
      final suggestion = MealSuggestion(
        recipe: recipe,
        reason: _generateSuggestionReason(recipe, userProfile, nutritionalGaps, mealContext),
        confidence: score.clamp(0.0, 1.0),
        benefits: _generateBenefits(recipe, nutritionalGaps),
        mealType: mealType,
        timing: _getOptimalTiming(mealType, mealContext),
      );
      
      suggestions.add(suggestion);
    }
    
    return suggestions;
  }

  // Calculate nutritional score
  double _calculateNutritionalScore(Recipe recipe, Map<String, dynamic> gaps, Map<String, dynamic> context) {
    double score = 0.0;
    
    // Check if recipe helps fill nutritional gaps
    if (gaps['calorieGap'] != null && gaps['calorieGap'] > 0) {
      score += (recipe.calories / gaps['calorieGap']).clamp(0.0, 1.0);
    }
    
    if (gaps['proteinGap'] != null && gaps['proteinGap'] > 0) {
      final protein = recipe.macros['protein'] ?? 0.0;
      score += (protein / gaps['proteinGap']).clamp(0.0, 1.0);
    }
    
    if (gaps['carbGap'] != null && gaps['carbGap'] > 0) {
      final carbs = recipe.macros['carbs'] ?? 0.0;
      score += (carbs / gaps['carbGap']).clamp(0.0, 1.0);
    }
    
    // Normalize score
    return (score / 3.0).clamp(0.0, 1.0);
  }

  // Calculate preference alignment score
  double _calculatePreferenceScore(Recipe recipe, UserEatingProfile profile) {
    double score = 0.0;
    
    // Check cuisine preference (using diet types as cuisine indicator)
    bool hasPreferredCuisine = false;
    for (final dietType in recipe.dietTypes) {
      if (profile.favoriteCuisines.contains(dietType)) {
        hasPreferredCuisine = true;
        break;
      }
    }
    if (hasPreferredCuisine) {
      score += 0.3;
    }
    
    // Check for disliked ingredients
    bool hasDislikedIngredients = false;
    for (final ingredient in profile.dislikedIngredients) {
      for (final recipeIngredient in recipe.ingredients) {
        if (recipeIngredient.toLowerCase().contains(ingredient.toLowerCase())) {
          hasDislikedIngredients = true;
          break;
        }
      }
      if (hasDislikedIngredients) break;
    }
    if (!hasDislikedIngredients) {
      score += 0.4;
    }
    
    // Check dietary restrictions
    bool meetsRestrictions = true;
    for (final restriction in profile.dietaryRestrictions) {
      if (!_meetsDietaryRestriction(recipe, restriction)) {
        meetsRestrictions = false;
        break;
      }
    }
    if (meetsRestrictions) {
      score += 0.3;
    }
    
    return score;
  }

  // Calculate pattern alignment score
  double _calculatePatternScore(Recipe recipe, Map<String, dynamic> patterns, Map<String, dynamic> context) {
    double score = 0.0;
    
    // Check if recipe fits typical meal timing
    if (patterns['averageMealTime'] != null) {
      final timeDiff = (context['hour'] - patterns['averageMealTime']).abs();
      if (timeDiff <= 2) {
        score += 0.5;
      }
    }
    
    // Check if recipe fits typical calorie range
    if (patterns['averageCalories'] != null) {
      final calorieDiff = (recipe.calories - patterns['averageCalories']).abs();
      final calorieRange = patterns['averageCalories'] * 0.3; // 30% tolerance
      if (calorieDiff <= calorieRange) {
        score += 0.5;
      }
    }
    
    return score;
  }

  // Calculate contextual score
  double _calculateContextualScore(Recipe recipe, Map<String, dynamic> context) {
    double score = 0.0;
    
    // Seasonal appropriateness
    if (_isSeasonallyAppropriate(recipe, context['season'])) {
      score += 0.5;
    }
    
    // Meal type appropriateness
    if (_isMealTypeAppropriate(recipe, context['mealType'])) {
      score += 0.5;
    }
    
    return score;
  }

  // Generate personalized suggestion reason
  String _generateSuggestionReason(
    Recipe recipe,
    UserEatingProfile profile,
    Map<String, dynamic> gaps,
    Map<String, dynamic> context,
  ) {
    final reasons = <String>[];
    
    // Nutritional reasons
    final protein = recipe.macros['protein'] ?? 0.0;
    if (gaps['proteinGap'] != null && gaps['proteinGap'] > 0 && protein > 20) {
      reasons.add('High in protein to meet your daily goals');
    }
    
    if (gaps['calorieGap'] != null && gaps['calorieGap'] > 0) {
      reasons.add('Perfect calorie content for your needs');
    }
    
    // Preference reasons
    bool hasPreferredCuisine = false;
    String preferredCuisine = '';
    for (final dietType in recipe.dietTypes) {
      if (profile.favoriteCuisines.contains(dietType)) {
        hasPreferredCuisine = true;
        preferredCuisine = dietType;
        break;
      }
    }
    if (hasPreferredCuisine) {
      reasons.add('Matches your favorite $preferredCuisine cuisine');
    }
    
    // Contextual reasons
    if (context['isBreakfast'] && recipe.calories < 400) {
      reasons.add('Light and energizing breakfast option');
    }
    
    if (context['season'] == 'winter' && recipe.calories > 500) {
      reasons.add('Warming and hearty for cold weather');
    }
    
    // Fallback reason
    if (reasons.isEmpty) {
      reasons.add('Balanced and nutritious meal option');
    }
    
    return reasons.take(2).join(' • ');
  }

  // Generate health benefits
  List<String> _generateBenefits(Recipe recipe, Map<String, dynamic> gaps) {
    final benefits = <String>[];
    
    final protein = recipe.macros['protein'] ?? 0.0;
    final fiber = recipe.macros['fiber'] ?? 0.0;
    final fat = recipe.macros['fat'] ?? 0.0;
    final sugar = recipe.macros['sugar'] ?? 0.0;
    
    if (protein > 25) benefits.add('High protein');
    if (fiber > 8) benefits.add('High fiber');
    if (recipe.calories < 400) benefits.add('Low calorie');
    if (fat < 15) benefits.add('Low fat');
    if (sugar < 10) benefits.add('Low sugar');
    
    // Fill nutritional gaps
    if (gaps['proteinGap'] != null && gaps['proteinGap'] > 0) {
      benefits.add('Fills protein gap');
    }
    if (gaps['fiberGap'] != null && gaps['fiberGap'] > 0) {
      benefits.add('Fills fiber gap');
    }
    
    return benefits.take(3).toList();
  }

  // Helper methods
  List<String> _extractFavoriteCuisines(List<dynamic> mealHistory) {
    // Implementation to extract favorite cuisines from meal history
    return ['Italian', 'Mexican', 'Asian']; // Placeholder
  }

  List<String> _extractDislikedIngredients(List<dynamic> mealHistory) {
    // Implementation to extract disliked ingredients
    return ['onions', 'mushrooms']; // Placeholder
  }

  Map<String, int> _analyzeMealTiming(List<dynamic> mealHistory) {
    // Implementation to analyze meal timing patterns
    return {'breakfast': 8, 'lunch': 13, 'dinner': 19}; // Placeholder
  }

  List<String> _identifySkippedMealTypes(List<dynamic> mealHistory) {
    // Implementation to identify skipped meal types
    return ['breakfast']; // Placeholder
  }

  Map<String, double> _extractMacroPreferences(Map<String, dynamic>? prefs) {
    // Implementation to extract macro preferences
    return {'protein': 0.3, 'carbs': 0.5, 'fat': 0.2}; // Placeholder
  }

  double _calculateVariance(List<int> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }

  bool _meetsDietaryRestriction(Recipe recipe, String restriction) {
    // Implementation to check dietary restrictions
    return true; // Placeholder
  }

  bool _isSeasonallyAppropriate(Recipe recipe, String season) {
    // Implementation to check seasonal appropriateness
    return true; // Placeholder
  }

  bool _isMealTypeAppropriate(Recipe recipe, String mealType) {
    // Implementation to check meal type appropriateness
    return true; // Placeholder
  }

  String _getOptimalTiming(String mealType, Map<String, dynamic> context) {
    // Implementation to get optimal timing
    return 'Within the next hour'; // Placeholder
  }

  Future<List<Recipe>> _getAvailableRecipes() async {
    // Implementation to fetch available recipes
    return []; // Placeholder
  }

  Future<List<MealHistoryEntry>> _getRecentMeals(String userId, {required int days}) async {
    // Implementation to fetch recent meals
    return []; // Placeholder
  }

  Future<UserNutritionGoals?> _getUserNutritionGoals(String userId) async {
    // Implementation to fetch user nutrition goals
    return null; // Placeholder
  }
}
