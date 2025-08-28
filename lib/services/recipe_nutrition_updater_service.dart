import 'package:supabase_flutter/supabase_flutter.dart';
import 'fnri_nutrition_service.dart';

class RecipeNutritionUpdaterService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Update nutrition for a single recipe
  static Future<bool> updateRecipeNutrition(String recipeId) async {
    try {
      // Get recipe data from Supabase
      final recipeData = await _client
          .from('recipes')
          .select('ingredients, title')
          .eq('id', recipeId)
          .single();

      if (recipeData == null) {
        print('Recipe not found: $recipeId');
        return false;
      }

      final ingredients = recipeData['ingredients'] as List;
      final title = recipeData['title'] as String;

      print('Updating nutrition for: $title');

      // Convert ingredients to nutrition calculator format
      final ingredientList = _parseIngredients(ingredients);
      
      // Calculate nutrition using FNRI data
      final nutrition = await FNRINutritionService.calculateRecipeNutrition(
        ingredients.map((i) => i.toString()).toList(),
        Map.fromEntries(ingredientList.map((i) => MapEntry(i['name'].toString(), i['quantity'])))
      );
      
      // Update recipe in Supabase
      final updateResult = await _client
          .from('recipes')
          .update({
            'macros': nutrition['summary'],
            'calories': nutrition['summary']['calories'],
          })
          .eq('id', recipeId);

      print('✅ Updated nutrition for $title:');
      print(nutrition.toString());
      
      return true;
    } catch (e) {
      print('❌ Error updating recipe nutrition: $e');
      return false;
    }
  }

  /// Update nutrition for all recipes in database
  static Future<Map<String, bool>> updateAllRecipesNutrition() async {
    try {
      print('🔄 Starting nutrition update for all recipes...');
      
      // Get all recipe IDs
      final recipes = await _client
          .from('recipes')
          .select('id, title')
          .order('title');

      final results = <String, bool>{};
      
      for (final recipe in recipes) {
        final id = recipe['id'] as String;
        final title = recipe['title'] as String;
        
        print('\n📝 Processing: $title');
        final success = await updateRecipeNutrition(id);
        results[title] = success;
        
        // Small delay to avoid overwhelming the API
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Print summary
      final successful = results.values.where((success) => success).length;
      final total = results.length;
      
      print('\n🎯 Nutrition Update Summary:');
      print('✅ Successful: $successful');
      print('❌ Failed: ${total - successful}');
      print('📊 Total: $total');
      
      return results;
    } catch (e) {
      print('❌ Error updating all recipes: $e');
      return {};
    }
  }

  /// Parse ingredients list and estimate quantities
  static List<Map<String, dynamic>> _parseIngredients(List ingredients) {
    final List<Map<String, dynamic>> parsedIngredients = [];
    
    for (final ingredient in ingredients) {
      final ingredientStr = ingredient.toString().toLowerCase();
      
      // Try to extract quantity from ingredient string first
      double extractedQuantity = _extractQuantityFromString(ingredientStr);
      
      // If no quantity found, estimate based on ingredient type
      double estimatedQuantity = extractedQuantity > 0 ? extractedQuantity : _estimateIngredientQuantity(ingredientStr);
      
      // Clean ingredient name (remove quantity info)
      String cleanIngredientName = _cleanIngredientName(ingredientStr);
      
      parsedIngredients.add({
        'name': cleanIngredientName,
        'quantity': estimatedQuantity,
      });
      
      print('  📏 $ingredient: ${extractedQuantity > 0 ? 'extracted' : 'estimated'} ${estimatedQuantity}g');
    }
    
    return parsedIngredients;
  }

  /// Extract quantity from ingredient string (e.g., "12 oz mung bean sprouts" -> 340.2g)
  static double _extractQuantityFromString(String ingredientStr) {
    // Handle ounces (oz)
    final ozMatch = RegExp(r'(\d+(?:\.\d+)?)\s*oz').firstMatch(ingredientStr);
    if (ozMatch != null) {
      final oz = double.tryParse(ozMatch.group(1) ?? '1');
      return (oz ?? 1) * 28.35; // Convert to grams
    }
    
    // Handle cups
    final cupMatch = RegExp(r'(\d+(?:\.\d+)?)\s*cup').firstMatch(ingredientStr);
    if (cupMatch != null) {
      final cups = double.tryParse(cupMatch.group(1) ?? '1');
      return (cups ?? 1) * 240; // Convert to grams (1 cup ≈ 240g for most ingredients)
    }
    
    // Handle tablespoons
    final tbspMatch = RegExp(r'(\d+(?:\.\d+)?)\s*tbsp').firstMatch(ingredientStr);
    if (tbspMatch != null) {
      final tbsp = double.tryParse(tbspMatch.group(1) ?? '1');
      return (tbsp ?? 1) * 15; // Convert to grams (1 tbsp ≈ 15g)
    }
    
    // Handle teaspoons
    final tspMatch = RegExp(r'(\d+(?:\.\d+)?)\s*tsp').firstMatch(ingredientStr);
    if (tspMatch != null) {
      final tsp = double.tryParse(tspMatch.group(1) ?? '1');
      return (tsp ?? 1) * 5; // Convert to grams (1 tsp ≈ 5g)
    }
    
    return 0; // No quantity found
  }

  /// Clean ingredient name by removing quantity information
  static String _cleanIngredientName(String ingredientStr) {
    // Remove common quantity patterns
    return ingredientStr
        .replaceAll(RegExp(r'\d+(?:\.\d+)?\s*(oz|ounce|cup|cups|tbsp|tsp|g|gram|grams|kg|kilogram|kilograms)'), '')
        .trim();
  }

  /// Estimate ingredient quantities based on common Filipino recipe amounts
  static double _estimateIngredientQuantity(String ingredient) {
    final ingredientLower = ingredient.toLowerCase();
    
    // Meat and protein - more realistic portions
    if (ingredientLower.contains('pork') || ingredientLower.contains('beef') || ingredientLower.contains('chicken')) {
      if (ingredientLower.contains('ribs') || ingredientLower.contains('chunk') || ingredientLower.contains('cut')) return 120; // 120g per serving
      if (ingredientLower.contains('thigh') || ingredientLower.contains('breast') || ingredientLower.contains('fillet')) return 100; // 100g per serving
      if (ingredientLower.contains('ground') || ingredientLower.contains('minced')) return 80; // 80g per serving
      return 80; // Default meat portion - more realistic
    }
    
    // Fish and seafood
    if (ingredientLower.contains('fish') || ingredientLower.contains('tilapia') || ingredientLower.contains('bangus')) return 100; // 100g per serving
    if (ingredientLower.contains('shrimp') || ingredientLower.contains('hipon')) return 60; // 60g per serving
    if (ingredientLower.contains('crab') || ingredientLower.contains('alimango')) return 80; // 80g per serving
    
    // Vegetables - more realistic portions
    if (ingredientLower.contains('tomato')) return 60; // 1 medium tomato
    if (ingredientLower.contains('onion')) return 50; // 1 medium onion
    if (ingredientLower.contains('carrot')) return 40; // 1 medium carrot
    if (ingredientLower.contains('gabi')) return 30; // 1 piece gabi
    if (ingredientLower.contains('labano') || ingredientLower.contains('radish')) return 40; // 1 medium radish
    if (ingredientLower.contains('sitaw') || ingredientLower.contains('beans')) return 60; // 1/3 bunch
    if (ingredientLower.contains('eggplant')) return 60; // 1 medium eggplant
    if (ingredientLower.contains('okra')) return 40; // 4 pieces
    if (ingredientLower.contains('bok choy') || ingredientLower.contains('pechay')) return 60; // 1/2 bunch
    if (ingredientLower.contains('spinach') || ingredientLower.contains('kangkong')) return 50; // 1/2 bunch
    if (ingredientLower.contains('garlic')) return 15; // 3-4 cloves
    if (ingredientLower.contains('ginger')) return 10; // 1 thumb-sized piece
    
    // Mung bean sprouts and togue - common in Filipino dishes
    if (ingredientLower.contains('mung bean') || ingredientLower.contains('togue') || ingredientLower.contains('bean sprout')) {
      // Check if quantity is specified (e.g., "12 oz mung bean sprouts")
      if (ingredientLower.contains('oz') || ingredientLower.contains('ounce')) {
        // Extract number and convert oz to grams (1 oz = 28.35g)
        final ozMatch = RegExp(r'(\d+(?:\.\d+)?)\s*oz').firstMatch(ingredientLower);
        if (ozMatch != null) {
          final oz = double.tryParse(ozMatch.group(1) ?? '1');
          return (oz ?? 1) * 28.35; // Convert to grams
        }
      }
      // Default: 1 cup of mung bean sprouts is about 100g
      return 100;
    }
    
    // Grains and starches
    if (ingredientLower.contains('rice')) return 80; // 1/2 cup cooked
    if (ingredientLower.contains('noodles') || ingredientLower.contains('pancit')) return 70; // 1 cup cooked
    if (ingredientLower.contains('potato') || ingredientLower.contains('patatas')) return 60; // 1 medium potato
    if (ingredientLower.contains('sweet potato') || ingredientLower.contains('kamote')) return 60; // 1 medium sweet potato
    
    // Condiments and seasonings - smaller amounts
    if (ingredientLower.contains('fish sauce')) return 15; // 1 tablespoon
    if (ingredientLower.contains('soy sauce')) return 10; // 2/3 tablespoon
    if (ingredientLower.contains('vinegar')) return 10; // 2/3 tablespoon
    if (ingredientLower.contains('tamarind')) return 15; // 1 tablespoon paste
    if (ingredientLower.contains('salt') || ingredientLower.contains('pepper')) return 2; // Seasoning amounts
    if (ingredientLower.contains('bay leaves')) return 1; // 1-2 leaves
    
    // Common Filipino ingredients
    if (ingredientLower.contains('patis') || ingredientLower.contains('fish sauce')) return 15; // 1 tablespoon
    if (ingredientLower.contains('toyo') || ingredientLower.contains('soy sauce')) return 10; // 2/3 tablespoon
    if (ingredientLower.contains('suka') || ingredientLower.contains('vinegar')) return 10; // 2/3 tablespoon
    if (ingredientLower.contains('sampalok') || ingredientLower.contains('tamarind')) return 15; // 1 tablespoon paste
    if (ingredientLower.contains('asin') || ingredientLower.contains('salt')) return 2; // Seasoning amounts
    if (ingredientLower.contains('paminta') || ingredientLower.contains('pepper')) return 2; // Seasoning amounts
    
    // Other ingredients
    if (ingredientLower.contains('egg')) return 50; // 1 large egg
    if (ingredientLower.contains('wonton') || ingredientLower.contains('wrapper')) return 15; // 1 wrapper
    if (ingredientLower.contains('oil') || ingredientLower.contains('mantika')) return 10; // 2/3 tablespoon
    if (ingredientLower.contains('butter')) return 10; // 2/3 tablespoon
    if (ingredientLower.contains('cheese')) return 20; // 1/4 cup grated
    if (ingredientLower.contains('tofu')) return 60; // 1/2 block
    
    // Default quantity - more conservative
    return 30;
  }

  /// Get recipes with missing nutrition data
  static Future<List<Map<String, dynamic>>> getRecipesWithMissingNutrition() async {
    try {
      final recipes = await _client
          .from('recipes')
          .select('id, title, macros, calories')
          .order('title');

      final missingNutrition = <Map<String, dynamic>>[];
      
      for (final recipe in recipes) {
        final macros = recipe['macros'] as Map<String, dynamic>?;
        final calories = recipe['calories'];
        
        bool hasMissingData = false;
        List<String> missingNutrients = [];
        
        if (macros == null) {
          hasMissingData = true;
          missingNutrients = ['all nutrients'];
        } else {
          final requiredNutrients = ['protein', 'fat', 'carbs', 'fiber', 'sugar', 'sodium', 'cholesterol'];
          
          for (final nutrient in requiredNutrients) {
            if (macros[nutrient] == null || macros[nutrient] == 0) {
              hasMissingData = true;
              missingNutrients.add(nutrient);
            }
          }
        }
        
        if (hasMissingData) {
          missingNutrition.add({
            'id': recipe['id'],
            'title': recipe['title'],
            'missing_nutrients': missingNutrients,
            'current_macros': macros,
            'current_calories': calories,
          });
        }
      }
      
      return missingNutrition;
    } catch (e) {
      print('Error getting recipes with missing nutrition: $e');
      return [];
    }
  }

  /// Update specific nutrient for a recipe
  static Future<bool> updateRecipeNutrient(
    String recipeId,
    String nutrient,
    double value
  ) async {
    try {
      // Get current macros first
      final currentRecipe = await _client
          .from('recipes')
          .select('macros')
          .eq('id', recipeId)
          .single();
      
      Map<String, dynamic> currentMacros = {};
      if (currentRecipe['macros'] != null) {
        currentMacros = Map<String, dynamic>.from(currentRecipe['macros']);
      }
      
      // Update the specific nutrient
      currentMacros[nutrient] = value;
      
      final result = await _client
          .from('recipes')
          .update({
            'macros': currentMacros,
          })
          .eq('id', recipeId);

      print('✅ Updated $nutrient to $value for recipe $recipeId');
      return true;
    } catch (e) {
      print('❌ Error updating nutrient: $e');
      return false;
    }
  }
}
