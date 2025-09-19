import 'package:supabase_flutter/supabase_flutter.dart';
import 'fnri_nutrition_service.dart';
import 'measurement_converter.dart';

class IngredientTrackingService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Extract quantity from ingredient string (public method)
  static Map<String, dynamic> extractQuantity(String ingredientStr) {
    return MeasurementConverter.parseMeasurement(ingredientStr);
  }

  /// Enhanced ingredient parsing with validation and correction
  static Future<Map<String, dynamic>> parseAndValidateIngredient(String ingredientStr) async {
    final original = ingredientStr;
    final ingredientLower = ingredientStr.toLowerCase();
    
    // Step 1: Extract quantity and unit
    final quantityInfo = _extractQuantityAndUnit(ingredientLower);
    
    // Step 2: Clean ingredient name
    final cleanName = _cleanIngredientName(ingredientLower);
    
    // Step 3: Detect preparation method
    final preparation = _detectPreparationMethod(ingredientLower);
    
    // Step 4: Validate against FNRI database
    final validation = await _validateIngredientInFNRI(cleanName);
    
    // Step 5: Suggest corrections if needed
    final suggestions = await _suggestIngredientCorrections(cleanName, validation);
    
    return {
      'original': original,
      'clean_name': cleanName,
      'quantity': quantityInfo['quantity'],
      'unit': quantityInfo['unit'],
      'preparation': preparation,
      'is_valid': validation['found'],
      'fnri_match': validation['match'],
      'suggestions': suggestions,
      'confidence': validation['confidence'],
    };
  }

  /// Extract quantity and unit from ingredient string using clean converter
  static Map<String, dynamic> _extractQuantityAndUnit(String ingredientStr) {
    return MeasurementConverter.parseMeasurement(ingredientStr);
  }

  /// Clean ingredient name with improved accuracy
  static String _cleanIngredientName(String ingredientStr) {
    String cleaned = ingredientStr.toLowerCase();
    
    // Remove measurements with better regex
    cleaned = cleaned.replaceAll(RegExp(r'\d+(?:\.\d+)?\s*(oz|ounce|cup|cups|tbsp|tsp|g|gram|grams|kg|kilogram|kilograms|lbs?|pound|pounds)'), '');
    
    // Remove pieces, bunches, cloves
    cleaned = cleaned.replaceAll(RegExp(r'\d+(?:\.\d+)?\s*(piece|pieces|bunch|bunches|clove|cloves)'), '');
    
    // Remove fractions
    cleaned = cleaned.replaceAll(RegExp(r'\d+/\d+'), '');
    
    // Remove "to taste", "and", "with"
    cleaned = cleaned.replaceAll(RegExp(r'\s*(to taste|and|with)\s*'), ' ');
    
    // Remove any remaining numbers at the start
    cleaned = cleaned.replaceAll(RegExp(r'^\d+(?:\.\d+)?\s*'), '');
    
    // Clean up extra spaces and punctuation
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[.,\s]+|[.,\s]+$'), '');
    
    return cleaned;
  }

  /// Detect preparation method from ingredient description
  static String _detectPreparationMethod(String ingredientStr) {
    if (ingredientStr.contains('minced') || ingredientStr.contains('giniling') || 
        ingredientStr.contains('ground') || ingredientStr.contains('chopped') || 
        ingredientStr.contains('diced') || ingredientStr.contains('sliced')) {
      return 'minced';
    }
    if (ingredientStr.contains('crushed')) {
      return 'crushed';
    }
    if (ingredientStr.contains('peeled') || ingredientStr.contains('balat')) {
      return 'peeled';
    }
    if (ingredientStr.contains('cleaned') || ingredientStr.contains('linis')) {
      return 'cleaned';
    }
    if (ingredientStr.contains('cooked') || ingredientStr.contains('luto')) {
      return 'cooked';
    }
    if (ingredientStr.contains('raw') || ingredientStr.contains('hilaw')) {
      return 'raw';
    }
    return 'raw'; // Default
  }

  /// Validate ingredient against FNRI database
  static Future<Map<String, dynamic>> _validateIngredientInFNRI(String ingredientName) async {
    final results = await FNRINutritionService.searchIngredients(ingredientName);
    
    if (results.isEmpty) {
      return {
        'found': false,
        'match': null,
        'confidence': 0.0,
        'alternatives': [],
      };
    }
    
    final bestMatch = results.first;
    final confidence = _calculateConfidence(ingredientName, bestMatch.foodName);
    
    return {
      'found': true,
      'match': bestMatch,
      'confidence': confidence,
      'alternatives': results.take(5).map((r) => r.foodName).toList(),
    };
  }

  /// Calculate confidence score for ingredient matching
  static double _calculateConfidence(String searchTerm, String fnriName) {
    final searchWords = searchTerm.toLowerCase().split(' ');
    final fnriWords = fnriName.toLowerCase().split(' ');
    
    int matches = 0;
    for (final searchWord in searchWords) {
      if (searchWord.length < 3) continue; // Skip short words
      for (final fnriWord in fnriWords) {
        if (fnriWord.contains(searchWord) || searchWord.contains(fnriWord)) {
          matches++;
          break;
        }
      }
    }
    
    return matches / searchWords.length;
  }

  /// Suggest ingredient corrections
  static Future<List<String>> _suggestIngredientCorrections(String ingredientName, Map<String, dynamic> validation) async {
    final suggestions = <String>[];
    
    if (validation['found']) {
      return suggestions; // No suggestions needed if found
    }
    
    // Common Filipino ingredient corrections
    final corrections = {
      'bawang': 'garlic',
      'sibuyas': 'onion',
      'kamatis': 'tomato',
      'karot': 'carrot',
      'patatas': 'potato',
      'talong': 'eggplant',
      'okra': 'okra',
      'sitaw': 'string beans',
      'kangkong': 'water spinach',
      'repolyo': 'cabbage',
      'litsugas': 'lettuce',
      'luya': 'ginger',
      'tanglad': 'lemongrass',
      'sampalok': 'tamarind',
      'dayap': 'lime',
      'mangga': 'mango',
      'saging': 'banana',
      'papaya': 'papaya',
      'pinya': 'pineapple',
      'niyog': 'coconut',
      'gata': 'coconut milk',
      'toyo': 'soy sauce',
      'patis': 'fish sauce',
      'suka': 'vinegar',
      'asin': 'salt',
      'paminta': 'black pepper',
      'mantika': 'cooking oil',
      'baboy': 'pork',
      'manok': 'chicken',
      'baka': 'beef',
      'isda': 'fish',
      'hipon': 'shrimp',
      'alimango': 'crab',
      'itlog': 'egg',
      'gatas': 'milk',
      'keso': 'cheese',
      'tinapay': 'bread',
      'kanin': 'rice',
      'bigas': 'rice',
      'harina': 'flour',
      'tokwa': 'tofu',
    };
    
    // Check for direct corrections
    if (corrections.containsKey(ingredientName)) {
      suggestions.add(corrections[ingredientName]!);
    }
    
    // Check for partial matches
    for (final entry in corrections.entries) {
      if (ingredientName.contains(entry.key) || entry.key.contains(ingredientName)) {
        suggestions.add(entry.value);
      }
    }
    
    // Add common variations
    if (ingredientName.contains('bell pepper')) suggestions.add('green pepper');
    if (ingredientName.contains('green pepper')) suggestions.add('bell pepper');
    if (ingredientName.contains('string bean')) suggestions.add('yard long bean');
    if (ingredientName.contains('yard long bean')) suggestions.add('string bean');
    if (ingredientName.contains('water spinach')) suggestions.add('kangkong');
    if (ingredientName.contains('kangkong')) suggestions.add('water spinach');
    
    return suggestions.toSet().toList(); // Remove duplicates
  }


  /// Analyze recipe ingredients for accuracy
  static Future<Map<String, dynamic>> analyzeRecipeIngredients(List<String> ingredients) async {
    final analysis = <String, dynamic>{};
    final issues = <String>[];
    final suggestions = <String, String>{};
    
    for (final ingredient in ingredients) {
      final result = await parseAndValidateIngredient(ingredient);
      
      analysis[ingredient] = result;
      
      if (!result['is_valid']) {
        issues.add('❌ "${ingredient}" not found in FNRI database');
        if (result['suggestions'].isNotEmpty) {
          suggestions[ingredient] = result['suggestions'].first;
        }
      } else if (result['confidence'] < 0.7) {
        issues.add('⚠️ Low confidence match for "${ingredient}" (${(result['confidence'] * 100).toStringAsFixed(1)}%)');
      }
    }
    
    return {
      'analysis': analysis,
      'issues': issues,
      'suggestions': suggestions,
      'total_ingredients': ingredients.length,
      'valid_ingredients': analysis.values.where((r) => r['is_valid']).length,
      'accuracy_percentage': (analysis.values.where((r) => r['is_valid']).length / ingredients.length) * 100,
    };
  }

  /// Get ingredient tracking report
  static Future<Map<String, dynamic>> generateIngredientReport(String recipeId) async {
    try {
      final recipeData = await _client
          .from('recipes')
          .select('ingredients, title')
          .eq('id', recipeId)
          .single();


      final ingredients = (recipeData['ingredients'] as List).cast<String>();
      final title = recipeData['title'] as String;

      print('🔍 Analyzing ingredients for: $title');
      
      final analysis = await analyzeRecipeIngredients(ingredients);
      
      print('\n📊 Ingredient Analysis Report for "$title":');
      print('  Total ingredients: ${analysis['total_ingredients']}');
      print('  Valid ingredients: ${analysis['valid_ingredients']}');
      print('  Accuracy: ${analysis['accuracy_percentage'].toStringAsFixed(1)}%');
      
      if (analysis['issues'].isNotEmpty) {
        print('\n⚠️ Issues found:');
        for (final issue in analysis['issues']) {
          print('  $issue');
        }
      }
      
      if (analysis['suggestions'].isNotEmpty) {
        print('\n💡 Suggestions:');
        for (final entry in analysis['suggestions'].entries) {
          print('  "${entry.key}" → "${entry.value}"');
        }
      }
      
      return analysis;
    } catch (e) {
      print('❌ Error generating ingredient report: $e');
      return {'error': e.toString()};
    }
  }
}
