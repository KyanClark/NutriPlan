import 'package:supabase_flutter/supabase_flutter.dart';
import 'fnri_nutrition_service.dart';

class IngredientTrackingService {
  static final SupabaseClient _client = Supabase.instance.client;

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

  /// Extract quantity and unit from ingredient string
  static Map<String, dynamic> _extractQuantityAndUnit(String ingredientStr) {
    double quantity = 0;
    String unit = 'g';
    
    // Handle fractions first
    final fractionMatch = RegExp(r'(\d+)/(\d+)').firstMatch(ingredientStr);
    if (fractionMatch != null) {
      final numerator = double.tryParse(fractionMatch.group(1) ?? '1');
      final denominator = double.tryParse(fractionMatch.group(2) ?? '1');
      quantity = (numerator ?? 1) / (denominator ?? 1);
      
      // Determine unit for fraction
      if (ingredientStr.contains('cup')) {
        unit = 'cup';
        quantity *= 240; // Convert to grams
      } else if (ingredientStr.contains('tbsp')) {
        unit = 'tbsp';
        quantity *= 15; // Convert to grams
      } else if (ingredientStr.contains('tsp')) {
        unit = 'tsp';
        quantity *= 5; // Convert to grams
      } else if (ingredientStr.contains('piece')) {
        unit = 'piece';
        quantity *= 30; // Convert to grams
      }
    }
    
    // Handle specific units
    final lbsMatch = RegExp(r'(\d+(?:\.\d+)?)\s*lbs?').firstMatch(ingredientStr);
    if (lbsMatch != null) {
      quantity = double.tryParse(lbsMatch.group(1) ?? '1') ?? 1;
      unit = 'lbs';
      quantity *= 453.59; // Convert to grams
    }
    
    final ozMatch = RegExp(r'(\d+(?:\.\d+)?)\s*oz').firstMatch(ingredientStr);
    if (ozMatch != null) {
      quantity = double.tryParse(ozMatch.group(1) ?? '1') ?? 1;
      unit = 'oz';
      quantity *= 28.35; // Convert to grams
    }
    
    final cupMatch = RegExp(r'(\d+(?:\.\d+)?)\s*cup').firstMatch(ingredientStr);
    if (cupMatch != null) {
      quantity = double.tryParse(cupMatch.group(1) ?? '1') ?? 1;
      unit = 'cup';
      quantity *= 240; // Convert to grams
    }
    
    final tbspMatch = RegExp(r'(\d+(?:\.\d+)?)\s*tbsp').firstMatch(ingredientStr);
    if (tbspMatch != null) {
      quantity = double.tryParse(tbspMatch.group(1) ?? '1') ?? 1;
      unit = 'tbsp';
      quantity *= 15; // Convert to grams
    }
    
    final tspMatch = RegExp(r'(\d+(?:\.\d+)?)\s*tsp').firstMatch(ingredientStr);
    if (tspMatch != null) {
      quantity = double.tryParse(tspMatch.group(1) ?? '1') ?? 1;
      unit = 'tsp';
      quantity *= 5; // Convert to grams
    }
    
    final pieceMatch = RegExp(r'(\d+(?:\.\d+)?)\s*piece').firstMatch(ingredientStr);
    if (pieceMatch != null) {
      quantity = double.tryParse(pieceMatch.group(1) ?? '1') ?? 1;
      unit = 'piece';
      quantity = _estimatePieceWeight(ingredientStr, quantity);
    }
    
    final bunchMatch = RegExp(r'(\d+(?:\.\d+)?)\s*bunch').firstMatch(ingredientStr);
    if (bunchMatch != null) {
      quantity = double.tryParse(bunchMatch.group(1) ?? '1') ?? 1;
      unit = 'bunch';
      quantity = _estimateBunchWeight(ingredientStr, quantity);
    }
    
    final cloveMatch = RegExp(r'(\d+(?:\.\d+)?)\s*clove').firstMatch(ingredientStr);
    if (cloveMatch != null) {
      quantity = double.tryParse(cloveMatch.group(1) ?? '1') ?? 1;
      unit = 'clove';
      quantity *= 3; // Convert to grams
    }
    
    return {
      'quantity': quantity,
      'unit': unit,
    };
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
      'kangkong': 'spinach',
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

  /// Estimate weight per piece based on ingredient type
  static double _estimatePieceWeight(String ingredientStr, double pieces) {
    final ingredientLower = ingredientStr.toLowerCase();
    
    // Vegetables
    if (ingredientLower.contains('tomato')) return pieces * 60;
    if (ingredientLower.contains('onion')) return pieces * 50;
    if (ingredientLower.contains('eggplant')) return pieces * 60;
    if (ingredientLower.contains('okra')) return pieces * 10;
    if (ingredientLower.contains('potato')) return pieces * 60;
    if (ingredientLower.contains('radish') || ingredientLower.contains('daikon')) return pieces * 40;
    if (ingredientLower.contains('carrot')) return pieces * 40;
    if (ingredientLower.contains('cucumber')) return pieces * 50;
    if (ingredientLower.contains('bell pepper') || ingredientLower.contains('capsicum')) return pieces * 50;
    
    // Fruits
    if (ingredientLower.contains('apple')) return pieces * 80;
    if (ingredientLower.contains('banana')) return pieces * 40;
    if (ingredientLower.contains('orange')) return pieces * 60;
    if (ingredientLower.contains('mango')) return pieces * 70;
    
    // Meat/Fish
    if (ingredientLower.contains('chicken')) return pieces * 100;
    if (ingredientLower.contains('fish')) return pieces * 80;
    if (ingredientLower.contains('shrimp')) return pieces * 20;
    
    return pieces * 30; // Default
  }

  /// Estimate weight per bunch based on ingredient type
  static double _estimateBunchWeight(String ingredientStr, double bunches) {
    final ingredientLower = ingredientStr.toLowerCase();
    
    if (ingredientLower.contains('spinach') || ingredientLower.contains('kangkong')) return bunches * 100;
    if (ingredientLower.contains('string beans') || ingredientLower.contains('sitaw')) return bunches * 180;
    if (ingredientLower.contains('water spinach')) return bunches * 120;
    if (ingredientLower.contains('bok choy') || ingredientLower.contains('pechay')) return bunches * 150;
    if (ingredientLower.contains('lettuce')) return bunches * 200;
    if (ingredientLower.contains('celery')) return bunches * 250;
    
    return bunches * 80; // Default
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

      if (recipeData == null) {
        return {'error': 'Recipe not found'};
      }

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
