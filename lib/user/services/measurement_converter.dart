/// Measurement conversion service for recipe ingredients
/// Handles various measurement units and converts them to grams for consistency
library;

class MeasurementConverter {
  
  /// Supported measurement units with their conversions to grams
  static const Map<String, double> _volumeConversions = {
    // Volume measurements (for liquids/semi-liquids)
    'cup': 240.0,           // 1 cup = ~240g (varies by ingredient)
    'cups': 240.0,
    'tbsp': 15.0,           // 1 tablespoon = ~15g
    'tablespoon': 15.0,
    'tablespoons': 15.0,
    'tsp': 5.0,             // 1 teaspoon = ~5g
    'teaspoon': 5.0,
    'teaspoons': 5.0,
    'ml': 1.0,              // 1ml ≈ 1g for water-based liquids
    'milliliter': 1.0,
    'milliliters': 1.0,
    'l': 1000.0,            // 1 liter = 1000g
    'liter': 1000.0,
    'liters': 1000.0,
  };
  
  static const Map<String, double> _weightConversions = {
    // Weight measurements
    'g': 1.0,               // Base unit
    'gram': 1.0,
    'grams': 1.0,
    'kg': 1000.0,           // 1 kg = 1000g
    'kilogram': 1000.0,
    'kilograms': 1000.0,
    'lb': 453.59,           // 1 pound = 453.59g
    'lbs': 453.59,
    'pound': 453.59,
    'pounds': 453.59,
    'oz': 28.35,            // 1 ounce = 28.35g
    'ounce': 28.35,
    'ounces': 28.35,
  };
  
  static const Map<String, double> _countConversions = {
    // Count-based measurements (estimated weights)
    'clove': 3.0,           // 1 clove garlic ≈ 3g
    'cloves': 3.0,
  };
  
  /// Parse measurement from ingredient string
  static Map<String, dynamic> parseMeasurement(String ingredientStr) {
    final input = ingredientStr.toLowerCase().trim();
    
    // Handle fractions first (like "1/2 cup", "3/4 tbsp")
    final fractionResult = _parseFractionMeasurement(input);
    if (fractionResult['found']) {
      return fractionResult;
    }
    
    // Handle decimal measurements (like "1.5 tbsp", "2.0 cups")
    final decimalResult = _parseDecimalMeasurement(input);
    if (decimalResult['found']) {
      return decimalResult;
    }
    
    // Handle count-based measurements (like "3 pieces", "2 bunches")
    final countResult = _parseCountMeasurement(input);
    if (countResult['found']) {
      return countResult;
    }
    
    // No measurement found, return default
    return {
      'quantity': 100.0,
      'unit': 'g',
      'originalUnit': 'estimated',
      'found': false,
    };
  }
  
  /// Parse fraction measurements (1/2 cup, 3/4 tbsp, etc.)
  static Map<String, dynamic> _parseFractionMeasurement(String input) {
    final fractionRegex = RegExp(r'(\d+)/(\d+)\s*(\w+)');
    final match = fractionRegex.firstMatch(input);
    
    if (match != null) {
      final numerator = double.tryParse(match.group(1) ?? '1') ?? 1;
      final denominator = double.tryParse(match.group(2) ?? '1') ?? 1;
      final unit = match.group(3) ?? '';
      
      final fraction = numerator / denominator;
      final grams = _convertToGrams(fraction, unit, input);
      
      if (grams > 0) {
        return {
          'quantity': grams,
          'unit': 'g',
          'originalUnit': unit,
          'originalQuantity': fraction,
          'found': true,
        };
      }
    }
    
    return {'found': false};
  }
  
