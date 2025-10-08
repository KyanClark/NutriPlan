import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/smart_suggestion_models.dart';
import '../models/meal_history_entry.dart';
import '../models/user_nutrition_goals.dart';
import '../models/recipes.dart';
import 'recipe_service.dart';

class GeminiMealSuggestionService {
  // Read from build-time env, fallback to previously used key for compatibility
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyA58P35E85fvoML8AkqKIME9n4dC26M4GQ',
  );
  static const String _groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Get AI-powered meal suggestions using Gemini API
  static Future<List<SmartMealSuggestion>> getAISuggestions({
    required String userId,
    required MealCategory mealCategory,
    required UserNutritionGoals userGoals,
    required CurrentDayNutrition currentNutrition,
    required UserEatingPatterns userPatterns,
    DateTime? targetTime,
  }) async {
    try {
      // If API key is missing, return empty suggestions gracefully
      if (_apiKey.isEmpty) {
        return [];
      }
      // Get available recipes
      final allRecipes = await RecipeService.fetchRecipes();
      if (allRecipes.isEmpty) {
        return [];
      }

      // Prepare the AI prompt
      final prompt = _buildAIPrompt(
        mealCategory: mealCategory,
        userGoals: userGoals,
        currentNutrition: currentNutrition,
        userPatterns: userPatterns,
        recipes: allRecipes,
        targetTime: targetTime ?? DateTime.now(),
      );

      // Call Groq with retry logic (Gemini deprecated)
      final response = await _callAIWithRetry(prompt);
      
      // Parse AI response
      final suggestions = _parseAIResponse(response, allRecipes);
      
      return suggestions;
    } catch (e) {
      print('Error getting AI suggestions: $e');
      return [];
    }
  }

  /// Call AI provider with retry logic for overloaded service
  static Future<String> _callAIWithRetry(String prompt, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _callAI(prompt);
      } catch (e) {
        final errorMessage = e.toString();
        
        // If it's a 503 (overloaded) or 429 (rate limit), retry with backoff
        if (errorMessage.contains('503') || errorMessage.contains('429')) {
          if (attempt < maxRetries) {
            final delay = Duration(seconds: attempt * 2); // Exponential backoff: 2s, 4s, 6s
            print('AI API overloaded, retrying in ${delay.inSeconds}s (attempt $attempt/$maxRetries)');
            await Future.delayed(delay);
            continue;
          }
        }
        
        // For other errors or max retries reached, throw the error
        rethrow;
      }
    }
    
    throw Exception('Max retries exceeded for AI API');
  }

  /// Build the AI prompt for meal suggestions
  static String _buildAIPrompt({
    required MealCategory mealCategory,
    required UserNutritionGoals userGoals,
    required CurrentDayNutrition currentNutrition,
    required UserEatingPatterns userPatterns,
    required List<Recipe> recipes,
    required DateTime targetTime,
  }) {
    final hour = targetTime.hour;
    final mealTime = _getMealTimeDescription(hour);
    
    // Calculate nutritional gaps
    final calorieGap = userGoals.calorieGoal - currentNutrition.totalCalories;
    final proteinGap = userGoals.proteinGoal - currentNutrition.totalProtein;
    final fiberGap = userGoals.fiberGoal - currentNutrition.totalFiber;

    // Build recipe list for AI
    final recipeList = recipes.take(20).map((recipe) {
      return '''
        - ${recipe.title}
          Calories: ${recipe.calories}
          Protein: ${recipe.macros['protein'] ?? 0}g
          Fiber: ${recipe.macros['fiber'] ?? 0}g
          Cost: ₱${recipe.cost.toStringAsFixed(2)}
          Description: ${recipe.shortDescription}
          Diet Types: ${recipe.dietTypes.join(', ')}
      ''';
    }).join('\n');

    return '''
You are an expert Filipino nutritionist AI specializing in personalized meal recommendations for Filipino users.

USER PROFILE:
- Meal Time: $mealTime (${mealCategory.name})
- Current Time: ${targetTime.hour}:${targetTime.minute.toString().padLeft(2, '0')}
- User ID: unknown

NUTRITIONAL GOALS:
- Daily Calorie Goal: ${userGoals.calorieGoal.toInt()} kcal
- Daily Protein Goal: ${userGoals.proteinGoal.toInt()}g
- Daily Fiber Goal: ${userGoals.fiberGoal.toInt()}g
- Daily Sugar Limit: ${userGoals.sugarGoal.toInt()}g
- Daily Sodium Limit: ${userGoals.sodiumLimit?.toInt() ?? 2300}mg

CURRENT DAY INTAKE:
- Calories Consumed: ${currentNutrition.totalCalories.toInt()} kcal (${((currentNutrition.totalCalories / userGoals.calorieGoal) * 100).toInt()}% of goal)
- Protein Consumed: ${currentNutrition.totalProtein.toInt()}g (${((currentNutrition.totalProtein / userGoals.proteinGoal) * 100).toInt()}% of goal)
- Fiber Consumed: ${currentNutrition.totalFiber.toInt()}g (${((currentNutrition.totalFiber / userGoals.fiberGoal) * 100).toInt()}% of goal)
- Sugar Consumed: ${currentNutrition.totalSugar.toInt()}g
- Sodium Consumed: ${currentNutrition.totalSodium.toInt()}mg

NUTRITIONAL GAPS ANALYSIS:
- Calories Needed: ${calorieGap.toInt()} kcal (${calorieGap > 0 ? 'DEFICIT' : 'EXCESS'})
- Protein Needed: ${proteinGap.toInt()}g (${proteinGap > 0 ? 'DEFICIT' : 'EXCESS'})
- Fiber Needed: ${fiberGap.toInt()}g (${fiberGap > 0 ? 'DEFICIT' : 'EXCESS'})
- Sugar Status: ${currentNutrition.totalSugar > userGoals.sugarGoal ? 'OVER LIMIT' : 'WITHIN LIMIT'}
- Sodium Status: ${currentNutrition.totalSodium > (userGoals.sodiumLimit ?? 2300) ? 'OVER LIMIT' : 'WITHIN LIMIT'}

USER EATING PATTERNS:
- Favorite Categories: ${userPatterns.favoriteCategories.join(', ')}
- Most Frequent Recipes: ${userPatterns.mostFrequentRecipes.take(3).join(', ')}
- Average Meals Per Day: ${userPatterns.averageMealFrequency.toStringAsFixed(1)}
- Meal Consistency Score: ${(userPatterns.mealConsistencyScore * 100).toInt()}%
- Meal Variety Score: ${(userPatterns.mealVarietyScore * 100).toInt()}%

MEAL TIMING CONTEXT:
- Current Hour: ${targetTime.hour}
- Meal Category: ${mealCategory.name}
- Time Context: $mealTime
- Previous Meal: ${_getPreviousMealContext(targetTime)}
- Next Meal: ${_getNextMealContext(targetTime)}

AVAILABLE RECIPES:
$recipeList

TASK:
As a Filipino nutritionist, recommend 3 meals that:

1. NUTRITIONAL PRIORITY:
   - Fill critical nutritional gaps (calories, protein, fiber)
   - Avoid exceeding sugar/sodium limits
   - Provide balanced macronutrients
   - Consider meal timing and portion size

2. CULTURAL FIT:
   - Prioritize Filipino cuisine preferences
   - Consider traditional meal patterns
   - Match local ingredient availability
   - Respect cultural eating habits

3. PERSONALIZATION:
   - Align with user's favorite categories
   - Consider eating patterns and consistency
   - Provide variety to improve meal diversity
   - Match user's budget and preferences

4. TIMING OPTIMIZATION:
   - Appropriate for $mealTime
   - Consider previous/next meals
   - Optimize for current hour (${targetTime.hour})
   - Balance energy needs throughout day

RESPONSE FORMAT:
Return a JSON array with exactly 3 recommendations:
[
  {
    "recipe_title": "Exact Recipe Name from Available List",
    "reasoning": "Detailed explanation of why this meal is perfect for this user at this time (3-4 sentences covering nutrition, timing, and personal fit)",
    "suggestion_type": "fillGap|perfectTiming|userFavorites|trySomethingNew|healthBoost|budgetFriendly|quickPrep",
    "nutritional_benefits": {
      "calories": 350,
      "protein": 25,
      "fiber": 8,
      "sugar": 12,
      "sodium": 450
    },
    "relevance_score": 0.9,
    "meal_timing_benefit": "Why this timing is optimal",
    "cultural_fit": "How this fits Filipino preferences"
  }
]

CRITICAL REQUIREMENTS:
- Only recommend recipes from the available list (exact title match)
- Provide specific nutritional benefits with actual values
- Consider Filipino cuisine and cultural preferences
- Make reasoning personal, detailed, and helpful
- Ensure variety in recommendations (different types)
- Optimize for current meal timing and user patterns
- Balance nutrition, taste, and practicality
''';
  }

  /// Call AI provider with the prompt
  static Future<String> _callAI(String prompt) async {
    final response = _groqApiKey.isNotEmpty
        ? await http.post(
            Uri.parse(_groqUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_groqApiKey',
            },
            body: jsonEncode({
              'model': 'llama-3.1-70b-versatile',
              'temperature': 0.7,
              'max_tokens': 1024,
              'messages': [
                {
                  'role': 'system',
                  'content': 'You are a Filipino nutritionist AI generating meal suggestions.'
                },
                {
                  'role': 'user',
                  'content': prompt,
                }
              ],
            }),
          )
        : http.Response('{"choices": []}', 200);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (_groqApiKey.isNotEmpty) {
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'];
        }
        throw Exception('No choices in Groq response');
      }
    } else if (response.statusCode == 503) {
      throw Exception('AI API overloaded - service temporarily unavailable');
    } else if (response.statusCode == 429) {
      throw Exception('AI API rate limit exceeded - too many requests');
    } else if (response.statusCode == 400) {
      throw Exception('AI API bad request - check prompt format');
    } else {
      throw Exception('AI API error: ${response.statusCode} - ${response.body}');
    }

    // Fallback if no content
    return '[]';
  }

  /// Parse AI response and convert to SmartMealSuggestion objects
  static List<SmartMealSuggestion> _parseAIResponse(String response, List<Recipe> allRecipes) {
    try {
      // Extract JSON from response (AI might include extra text)
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No JSON found in AI response');
      }
      
      final jsonString = response.substring(jsonStart, jsonEnd);
      final List<dynamic> suggestions = jsonDecode(jsonString);
      
      final result = <SmartMealSuggestion>[];
      
      for (final suggestion in suggestions) {
        final recipeTitle = suggestion['recipe_title'] as String;
        final reasoning = suggestion['reasoning'] as String;
        final suggestionType = _parseSuggestionType(suggestion['suggestion_type'] as String);
        
        // Safely parse nutritional benefits with proper type conversion
        final nutritionalBenefits = <String, double>{};
        if (suggestion['nutritional_benefits'] != null) {
          final benefits = suggestion['nutritional_benefits'] as Map;
          benefits.forEach((key, value) {
            if (value is num) {
              nutritionalBenefits[key.toString()] = value.toDouble();
            }
          });
        }
        
        // Safely parse relevance score
        final relevanceScore = suggestion['relevance_score'] != null 
            ? (suggestion['relevance_score'] as num).toDouble()
            : 0.8; // Default score
        
        // Find the recipe by title
        final recipe = allRecipes.firstWhere(
          (r) => r.title.toLowerCase().contains(recipeTitle.toLowerCase()) ||
                 recipeTitle.toLowerCase().contains(r.title.toLowerCase()),
          orElse: () => allRecipes.first, // Fallback to first recipe
        );
        
        result.add(SmartMealSuggestion(
          recipe: recipe,
          type: suggestionType,
          reasoning: reasoning,
          relevanceScore: relevanceScore,
          nutritionalBenefits: nutritionalBenefits,
          tags: ['ai-powered', suggestionType.name],
        ));
      }
      
      return result;
    } catch (e) {
      print('Error parsing AI response: $e');
      print('Response was: $response');
      return [];
    }
  }

  /// Parse suggestion type from string
  static SuggestionType _parseSuggestionType(String type) {
    switch (type.toLowerCase()) {
      case 'fillgap':
        return SuggestionType.fillGap;
      case 'perfecttiming':
        return SuggestionType.perfectTiming;
      case 'userfavorites':
        return SuggestionType.userFavorites;
      case 'trysomethingnew':
        return SuggestionType.trySomethingNew;
      case 'healthboost':
        return SuggestionType.healthBoost;
      case 'budgetfriendly':
        return SuggestionType.budgetFriendly;
      case 'quickprep':
        return SuggestionType.quickPrep;
      default:
        return SuggestionType.trySomethingNew;
    }
  }

  /// Get meal time description based on hour
  static String _getMealTimeDescription(int hour) {
    if (hour < 7) {
      return 'Early morning';
    } else if (hour < 11) {
      return 'Morning';
    } else if (hour < 15) {
      return 'Afternoon';
    } else if (hour < 20) {
      return 'Evening';
    } else {
      return 'Late evening';
    }
  }

  /// Get previous meal context
  static String _getPreviousMealContext(DateTime targetTime) {
    final hour = targetTime.hour;
    if (hour < 11) {
      return 'No previous meal today';
    } else if (hour < 15) {
      return 'Breakfast was earlier';
    } else if (hour < 20) {
      return 'Breakfast and lunch were earlier';
    } else {
      return 'Breakfast, lunch, and dinner were earlier';
    }
  }

  /// Get next meal context
  static String _getNextMealContext(DateTime targetTime) {
    final hour = targetTime.hour;
    if (hour < 11) {
      return 'Lunch and dinner later today';
    } else if (hour < 15) {
      return 'Dinner later today';
    } else if (hour < 20) {
      return 'Late dinner later';
    } else {
      return 'No more meals planned today';
    }
  }

  /// Test the Gemini API connection
  static Future<bool> testConnection() async {
    if (_apiKey.isEmpty) {
      // No API key available; treat as unavailable
      return false;
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Say "Hello" if you can hear me.',
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 10,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'] != null && data['candidates'].isNotEmpty;
      } else if (response.statusCode == 503) {
        print('Gemini API is overloaded - service temporarily unavailable');
        return false;
      } else if (response.statusCode == 429) {
        print('Gemini API rate limit exceeded');
        return false;
      } else {
        print('Gemini API test failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Gemini API test failed: $e');
      return false;
    }
  }
}
