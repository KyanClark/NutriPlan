import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:csv/csv.dart';

class FNRIIngredientNutrition {
  final String foodId;
  final String foodName;
  final String scientificName;
  final String alternateNames;
  final String ediblePortion;
  
  // Proximates (per 100g)
  final double water;
  final double energyKcal;
  final double protein;
  final double totalFat;
  final double totalCarbohydrate;
  final double availableCarbohydrate;
  final double ash;
  final double fiber;
  final double sugars;
  
  // Minerals
  final double calcium;
  final double phosphorus;
  final double iron;
  final double sodium;
  final double potassium;
  final double zinc;
  
  // Vitamins
  final double retinol;
  final double betaCarotene;
  final double thiamin;
  final double riboflavin;
  final double niacin;
  final double vitaminC;
  
  // Lipids
  final double saturatedFat;
  final double monounsaturatedFat;
  final double polyunsaturatedFat;
  final double cholesterol;

  FNRIIngredientNutrition({
    required this.foodId,
    required this.foodName,
    required this.scientificName,
    required this.alternateNames,
    required this.ediblePortion,
    required this.water,
    required this.energyKcal,
    required this.protein,
    required this.totalFat,
    required this.totalCarbohydrate,
    required this.availableCarbohydrate,
    required this.ash,
    required this.fiber,
    required this.sugars,
    required this.calcium,
    required this.phosphorus,
    required this.iron,
    required this.sodium,
    required this.potassium,
    required this.zinc,
    required this.retinol,
    required this.betaCarotene,
    required this.thiamin,
    required this.riboflavin,
    required this.niacin,
    required this.vitaminC,
    required this.saturatedFat,
    required this.monounsaturatedFat,
    required this.polyunsaturatedFat,
    required this.cholesterol,
  });

  factory FNRIIngredientNutrition.fromCsvRow(List<dynamic> row) {
    return FNRIIngredientNutrition(
      foodId: row[0]?.toString() ?? '',
      foodName: row[1]?.toString() ?? '',
      scientificName: row[2]?.toString() ?? '',
      alternateNames: row[3]?.toString() ?? '',
      ediblePortion: row[4]?.toString() ?? '',
      water: _parseDouble(row[5]) ?? 0.0,
      energyKcal: _parseDouble(row[6]) ?? 0.0,
      protein: _parseDouble(row[7]) ?? 0.0,
      totalFat: _parseDouble(row[8]) ?? 0.0,
      totalCarbohydrate: _parseDouble(row[9]) ?? 0.0,
      availableCarbohydrate: _parseDouble(row[10]) ?? 0.0,
      ash: _parseDouble(row[11]) ?? 0.0,
      fiber: _parseDouble(row[12]) ?? 0.0,
      sugars: _parseDouble(row[13]) ?? 0.0,
      calcium: _parseDouble(row[14]) ?? 0.0,
      phosphorus: _parseDouble(row[15]) ?? 0.0,
      iron: _parseDouble(row[16]) ?? 0.0,
      sodium: _parseDouble(row[17]) ?? 0.0,
      potassium: _parseDouble(row[18]) ?? 0.0,
      zinc: _parseDouble(row[19]) ?? 0.0,
      retinol: _parseDouble(row[20]) ?? 0.0,
      betaCarotene: _parseDouble(row[21]) ?? 0.0,
      thiamin: _parseDouble(row[22]) ?? 0.0,
      riboflavin: _parseDouble(row[23]) ?? 0.0,
      niacin: _parseDouble(row[24]) ?? 0.0,
      vitaminC: _parseDouble(row[25]) ?? 0.0,
      saturatedFat: _parseDouble(row[26]) ?? 0.0,
      monounsaturatedFat: _parseDouble(row[27]) ?? 0.0,
      polyunsaturatedFat: _parseDouble(row[28]) ?? 0.0,
      cholesterol: _parseDouble(row[29]) ?? 0.0,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null || value == '' || value == '-') return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '').trim();
      return double.tryParse(cleaned);
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() => {
    'foodId': foodId,
    'foodName': foodName,
    'protein': protein,
    'totalFat': totalFat,
    'totalCarbohydrate': totalCarbohydrate,
    'fiber': fiber,
    'sugars': sugars,
    'sodium': sodium,
    'cholesterol': cholesterol,
    'energyKcal': energyKcal,
    'calcium': calcium,
    'iron': iron,
    'vitaminC': vitaminC,
  };

