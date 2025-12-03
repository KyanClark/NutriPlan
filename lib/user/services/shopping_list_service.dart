import '../models/recipes.dart';
import '../models/shopping_list_models.dart';
import '../utils/app_logger.dart';

class ShoppingListService {
  static ShoppingListData buildFromMeals(List<Map<String, dynamic>> meals) {
    final groupedByRecipe = <String, List<ShoppingListItem>>{};
    final mealTitles = <String>{};
    final missingMeals = <String>[];

    for (final meal in meals) {
      final recipeData = meal['recipes'] as Map<String, dynamic>?;
      if (recipeData == null) {
        AppLogger.warning('Shopping list: meal missing recipe data', meal);
        final title = meal['title']?.toString() ?? 'Unknown meal';
        missingMeals.add(title);
        continue;
      }

      final recipe = Recipe.fromMap(recipeData);
      if (recipe.ingredients.isEmpty) {
        continue;
      }

      final mealTitle = (meal['title'] ?? recipe.title).toString();
      final mealType = (meal['meal_type'] ?? 'meal').toString();
      mealTitles.add(mealTitle);

      // Create a list of ingredients for this recipe
      final recipeIngredients = <ShoppingListItem>[];
      
      for (final rawIngredient in recipe.ingredients) {
        final parsed = _parseIngredient(rawIngredient);
        if (parsed == null || parsed.normalizedName.isEmpty) {
          AppLogger.debug('Shopping list: unable to parse ingredient "$rawIngredient"');
          continue;
        }

        recipeIngredients.add(ShoppingListItem(
          key: '${mealTitle}_${parsed.normalizedName}',
          displayName: parsed.displayName,
          category: _categorize(parsed.displayName),
          quantity: parsed.quantity,
          unit: parsed.unit,
          sourceMeals: {mealTitle},
          mealTypes: {mealType},
        ));
      }

      // Group ingredients by recipe (meal title)
      if (recipeIngredients.isNotEmpty) {
        groupedByRecipe[mealTitle] = recipeIngredients;
      }
    }

    // Calculate total items across all recipes
    final totalItems = groupedByRecipe.values.fold<int>(
      0,
      (sum, items) => sum + items.length,
    );

    return ShoppingListData(
      itemsByCategory: groupedByRecipe, // Now grouped by recipe name instead of category
      mealsIncluded: mealTitles.length,
      totalItems: totalItems,
      mealTitles: mealTitles.toList()..sort(),
      missingMeals: missingMeals,
    );
  }


  static _ParsedIngredient? _parseIngredient(String raw) {
    var working = raw.trim();
    if (working.isEmpty) {
      return null;
    }

    working = working.replaceAll(RegExp(r'^[•\-]+'), '').trim();

    final numberMatch = RegExp(r'^([0-9]+(?:\s+[0-9]+\/[0-9]+|[0-9]*\/?[0-9]*)?)\s*(\w+)?\s+(.*)$')
        .firstMatch(working);

    double? quantity;
    String? unit;
    String name = working;

    if (numberMatch != null) {
      quantity = _parseQuantity(numberMatch.group(1));
      final candidateUnit = numberMatch.group(2) ?? '';
      final normalizedCandidate = _normalizeUnit(candidateUnit);
      final remainder = numberMatch.group(3)?.trim() ?? '';
      if (quantity != null && remainder.isNotEmpty) {
        name = remainder;
        unit = normalizedCandidate ?? candidateUnit;
      }
    }

    final normalizedName = _normalizeName(name);
    final displayName = _formatDisplayName(name);

    return _ParsedIngredient(
      raw: raw,
      normalizedName: normalizedName,
      displayName: displayName,
      quantity: quantity,
      unit: unit,
    );
  }

