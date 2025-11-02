import 'fnri_csv_service.dart';

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

  factory FNRIIngredientNutrition.fromSupabase(Map<String, dynamic> data) {
    return FNRIIngredientNutrition(
      foodId: data['Food_ID']?.toString() ?? '',
      foodName: data['Food_name_and_Description']?.toString() ?? '',
      scientificName: data['Scientific_name']?.toString() ?? '',
      alternateNames: data['Alternate_Common_names']?.toString() ?? '',
      ediblePortion: data['Edible_portion']?.toString() ?? '100%',
      water: _parseDouble(data['Proximates_Water_g']) ?? 0.0,
      energyKcal: _parseDouble(data['Proximates_Energy_calculated_kcal']) ?? 0.0,
      protein: _parseDouble(data['Proximates_Protein_g']) ?? 0.0,
      totalFat: _parseDouble(data['Proximates_Total_Fat_g']) ?? 0.0,
      totalCarbohydrate: _parseDouble(data['Proximates_Carbohydrate_total_g']) ?? 0.0,
      availableCarbohydrate: _parseDouble(data['Proximates_Carbohydrate_available_g']) ?? 0.0,
      ash: _parseDouble(data['Proximates_Ash_total_g']) ?? 0.0,
      fiber: _parseDouble(data['Other_Carbohydrate_Fiber_total_dietary_g']) ?? 0.0,
      sugars: _parseDouble(data['Other_Carbohydrate_Sugars_total_g']) ?? 0.0,
      calcium: _parseDouble(data['Minerals_Calcium_Ca_mg']) ?? 0.0,
      phosphorus: _parseDouble(data['Minerals_Phosphorus_P_mg']) ?? 0.0,
      iron: _parseDouble(data['Minerals_Iron_Fe_mg']) ?? 0.0,
      sodium: _parseDouble(data['Minerals_Sodium_Na_mg']) ?? 0.0,
      potassium: _parseDouble(data['Minerals_Potassium_K_mg']) ?? 0.0,
      zinc: _parseDouble(data['Minerals_Zinc_Zn_mg']) ?? 0.0,
      retinol: _parseDouble(data['Vitamins_Retinol_Vitamin_A_µg']) ?? 0.0,
      betaCarotene: _parseDouble(data['Vitamins_beta-Carotene_µg']) ?? 0.0,
      thiamin: _parseDouble(data['Vitamins_Thiamin_Vitamin_B1_mg']) ?? 0.0,
      riboflavin: _parseDouble(data['Vitamins_Riboflavin_Vitamin_B2_mg']) ?? 0.0,
      niacin: _parseDouble(data['Vitamins_Niacin_mg']) ?? 0.0,
      vitaminC: _parseDouble(data['Vitamins_Ascorbic_Acid_Vitamin_C_mg']) ?? 0.0,
      saturatedFat: _parseDouble(data['Lipids_Fatty_acids_saturated_total_g']) ?? 0.0,
      monounsaturatedFat: _parseDouble(data['Lipids_Fatty_acids_monounsaturated_total_g']) ?? 0.0,
      polyunsaturatedFat: _parseDouble(data['Lipids_Fatty_acids_polyunsaturated_totalg']) ?? 0.0,
      cholesterol: _parseDouble(data['Lipids_Cholesterol_mg']) ?? 0.0,
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

  /// Get edible portion percentage as a decimal
  double get ediblePortionPercentage {
    if (ediblePortion.isEmpty) return 1.0; // Default to 100% if not specified
    final percentage = ediblePortion.replaceAll('%', '').trim();
    final value = double.tryParse(percentage);
    return (value ?? 100.0) / 100.0;
  }

  /// Apply cooking loss factors to nutrition values
  Map<String, double> getCookingAdjustedNutrition(String cookingMethod) {
    final cookingLossFactors = _getCookingLossFactors(cookingMethod);
    
    return {
      'protein': protein * cookingLossFactors['protein']!,
      'totalFat': totalFat * cookingLossFactors['fat']!,
      'totalCarbohydrate': totalCarbohydrate * cookingLossFactors['carbs']!,
      'fiber': fiber * cookingLossFactors['fiber']!,
      'sugars': sugars * cookingLossFactors['sugars']!,
      'sodium': sodium * cookingLossFactors['sodium']!,
      'cholesterol': cholesterol * cookingLossFactors['cholesterol']!,
      'energyKcal': energyKcal * cookingLossFactors['calories']!,
      'calcium': calcium * cookingLossFactors['minerals']!,
      'iron': iron * cookingLossFactors['minerals']!,
      'vitaminC': vitaminC * cookingLossFactors['vitamins']!,
    };
  }

  /// Get cooking loss factors based on cooking method
  Map<String, double> _getCookingLossFactors(String cookingMethod) {
    final method = cookingMethod.toLowerCase();
    
    // Default factors (no loss)
    Map<String, double> factors = {
      'protein': 1.0,
      'fat': 1.0,
      'carbs': 1.0,
      'fiber': 1.0,
      'sugars': 1.0,
      'sodium': 1.0,
      'cholesterol': 1.0,
      'calories': 1.0,
      'minerals': 1.0,
      'vitamins': 1.0,
    };

    if (method.contains('boil') || method.contains('steam')) {
      // Boiling/steaming: some water-soluble vitamins and minerals are lost
      factors['vitamins'] = 0.8; // 20% loss of water-soluble vitamins
      factors['minerals'] = 0.9; // 10% loss of minerals
    } else if (method.contains('fry') || method.contains('deep fry')) {
      // Frying: some fat-soluble vitamins are lost, but fat content may increase
      factors['vitamins'] = 0.85; // 15% loss of vitamins
      factors['fat'] = 1.1; // 10% increase in fat due to oil absorption
    } else if (method.contains('grill') || method.contains('broil')) {
      // Grilling: minimal losses
      factors['vitamins'] = 0.9; // 10% loss of vitamins
    } else if (method.contains('bake') || method.contains('roast')) {
      // Baking/roasting: moderate losses
      factors['vitamins'] = 0.85; // 15% loss of vitamins
      factors['minerals'] = 0.95; // 5% loss of minerals
    }

    return factors;
  }

  Map<String, dynamic> toJson() => {
    'foodId': foodId,
    'foodName': foodName,
    'ediblePortion': ediblePortion,
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
    return 'FNRIIngredientNutrition($foodName: ${protein}g protein, ${totalFat}g fat, ${totalCarbohydrate}g carbs, $energyKcal kcal, EP: $ediblePortion)';
  }
}

class FNRINutritionService {
  static List<FNRIIngredientNutrition>? _ingredientsCache;
  static Map<String, FNRIIngredientNutrition>? _searchCache;

  /// Load FNRI nutrition data from local CSV (replaces Supabase)
  static Future<List<FNRIIngredientNutrition>> loadFNRIData() async {
    if (_ingredientsCache != null) {
      return _ingredientsCache!;
    }

    // Use CSV service instead of Supabase
    _ingredientsCache = await LocalFNRIService.loadFromCSV();
    return _ingredientsCache ?? [];
  }

  /// Search for ingredients in FNRI data using local CSV
  static Future<List<FNRIIngredientNutrition>> searchIngredients(String query) async {
    // Use CSV service instead of Supabase
    return await LocalFNRIService.searchIngredients(query);
  }

  /// Fallback search using cached data
  static Future<List<FNRIIngredientNutrition>> _searchIngredientsCached(String query) async {
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

    // Apply ingredient synonyms logic
    final ingredientSynonyms = _getIngredientSynonyms();
    String searchQuery = queryLower;
    for (final entry in ingredientSynonyms.entries) {
      if (entry.value.contains(queryLower)) {
        searchQuery = entry.key;
        break;
      }
    }

    // Search with multiple strategies using cached data
    if (_searchCache != null) {
      // Strategy 1: Exact matches first
      for (final entry in _searchCache!.entries) {
        if (entry.key == searchQuery) {
          results.add(entry.value);
        }
      }
      
      // Strategy 2: Contains matches
      for (final entry in _searchCache!.entries) {
        if (entry.key.contains(searchQuery) || searchQuery.contains(entry.key)) {
          if (!results.contains(entry.value)) {
            results.add(entry.value);
          }
        }
      }
      
      // Strategy 3: Word-by-word matching for multi-word ingredients
      final searchWords = searchQuery.split(' ');
      if (searchWords.length > 1) {
        for (final entry in _searchCache!.entries) {
          final entryWords = entry.key.split(' ');
          // Check if at least 2 words match
          int matches = 0;
          for (final searchWord in searchWords) {
            if (entryWords.any((entryWord) => entryWord.contains(searchWord) || searchWord.contains(entryWord))) {
              matches++;
            }
          }
          if (matches >= 2 && !results.contains(entry.value)) {
            results.add(entry.value);
          }
        }
      }
      
      // Strategy 4: If still no results, try fuzzy matching - look for partial word matches
      if (results.isEmpty && searchWords.isNotEmpty) {
        for (final entry in _searchCache!.entries) {
          final entryLower = entry.key.toLowerCase();
          for (final searchWord in searchWords) {
            if (searchWord.length >= 3 && entryLower.contains(searchWord.substring(0, (searchWord.length / 2).ceil()))) {
              if (!results.contains(entry.value)) {
                results.add(entry.value);
              }
            }
          }
        }
      }
    }

    return _filterAndSortResults(results, query);
  }

  /// Filter and sort search results
  static List<FNRIIngredientNutrition> _filterAndSortResults(
    List<FNRIIngredientNutrition> results, 
    String query
  ) {
    final queryLower = query.toLowerCase();
    
    // Apply ingredient synonyms logic
    final ingredientSynonyms = _getIngredientSynonyms();
    String searchQuery = queryLower;
    for (final entry in ingredientSynonyms.entries) {
      if (entry.value.contains(queryLower)) {
        searchQuery = entry.key;
        break;
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

  /// Get ingredient synonyms mapping
  static Map<String, List<String>> _getIngredientSynonyms() {
    return {
      'pork': ['pork', 'baboy', 'pig', 'sus'],
      'ground pork': ['ground pork', 'minced pork', 'pork ground', 'baboy giniling', 'giniling na baboy', 'pork butt', 'boston butt', 'baboy paypay'],
      'pork ribs': ['pork ribs', 'baboy tadyang', 'ribs', 'tadyang'],
      'pork belly': ['pork belly', 'baboy liempo', 'liempo', 'belly'],
      'pork shoulder': ['pork shoulder', 'boston butt', 'baboy paypay'],
      'pork butt': ['pork butt', 'boston butt', 'baboy paypay'],
      'chicken': ['chicken', 'manok', 'gallus'],
      'chicken breast': ['chicken breast', 'manok dibdib', 'breast', 'dibdib'],
      'egg': ['egg', 'eggs', 'itlog', 'chicken egg', 'whole egg'],
      'beef': ['beef', 'baka', 'cattle', 'bos'],
      'fish': ['fish', 'isda', 'tilapia', 'bangus'],
      'shrimp': ['shrimp', 'hipon', 'prawn', 'crustacean'],
      'crab': ['crab', 'alimango', 'crustacean'],
      'rice': ['rice', 'kanin', 'bigas', 'oryza'],
      'brown rice': ['brown rice', 'undermilled', 'rice'],
      'onion': ['onion', 'sibuyas', 'allium', 'bulb'],
      'garlic': ['garlic', 'bawang', 'allium', 'bulb'],
      'tomato': ['tomato', 'kamatis', 'solanum', 'fruit'],
      'carrot': ['carrot', 'karot', 'daucus', 'root'],
      'broccoli': ['broccoli', 'brassica', 'vegetable'],
      'cabbage': ['cabbage', 'repolyo', 'brassica', 'vegetable'],
      'lettuce': ['lettuce', 'litsugas', 'lactuca', 'leafy'],
      'spinach': ['spinach', 'kangkong', 'spinacia', 'leafy'],
      'water spinach': ['water spinach', 'kangkong', 'swamp cabbage', 'ipomoea'],
      'string beans': ['string beans', 'sitaw', 'yard long bean', 'vigna', 'long bean'],
      'eggplant': ['eggplant', 'talong', 'solanum', 'vegetable', 'aubergine'],
      'okra': ['okra', 'abelmoschus', 'vegetable', 'lady finger'],
      'bitter melon': ['bitter melon', 'ampalaya', 'momordica', 'vegetable', 'bitter gourd'],
      'ampalaya': ['ampalaya', 'bitter melon', 'momordica', 'vegetable', 'bitter gourd'],
      'squash': ['squash', 'kalabasa', 'calabaza', 'vegetable', 'pumpkin'],
      'kalabasa': ['kalabasa', 'squash', 'calabaza', 'vegetable', 'pumpkin'],
      'patola': ['patola', 'sponge gourd', 'ridge gourd', 'luffa'],
      'winter melon': ['winter melon', 'winter squash', 'calabaza'],
      'potato': ['potato', 'patatas', 'solanum', 'tuber'],
      'sweet potato': ['sweet potato', 'kamote', 'ipomoea', 'tuber'],
      'cassava': ['cassava', 'kamoteng kahoy', 'manihot', 'tuber'],
      'corn': ['corn', 'mais', 'zea', 'grain'],
      'radish': ['radish', 'labanos', 'raphanus', 'root'],
      'daikon': ['daikon', 'radish', 'labanos', 'raphanus'],
      'green pepper': ['green pepper', 'bell pepper', 'capsicum', 'vegetable'],
      'long green pepper': ['long green pepper', 'green pepper', 'bell pepper', 'capsicum'],
      'soy sauce': ['soy sauce', 'toyo', 'soy', 'condiment'],
      'fish sauce': ['fish sauce', 'patis', 'fish', 'condiment'],
      'vinegar': ['vinegar', 'suka', 'acetic', 'condiment'],
      'oil': ['oil', 'mantika', 'fat', 'cooking'],
      'cooking oil': ['cooking oil', 'vegetable oil', 'cooking fat', 'mantika'],
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
      'young tamarind': ['young tamarind', 'tamarind', 'sampalok', 'tamarindus'],
      'calamansi': ['calamansi', 'calamansi', 'citrus', 'fruit'],
      'lime': ['lime', 'dayap', 'citrus', 'fruit'],
      'lemon': ['lemon', 'lemon', 'citrus', 'fruit'],
      'mango': ['mango', 'mangga', 'mangifera', 'fruit'],
      'banana': ['banana', 'saging', 'musa', 'fruit'],
      'banana blossom': ['banana blossom', 'banana heart', 'puso ng saging', 'puso saging', 'musa'],
      'banana heart': ['banana heart', 'banana blossom', 'puso ng saging', 'puso saging', 'musa'],
      'papaya': ['papaya', 'papaya', 'carica', 'fruit'],
      'pineapple': ['pineapple', 'pinya', 'ananas', 'fruit'],
      'coconut': ['coconut', 'niyog', 'cocos', 'fruit'],
      'coconut milk': ['coconut milk', 'gata', 'cocos', 'liquid'],
      'ginataang gulay mix': ['ginataang gulay mix', 'knorr ginataang gulay mix', 'seasoning mix'],
      'mushroom': ['mushroom', 'kabute', 'fungus', 'fungi'],
      'tofu': ['tofu', 'tokwa', 'soy', 'protein'],
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

  /// Extract the actual ingredient name from recipe strings with portions/quantities
  static String _extractIngredientName(String ingredientString) {
    String cleaned = ingredientString.toLowerCase().trim();
    
    // Remove common quantity patterns
    cleaned = cleaned
        // Remove numbers and fractions at the start
        .replaceAll(RegExp(r'^\d+(/\d+)?\s*'), '')
        // Remove leading quantities and units (be more careful)
        .replaceAll(RegExp(r'^\d+(?:\.\d+)?\s*(?:ml|oz|lb|lbs|kg|g|pieces?|pcs?)\s+'), '')
        .replaceAll(RegExp(r'^\d+(?:\.\d+)?\s*(?:cup|tbsp|tsp|tablespoon|teaspoon)s?\s+'), '')
        // Remove leading fraction quantities
        .replaceAll(RegExp(r'^½|⅓|¼|¾|⅔\s+'), '')
        // Only remove preparation methods at the END, not in the middle
        .replaceAll(RegExp(r',\s*(sliced|diced|chopped|minced|crushed|ground|cooked|fried|boiled|steamed)$'), '')
        // Remove trailing parenthetical descriptions
        .replaceAll(RegExp(r'\s*\(.*?\)$'), '')
        .trim();
    
    // Handle specific ingredient patterns
    final ingredientMappings = {
      // Eggs
      r'^\d+\s*eggs?$': 'egg',
      r'eggs?$': 'egg',
      
      // Hotdogs/Sausages
      r'red hotdogs?': 'hotdog',
      r'hotdogs?': 'hotdog',
      r'sausages?': 'sausage',
      
      // Seafood
      r'shrimp.*': 'shrimp',
      r'hipon.*': 'shrimp',
      r'prawns?.*': 'shrimp',
      
      // Rice
      r'garlic fried rice': 'rice',
      r'fried rice': 'rice',
      r'cooked rice': 'rice',
      r'steamed rice': 'rice',
      
      // Vegetables
      r'tomato.*': 'tomato',
      r'onion.*': 'onion', 
      r'garlic.*': 'garlic',
      
      // Peppers/Chilies
      r'long green chilies.*': 'green pepper',
      r'long red chilies.*': 'red pepper',
      r'green chilies.*': 'green pepper',
      r'red chilies.*': 'red pepper',
      r'chili.*': 'pepper',
      
      // Liquids
      r'water': 'water',
      r'cooking oil': 'vegetable oil',
      r'vegetable oil': 'vegetable oil',
      r'olive oil': 'olive oil',
      r'^oil$': 'vegetable oil',
      
      // Meat
      r'chicken thighs?': 'chicken',
      r'chicken breast': 'chicken',
      r'chicken.*': 'chicken',
      r'pork.*': 'pork',
      r'beef.*': 'beef',
      
      // Condiments
      r'soy sauce': 'soy sauce',
      r'fish sauce': 'fish sauce',
      r'vinegar': 'vinegar',
      
      // Herbs and spices
      r'bay leaves?': 'bay leaves',
      r'peppercorns?': 'black pepper',
      r'black pepper': 'black pepper',
    };
    
    // Apply mappings
    for (final entry in ingredientMappings.entries) {
      if (RegExp(entry.key).hasMatch(cleaned)) {
        cleaned = entry.value;
        break;
      }
    }
    
    return cleaned;
  }

  /// Find best matching ingredient for a recipe ingredient
  static Future<FNRIIngredientNutrition?> findBestMatch(String ingredientName) async {
    print('🔍 === SEARCHING FOR INGREDIENT ===');
    print('  Original: "$ingredientName"');
    
    // Extract the actual ingredient name from portions/quantities
    final cleanedName = _extractIngredientName(ingredientName);
    print('  🧹 After cleaning: "$cleanedName"');
    
    final results = await searchIngredients(cleanedName);
    print('  📊 Search found ${results.length} results');

    // Special handling for ground pork - find the best pork cut substitute
    if (cleanedName.toLowerCase().contains('ground pork') || 
        cleanedName.toLowerCase().contains('minced pork') ||
        cleanedName.toLowerCase().contains('baboy giniling')) {
      
      // Search for pork cuts that are commonly used for ground pork
      final porkCutResults = await searchIngredients('pork boston butt');
      if (porkCutResults.isNotEmpty) {
        // Prefer raw/unprocessed cuts over cooked ones for ground pork
        final rawPorkCuts = porkCutResults.where((r) => 
          !r.foodName.toLowerCase().contains('boiled') &&
          !r.foodName.toLowerCase().contains('broiled') &&
          !r.foodName.toLowerCase().contains('fried') &&
          !r.foodName.toLowerCase().contains('cooked')
        ).toList();
        
        if (rawPorkCuts.isNotEmpty) {
          final validPorkCuts = rawPorkCuts.where((ingredient) => _isValidNutritionData(ingredient)).toList();
          if (validPorkCuts.isNotEmpty) {
            print('    🔄 Using ${validPorkCuts.first.foodName} as substitute for ground pork');
            return validPorkCuts.first;
          }
        }
        
        // If no raw cuts found, use any valid pork cut
        final validPorkCuts = porkCutResults.where((ingredient) => _isValidNutritionData(ingredient)).toList();
        if (validPorkCuts.isNotEmpty) {
          print('    🔄 Using ${validPorkCuts.first.foodName} as substitute for ground pork');
          return validPorkCuts.first;
        }
      }
    }

    // Special handling for bell peppers - find the best pepper match
    if (cleanedName.toLowerCase().contains('bell pepper') || 
        cleanedName.toLowerCase().contains('bell peppers') ||
        cleanedName.toLowerCase().contains('sweet pepper') ||
        cleanedName.toLowerCase().contains('green pepper') ||
        cleanedName.toLowerCase().contains('red pepper') ||
        cleanedName.toLowerCase().contains('yellow pepper')) {
      
      // Search for bell pepper entries in FNRI data
      final bellPepperResults = await searchIngredients('pepper sweet bell');
      if (bellPepperResults.isNotEmpty) {
        // Prefer fresh/raw bell peppers over processed ones
        final freshBellPeppers = bellPepperResults.where((r) => 
          r.foodName.toLowerCase().contains('bell') &&
          !r.foodName.toLowerCase().contains('canned') &&
          !r.foodName.toLowerCase().contains('pickled') &&
          !r.foodName.toLowerCase().contains('dried')
        ).toList();
        
        if (freshBellPeppers.isNotEmpty) {
          final validBellPeppers = freshBellPeppers.where((ingredient) => _isValidNutritionData(ingredient)).toList();
          if (validBellPeppers.isNotEmpty) {
            print('    🔄 Using ${validBellPeppers.first.foodName} as substitute for bell peppers');
            return validBellPeppers.first;
          }
        }
        
        // If no fresh bell peppers found, use any valid bell pepper
        final validBellPeppers = bellPepperResults.where((ingredient) => _isValidNutritionData(ingredient)).toList();
        if (validBellPeppers.isNotEmpty) {
          print('    🔄 Using ${validBellPeppers.first.foodName} as substitute for bell peppers');
          return validBellPeppers.first;
        }
      }
    }

    // Special handling for shrimp - default to tiger shrimp (common in Philippines)
    if (cleanedName.toLowerCase().contains('shrimp') || 
        cleanedName.toLowerCase().contains('hipon') ||
        cleanedName.toLowerCase().contains('prawn')) {
      
      // Search for tiger shrimp first (most common in Philippines)
      final tigerShrimpResults = await searchIngredients('giant tiger prawn');
      if (tigerShrimpResults.isNotEmpty) {
        final validShrimp = tigerShrimpResults.where((ingredient) => _isValidNutritionData(ingredient)).toList();
        if (validShrimp.isNotEmpty) {
          print('    🔄 Using ${validShrimp.first.foodName} as substitute for shrimp');
          return validShrimp.first;
        }
      }
      
      // If no tiger shrimp, try banana prawn
      final bananaShrimp = await searchIngredients('banana prawn');
      if (bananaShrimp.isNotEmpty) {
        final validShrimp = bananaShrimp.where((ingredient) => _isValidNutritionData(ingredient)).toList();
        if (validShrimp.isNotEmpty) {
          print('    🔄 Using ${validShrimp.first.foodName} as substitute for shrimp');
          return validShrimp.first;
        }
      }
      
      // If none found, try any shrimp
      final anyShrimp = await searchIngredients('shrimp');
      if (anyShrimp.isNotEmpty) {
        final validShrimp = anyShrimp.where((ingredient) => 
          _isValidNutritionData(ingredient) && 
          !ingredient.foodName.toLowerCase().contains('paste') &&
          !ingredient.foodName.toLowerCase().contains('chips')
        ).toList();
        if (validShrimp.isNotEmpty) {
          print('    🔄 Using ${validShrimp.first.foodName} as substitute for shrimp');
          return validShrimp.first;
        }
      }
    }

    // Special handling for eggs - find the best egg match
    if (cleanedName.toLowerCase().contains('egg') || 
        cleanedName.toLowerCase().contains('eggs') ||
        cleanedName.toLowerCase().contains('itlog')) {
      
      // Search for egg entries in FNRI data
      final eggResults = await searchIngredients('egg chicken');
      if (eggResults.isNotEmpty) {
        // Prefer whole eggs over processed egg products
        final wholeEggs = eggResults.where((r) => 
          r.foodName.toLowerCase().contains('egg') &&
          (r.foodName.toLowerCase().contains('whole') || 
           (!r.foodName.toLowerCase().contains('white') &&
            !r.foodName.toLowerCase().contains('yolk'))) &&
          !r.foodName.toLowerCase().contains('powdered') &&
          !r.foodName.toLowerCase().contains('dried')
        ).toList();
        
        if (wholeEggs.isNotEmpty) {
          final validEggs = wholeEggs.where((ingredient) => _isValidNutritionData(ingredient)).toList();
          if (validEggs.isNotEmpty) {
            print('    🔄 Using ${validEggs.first.foodName} as substitute for eggs');
            return validEggs.first;
          }
        }
        
        // If no whole eggs found, use any valid egg
        final validEggs = eggResults.where((ingredient) => _isValidNutritionData(ingredient)).toList();
        if (validEggs.isNotEmpty) {
          print('    🔄 Using ${validEggs.first.foodName} as substitute for eggs');
          return validEggs.first;
        }
      }
    }

    // Note: Black pepper (Piper nigrum) is not available in FNRI data
    // The app will return null for black pepper ingredients

    // Special handling for cooking oil - default to corn oil (most common cooking oil)
    if (cleanedName.toLowerCase().contains('oil') && 
        !cleanedName.toLowerCase().contains('olive') &&
        !cleanedName.toLowerCase().contains('coconut')) {
      
      // Try corn oil first (most common cooking oil in Philippines)
      final cornOilResults = await searchIngredients('oil corn');
      if (cornOilResults.isNotEmpty) {
        final validOil = cornOilResults.where((ingredient) => _isValidNutritionData(ingredient)).toList();
        if (validOil.isNotEmpty) {
          print('    🔄 Using ${validOil.first.foodName} as substitute for cooking oil');
          return validOil.first;
        }
      }
      
      // Fallback to coconut oil
      final coconutOilResults = await searchIngredients('oil coconut');
      if (coconutOilResults.isNotEmpty) {
        final validOil = coconutOilResults.where((ingredient) => _isValidNutritionData(ingredient)).toList();
        if (validOil.isNotEmpty) {
          print('    🔄 Using ${validOil.first.foodName} as substitute for cooking oil');
          return validOil.first;
        }
      }
    }

    // If no special handling worked and no results found, return null
    if (results.isEmpty) return null;

    // Filter out ingredients with impossible nutrition values
    final validResults = results.where((ingredient) => _isValidNutritionData(ingredient)).toList();
    
    if (validResults.isEmpty) {
      print('❌ === INGREDIENT NOT FOUND ===');
      print('  ❌ All matches for "$cleanedName" had invalid nutrition data');
      if (results.isNotEmpty) {
        print('  📋 Top match found but rejected: "${results.first.foodName}"');
        print('  📋 Alternate names tried: ${results.map((r) => r.foodName).take(5).join(", ")}');
      } else {
        print('  🔍 No results found in Supabase for: "$cleanedName"');
        print('  💡 Search strategies attempted:');
        print('    1. Main column search (Food_name_and_Description)');
        print('    2. Alternate names search');
        print('    3. Word-by-word search');
      }
      print('=== END SEARCH ===\n');
      return null;
    }

    // Return the best match (usually the first one)
    print('✅ === INGREDIENT FOUND ===');
    print('  ✅ Match: "${validResults.first.foodName}"');
    print('  📊 Nutrition: ${validResults.first.protein}g protein, ${validResults.first.totalFat}g fat, ${validResults.first.totalCarbohydrate}g carbs, ${validResults.first.energyKcal}kcal');
    print('=== END SEARCH ===\n');
    return validResults.first;
  }

  /// Validate that nutrition data makes sense (per 100g)
  static bool _isValidNutritionData(FNRIIngredientNutrition ingredient) {
    // Special case: Pure fats/oils can have 0 protein and high fat
    if (ingredient.foodName.toLowerCase().contains('fat') || 
        ingredient.foodName.toLowerCase().contains('oil') ||
        ingredient.foodName.toLowerCase().contains('mantika')) {
      // These can have 0 protein and up to 100g fat
      return true;
    }
    
    // Protein: 0-100g per 100g is realistic (some high-protein foods like meat, fish, tofu, shrimp paste)
    if (ingredient.protein < 0 || ingredient.protein > 100) {
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
    
    // Sodium: 0-10000mg per 100g is realistic (fish sauce, soy sauce can be very high)
    if (ingredient.sodium < 0 || ingredient.sodium > 10000) {
      print('    ❌ Invalid sodium: ${ingredient.sodium}mg per 100g for ${ingredient.foodName}');
      return false;
    }
    
    // Cholesterol: 0-1500mg per 100g is realistic (egg yolks can be ~1100mg, organ meats higher)
    if (ingredient.cholesterol < 0 || ingredient.cholesterol > 1500) {
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
        print('      📊 Added: ${(nutrition.protein * multiplier).toStringAsFixed(1)}g protein, ${(nutrition.totalFat * multiplier).toStringAsFixed(1)}g fat, ${(nutrition.totalCarbohydrate * multiplier).toStringAsFixed(1)}g carbs, ${(nutrition.energyKcal * multiplier).round()} kcal');
        
        results[ingredient] = {
          'found': true,
          'fnri_name': nutrition.foodName,
          'nutrition': nutrition.toJson(),
          'quantity': quantity,
        };
      } else {
        print('    ❌ === MISSING INGREDIENT DETECTED ===');
        print('    ❌ Ingredient: "$ingredient"');
        print('    ❌ Quantity requested: ${quantity}g');
        print('    ⚠️ REASON: No match found in FNRI database');
        print('    📋 This ingredient will be skipped in nutrition calculation');
        print('    💡 SUGGESTION: Check if ingredient exists in FNRI data with alternate name');
        print('    ❌ =======================================');
        missingIngredients.add(ingredient);
        
        results[ingredient] = {
          'found': false,
          'quantity': quantity,
        };
      }
    }
    
    // Calculate per serving (typical Filipino dishes serve 4-6 people)
    final estimatedServings = _estimateServings(ingredients, quantities);
    print('🍽️ Estimated servings: $estimatedServings');
    
    final perServingProtein = totalProtein / estimatedServings;
    final perServingFat = totalFat / estimatedServings;
    final perServingCarbs = totalCarbs / estimatedServings;
    final perServingFiber = totalFiber / estimatedServings;
    final perServingSugar = totalSugar / estimatedServings;
    final perServingSodium = totalSodium / estimatedServings;
    final perServingCholesterol = totalCholesterol / estimatedServings;
    final perServingCalories = totalCalories / estimatedServings;
    
    // Round all values to 2 decimal places and validate
    final roundedSummary = {
      'protein': _roundToTwoDecimals(perServingProtein),
      'fat': _roundToTwoDecimals(perServingFat),
      'carbs': _roundToTwoDecimals(perServingCarbs),
      'fiber': _roundToTwoDecimals(perServingFiber),
      'sugar': _roundToTwoDecimals(perServingSugar),
      'sodium': _roundToTwoDecimals(perServingSodium),
      'cholesterol': _roundToTwoDecimals(perServingCholesterol),
      'calories': perServingCalories.round(),
    };
    
    // Validate nutrition values for realism
    final validatedSummary = _validateNutritionValues(roundedSummary);
    
    print('\n🎯 Recipe Nutrition Summary (per serving):');
    print('  Protein: ${validatedSummary['protein']}g');
    print('  Fat: ${validatedSummary['fat']}g');
    print('  Carbs: ${validatedSummary['carbs']}g');
    print('  Fiber: ${validatedSummary['fiber']}g');
    print('  Sugar: ${validatedSummary['sugar']}g');
    print('  Sodium: ${validatedSummary['sodium']}mg');
    print('  Cholesterol: ${validatedSummary['cholesterol']}mg');
    print('  Calories: ${validatedSummary['calories']}');
    
    if (missingIngredients.isNotEmpty) {
      print('\n⚠️ === MISSING INGREDIENTS SUMMARY ===');
      print('⚠️ Total missing: ${missingIngredients.length} out of ${ingredients.length} ingredients');
      print('⚠️ Missing ingredients: ${missingIngredients.join(', ')}');
      print('📋 IMPACT: Nutrition calculation may be incomplete due to missing data');
      print('💡 ACTION REQUIRED: Check debug logs above for each missing ingredient to see:');
      print('   1. What the cleaned search term was');
      print('   2. Why it failed (no results or invalid nutrition data)');
      print('   3. What alternate names were tried');
      print('⚠️ ========================================');
    }
    
    return {
      'summary': validatedSummary,
      'ingredients': results,
      'missing_ingredients': missingIngredients,
      'method': 'ingredient_calculation',
      'total_recipe_calories': totalCalories,
      'estimated_servings': estimatedServings,
    };
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

  /// Estimate number of servings based on ingredients and quantities
  static double _estimateServings(List<String> ingredients, Map<String, double> quantities) {
    double totalWeight = 0;
    int meatCount = 0;
    
    for (final ingredient in ingredients) {
      final quantity = quantities[ingredient] ?? 0;
      totalWeight += quantity;
      
      final ingredientLower = ingredient.toLowerCase();
      if (ingredientLower.contains('pork') || ingredientLower.contains('beef') || 
          ingredientLower.contains('chicken') || ingredientLower.contains('fish')) {
        meatCount++;
      }
    }
    
    // Estimate servings based on total weight and ingredient types
    if (totalWeight > 2000) return 6.0; // Large recipe (2kg+)
    if (totalWeight > 1500) return 5.0; // Medium-large recipe (1.5kg+)
    if (totalWeight > 1000) return 4.0; // Medium recipe (1kg+)
    if (totalWeight > 500) return 3.0;  // Small-medium recipe (500g+)
    if (totalWeight > 200) return 2.0;  // Small recipe (200g+)
    
    // Default based on meat content (typical Filipino serving has meat)
    if (meatCount > 0) return 4.0; // Typical Filipino family meal
    return 2.0; // Light meal
  }

  /// Round a number to 2 decimal places
  static double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

  /// Validate nutrition values for realism
  static Map<String, dynamic> _validateNutritionValues(Map<String, dynamic> nutrition) {
    final validated = Map<String, dynamic>.from(nutrition);
    
    // More realistic ranges for Filipino dishes (per serving ~250-300g)
    // Protein validation (typical range: 8-45g per serving for Filipino dishes)
    if (validated['protein'] > 45.0) {
      print('⚠️ Protein value ${validated['protein']}g seems too high for a single serving, capping at 45g');
      validated['protein'] = 45.0;
    }
    
    // Fat validation (typical range: 3-35g per serving for Filipino dishes)
    if (validated['fat'] > 35.0) {
      print('⚠️ Fat value ${validated['fat']}g seems too high for a single serving, capping at 35g');
      validated['fat'] = 35.0;
    }
    
    // Calories validation (typical range: 150-800 per serving for Filipino dishes)
    if (validated['calories'] > 800) {
      print('⚠️ Calories value ${validated['calories']} seems too high for a single serving, capping at 800');
      validated['calories'] = 800;
    }
    
    // Sodium validation (typical range: 100-2000mg per serving for Filipino dishes)
    if (validated['sodium'] > 2000.0) {
      print('⚠️ Sodium value ${validated['sodium']}mg seems too high for a single serving, capping at 2000mg');
      validated['sodium'] = 2000.0;
    }
    
    // Cholesterol validation (typical range: 0-200mg per serving)
    if (validated['cholesterol'] > 200.0) {
      print('⚠️ Cholesterol value ${validated['cholesterol']}mg seems too high for a single serving, capping at 200mg');
      validated['cholesterol'] = 200.0;
    }
    
    // Carbs validation (typical range: 8-100g per serving)
    if (validated['carbs'] > 100.0) {
      print('⚠️ Carbs value ${validated['carbs']}g seems too high for a single serving, capping at 100g');
      validated['carbs'] = 100.0;
    }
    
    // Fiber validation (typical range: 0-20g per serving)
    if (validated['fiber'] > 20.0) {
      print('⚠️ Fiber value ${validated['fiber']}g seems too high for a single serving, capping at 20g');
      validated['fiber'] = 20.0;
    }
    
    // Sugar validation (typical range: 0-40g per serving)
    if (validated['sugar'] > 40.0) {
      print('⚠️ Sugar value ${validated['sugar']}g seems too high for a single serving, capping at 40g');
      validated['sugar'] = 40.0;
    }
    
    return validated;
  }
}