  @override
  String toString() {
    return 'FNRIIngredientNutrition($foodName: ${protein}g protein, ${totalFat}g fat, ${totalCarbohydrate}g carbs, ${energyKcal} kcal)';
  }
}

class FNRINutritionService {
  static List<FNRIIngredientNutrition>? _ingredientsCache;
  static Map<String, FNRIIngredientNutrition>? _searchCache;

  /// Load FNRI nutrition data from CSV file
  static Future<List<FNRIIngredientNutrition>> loadFNRIData() async {
    if (_ingredientsCache != null) {
      return _ingredientsCache!;
    }

    try {
      // Path to the CSV file in the fnri-food-composition-scraper directory
      final csvPath = path.join(
        Directory.current.path,
        'fnri-food-composition-scraper',
        'fnri_detailed_nutritional_data.csv'
      );

      final file = File(csvPath);
      if (!await file.exists()) {
        throw Exception('FNRI CSV file not found at: $csvPath');
      }

      final csvString = await file.readAsString();
      final csvTable = const CsvToListConverter().convert(csvString);

      // Skip header row
      final dataRows = csvTable.skip(1).toList();
      
      _ingredientsCache = dataRows
          .map((row) => FNRIIngredientNutrition.fromCsvRow(row))
          .toList();

      if (_ingredientsCache != null) {
      print('✅ Loaded ${_ingredientsCache!.length} FNRI ingredients');
      return _ingredientsCache!;
      } else {
        print('❌ Failed to create ingredients cache');
        return [];
      }
    } catch (e) {
      print('❌ Error loading FNRI data: $e');
      return [];
    }
  }