  static double? _parseQuantity(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains(' ')) {
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length == 2 && parts[1].contains('/')) {
        final whole = double.tryParse(parts.first);
        final fraction = _parseFraction(parts[1]);
        if (whole != null && fraction != null) {
          return whole + fraction;
        }
      }
    }

    if (trimmed.contains('/')) {
      final fraction = _parseFraction(trimmed);
      if (fraction != null) {
        return fraction;
      }
    }

    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  static double? _parseFraction(String input) {
    final fractionMatch = RegExp(r'^([0-9]+)\/([0-9]+)$').firstMatch(input.trim());
    if (fractionMatch == null) return null;
    final numerator = double.tryParse(fractionMatch.group(1)!);
    final denominator = double.tryParse(fractionMatch.group(2)!);
    if (numerator == null || denominator == null || denominator == 0) return null;
    return numerator / denominator;
  }

  static String _normalizeName(String name) {
    final cleaned = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s&-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  static String _formatDisplayName(String name) {
    if (name.isEmpty) return name;
    return name
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ')
        .trim();
  }

  static String _categorize(String name) {
    final lower = name.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Other';
  }

  static String? _normalizeUnit(String? unit) {
    if (unit == null || unit.isEmpty) return null;
    final lower = unit.toLowerCase().replaceAll('.', '');
    return _unitAliases[lower] ?? lower;
  }

  static const Map<String, List<String>> _categoryKeywords = {
    'Produce': [
      'tomato',
      'onion',
      'garlic',
      'ginger',
      'potato',
      'carrot',
      'pepper',
      'okra',
      'eggplant',
      'squash',
      'beans',
      'cabbage',
      'lettuce',
      'parsley',
      'cilantro',
      'calamansi',
      'lime',
      'lemon',
      'banana',
      'mango',
      'apple',
      'spinach',
      'kale',
      'celery',
      'cucumber',
      'bitter melon',
      'ampalaya',
      'malunggay',
      'kamote',
      'sweet potato',
      'string beans',
      'sitaw',
      'okra',
      'ginger',
      'okra',
      'tomatoes',
      'chili',
      'ginger',
      'ginger',
    ],
    'Meat & Seafood': [
      'chicken',
      'pork',
      'beef',
      'fish',
      'shrimp',
      'prawn',
      'crab',
      'squid',
      'tilapia',
      'bangus',
      'liver',
      'ham',
      'bacon',
      'hotdog',
      'hotdogs',
      'sausage',
      'meat',
      'seafood',
      'tuna',
      'salmon',
      'milkfish',
    ],
    'Pantry & Staples': [
      'rice',
      'noodles',
      'spaghetti',
      'pasta',
      'flour',
      'sugar',
      'salt',
      'pepper',
      'oil',
      'vinegar',
      'soy sauce',
      'sauce',
      'broth',
      'cube',
      'bouillon',
      'cornstarch',
      'baking',
      'breadcrumbs',
      'macaroni',
      'corned beef',
      'luncheon meat',
      'noodle',
    ],
    'Canned & Packaged': [
      'canned',
      'can ',
      'packet',
      'pack',
      'sardines',
      'spam',
      'tuna',
      'evaporated milk',
      'condensed milk',
      'knorr',
      'powder',
    ],
    'Dairy & Refrigerated': [
      'milk',
      'cheese',
      'butter',
      'yogurt',
      'cream',
      'mayonnaise',
      'evaporated milk',
      'condensed milk',
      'egg',
      'eggs',
    ],
    'Spices & Seasonings': [
      'spice',
      'seasoning',
      'paprika',
      'oregano',
      'basil',
      'thyme',
      'peppercorn',
      'cumin',
      'turmeric',
      'bay leaf',
      'salt and pepper',
      'garlic powder',
      'onion powder',
      'powder',
      'seasoning',
    ],
  };

  static const Map<String, String> _unitAliases = {
    'cup': 'cup',
    'cups': 'cup',
    'tbsp': 'tbsp',
    'tablespoon': 'tbsp',
    'tablespoons': 'tbsp',
    'tbs': 'tbsp',
    'tsp': 'tsp',
    'teaspoon': 'tsp',
    'teaspoons': 'tsp',
    'g': 'g',
    'gram': 'g',
    'grams': 'g',
    'kg': 'kg',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'lb': 'lb',
    'lbs': 'lb',
    'pound': 'lb',
    'pounds': 'lb',
    'oz': 'oz',
    'ounce': 'oz',
    'ounces': 'oz',
    'ml': 'ml',
    'milliliter': 'ml',
    'milliliters': 'ml',
    'l': 'l',
    'liter': 'l',
    'liters': 'l',
    'clove': 'clove',
    'cloves': 'clove',
    'piece': 'pc',
    'pieces': 'pc',
    'pc': 'pc',
    'pcs': 'pc',
    'stick': 'stick',
    'sticks': 'stick',
    'can': 'can',
    'cans': 'can',
    'packet': 'pack',
    'packets': 'pack',
    'pack': 'pack',
    'packs': 'pack',
    'thumb': 'thumb',
    'thumbs': 'thumb',
    'head': 'head',
    'heads': 'head',
    'bunch': 'bunch',
    'bunches': 'bunch',
    'slice': 'slice',
    'slices': 'slice',
    'pinch': 'pinch',
    'pinches': 'pinch',
    'dash': 'dash',
    'dashes': 'dash',
  };
}

class _ParsedIngredient {
  final String raw;
  final String normalizedName;
  final String displayName;
  final double? quantity;
  final String? unit;

  _ParsedIngredient({
    required this.raw,
    required this.normalizedName,
    required this.displayName,
    this.quantity,
    this.unit,
  });
}


