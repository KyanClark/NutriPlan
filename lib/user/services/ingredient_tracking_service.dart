import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'fnri_nutrition_service.dart';
import 'measurement_converter.dart';
import '../utils/app_logger.dart';

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
    
    // Step 2: Clean ingredient name (try AI first, fallback to regex)
    String cleanName = await _cleanIngredientName(ingredientLower);
    
    // Try AI normalization for better accuracy (optional enhancement)
    final aiNormalized = await _normalizeWithAI(original);
    if (aiNormalized != null && aiNormalized.isNotEmpty) {
      // Use AI result if it seems more accurate
      final aiLower = aiNormalized.toLowerCase();
      if (aiLower.length > 2 && aiLower != cleanName) {
        AppLogger.debug('AI normalized "$original" from "$cleanName" to "$aiLower"');
        // Prefer AI if it's shorter (more concise) or contains key words
        if (aiLower.length < cleanName.length * 1.5) {
          cleanName = aiLower;
        }
      }
    }
    
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

  /// AI-assisted ingredient name normalization (optional enhancement)
  static Future<String?> _normalizeWithAI(String ingredientStr) async {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) return null;
      
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a Filipino food ingredient expert. Extract ONLY the ingredient name from recipe ingredient strings. Return just the normalized ingredient name (e.g., "coconut milk", "chicken", "onion"). No explanations, just the name.'
            },
            {
              'role': 'user',
              'content': 'Extract the ingredient name from: "$ingredientStr"'
            }
          ],
          'max_tokens': 30,
          'temperature': 0.3,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = (data['choices'] != null && data['choices'].isNotEmpty)
            ? (data['choices'][0]['message']['content'] as String).trim()
            : null;
        return content;
      }
    } catch (e) {
      AppLogger.error('AI normalization error', e);
    }
    return null;
  }

  /// Clean ingredient name with improved accuracy
  static Future<String> _cleanIngredientName(String ingredientStr) async {
    String cleaned = ingredientStr.toLowerCase();
    
    // Remove container/package measurements first (can, bottle, package, etc.)
    cleaned = cleaned.replaceAll(RegExp(r'\d+\s*(can|cans|bottle|bottles|package|packages|pack|packs|box|boxes|jar|jars|tin|tins)\s*', caseSensitive: false), '');
    
    // Remove measurements with better regex (handles "1 can 2 cups" scenarios)
    cleaned = cleaned.replaceAll(RegExp(r'\d+(?:\.\d+)?\s*(oz|ounce|ounces|cup|cups|tbsp|tablespoon|tablespoons|tsp|teaspoon|teaspoons|g|gram|grams|kg|kilogram|kilograms|lbs?|pound|pounds|ml|milliliter|milliliters|l|liter|liters)\s*'), ' ');
    
    // Remove pieces, bunches, cloves, heads, stalks, etc.
    cleaned = cleaned.replaceAll(RegExp(r'\d+(?:\.\d+)?\s*(piece|pieces|bunch|bunches|clove|cloves|head|heads|stalk|stalks|bulb|bulbs|whole|halves)\s*'), ' ');
    
    // Remove fractions (standalone and with units)
    cleaned = cleaned.replaceAll(RegExp(r'\d+/\d+\s*(cup|cups|tbsp|tsp|oz|piece|pieces)?\s*'), ' ');
    
    // Remove "of", "and", "with", "to taste", "for", etc.
    cleaned = cleaned.replaceAll(RegExp(r'\s*(of|and|with|to taste|for|or|plus)\s*'), ' ');
    
    // Remove any remaining numbers at the start or middle
    cleaned = cleaned.replaceAll(RegExp(r'^\d+(?:\.\d+)?\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+\d+(?:\.\d+)?\s*'), ' ');
    
    // Remove parenthetical descriptions and extra punctuation
    cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    
    // Clean up extra spaces and punctuation
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[.,\s\-]+|[.,\s\-]+$'), '');
    
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
        issues.add('❌ "$ingredient" not found in FNRI database');
        if (result['suggestions'].isNotEmpty) {
          suggestions[ingredient] = result['suggestions'].first;
        }
      } else if (result['confidence'] < 0.7) {
        issues.add('⚠️ Low confidence match for "$ingredient" (${(result['confidence'] * 100).toStringAsFixed(1)}%)');
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

      AppLogger.debug('🔍 Analyzing ingredients for: $title');
      
      final analysis = await analyzeRecipeIngredients(ingredients);
      
      AppLogger.info('\n📊 Ingredient Analysis Report for "$title":');
      AppLogger.info('  Total ingredients: ${analysis['total_ingredients']}');
      AppLogger.info('  Valid ingredients: ${analysis['valid_ingredients']}');
      AppLogger.info('  Accuracy: ${analysis['accuracy_percentage'].toStringAsFixed(1)}%');
      
      if (analysis['issues'].isNotEmpty) {
        AppLogger.warning('\n⚠️ Issues found:');
        for (final issue in analysis['issues']) {
          AppLogger.warning('  $issue');
        }
      }
      
      if (analysis['suggestions'].isNotEmpty) {
        AppLogger.info('\n💡 Suggestions:');
        for (final entry in analysis['suggestions'].entries) {
          AppLogger.info('  "${entry.key}" → "${entry.value}"');
        }
      }
      
      return analysis;
    } catch (e) {
      AppLogger.error('❌ Error generating ingredient report', e);
      return {'error': e.toString()};
    }
  }
}