  /// Search for ingredients in FNRI data
  static Future<List<FNRIIngredientNutrition>> searchIngredients(String query) async {
    if (_searchCache == null) {
      await loadFNRIData();
      // Populate search cache for faster lookups
      _searchCache = {};
      if (_ingredientsCache != null) {
        for (final ingredient in _ingredientsCache!) {
          _searchCache![ingredient.foodName.toLowerCase()] = ingredient;
          // Also add alternate names to search cache
          if (ingredient.alternateNames.isNotEmpty) {
            final alternateNames = ingredient.alternateNames.split(',');
            for (final name in alternateNames) {
              final cleanName = name.trim().toLowerCase();
              if (cleanName.isNotEmpty) {
                _searchCache![cleanName] = ingredient;
              }
            }
          }
        }
      }
    }

    final queryLower = query.toLowerCase();
    final results = <FNRIIngredientNutrition>[];

    // Common ingredient synonyms and variations
    final ingredientSynonyms = {
      'pork': ['pork', 'baboy', 'pig', 'sus'],
      'pork ribs': ['pork ribs', 'baboy tadyang', 'ribs', 'tadyang'],
      'pork belly': ['pork belly', 'baboy liempo', 'liempo', 'belly'],
      'chicken': ['chicken', 'manok', 'gallus'],
      'chicken breast': ['chicken breast', 'manok dibdib', 'breast', 'dibdib'],
      'beef': ['beef', 'baka', 'cattle', 'bos'],
      'fish': ['fish', 'isda', 'tilapia', 'bangus'],
      'shrimp': ['shrimp', 'hipon', 'prawn', 'crustacean'],
      'crab': ['crab', 'alimango', 'crab', 'crustacean'],
      'rice': ['rice', 'kanin', 'bigas', 'oryza'],
      'brown rice': ['brown rice', 'brown rice', 'undermilled', 'rice'],
      'onion': ['onion', 'sibuyas', 'allium', 'bulb'],
      'garlic': ['garlic', 'bawang', 'allium', 'bulb'],
      'tomato': ['tomato', 'kamatis', 'solanum', 'fruit'],
      'carrot': ['carrot', 'karot', 'daucus', 'root'],
      'broccoli': ['broccoli', 'broccoli', 'brassica', 'vegetable'],
      'cabbage': ['cabbage', 'repolyo', 'brassica', 'vegetable'],
      'lettuce': ['lettuce', 'litsugas', 'lactuca', 'leafy'],
      'spinach': ['spinach', 'kangkong', 'spinacia', 'leafy'],
      'eggplant': ['eggplant', 'talong', 'solanum', 'vegetable'],
      'okra': ['okra', 'okra', 'abelmoschus', 'vegetable'],
      'potato': ['potato', 'patatas', 'solanum', 'tuber'],
      'sweet potato': ['sweet potato', 'kamote', 'ipomoea', 'tuber'],
      'cassava': ['cassava', 'kamoteng kahoy', 'manihot', 'tuber'],
      'corn': ['corn', 'mais', 'zea', 'grain'],
      'soy sauce': ['soy sauce', 'toyo', 'soy', 'condiment'],
      'fish sauce': ['fish sauce', 'patis', 'fish', 'condiment'],
      'vinegar': ['vinegar', 'suka', 'acetic', 'condiment'],
      'oil': ['oil', 'mantika', 'fat', 'cooking'],
      'olive oil': ['olive oil', 'olive oil', 'olea', 'oil'],
      'coconut oil': ['coconut oil', 'mantika ng niyog', 'cocos', 'oil'],
      'vegetable oil': ['vegetable oil', 'vegetable oil', 'plant', 'oil'],
      'salt': ['salt', 'asin', 'sodium', 'mineral'],
      'sugar': ['sugar', 'asukal', 'sucrose', 'carbohydrate'],
      'black pepper': ['black pepper', 'paminta', 'piper', 'spice'],
      'bay leaves': ['bay leaves', 'bay leaves', 'laurus', 'herb'],
      'ginger': ['ginger', 'luya', 'zingiber', 'rhizome'],
      'turmeric': ['turmeric', 'luyang dilaw', 'curcuma', 'rhizome'],
      'lemongrass': ['lemongrass', 'tanglad', 'cymbopogon', 'herb'],
      'tamarind': ['tamarind', 'sampalok', 'tamarindus', 'fruit'],
      'calamansi': ['calamansi', 'calamansi', 'citrus', 'fruit'],
      'lime': ['lime', 'dayap', 'citrus', 'fruit'],
      'lemon': ['lemon', 'lemon', 'citrus', 'fruit'],
      'mango': ['mango', 'mangga', 'mangifera', 'fruit'],
      'banana': ['banana', 'saging', 'musa', 'fruit'],
      'papaya': ['papaya', 'papaya', 'carica', 'fruit'],
      'pineapple': ['pineapple', 'pinya', 'ananas', 'fruit'],
      'coconut': ['coconut', 'niyog', 'cocos', 'fruit'],
      'mushroom': ['mushroom', 'kabute', 'fungus', 'fungi'],
      'tofu': ['tofu', 'tokwa', 'soy', 'protein'],
      'egg': ['egg', 'itlog', 'gallus', 'protein'],
      'milk': ['milk', 'gatas', 'dairy', 'liquid'],
      'cheese': ['cheese', 'keso', 'dairy', 'solid'],
      'butter': ['butter', 'mantikilya', 'dairy', 'fat'],
      'bread': ['bread', 'tinapay', 'wheat', 'baked'],
      'noodles': ['noodles', 'pancit', 'wheat', 'pasta'],
      'pasta': ['pasta', 'pasta', 'wheat', 'pasta'],
      'flour': ['flour', 'harina', 'wheat', 'powder'],
      'vegetables': ['vegetables', 'gulay', 'plant', 'mixed'],
      'fruits': ['fruits', 'prutas', 'plant', 'mixed'],
      'herbs': ['herbs', 'herbal', 'plant', 'mixed'],
      'spices': ['spices', 'pampalasa', 'plant', 'mixed'],
    };

    // Try to find synonyms for the ingredient
    String searchQuery = queryLower;
    for (final entry in ingredientSynonyms.entries) {
      if (entry.value.contains(queryLower)) {
        searchQuery = entry.key;
        break;
      }
    }

    // Exact matches first
    if (_searchCache != null) {
    for (final entry in _searchCache!.entries) {
      if (entry.key.contains(searchQuery) || searchQuery.contains(entry.key)) {
        results.add(entry.value);
        }
      }
    }

    // Sort by relevance and quality
    results.sort((a, b) {
      // First priority: exact matches
      final aExact = a.foodName.toLowerCase() == searchQuery;
      final bExact = b.foodName.toLowerCase() == searchQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;
      
      // Second priority: avoid processed/snack foods when looking for raw ingredients
      final aIsProcessed = _isProcessedFood(a.foodName);
      final bIsProcessed = _isProcessedFood(b.foodName);
      if (!aIsProcessed && bIsProcessed) return -1;
      if (aIsProcessed && !bIsProcessed) return 1;
      
      // Third priority: alphabetical
      return a.foodName.compareTo(b.foodName);
    });

    return results.take(10).toList(); // Limit to top 10 results
  }

