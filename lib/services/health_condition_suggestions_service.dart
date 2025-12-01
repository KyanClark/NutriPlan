import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipes.dart';
import '../models/smart_suggestion_models.dart';
import 'recipe_service.dart';

/// Service for generating health condition-specific recipe suggestions
class HealthConditionSuggestionsService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get recipes specifically tailored to user's health conditions
  static Future<List<SmartMealSuggestion>> getHealthConditionSuggestions({
    required String userId,
    required List<String> healthConditions,
    int limit = 6,
  }) async {
    if (healthConditions.isEmpty || healthConditions.contains('none')) {
      return [];
    }

    try {
      // Fetch all recipes with allergy filtering
      var allRecipes = await RecipeService.fetchRecipes(userId: userId);
      
      // Filter out disallowed items
      allRecipes = allRecipes.where((r) => !RecipeService.isRecipeDisallowed(r)).toList();
      
      // Filter recipes based on health conditions
      final healthConditionRecipes = allRecipes.where((recipe) {
        return _isRecipeSuitableForHealthConditions(recipe, healthConditions);
      }).toList();

      // Score and sort recipes by how well they match health conditions
      final scoredRecipes = healthConditionRecipes.map((recipe) {
        final score = _calculateHealthConditionScore(recipe, healthConditions);
        return MapEntry(recipe, score);
      }).toList();

      // Sort by score (highest first) and take top recipes
      scoredRecipes.sort((a, b) => b.value.compareTo(a.value));
      final topRecipes = scoredRecipes.take(limit).map((e) => e.key).toList();

      // Convert to SmartMealSuggestion
      return topRecipes.map((recipe) {
        return SmartMealSuggestion(
          recipe: recipe,
          type: SuggestionType.healthBoost,
          reasoning: _generateHealthConditionReasoning(recipe, healthConditions),
          relevanceScore: _calculateHealthConditionScore(recipe, healthConditions),
          nutritionalBenefits: _extractNutritionalBenefits(recipe, healthConditions),
          tags: ['health_condition', 'recipe', ...healthConditions],
        );
      }).toList();
    } catch (e) {
      print('Error fetching health condition suggestions: $e');
      return [];
    }
  }

  /// Check if recipe is suitable for user's health conditions
  static bool _isRecipeSuitableForHealthConditions(
    Recipe recipe,
    List<String> healthConditions,
  ) {
    final protein = (recipe.macros['protein'] ?? 0).toDouble();
    final carbs = (recipe.macros['carbs'] ?? 0).toDouble();
    final fiber = (recipe.macros['fiber'] ?? 0).toDouble();
    final sugar = (recipe.macros['sugar'] ?? 0).toDouble();
    final sodium = (recipe.macros['sodium'] ?? 0).toDouble();
    final calories = recipe.calories.toDouble();

    for (final condition in healthConditions) {
      switch (condition.toLowerCase()) {
        case 'diabetes':
          // Low carbs, high fiber, low sugar
          if (carbs > 60 || sugar > 15 || fiber < 3) return false;
          break;
        case 'hypertension':
        case 'high_blood_pressure':
          // Very low sodium
          if (sodium > 500) return false;
          break;
        case 'stroke_recovery':
          // Very low sodium, low saturated fat
          if (sodium > 400) return false;
          break;
        case 'malnutrition':
          // High calories and protein
          if (calories < 300 || protein < 15) return false;
          break;
        case 'heart_disease':
          // Low sodium, low saturated fat, high fiber
          if (sodium > 600 || fiber < 2) return false;
          break;
        default:
          // For unknown conditions, apply general healthy criteria
          if (sugar > 30 || sodium > 1000) return false;
          break;
      }
    }

    return true;
  }

  /// Calculate how well a recipe matches health conditions
  static double _calculateHealthConditionScore(
    Recipe recipe,
    List<String> healthConditions,
  ) {
    double score = 0.0;
    final protein = (recipe.macros['protein'] ?? 0).toDouble();
    final carbs = (recipe.macros['carbs'] ?? 0).toDouble();
    final fiber = (recipe.macros['fiber'] ?? 0).toDouble();
    final sugar = (recipe.macros['sugar'] ?? 0).toDouble();
    final sodium = (recipe.macros['sodium'] ?? 0).toDouble();
    final calories = recipe.calories.toDouble();

    for (final condition in healthConditions) {
      switch (condition.toLowerCase()) {
        case 'diabetes':
          // Prefer low carbs, high fiber, low sugar
          if (carbs <= 40) score += 20;
          if (carbs <= 50) score += 10;
          if (fiber >= 5) score += 15;
          if (fiber >= 3) score += 5;
          if (sugar <= 10) score += 15;
          if (sugar <= 15) score += 5;
          break;
        case 'hypertension':
        case 'high_blood_pressure':
          // Prefer very low sodium
          if (sodium <= 300) score += 25;
          if (sodium <= 400) score += 15;
          if (sodium <= 500) score += 5;
          // Prefer high potassium (fiber-rich foods often have potassium)
          if (fiber >= 5) score += 10;
          break;
        case 'stroke_recovery':
          // Prefer very low sodium, high protein
          if (sodium <= 300) score += 20;
          if (sodium <= 400) score += 10;
          if (protein >= 20) score += 15;
          if (protein >= 15) score += 5;
          break;
        case 'malnutrition':
          // Prefer high calories and protein
          if (calories >= 400) score += 15;
          if (calories >= 300) score += 5;
          if (protein >= 25) score += 20;
          if (protein >= 20) score += 10;
          break;
        case 'kidney_disease':
          // Prefer low sodium, moderate protein
          if (sodium <= 400) score += 15;
          if (sodium <= 500) score += 5;
          if (protein >= 15 && protein <= 25) score += 15;
          break;
        case 'heart_disease':
          // Prefer low sodium, high fiber
          if (sodium <= 400) score += 15;
          if (sodium <= 500) score += 5;
          if (fiber >= 5) score += 15;
          if (fiber >= 3) score += 5;
          break;
        default:
          // General healthy criteria
          if (fiber >= 3) score += 5;
          if (protein >= 15) score += 5;
          break;
      }
    }

    return score;
  }

  /// Generate reasoning text for health condition suggestions
  static String _generateHealthConditionReasoning(
    Recipe recipe,
    List<String> healthConditions,
  ) {
    final conditionNames = healthConditions.map((c) {
      switch (c.toLowerCase()) {
        case 'diabetes':
          return 'diabetes';
        case 'hypertension':
        case 'high_blood_pressure':
          return 'high blood pressure';
        case 'stroke_recovery':
          return 'stroke recovery';
        case 'malnutrition':
          return 'malnutrition';
        case 'kidney_disease':
          return 'kidney health';
        case 'heart_disease':
          return 'heart health';
        default:
          return c.replaceAll('_', ' ');
      }
    }).join(' and ');

    final protein = (recipe.macros['protein'] ?? 0).toDouble();
    final carbs = (recipe.macros['carbs'] ?? 0).toDouble();
    final fiber = (recipe.macros['fiber'] ?? 0).toDouble();
    final sugar = (recipe.macros['sugar'] ?? 0).toDouble();
    final sodium = (recipe.macros['sodium'] ?? 0).toDouble();

    final benefits = <String>[];
    
    if (healthConditions.any((c) => c.toLowerCase() == 'diabetes')) {
      if (carbs <= 50) benefits.add('low in carbs');
      if (fiber >= 3) benefits.add('high in fiber');
      if (sugar <= 15) benefits.add('low in sugar');
    }
    
    if (healthConditions.any((c) => c.toLowerCase().contains('hypertension') || 
                               c.toLowerCase().contains('blood_pressure'))) {
      if (sodium <= 500) benefits.add('low in sodium');
    }
    
    if (healthConditions.any((c) => c.toLowerCase() == 'stroke_recovery')) {
      if (sodium <= 400) benefits.add('low in sodium');
      if (protein >= 15) benefits.add('high in protein');
    }
    
    if (healthConditions.any((c) => c.toLowerCase() == 'malnutrition')) {
      if (recipe.calories >= 300) benefits.add('nutrient-dense');
      if (protein >= 15) benefits.add('high in protein');
    }

    if (benefits.isEmpty) {
      return 'Specially selected for your health needs';
    }

    return 'Perfect for ${conditionNames}: ${benefits.join(', ')}';
  }

  /// Extract nutritional benefits for health conditions
  static Map<String, double> _extractNutritionalBenefits(
    Recipe recipe,
    List<String> healthConditions,
  ) {
    final benefits = <String, double>{};
    final protein = (recipe.macros['protein'] ?? 0).toDouble();
    final fiber = (recipe.macros['fiber'] ?? 0).toDouble();
    final sodium = (recipe.macros['sodium'] ?? 0).toDouble();

    if (healthConditions.any((c) => c.toLowerCase() == 'diabetes' || 
                             c.toLowerCase() == 'malnutrition')) {
      if (protein > 0) benefits['protein'] = protein;
      if (fiber > 0) benefits['fiber'] = fiber;
    }

    if (healthConditions.any((c) => c.toLowerCase().contains('hypertension') || 
                             c.toLowerCase().contains('blood_pressure') ||
                             c.toLowerCase() == 'stroke_recovery')) {
      if (sodium < 500) benefits['low_sodium'] = sodium;
    }

    return benefits;
  }

  /// Fetch user's health conditions from preferences
  static Future<List<String>> getUserHealthConditions(String userId) async {
    try {
      final response = await _client
          .from('user_preferences')
          .select('health_conditions')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null || response['health_conditions'] == null) {
        return [];
      }

      final healthConditions = response['health_conditions'];
      if (healthConditions is List) {
        return healthConditions.map((e) => e.toString()).toList();
      } else if (healthConditions is String) {
        // Parse string representation of list
        if (healthConditions.startsWith('[') && healthConditions.endsWith(']')) {
          final cleaned = healthConditions
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll("'", '')
              .trim();
          if (cleaned.isEmpty) return [];
          return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        return [healthConditions.trim()];
      }

      return [];
    } catch (e) {
      print('Error fetching health conditions: $e');
      return [];
    }
  }
}

