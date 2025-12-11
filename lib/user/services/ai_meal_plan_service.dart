import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/recipes.dart';
import '../models/user_nutrition_goals.dart';
import '../utils/app_logger.dart';

/// Dedicated AI service for meal plan generation
/// This is separate from SmartMealSuggestionService to use different AI models/prompts
class AIMealPlanService {
  // Read from .env via flutter_dotenv (fallback to --dart-define)
  static String get _groqApiKey =>
      (dotenv.env['GROQ_API_KEY'] ?? const String.fromEnvironment('GROQ_API_KEY', defaultValue: ''));

  /// Generate meal plan using AI analysis
  /// This uses a different AI model/prompt strategy than smart meal suggestions
  static Future<List<Map<String, dynamic>>> generateMealPlan({
    required String userId,
    required DateTime targetDate,
    required List<Recipe> allRecipes,
    required List<Map<String, dynamic>> mealHistory,
    required Map<String, dynamic> userPrefs,
    required UserNutritionGoals? userGoals,
    required Map<String, double> currentNutrition,
    required Set<String> recentMeals,
    required bool includeBreakfast,
    required bool includeLunch,
    required bool includeDinner,
  }) async {
    try {
      if (_groqApiKey.isEmpty) {
        AppLogger.warning('GROQ_API_KEY not set for AI meal plan generation');
        return [];
      }

      // Build comprehensive AI prompt
      final prompt = _buildMealPlanPrompt(
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

      // Call AI API with a different model than smart suggestions
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-70b-versatile', // Use a more powerful model for meal planning
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert Filipino nutritionist and meal planning AI. You analyze comprehensive user data and intelligently select the best meals from available recipes to create balanced, personalized meal plans.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 2500, // More tokens for comprehensive meal planning
          'temperature': 0.6, // Slightly lower temperature for more consistent meal planning
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];

        // Parse AI response
        final selectedMeals = _parseMealPlanResponse(aiResponse, allRecipes, targetDate);

        if (selectedMeals.isNotEmpty) {
          return selectedMeals;
        }
      } else {
        AppLogger.error('AI meal plan API error: ${response.statusCode} - ${response.body}');
      }

      return [];
    } catch (e) {
      AppLogger.error('Error generating AI meal plan', e);
      return [];
    }
  }

  /// Build comprehensive prompt for meal plan generation
  static String _buildMealPlanPrompt({
    required String userId,
    required DateTime targetDate,
    required List<Recipe> allRecipes,
    required List<Map<String, dynamic>> mealHistory,
    required Map<String, dynamic> userPrefs,
    required UserNutritionGoals? userGoals,
    required Map<String, double> currentNutrition,
    required Set<String> recentMeals,
    required bool includeBreakfast,
    required bool includeLunch,
    required bool includeDinner,
  }) {
    final healthConditions = userPrefs['health_conditions'] as List<dynamic>? ?? [];
    final likedDishes = userPrefs['like_dishes'] as List<dynamic>? ?? [];
    final dietType = userPrefs['diet_type'] as List<dynamic>? ?? [];

    // Build available recipes list (limit to 100 to avoid token limits)
    final recipesList = allRecipes.take(100).map((r) {
      final protein = (r.macros['protein'] ?? 0).toDouble();
      final carbs = (r.macros['carbs'] ?? 0).toDouble();
      final fat = (r.macros['fat'] ?? 0).toDouble();
      final fiber = (r.macros['fiber'] ?? 0).toDouble();
      final sugar = (r.macros['sugar'] ?? 0).toDouble();
      final sodium = (r.macros['sodium'] ?? 0).toDouble();
      return '- ${r.title} (ID: ${r.id}) | Calories: ${r.calories} | Protein: ${protein}g | Carbs: ${carbs}g | Fat: ${fat}g | Fiber: ${fiber}g | Sugar: ${sugar}g | Sodium: ${sodium}mg | Tags: ${r.tags.join(", ")}';
    }).join('\n');

    // Build recent meals list
    final recentMealsList = recentMeals.take(20).join(', ');

    // Build meal history summary
    final mealHistorySummary = mealHistory.take(10).map((m) => '${m['title']} (${m['meal_type'] ?? 'unknown'})').join(', ');

    // Build health conditions info
    final healthInfo = healthConditions.isNotEmpty && !healthConditions.contains('none')
        ? healthConditions.map((c) {
            switch (c.toString().toLowerCase()) {
              case 'diabetes':
                return 'Diabetes: Low carbs (<60g per meal), high fiber (>3g), low sugar (<15g). AVOID recipes with: high carbs (>60g), high sugar (>15g), low fiber (<3g)';
              case 'hypertension':
              case 'high_blood_pressure':
                return 'Hypertension: Very low sodium (<500mg per meal). AVOID recipes with: high sodium (>500mg), processed foods, salty dishes';
              default:
                return '$c: Apply general healthy criteria';
            }
          }).join('\n')
        : 'None';

    final calorieGoal = userGoals?.calorieGoal ?? 2000.0;
    final proteinGoal = userGoals?.proteinGoal ?? 150.0;
    final carbGoal = userGoals?.carbGoal ?? 250.0;
    final fatGoal = userGoals?.fatGoal ?? 65.0;

    final mealsNeeded = <String>[];
    if (includeBreakfast) mealsNeeded.add('breakfast');
    if (includeLunch) mealsNeeded.add('lunch');
    if (includeDinner) mealsNeeded.add('dinner');

    return '''You are an expert Filipino nutritionist and meal planning AI. Your task is to analyze the user's comprehensive data and intelligently select the BEST meals from the available recipes list to create a complete, balanced meal plan.

USER PROFILE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target Date: ${targetDate.toString().split(' ')[0]}
Meals Needed: ${mealsNeeded.join(', ')}

CURRENT NUTRITION STATUS (for target date):
- Calories: ${currentNutrition['calories']!.toStringAsFixed(0)} / ${calorieGoal.toStringAsFixed(0)} (${((currentNutrition['calories']! / calorieGoal) * 100).toStringAsFixed(0)}%)
- Protein: ${currentNutrition['protein']!.toStringAsFixed(1)}g / ${proteinGoal.toStringAsFixed(0)}g (${((currentNutrition['protein']! / proteinGoal) * 100).toStringAsFixed(0)}%)
- Carbs: ${currentNutrition['carbs']!.toStringAsFixed(1)}g / ${carbGoal.toStringAsFixed(0)}g (${((currentNutrition['carbs']! / carbGoal) * 100).toStringAsFixed(0)}%)
- Fat: ${currentNutrition['fat']!.toStringAsFixed(1)}g / ${fatGoal.toStringAsFixed(0)}g (${((currentNutrition['fat']! / fatGoal) * 100).toStringAsFixed(0)}%)
- Fiber: ${currentNutrition['fiber']!.toStringAsFixed(1)}g (Goal: 25-30g)

HEALTH CONDITIONS (CRITICAL - STRICTLY ENFORCE):
$healthInfo

USER PREFERENCES:
- Liked Dishes: ${likedDishes.isEmpty ? 'None specified' : likedDishes.join(', ')}
- Diet Type: ${dietType.isEmpty ? 'None specified' : dietType.join(', ')}
- Recent Meal History (last 10): ${mealHistorySummary.isEmpty ? 'No recent meals' : mealHistorySummary}

CRITICAL ANTI-REPETITION REQUIREMENT:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The following meals were consumed in the last 14 days. You MUST AVOID selecting these to ensure variety:
${recentMealsList.isEmpty ? 'None (user has no recent meals)' : recentMealsList}

AVAILABLE RECIPES (SELECT FROM THESE ONLY):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
$recipesList

YOUR TASK:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Analyze the user's nutritional gaps and select meals that help fill them
2. Choose meals that complement each other nutritionally (e.g., if breakfast is high in carbs, lunch should be protein-rich)
3. STRICTLY AVOID any meals from the "Recent Meals" list above - prioritize variety and freshness
4. Ensure meals are appropriate for their meal type (breakfast, lunch, dinner)
5. Consider user preferences (liked dishes, diet type)
6. STRICTLY enforce health condition requirements
7. Select DIFFERENT recipes for each meal type (no duplicates in the same day)
8. Prioritize meals that the user hasn't eaten recently to maximize variety

SELECTION CRITERIA (in priority order):
1. Nutritional balance and gap-filling (40%)
2. Variety - avoiding recent meals (30%)
3. User preferences and health conditions (20%)
4. Meal type appropriateness (10%)

OUTPUT FORMAT (JSON only):
{
  "meal_plan": [
    {
      "recipe_id": "exact_id_from_available_recipes",
      "recipe_title": "exact_title_from_available_recipes",
      "meal_type": "breakfast|lunch|dinner",
      "reasoning": "Brief explanation of why this meal was selected (nutritional benefits, variety, preferences)"
    }
  ],
  "total_calories": 0,
  "total_protein": 0,
  "total_carbs": 0,
  "total_fat": 0,
  "total_fiber": 0
}

CRITICAL REQUIREMENTS:
- You MUST select recipes ONLY from the "AVAILABLE RECIPES" list above
- Use EXACT recipe IDs and titles as shown in the list
- DO NOT create new recipes or suggest recipes not in the list
- NEVER select recipes with "test", "sample", or "demo" in the title
- Ensure all selected recipes are DIFFERENT (no duplicates)
- Calculate totals for the entire meal plan
- Provide clear reasoning for each selection
- Prioritize variety - avoid recent meals at all costs
- If no health conditions: Select 1 random meal + 2 healthy meals
- If health conditions exist: Select all meals that meet health requirements''';
  }

  /// Parse AI response and map to actual recipes
  static List<Map<String, dynamic>> _parseMealPlanResponse(
    String aiResponse,
    List<Recipe> allRecipes,
    DateTime targetDate,
  ) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', multiLine: true, dotAll: true).firstMatch(aiResponse);
      if (jsonMatch == null) {
        AppLogger.warning('No JSON found in AI meal plan response');
        return [];
      }

      final jsonStr = jsonMatch.group(0)!;
      final data = jsonDecode(jsonStr);
      final mealPlan = data['meal_plan'] as List;

      // Create map of recipes by ID and title for quick lookup
      final recipesById = {for (final r in allRecipes) r.id: r};
      final recipesByTitle = {for (final r in allRecipes) r.title.toLowerCase(): r};

      final result = <Map<String, dynamic>>[];
      final usedRecipeIds = <String>{};

      for (final meal in mealPlan) {
        final recipeId = meal['recipe_id']?.toString();
        final recipeTitle = meal['recipe_title']?.toString();
        final mealType = meal['meal_type']?.toString() ?? 'dinner';

        if (recipeId == null && recipeTitle == null) continue;

        Recipe? recipe;
        if (recipeId != null && recipesById.containsKey(recipeId)) {
          recipe = recipesById[recipeId];
        } else if (recipeTitle != null) {
          recipe = recipesByTitle[recipeTitle.toLowerCase()];
        }

        if (recipe == null || usedRecipeIds.contains(recipe.id)) continue;
        
        // Validate recipe - filter out test recipes and invalid recipes
        final titleLower = recipe.title.toLowerCase();
        if (titleLower.contains('test') || titleLower.contains('sample') || titleLower.contains('demo')) {
          AppLogger.warning('Filtered out test recipe: ${recipe.title}');
          continue;
        }
        if (recipe.title.trim().isEmpty || recipe.calories <= 0) {
          AppLogger.warning('Filtered out invalid recipe: ${recipe.title}');
          continue;
        }

        usedRecipeIds.add(recipe.id);

        // Determine meal time based on type
        final hour = mealType == 'breakfast' ? 8 : mealType == 'lunch' ? 12 : 19;
        final mealTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, 0);

        result.add({
          'recipe': recipe,
          'meal_type': mealType,
          'meal_time': _formatTime(mealTime),
          'date': mealTime,
          'ai_reasoning': meal['reasoning']?.toString() ?? 'AI-selected meal',
        });
      }

      return result;
    } catch (e) {
      AppLogger.error('Error parsing AI meal plan response', e);
      return [];
    }
  }

  /// Format time as HH:MM
  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