  /// Check if a food item is processed/snack food
  static bool _isProcessedFood(String foodName) {
    final processedKeywords = [
      'chips', 'sticks', 'flvr', 'flavor', 'snack', 'crackers',
      'cookies', 'biscuits', 'candy', 'chocolate', 'ice cream',
      'soda', 'juice', 'drink', 'beverage', 'processed', 'canned',
      'frozen', 'dried', 'powdered', 'extract', 'concentrate'
    ];
    
    final nameLower = foodName.toLowerCase();
    return processedKeywords.any((keyword) => nameLower.contains(keyword));
  }

  /// Find best matching ingredient for a recipe ingredient
  static Future<FNRIIngredientNutrition?> findBestMatch(String ingredientName) async {
    final results = await searchIngredients(ingredientName);
    if (results.isEmpty) return null;

    // Filter out ingredients with impossible nutrition values
    final validResults = results.where((ingredient) => _isValidNutritionData(ingredient)).toList();
    
    if (validResults.isEmpty) {
      print('⚠️ All matches for "$ingredientName" had invalid nutrition data');
      return null;
    }

    // Return the best match (usually the first one)
    return validResults.first;
  }

  /// Validate that nutrition data makes sense (per 100g)
  static bool _isValidNutritionData(FNRIIngredientNutrition ingredient) {
    // Protein: 0-50g per 100g is realistic (some high-protein foods like meat, fish, tofu)
    if (ingredient.protein < 0 || ingredient.protein > 50) {
      print('    ❌ Invalid protein: ${ingredient.protein}g per 100g for ${ingredient.foodName}');
      return false;
    }
    
    // Fat: 0-100g per 100g is realistic (oils, nuts, fatty meats)
    if (ingredient.totalFat < 0 || ingredient.totalFat > 100) {
      print('    ❌ Invalid fat: ${ingredient.totalFat}g per 100g for ${ingredient.foodName}');
      return false;
    }
    
    // Carbs: 0-90g per 100g is realistic (grains, fruits, some vegetables)
    if (ingredient.totalCarbohydrate < 0 || ingredient.totalCarbohydrate > 90) {
      print('    ❌ Invalid carbs: ${ingredient.totalCarbohydrate}g per 100g for ${ingredient.foodName}');
      return false;
    }
    
    // Calories: 0-900 kcal per 100g is realistic (oils are highest)
    if (ingredient.energyKcal < 0 || ingredient.energyKcal > 900) {
      print('    ❌ Invalid calories: ${ingredient.energyKcal} kcal per 100g for ${ingredient.foodName}');
      return false;
    }
    
    // Sodium: 0-5000mg per 100g is realistic (some processed foods are very high)
    if (ingredient.sodium < 0 || ingredient.sodium > 5000) {
      print('    ❌ Invalid sodium: ${ingredient.sodium}mg per 100g for ${ingredient.foodName}');
      return false;
    }
    
    // Cholesterol: 0-500mg per 100g is realistic (egg yolks, organ meats)
    if (ingredient.cholesterol < 0 || ingredient.cholesterol > 500) {
      print('    ❌ Invalid cholesterol: ${ingredient.cholesterol}mg per 100g for ${ingredient.foodName}');
      return false;
    }
    
    return true;
  }