  /// Parse decimal measurements (1.5 tbsp, 2.0 cups, etc.)
  static Map<String, dynamic> _parseDecimalMeasurement(String input) {
    final decimalRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(\w+)');
    final match = decimalRegex.firstMatch(input);
    
    if (match != null) {
      final quantity = double.tryParse(match.group(1) ?? '1') ?? 1;
      final unit = match.group(2) ?? '';
      
      final grams = _convertToGrams(quantity, unit, input);
      
      if (grams > 0) {
        return {
          'quantity': grams,
          'unit': 'g',
          'originalUnit': unit,
          'originalQuantity': quantity,
          'found': true,
        };
      }
    }
    
    return {'found': false};
  }
  
  /// Parse count-based measurements (3 pieces, 2 eggs, 1 bunch, etc.)
  static Map<String, dynamic> _parseCountMeasurement(String input) {
    final countRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(piece|pieces|bunch|bunches|egg|eggs|clove|cloves)');
    final match = countRegex.firstMatch(input);
    
    if (match != null) {
      final count = double.tryParse(match.group(1) ?? '1') ?? 1;
      final countUnit = match.group(2) ?? '';
      
      double grams = 0;
      
      // Handle specific count conversions
      if (countUnit.contains('clove')) {
        grams = count * (_countConversions['clove'] ?? 3.0);
      } else if (countUnit.contains('piece')) {
        grams = _estimatePieceWeight(input, count);
      } else if (countUnit.contains('bunch')) {
        grams = _estimateBunchWeight(input, count);
      } else if (countUnit.contains('egg')) {
        grams = count * 50.0; // ~50g per egg
      }
      
      if (grams > 0) {
        return {
          'quantity': grams,
          'unit': 'g',
          'originalUnit': countUnit,
          'originalQuantity': count,
          'found': true,
        };
      }
    }
    
    return {'found': false};
  }
  
  /// Convert quantity and unit to grams
  static double _convertToGrams(double quantity, String unit, String context) {
    final unitLower = unit.toLowerCase();
    
    // Check weight conversions first
    if (_weightConversions.containsKey(unitLower)) {
      return quantity * _weightConversions[unitLower]!;
    }
    
    // Check volume conversions
    if (_volumeConversions.containsKey(unitLower)) {
      return quantity * _volumeConversions[unitLower]!;
    }
    
    // Check count conversions
    if (_countConversions.containsKey(unitLower)) {
      return quantity * _countConversions[unitLower]!;
    }
    
    return 0; // Unit not found
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
    if (ingredientLower.contains('carrot')) return pieces * 40;
    if (ingredientLower.contains('bell pepper')) return pieces * 50;
    
    // Fruits
    if (ingredientLower.contains('apple')) return pieces * 80;
    if (ingredientLower.contains('banana')) return pieces * 40;
    if (ingredientLower.contains('orange')) return pieces * 60;
    if (ingredientLower.contains('mango')) return pieces * 70;
    
    // Meat/Protein
    if (ingredientLower.contains('chicken')) return pieces * 100;
    if (ingredientLower.contains('fish')) return pieces * 80;
    if (ingredientLower.contains('egg')) return pieces * 50;
    if (ingredientLower.contains('hotdog')) return pieces * 50;
    if (ingredientLower.contains('sausage')) return pieces * 50;
    
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
  
  /// Get all supported measurement units
  static List<String> getSupportedUnits() {
    final allUnits = <String>[];
    allUnits.addAll(_weightConversions.keys);
    allUnits.addAll(_volumeConversions.keys);
    allUnits.addAll(_countConversions.keys);
    allUnits.addAll(['piece', 'pieces', 'bunch', 'bunches', 'egg', 'eggs']);
    return allUnits..sort();
  }
  
  /// Get measurement type for a unit
  static String getMeasurementType(String unit) {
    final unitLower = unit.toLowerCase();
    
    if (_weightConversions.containsKey(unitLower)) return 'weight';
    if (_volumeConversions.containsKey(unitLower)) return 'volume';
    if (_countConversions.containsKey(unitLower)) return 'count';
    if (['piece', 'pieces', 'bunch', 'bunches', 'egg', 'eggs'].contains(unitLower)) return 'count';
    
    return 'unknown';
  }
}
