import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/smart_suggestion_models.dart';
import '../models/meal_history_entry.dart';
import '../models/user_nutrition_goals.dart';
import '../models/recipes.dart';
import 'recipe_service.dart';
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
        return await _getFallbackSuggestions(mealCategory);
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
          print('AI suggestions failed, falling back to rule-based: $e');
        }
      }
      
      // 6. Fallback to rule-based suggestions
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
      final favCats = context.userPatterns.favoriteCategories.map((e) => e.toLowerCase()).toList();
      final title = r.title.toLowerCase();
      final tags = r.tags.map((t) => t.toLowerCase()).toList();
      final matchesTitle = favCats.any((c) => title.contains(c)) ? 1.0 : 0.0;
      final matchesTag = favCats.any((c) => tags.any((t) => t.contains(c))) ? 1.0 : 0.0;
      final isFavoriteRecipe = context.userPatterns.mostFrequentRecipes.any((t) => t.toLowerCase() == title) ? 0.8 : 0.0;
      return (matchesTitle * 0.6) + (matchesTag * 0.6) + isFavoriteRecipe;
    }

    // Gap fit score: how much it helps with critical gaps
    double gapFitScore(Recipe r) {
      double score = 0.0;
      for (final gap in context.nutritionalGaps) {
        if (gap.priority == Priority.critical || gap.priority == Priority.high) {
          switch (gap.nutrient) {
            case 'protein':
              final v = _getNutrientValue(r, 'protein');
              if (v >= 15) score += (v / (gap.gap.abs() + 1)).clamp(0.0, 1.0) * 1.2;
              break;
            case 'fiber':
              final v2 = _getNutrientValue(r, 'fiber');
              if (v2 >= 5) score += (v2 / (gap.gap.abs() + 1)).clamp(0.0, 1.0);
              break;
            case 'calories':
              final kc = r.calories.toDouble();
              if (kc >= 200) score += (kc / (gap.gap.abs() + 200)).clamp(0.0, 1.0);
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

    // Composite scoring
    final scored = allRecipes.map((r) {
      final score =
          0.45 * gapFitScore(r) +
          0.25 * preferenceScore(r) +
          0.2 * timingBandScore(r) +
          0.1 * (1.0 + recencyPenalty(r));
      return SmartMealSuggestion(
        recipe: r,
        type: SuggestionType.fillGap,
        reasoning: 'Matches your patterns and goals',
        relevanceScore: score,
        nutritionalBenefits: {
          'protein': _getNutrientValue(r, 'protein'),
          'fiber': _getNutrientValue(r, 'fiber'),
          'calories': r.calories.toDouble(),
        },
        tags: ['personalized'],
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
      if (_groqApiKey.isEmpty) {
        print('AI Integration Test: GROQ_API_KEY not set');
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
      print('AI Integration Test: ${success ? "SUCCESS" : "FAILED"} (${response.statusCode})');
      
      if (!success) {
        print('AI Integration Test: Response body: ${response.body}');
      }
      
      return success;
    } catch (e) {
      print('AI Integration Test: ERROR - $e');
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
      final prompt = _buildAIPrompt(context);
      
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
        
        // Parse AI response and map to existing recipes only
        final parsed = _parseAIResponse(aiResponse, context);
        if (parsed.isEmpty) return [];
        final allRecipes = await RecipeService.fetchRecipes();
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
        print('AI API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('AI suggestions error: $e');
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

  /// Build prompt for AI suggestions
  static String _buildAIPrompt(SuggestionContext context) {
    final mealType = context.mealCategory.name.toLowerCase();
    final timeOfDay = context.targetTime.hour < 12 ? 'morning' : 
                     context.targetTime.hour < 17 ? 'afternoon' : 'evening';
    
    return '''
You are a Filipino nutrition expert. Suggest 3 healthy Filipino recipes for $mealType in the $timeOfDay.

Current nutrition status:
- Protein: ${context.currentNutrition.totalProtein}g (goal: ${context.userGoals.proteinGoal}g)
- Carbs: ${context.currentNutrition.totalCarbs}g (goal: ${context.userGoals.carbGoal}g)
- Fat: ${context.currentNutrition.totalFat}g (goal: ${context.userGoals.fatGoal}g)
- Calories: ${context.currentNutrition.totalCalories} (goal: ${context.userGoals.calorieGoal})

Nutritional gaps to address: ${context.nutritionalGaps.join(', ')}

User eating patterns: ${context.userPatterns.toString()}

Please suggest 3 Filipino recipes that:
1. Are appropriate for $mealType
2. Help fill nutritional gaps
3. Fit Filipino dietary preferences
4. Include cost estimates (₱50-200 range)

Format your response as JSON:
{
  "suggestions": [
    {
      "title": "Recipe Name",
      "reasoning": "Why this recipe helps with nutrition gaps",
      "cost": 120,
      "calories": 350,
      "protein": 25,
      "carbs": 30,
      "fat": 15
    }
  ]
}
''';
  }

  /// Parse AI response and convert to SmartMealSuggestion objects
  static List<SmartMealSuggestion> _parseAIResponse(String aiResponse, SuggestionContext context) {
    try {
      // Extract JSON from AI response
      final jsonMatch = RegExp(r'\{.*\}', multiLine: true, dotAll: true).firstMatch(aiResponse);
      if (jsonMatch == null) {
        print('No JSON found in AI response');
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
      print('Error parsing AI response: $e');
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