  /// Get nutrition for a specific ingredient
  static Future<FNRIIngredientNutrition?> getIngredientNutrition(String ingredientName) async {
    return await findBestMatch(ingredientName);
  }

  /// Calculate recipe nutrition using FNRI data
  static Future<Map<String, dynamic>> calculateRecipeNutrition(
    List<String> ingredients,
    Map<String, double> quantities
  ) async {
    double totalProtein = 0, totalFat = 0, totalCarbs = 0, totalFiber = 0;
    double totalSugar = 0, totalSodium = 0, totalCholesterol = 0;
    int totalCalories = 0;
    
    final results = <String, dynamic>{};
    final missingIngredients = <String>[];
    
    print('🍽️ Calculating nutrition for ${ingredients.length} ingredients...');
    print('🔍 Going directly to ingredient-level tracking for accuracy...');
    
    // Go directly to individual ingredient calculation for more accurate results
    for (final ingredient in ingredients) {
      final quantity = quantities[ingredient] ?? 100.0; // Default to 100g if not specified
      
      print('  🔍 Searching for: $ingredient (${quantity}g)');
      
      final nutrition = await findBestMatch(ingredient);
      
      if (nutrition != null) {
        // Convert from per 100g to actual quantity
        final multiplier = quantity / 100.0;
        
        totalProtein += nutrition.protein * multiplier;
        totalFat += nutrition.totalFat * multiplier;
        totalCarbs += nutrition.totalCarbohydrate * multiplier;
        totalFiber += nutrition.fiber * multiplier;
        totalSugar += nutrition.sugars * multiplier;
        totalSodium += nutrition.sodium * multiplier;
        totalCholesterol += nutrition.cholesterol * multiplier;
        totalCalories += (nutrition.energyKcal * multiplier).round();
        
        print('    ✅ Found: ${nutrition.foodName}');
        print('      📊 Added: ${(nutrition.protein * multiplier).toStringAsFixed(1)}g protein, ${(nutrition.totalFat * multiplier).toStringAsFixed(1)}g fat');
        
        results[ingredient] = {
          'found': true,
          'fnri_name': nutrition.foodName,
          'nutrition': nutrition.toJson(),
          'quantity': quantity,
        };
      } else {
        print('    ⚠️ No match found for: $ingredient');
        missingIngredients.add(ingredient);
        
        results[ingredient] = {
          'found': false,
          'quantity': quantity,
        };
      }
    }
    
    // Round all values to 2 decimal places and validate
    final roundedSummary = {
      'protein': _roundToTwoDecimals(totalProtein),
      'fat': _roundToTwoDecimals(totalFat),
      'carbs': _roundToTwoDecimals(totalCarbs),
      'fiber': _roundToTwoDecimals(totalFiber),
      'sugar': _roundToTwoDecimals(totalSugar),
      'sodium': _roundToTwoDecimals(totalSodium),
      'cholesterol': _roundToTwoDecimals(totalCholesterol),
      'calories': totalCalories.round(),
    };
    
    // Validate nutrition values for realism
    final validatedSummary = _validateNutritionValues(roundedSummary);
    
    print('\n🎯 Recipe Nutrition Summary (from ingredients):');
    print('  Protein: ${validatedSummary['protein']}g');
    print('  Fat: ${validatedSummary['fat']}g');
    print('  Carbs: ${validatedSummary['carbs']}g');
    print('  Fiber: ${validatedSummary['fiber']}g');
    print('  Sugar: ${validatedSummary['sugar']}g');
    print('  Sodium: ${validatedSummary['sodium']}mg');
    print('  Cholesterol: ${validatedSummary['cholesterol']}mg');
    print('  Calories: ${validatedSummary['calories']}');
    
    if (missingIngredients.isNotEmpty) {
      print('\n⚠️ Missing ingredients: ${missingIngredients.join(', ')}');
    }
    
    return {
      'summary': validatedSummary,
      'ingredients': results,
      'missing_ingredients': missingIngredients,
      'method': 'ingredient_calculation',
    };
  }

