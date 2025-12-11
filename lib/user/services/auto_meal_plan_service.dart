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
      
      // Enforce diabetes-safe pool if applicable
      final healthConditions = userPrefs['health_conditions'] as List<dynamic>? ?? [];
      final hasDiabetes = healthConditions.map((e) => e.toString().toLowerCase()).contains('diabetes');
      if (hasDiabetes) {
        allRecipes = await _filterDiabetesSafeRecipes(allRecipes);
        // For diabetes, use the fixed template meals
        return await _generateFixedDiabetesPlan(
          allRecipes: allRecipes,
          targetDate: targetDate,
          includeBreakfast: includeBreakfast,
          includeLunch: includeLunch,
          includeDinner: includeDinner,
        );
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
      final healthConditions = userPrefs['health_conditions'] as List<dynamic>? ?? [];
      final hasHealthConditions = healthConditions.isNotEmpty && !healthConditions.contains('none');
      final hasDiabetes = healthConditions.map((e) => e.toString().toLowerCase()).contains('diabetes');
      if (hasDiabetes) {
        var diabeticRecipes = await RecipeService.fetchRecipes(userId: userId);
        diabeticRecipes = await _filterDiabetesSafeRecipes(diabeticRecipes);
        return await _generateFixedDiabetesPlan(
          allRecipes: diabeticRecipes,
          targetDate: targetDate,
          includeBreakfast: includeBreakfast,
          includeLunch: includeLunch,
          includeDinner: includeDinner,
        );
      }
      
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

      // Enforce diabetes-safe pool if applicable
      if (hasDiabetes) {
        allRecipes = await _filterDiabetesSafeRecipes(allRecipes);
      }
      
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

    for (final condition in healthConditions) {
      switch (condition.toLowerCase()) {
        case 'diabetes':
          // Diabetes: Low carbs (<60g), high fiber (>3g), low sugar (<15g)
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

  /// Restrict recipe pool to diabetes-safe whitelist when diabetes condition is present.
  /// Titles are matched case-insensitively.
  static const List<String> _diabetesAllowedTitles = [
    'Boiled egg (1 pc)',
    '1 boiled egg',
    'Sliced papaya (1/4 cup)',
    'Sliced papaya',
    'Ensaladang pipino',
    'Sinangag',
    'Utan Bisaya-style boiled vegetables',
    'Utan Bisaya',
    'Inihaw na bangus',
    'Grilled milkfish',
    'Chicken tinola',
    'Tinolang manok',
    'Tinola',
  ];

  static Future<List<Recipe>> _filterDiabetesSafeRecipes(List<Recipe> recipes) async {
    final normalizedAllowed = _diabetesAllowedTitles.map((t) => t.toLowerCase()).toList();
    final filtered = recipes.where((r) {
      final title = r.title.toLowerCase();
      return normalizedAllowed.any((allowed) => title.contains(allowed));
    }).toList();

    final missingTitles = _diabetesAllowedTitles.where((allowed) {
      final allowedLower = allowed.toLowerCase();
      return filtered.every((r) => !r.title.toLowerCase().contains(allowedLower));
    }).toList();

    if (missingTitles.isNotEmpty) {
      try {
        final response = await _client
            .from('simple_meals')
            .select('id,title,image_url,short_description,calories,macros,cost')
            .inFilter('title', missingTitles);

        for (final meal in response) {
          final recipe = _mapSimpleMealToRecipe(meal);
          if (recipe != null) {
            filtered.add(recipe);
          }
        }
      } catch (e) {
        AppLogger.error('Error fetching diabetes simple meals', e);
      }

      // Fallback to hardcoded values if still missing
      final remainingMissing = missingTitles.where((allowed) {
        final allowedLower = allowed.toLowerCase();
        return filtered.every((r) => !r.title.toLowerCase().contains(allowedLower));
      }).toList();
      if (remainingMissing.isNotEmpty) {
        for (final fallback in _diabetesFallbackSimpleMeals) {
          if (remainingMissing.any((title) => title.toLowerCase() == fallback['title'].toString().toLowerCase())) {
            final recipe = _mapSimpleMealToRecipe(fallback);
            if (recipe != null) {
              filtered.add(recipe);
            }
          }
        }
      }
    }

    return filtered;
  }

  /// Fixed template for diabetic meal plans (breakfast: 3, lunch: 2, dinner: 2).
  /// Each entry may specify alternate titles to improve matching.
  static final List<Map<String, dynamic>> _diabetesTemplateMeals = [
    {
      'title': '1 boiled egg',
      'alternateTitles': ['Boiled egg (1 pc)'],
      'meal_type': 'breakfast',
      'time': '08:00',
    },
    {
      'title': 'Sinangag',
      'alternateTitles': [],
      'meal_type': 'breakfast',
      'time': '08:00',
    },
    {
      'title': 'Sliced papaya',
      'alternateTitles': ['Sliced papaya (1/4 cup)'],
      'meal_type': 'breakfast',
      'time': '08:00',
    },
    {
      'title': 'Utan Bisaya',
      'alternateTitles': ['Utan Bisaya-style boiled vegetables', 'Law-uy', 'Lawuy'],
      'meal_type': 'lunch',
      'time': '12:30',
    },
    {
      'title': 'Inihaw na Bangus (Grilled Milkfish)',
      'alternateTitles': [],
      'meal_type': 'lunch',
      'time': '12:30',
    },
    {
      'title': 'Chicken tinola',
      'alternateTitles': ['Tinolang manok', 'Tinola'],
      'meal_type': 'dinner',
      'time': '19:00',
    },
    {
      'title': 'Ensaladang pipino',
      'alternateTitles': [],
      'meal_type': 'dinner',
      'time': '19:00',
    },
  ];

  static Future<Recipe?> _findRecipeByTitles(List<Recipe> recipes, List<String> titles) async {
    final lowered = titles.map((t) => t.toLowerCase()).toList();
    for (final recipe in recipes) {
      final titleLower = recipe.title.toLowerCase();
      if (lowered.any((t) => titleLower.contains(t))) {
        return recipe;
      }
    }
    return null;
  }

  static Future<Recipe?> _fetchSimpleMealByTitles(List<String> titles) async {
    try {
      final response = await _client
          .from('simple_meals')
          .select('id,title,image_url,short_description,calories,macros,cost,ingredients,instructions')
          .inFilter('title', titles);
      if (response.isNotEmpty) {
        final meal = response.first;
        return _mapSimpleMealToRecipe(meal);
      }
    } catch (e) {
      AppLogger.error('Error fetching simple meal by titles', e);
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> _generateFixedDiabetesPlan({
    required List<Recipe> allRecipes,
    required DateTime targetDate,
    required bool includeBreakfast,
    required bool includeLunch,
    required bool includeDinner,
  }) async {
    final List<Map<String, dynamic>> mealPlan = [];

    for (final entry in _diabetesTemplateMeals) {
      final mealType = entry['meal_type'] as String;
      if ((mealType == 'breakfast' && !includeBreakfast) ||
          (mealType == 'lunch' && !includeLunch) ||
          (mealType == 'dinner' && !includeDinner)) {
        continue;
      }

      final titles = <String>[
        entry['title'] as String,
        ...(entry['alternateTitles'] as List<dynamic>? ?? const []),
      ];

      Recipe? recipe = await _findRecipeByTitles(allRecipes, titles);
      recipe ??= await _fetchSimpleMealByTitles(titles);

      if (recipe == null) {
        final fallback = _diabetesFallbackSimpleMeals.firstWhere(
          (f) => titles.any((t) => t.toLowerCase() == f['title'].toString().toLowerCase()),
          orElse: () => {},
        );
        if (fallback.isNotEmpty) {
          recipe = _mapSimpleMealToRecipe(fallback);
        }
      }

      if (recipe != null) {
        final timeParts = (entry['time'] as String).split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final mealDate = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
        mealPlan.add({
          'recipe': recipe,
          'meal_type': mealType,
          'meal_time': _formatTime(mealDate),
          'date': mealDate,
        });
      }
    }

    return mealPlan;
  }

  static Recipe? _mapSimpleMealToRecipe(Map<String, dynamic> meal) {
    final title = (meal['title'] ?? '').toString();
    if (title.isEmpty) return null;
    final macros = Map<String, dynamic>.from(meal['macros'] ?? {});
    final caloriesRaw = meal['calories'];
    final calories = caloriesRaw is int
        ? caloriesRaw
        : caloriesRaw is double
            ? caloriesRaw.round()
            : int.tryParse(caloriesRaw?.toString() ?? '') ?? _parseDouble(caloriesRaw).round();
    final costRaw = meal['cost'];
    final cost = costRaw is double ? costRaw : _parseDouble(costRaw);

    return Recipe(
      id: 'simple_${meal['id'] ?? title.toLowerCase().replaceAll(' ', '_')}',
      title: title,
      imageUrl: (meal['image_url'] ?? '').toString(),
      shortDescription: (meal['short_description'] ?? '').toString(),
      ingredients: List<String>.from(meal['ingredients'] ?? const []),
      instructions: List<String>.from(meal['instructions'] ?? const []),
      macros: macros,
      allergyWarning: '',
      calories: calories,
      tags: const ['simple_meal', 'diabetes_safe'],
      cost: cost,
      notes: 'simple_meal',
    );
  }

  static final List<Map<String, dynamic>> _diabetesFallbackSimpleMeals = [
    {
      'id': 'fallback_sinangag',
      'title': 'Sinangag',
      'image_url': '',
      'short_description': 'Garlic fried rice, ½ cup, low oil, low sodium',
      'calories': 180,
      'macros': {
        'protein': 3,
        'fat': 3.5,
        'carbs': 35,
        'sugar': 0.5,
        'fiber': 1,
        'sodium': 120,
        'cholesterol': 0,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_utan_bisaya',
      'title': 'Utan Bisaya-style boiled vegetables',
      'image_url': '',
      'short_description': 'Kalabasa, okra, upo; light broth',
      'calories': 90,
      'macros': {
        'protein': 3,
        'fat': 2,
        'carbs': 15,
        'sugar': 6,
        'fiber': 4,
        'sodium': 220,
        'cholesterol': 0,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_utan_bisaya_simple',
      'title': 'Utan Bisaya',
      'image_url': '',
      'short_description': 'Kalabasa, okra, upo; light broth',
      'calories': 90,
      'macros': {
        'protein': 3,
        'fat': 2,
        'carbs': 15,
        'sugar': 6,
        'fiber': 4,
        'sodium': 220,
        'cholesterol': 0,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_grilled_tilapia',
      'title': 'Grilled tilapia',
      'image_url': '',
      'short_description': 'Approx 2 oz portion',
      'calories': 110,
      'macros': {
        'protein': 22,
        'fat': 2,
        'carbs': 0,
        'sugar': 0,
        'fiber': 0,
        'sodium': 90,
        'cholesterol': 55,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_inihaw_bangus',
      'title': 'Inihaw na bangus (grilled milkfish)',
      'image_url': '',
      'short_description': 'Lean grilled milkfish fillet',
      'calories': 140,
      'macros': {
        'protein': 23,
        'fat': 4,
        'carbs': 0,
        'sugar': 0,
        'fiber': 0,
        'sodium': 95,
        'cholesterol': 70,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_chicken_tinola',
      'title': 'Chicken tinola',
      'image_url': '',
      'short_description': 'Skin removed, low salt',
      'calories': 220,
      'macros': {
        'protein': 28,
        'fat': 8,
        'carbs': 8,
        'sugar': 2,
        'fiber': 1,
        'sodium': 320,
        'cholesterol': 90,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_boiled_egg',
      'title': 'Boiled egg (1 pc)',
      'image_url': 'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/simple_meals/large_boiled_egg.jpg',
      'short_description': 'Simple protein-rich boiled egg',
      'calories': 78,
      'macros': {
        'protein': 6.3,
        'fat': 5.3,
        'carbs': 0.6,
        'sugar': 0,
        'fiber': 0,
        'sodium': 62,
        'cholesterol': 200,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_boiled_egg_one',
      'title': '1 boiled egg',
      'image_url': 'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/simple_meals/large_boiled_egg.jpg',
      'short_description': 'Simple protein-rich boiled egg',
      'calories': 78,
      'macros': {
        'protein': 6.3,
        'fat': 5.3,
        'carbs': 0.6,
        'sugar': 0,
        'fiber': 0,
        'sodium': 62,
        'cholesterol': 200,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_papaya',
      'title': 'Sliced papaya (1/4 cup)',
      'image_url': 'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/simple_meals/sliced_papaya.jpg',
      'short_description': 'Light, fruit-based option',
      'calories': 62,
      'macros': {
        'protein': 0.7,
        'fat': 0.4,
        'carbs': 16,
        'sugar': 11,
        'fiber': 2.5,
        'sodium': 0,
        'cholesterol': 0,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_papaya_simple',
      'title': 'Sliced papaya',
      'image_url': 'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/simple_meals/sliced_papaya.jpg',
      'short_description': 'Light, fruit-based option',
      'calories': 62,
      'macros': {
        'protein': 0.7,
        'fat': 0.4,
        'carbs': 16,
        'sugar': 11,
        'fiber': 2.5,
        'sodium': 0,
        'cholesterol': 0,
      },
      'cost': 0,
    },
    {
      'id': 'fallback_ensaladang_pipino',
      'title': 'Ensaladang pipino',
      'image_url': 'https://ehpwztftkbzjwezmdwzt.supabase.co/storage/v1/object/public/simple_meals/ensaladang_pipino.jpg',
      'short_description': 'Simple cucumber salad',
      'calories': 35,
      'macros': {
        'protein': 1.3,
        'fat': 0.2,
        'carbs': 8.3,
        'sugar': 5.4,
        'fiber': 1.5,
        'sodium': 120,
        'cholesterol': 0,
      },
      'cost': 0,
    },
  ];

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

