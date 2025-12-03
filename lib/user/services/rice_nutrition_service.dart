/// Rice Nutrition Service based on FNRI Food Exchange List for Meal Planning 4th Edition
/// Department of Science and Technology - Food and Nutrition Research Institute (DOST-FNRI)
class RiceNutritionService {
  /// Standard rice serving sizes based on FNRI Food Exchange List
  static const Map<String, RiceServing> _servingSizes = {
    'half_cup': RiceServing(
      label: '1/2 cup',
      cookedGrams: 80.0,
      description: '1 exchange (FNRI)',
    ),
    'one_cup': RiceServing(
      label: '1 cup',
      cookedGrams: 158.0,
      description: '2 exchanges (FNRI)',
    ),
    'one_and_half_cup': RiceServing(
      label: '1.5 cups',
      cookedGrams: 237.0,
      description: '3 exchanges (FNRI)',
    ),
    'two_cups': RiceServing(
      label: '2 cups',
      cookedGrams: 316.0,
      description: '4 exchanges (FNRI)',
    ),
  };

  /// Get all available serving sizes
  static List<RiceServing> getAvailableServings() {
    return _servingSizes.values.toList();
  }

  /// Get serving by key
  static RiceServing? getServing(String key) {
    return _servingSizes[key];
  }

  /// Get default serving (1 cup)
  static RiceServing getDefaultServing() {
    return _servingSizes['one_cup']!;
  }

  /// Calculate rice nutrition based on FNRI Food Exchange List standards
  /// Per 100g cooked rice (based on FNRI values):
  /// - Energy: 130 kcal
  /// - Protein: 2.7g
  /// - Carbohydrates: 28.0g
  /// - Fat: 0.3g
  /// - Fiber: 0.4g
  /// - Sodium: 1.0mg
  /// - Iron: 0.8mg
  /// - Thiamin: 0.02mg
  /// - Niacin: 0.4mg
  static RiceNutrition calculateNutrition(RiceServing serving) {
    // Per 100g cooked rice (FNRI standard)
    const per100g = RiceNutritionPer100g(
      calories: 130.0,
      protein: 2.7,
      carbs: 28.0,
      fat: 0.3,
      fiber: 0.4,
      sodium: 1.0,
      iron: 0.8,
      thiamin: 0.02,
      niacin: 0.4,
    );

    // Calculate based on serving size
    final multiplier = serving.cookedGrams / 100.0;

    return RiceNutrition(
      serving: serving,
      calories: (per100g.calories * multiplier).roundToDouble(),
      protein: (per100g.protein * multiplier),
      carbs: (per100g.carbs * multiplier),
      fat: (per100g.fat * multiplier),
      fiber: (per100g.fiber * multiplier),
      sodium: (per100g.sodium * multiplier),
      iron: (per100g.iron * multiplier),
      thiamin: (per100g.thiamin * multiplier),
      niacin: (per100g.niacin * multiplier),
    );
  }

  /// Convert to recipe macros format
  static Map<String, dynamic> toRecipeMacros(RiceNutrition nutrition) {
    return {
      'protein': nutrition.protein,
      'carbs': nutrition.carbs,
      'fat': nutrition.fat,
      'fiber': nutrition.fiber,
      'sugar': 0.0, // Rice has minimal sugar
      'sodium': nutrition.sodium,
      'cholesterol': 0.0, // Rice has no cholesterol
      'iron': nutrition.iron,
      'thiamin': nutrition.thiamin,
      'niacin': nutrition.niacin,
    };
  }
}

/// Rice serving size information
class RiceServing {
  final String label;
  final double cookedGrams;
  final String description;

  const RiceServing({
    required this.label,
    required this.cookedGrams,
    required this.description,
  });

  @override
  String toString() => label;
}

/// Rice nutrition per 100g (FNRI standard)
class RiceNutritionPer100g {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final double iron;
  final double thiamin;
  final double niacin;

  const RiceNutritionPer100g({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.iron,
    required this.thiamin,
    required this.niacin,
  });
}

/// Complete rice nutrition for a specific serving
class RiceNutrition {
  final RiceServing serving;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodium;
  final double iron;
  final double thiamin;
  final double niacin;

  RiceNutrition({
    required this.serving,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.iron,
    required this.thiamin,
    required this.niacin,
  });

  /// Get summary string
  String get summary {
    return '${serving.label} cooked rice: ${calories.round()} kcal, ${protein.toStringAsFixed(1)}g protein, ${carbs.toStringAsFixed(1)}g carbs';
  }
}