  /// Try to find a complete dish match based on recipe name
  static Future<FNRIIngredientNutrition?> _findCompleteDishMatch(String recipeName) async {
    final data = await loadFNRIData();
    
    // Common Filipino dish keywords and their variations
    final dishKeywords = {
      'lumpia shanghai': ['lumpia shanghai', 'spring roll shanghai', 'lumpiang shanghai', 'shanghai pork roll', 'lumpia'],
      'lumpia': ['lumpia', 'spring roll', 'lumpiang'],
      'adobo': ['adobo', 'adobong'],
      'sinigang': ['sinigang', 'sinigang na'],
      'afritada': ['afritada', 'apritada'],
      'kaldereta': ['kaldereta', 'caldereta'],
      'kare kare': ['kare kare', 'kare-kare'],
      'sisig': ['sisig'],
      'lechon': ['lechon', 'litson'],
      'pancit': ['pancit', 'pansit'],
      'arroz caldo': ['arroz caldo', 'arroz caldo'],
      'tinola': ['tinola'],
      'nilaga': ['nilaga'],
      'bulalo': ['bulalo'],
      'dinuguan': ['dinuguan'],
      'menudo': ['menudo'],
      'mechado': ['mechado'],
      'estopado': ['estopado'],
      'morcon': ['morcon'],
      'relleno': ['relleno'],
      'embutido': ['embutido'],
      'galantina': ['galantina'],
      'pochero': ['pochero'],
      'callos': ['callos'],
      'paella': ['paella'],
      'kari': ['kari', 'curry'],
      'bicol express': ['bicol express', 'bicol express'],
      'laing': ['laing'],
      'pinakbet': ['pinakbet'],
      'dinengdeng': ['dinengdeng'],
      'bulanglang': ['bulanglang'],
      'pakbet': ['pakbet'],
      'ginataang': ['ginataang'],
      'ginisaang': ['ginisaang'],
      'tinolang': ['tinolang'],
      'nilagang': ['nilagang'],
      'sinigang na': ['sinigang na'],
      'adobong': ['adobong'],
      'pritong': ['pritong'],
      'inihaw na': ['inihaw na'],
      'nilagang': ['nilagang'],
      'ginataang': ['ginataang'],
      'ginisaang': ['ginisaang'],
    };
    
    // Check for exact dish matches
    for (final entry in dishKeywords.entries) {
      for (final keyword in entry.value) {
        if (recipeName.contains(keyword)) {
          print('🔍 Looking for dish: ${entry.key}');
          
          // Search for the dish in FNRI data
          for (final item in data) {
            final itemName = item.foodName.toLowerCase();
            final alternateNames = item.alternateNames.toLowerCase();
            
            // Check if this item matches the dish we're looking for
            if (itemName.contains(entry.key) || 
                alternateNames.contains(entry.key) ||
                itemName.contains(keyword) ||
                alternateNames.contains(keyword)) {
              
              // Prefer cooked/prepared versions over raw ingredients
              if (itemName.contains('prep') || 
                  itemName.contains('cooked') || 
                  itemName.contains('luto') ||
                  itemName.contains('fried') ||
                  itemName.contains('roasted') ||
                  itemName.contains('grilled')) {
                print('  ✅ Found prepared dish: ${item.foodName}');
                return item;
              }
            }
          }
          
          // If no prepared version found, return the first match
          for (final item in data) {
            final itemName = item.foodName.toLowerCase();
            final alternateNames = item.alternateNames.toLowerCase();
            
            if (itemName.contains(entry.key) || 
                alternateNames.contains(entry.key) ||
                itemName.contains(keyword) ||
                alternateNames.contains(keyword)) {
              print('  ✅ Found dish: ${item.foodName}');
              return item;
            }
          }
        }
      }
    }
    
    return null;
  }

  /// Get realistic nutrition data for common Filipino dishes when not found in FNRI
  static Map<String, dynamic> _getRealisticDishNutrition(String dishName) {
    final dishLower = dishName.toLowerCase();
    
    // Realistic nutrition data for common Filipino dishes (per serving ~250g)
    if (dishLower.contains('lumpia shanghai') || dishLower.contains('lumpia')) {
      return {
        'protein': 12.0,    // Pork + wrapper
        'fat': 18.0,        // Fried in oil
        'carbs': 25.0,      // Wrapper + vegetables
        'fiber': 2.0,       // Vegetables
        'sugar': 1.0,       // Minimal
        'sodium': 450.0,    // Soy sauce + seasoning
        'cholesterol': 45.0, // Pork + egg
        'calories': 280,     // Realistic for fried spring rolls
      };
    }
    
    if (dishLower.contains('adobo')) {
      return {
        'protein': 25.0,    // Meat
        'fat': 15.0,        // Meat fat + oil
        'carbs': 8.0,       // Minimal
        'fiber': 1.0,       // Minimal
        'sugar': 2.0,       // Minimal
        'sodium': 800.0,    // Soy sauce
        'cholesterol': 80.0, // Meat
        'calories': 280,     // Realistic for adobo
      };
    }
    
    if (dishLower.contains('sinigang')) {
      return {
        'protein': 20.0,    // Meat
        'fat': 8.0,         // Meat fat
        'carbs': 15.0,      // Vegetables
        'fiber': 4.0,       // Vegetables
        'sugar': 3.0,       // Vegetables
        'sodium': 600.0,    // Fish sauce
        'cholesterol': 60.0, // Meat
        'calories': 220,     // Realistic for soup
      };
    }
    
    // Default realistic values for Filipino dishes
    return {
      'protein': 20.0,      // Typical meat portion
      'fat': 12.0,          // Typical fat content
      'carbs': 18.0,        // Typical carb content
      'fiber': 3.0,         // Typical fiber content
      'sugar': 2.0,         // Typical sugar content
      'sodium': 500.0,      // Typical sodium content
      'cholesterol': 70.0,  // Typical cholesterol content
      'calories': 250,      // Typical calorie content
    };
  }

  /// Identify the type of dish based on ingredients
  static String _identifyDishType(List<String> ingredients) {
    final ingredientsLower = ingredients.map((e) => e.toLowerCase()).toList();
    
    // Check for Lumpia Shanghai
    if (ingredientsLower.any((e) => e.contains('pork')) && 
        ingredientsLower.any((e) => e.contains('wrapper') || e.contains('wonton'))) {
      return 'lumpia shanghai';
    }
    
    // Check for Adobo
    if (ingredientsLower.any((e) => e.contains('pork') || e.contains('chicken') || e.contains('beef')) &&
        ingredientsLower.any((e) => e.contains('soy') || e.contains('vinegar'))) {
      return 'adobo';
    }
    
    // Check for Sinigang
    if (ingredientsLower.any((e) => e.contains('pork') || e.contains('beef')) &&
        ingredientsLower.any((e) => e.contains('tamarind') || e.contains('gabi'))) {
      return 'sinigang';
    }
    
    // Check for other common dishes
    if (ingredientsLower.any((e) => e.contains('pork') || e.contains('chicken')) &&
        ingredientsLower.any((e) => e.contains('tomato') || e.contains('potato'))) {
      return 'afritada';
    }
    
    return '';
  }

  /// Get statistics about the FNRI database
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final ingredients = await loadFNRIData();
    
    return {
      'total_ingredients': ingredients.length,
      'categories': {
        'grains': ingredients.where((i) => i.foodName.toLowerCase().contains('rice') || i.foodName.toLowerCase().contains('corn')).length,
        'vegetables': ingredients.where((i) => i.foodName.toLowerCase().contains('vegetable') || i.foodName.toLowerCase().contains('leafy')).length,
        'fruits': ingredients.where((i) => i.foodName.toLowerCase().contains('fruit') || i.foodName.toLowerCase().contains('banana')).length,
        'meat': ingredients.where((i) => i.foodName.toLowerCase().contains('pork') || i.foodName.toLowerCase().contains('beef') || i.foodName.toLowerCase().contains('chicken')).length,
        'fish': ingredients.where((i) => i.foodName.toLowerCase().contains('fish') || i.foodName.toLowerCase().contains('bangus') || i.foodName.toLowerCase().contains('tilapia')).length,
      },
      'sample_ingredients': ingredients.take(5).map((i) => i.foodName).toList(),
    };
  }

  /// Round a number to 2 decimal places
  static double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

  /// Validate nutrition values for realism
  static Map<String, dynamic> _validateNutritionValues(Map<String, dynamic> nutrition) {
    final validated = Map<String, dynamic>.from(nutrition);
    
    // More realistic ranges for Filipino dishes (per serving)
    // Protein validation (typical range: 5-80g per serving for meat-heavy dishes)
    if (validated['protein'] > 80.0) {
      print('⚠️ Protein value ${validated['protein']}g seems too high for a single serving, capping at 80g');
      validated['protein'] = 80.0;
    }
    
    // Fat validation (typical range: 2-50g per serving for fried dishes)
    if (validated['fat'] > 50.0) {
      print('⚠️ Fat value ${validated['fat']}g seems too high for a single serving, capping at 50g');
      validated['fat'] = 50.0;
    }
    
    // Calories validation (typical range: 100-1200 per serving for Filipino dishes)
    if (validated['calories'] > 1200) {
      print('⚠️ Calories value ${validated['calories']} seems too high for a single serving, capping at 1200');
      validated['calories'] = 1200;
    }
    
    // Sodium validation (typical range: 50-2000mg per serving for Filipino dishes)
    if (validated['sodium'] > 2000.0) {
      print('⚠️ Sodium value ${validated['sodium']}mg seems too high for a single serving, capping at 2000mg');
      validated['sodium'] = 2000.0;
    }
    
    // Cholesterol validation (typical range: 0-300mg per serving)
    if (validated['cholesterol'] > 300.0) {
      print('⚠️ Cholesterol value ${validated['cholesterol']}mg seems too high for a single serving, capping at 300mg');
      validated['cholesterol'] = 300.0;
    }
    
    // Carbs validation (typical range: 5-150g per serving)
    if (validated['carbs'] > 150.0) {
      print('⚠️ Carbs value ${validated['carbs']}g seems too high for a single serving, capping at 150g');
      validated['carbs'] = 150.0;
    }
    
    // Fiber validation (typical range: 0-20g per serving)
    if (validated['fiber'] > 20.0) {
      print('⚠️ Fiber value ${validated['fiber']}g seems too high for a single serving, capping at 20g');
      validated['fiber'] = 20.0;
    }
    
    // Sugar validation (typical range: 0-50g per serving)
    if (validated['sugar'] > 50.0) {
      print('⚠️ Sugar value ${validated['sugar']}g seems too high for a single serving, capping at 50g');
      validated['sugar'] = 50.0;
    }
    
    return validated;
  }
}
