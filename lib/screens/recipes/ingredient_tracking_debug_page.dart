import 'package:flutter/material.dart';
import '../../models/recipes.dart';
import '../../services/fnri_nutrition_service.dart';

class IngredientTrackingDebugPage extends StatefulWidget {
  final Recipe recipe;
  const IngredientTrackingDebugPage({super.key, required this.recipe});

  @override
  State<IngredientTrackingDebugPage> createState() => _IngredientTrackingDebugPageState();
}

class _IngredientTrackingDebugPageState extends State<IngredientTrackingDebugPage> {
  bool _loading = true;
  String? _error;
  late List<_IngredientRow> _rows;
  double? _estimatedServings;
  Map<String, dynamic>? _recipeNutritionData; // Store recipe-level nutrition data

  @override
  void initState() {
    super.initState();
    _compute();
  }

  // Use the same quantity estimation as recipe screen
  Map<String, double> _estimateIngredientQuantities(List<String> ingredients) {
    final quantities = <String, double>{};
    
    for (final ingredient in ingredients) {
      final ingredientLower = ingredient.toLowerCase();
      double quantity = _extractQuantityFromString(ingredientLower);
      
      if (quantity <= 0) {
        quantity = _estimateIngredientQuantity(ingredientLower);
      }
      
      quantities[ingredient] = quantity;
    }
    
    return quantities;
  }

  double _extractQuantityFromString(String ingredientStr) {
    // Handle fractions
    double fractionValue = 0.0;
    if (ingredientStr.contains('½') || ingredientStr.contains('1/2')) {
      fractionValue = 0.5;
    } else if (ingredientStr.contains('⅓') || ingredientStr.contains('1/3')) {
      fractionValue = 0.333;
    } else if (ingredientStr.contains('⅔') || ingredientStr.contains('2/3')) {
      fractionValue = 0.667;
    } else if (ingredientStr.contains('¼') || ingredientStr.contains('1/4')) {
      fractionValue = 0.25;
    } else if (ingredientStr.contains('¾') || ingredientStr.contains('3/4')) {
      fractionValue = 0.75;
    }
    
    // Handle grams
    final gramMatch = RegExp(r'(\d+(?:\.\d+)?)\s*g').firstMatch(ingredientStr);
    if (gramMatch != null) {
      return double.tryParse(gramMatch.group(1) ?? '1') ?? 0;
    }
    
    // Handle kilograms
    final kgMatch = RegExp(r'(\d+(?:\.\d+)?)\s*kg').firstMatch(ingredientStr);
    if (kgMatch != null) {
      return (double.tryParse(kgMatch.group(1) ?? '1') ?? 1) * 1000;
    }
    
    // Handle ounces
    final ozMatch = RegExp(r'(\d+(?:\.\d+)?)\s*oz').firstMatch(ingredientStr);
    if (ozMatch != null) {
      return (double.tryParse(ozMatch.group(1) ?? '1') ?? 1) * 28.35;
    }
    
    // Handle cups
    final cupMatch = RegExp(r'(\d+(?:\.\d+)?)\s*cup').firstMatch(ingredientStr);
    if (cupMatch != null) {
      return (double.tryParse(cupMatch.group(1) ?? '1') ?? 1) * 240;
    } else if (ingredientStr.contains('cup') && fractionValue > 0) {
      return fractionValue * 240;
    }
    
    // Handle tablespoons
    final tbspMatch = RegExp(r'(\d+(?:\.\d+)?)\s*tbsp').firstMatch(ingredientStr);
    if (tbspMatch != null) {
      return (double.tryParse(tbspMatch.group(1) ?? '1') ?? 1) * 15;
    } else if (ingredientStr.contains('tbsp') && fractionValue > 0) {
      return fractionValue * 15;
    }
    
    // Handle teaspoons
    final tspMatch = RegExp(r'(\d+(?:\.\d+)?)\s*tsp').firstMatch(ingredientStr);
    if (tspMatch != null) {
      return (double.tryParse(tspMatch.group(1) ?? '1') ?? 1) * 5;
    } else if (ingredientStr.contains('tsp') && fractionValue > 0) {
      return fractionValue * 5;
    }
    
    // Handle pieces
    final pieceMatch = RegExp(r'(\d+)\s*(?:piece|pieces|pc|pcs)').firstMatch(ingredientStr);
    if (pieceMatch != null) {
      final pieces = int.tryParse(pieceMatch.group(1) ?? '1');
      if (pieces != null) {
        if (ingredientStr.contains('chicken') || ingredientStr.contains('pork') || ingredientStr.contains('beef')) {
          return pieces * 100.0;
        } else if (ingredientStr.contains('tomato') || ingredientStr.contains('onion')) {
          return pieces * 60.0;
        } else if (ingredientStr.contains('egg')) {
          return pieces * 50.0;
        } else {
          return pieces * 50.0;
        }
      }
    }
    
    return 0;
  }

  double _estimateIngredientQuantity(String ingredient) {
    final ingredientLower = ingredient.toLowerCase();
    
    if (ingredientLower.contains('pork') || ingredientLower.contains('beef') || ingredientLower.contains('chicken')) {
      if (ingredientLower.contains('ribs') || ingredientLower.contains('chunk') || ingredientLower.contains('cut')) return 120;
      if (ingredientLower.contains('thigh') || ingredientLower.contains('breast') || ingredientLower.contains('fillet')) return 100;
      if (ingredientLower.contains('ground') || ingredientLower.contains('minced')) return 80;
      return 80;
    }
    
    if (ingredientLower.contains('tomato')) return 60;
    if (ingredientLower.contains('onion')) return 50;
    if (ingredientLower.contains('carrot')) return 40;
    if (ingredientLower.contains('garlic')) return 15;
    if (ingredientLower.contains('ginger')) return 10;
    
    if (ingredientLower.contains('fish sauce') || ingredientLower.contains('patis')) return 15;
    if (ingredientLower.contains('soy sauce') || ingredientLower.contains('toyo')) return 10;
    if (ingredientLower.contains('vinegar') || ingredientLower.contains('suka')) return 10;
    if (ingredientLower.contains('oil') || ingredientLower.contains('mantika')) return 10;
    
    return 30;
  }

  Future<void> _compute() async {
    setState(() {
      _loading = true;
      _error = null;
      _rows = [];
      _estimatedServings = null;
      _recipeNutritionData = null;
    });
    
    try {
      // Use the same calculation method as recipe screen
      final quantities = _estimateIngredientQuantities(widget.recipe.ingredients);
      
      // Calculate nutrition using the same service as recipe screen
      final nutrition = await FNRINutritionService.calculateRecipeNutrition(
        widget.recipe.ingredients,
        quantities,
      );
      
      _recipeNutritionData = nutrition;
      _estimatedServings = nutrition['estimated_servings'] as double?;
      
      // Build ingredient rows for display
      final rows = <_IngredientRow>[];
      final ingredientResults = nutrition['ingredients'] as Map<String, dynamic>? ?? {};
      
      for (final raw in widget.recipe.ingredients) {
        final qty = quantities[raw] ?? 100.0;
        final ingredientData = ingredientResults[raw] as Map<String, dynamic>?;
        final found = ingredientData?['found'] as bool? ?? false;
        
        if (!found || ingredientData == null) {
          rows.add(_IngredientRow(
            original: raw,
            cleaned: raw,
            grams: qty,
            matchedName: 'No match',
            calories: 0,
            fat: 0,
            sugar: 0,
            sodium: 0,
            found: false,
            multiplier: qty / 100.0,
          ));
          continue;
        }
        
        final fnriData = ingredientData['nutrition'] as Map<String, dynamic>?;
        if (fnriData == null) {
          rows.add(_IngredientRow(
            original: raw,
            cleaned: raw,
            grams: qty,
            matchedName: 'No match',
            calories: 0,
            fat: 0,
            sugar: 0,
            sodium: 0,
            found: false,
            multiplier: qty / 100.0,
          ));
          continue;
        }
        
        final multiplier = qty / 100.0;
        final caloriesPer100 = (fnriData['energyKcal'] as num?)?.toDouble() ?? 0.0;
        final fatPer100 = (fnriData['totalFat'] as num?)?.toDouble() ?? 0.0;
        final sugarPer100 = (fnriData['sugars'] as num?)?.toDouble() ?? 0.0;
        final sodiumPer100 = (fnriData['sodium'] as num?)?.toDouble() ?? 0.0;
        
        rows.add(_IngredientRow(
          original: raw,
          cleaned: ingredientData['fnri_name'] as String? ?? raw,
          grams: qty,
          matchedName: ingredientData['fnri_name'] as String? ?? 'Unknown',
          calories: (caloriesPer100 * multiplier).round(),
          fat: double.parse((fatPer100 * multiplier).toStringAsFixed(2)),
          sugar: double.parse((sugarPer100 * multiplier).toStringAsFixed(2)),
          sodium: double.parse((sodiumPer100 * multiplier).toStringAsFixed(2)),
          found: true,
          caloriesPer100g: caloriesPer100,
          fatPer100g: fatPer100,
          sugarPer100g: sugarPer100,
          sodiumPer100g: sodiumPer100,
          multiplier: multiplier,
        ));
      }

      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _rows.fold<int>(0, (sum, r) => sum + r.calories);
    final totalFat = _rows.fold<double>(0, (sum, r) => sum + r.fat);
    final totalSugar = _rows.fold<double>(0, (sum, r) => sum + r.sugar);
    final totalSodium = _rows.fold<double>(0, (sum, r) => sum + r.sodium);
    
    // Calculate per-serving values (same as recipe screen)
    final servings = _estimatedServings ?? 4.0;
    final perServingCalories = (totalCalories / servings).round();
    final perServingFat = totalFat / servings;
    final perServingSugar = totalSugar / servings;
    final perServingSodium = totalSodium / servings;
    
    // Get values from recipe screen calculation (with validation caps)
    final recipeCalories = (_recipeNutritionData?['summary']?['calories'] as num?)?.toInt() ?? 0;
    final recipeFat = (_recipeNutritionData?['summary']?['fat'] as num?)?.toDouble() ?? 0.0;
    final recipeSugar = (_recipeNutritionData?['summary']?['sugar'] as num?)?.toDouble() ?? 0.0;
    final recipeSodium = (_recipeNutritionData?['summary']?['sodium'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredient Tracking (Debug)'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _compute,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    // Total Recipe Summary
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restaurant_menu, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Total Recipe (${servings.toStringAsFixed(1)} servings)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.green[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _summaryCell('Calories', '$totalCalories kcal'),
                              _summaryCell('Fat', '${totalFat.toStringAsFixed(1)} g'),
                              _summaryCell('Sugar', '${totalSugar.toStringAsFixed(1)} g'),
                              _summaryCell('Sodium', '${totalSodium.toStringAsFixed(0)} mg'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Per-Serving Comparison
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people, size: 16, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Per Serving (calculated)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _summaryCell('Calories', '$perServingCalories kcal'),
                              _summaryCell('Fat', '${perServingFat.toStringAsFixed(1)} g'),
                              _summaryCell('Sugar', '${perServingSugar.toStringAsFixed(1)} g'),
                              _summaryCell('Sodium', '${perServingSodium.toStringAsFixed(0)} mg'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Recipe Screen Values (with validation caps)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.orange[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Recipe Screen (per serving, with validation)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Note: These values may be capped by validation rules',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _summaryCell('Calories', '$recipeCalories kcal'),
                              _summaryCell('Fat', '${recipeFat.toStringAsFixed(1)} g'),
                              _summaryCell('Sugar', '${recipeSugar.toStringAsFixed(1)} g'),
                              _summaryCell('Sodium', '${recipeSodium.toStringAsFixed(0)} mg'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = _rows[i];
                          return ExpansionTile(
                            leading: Icon(
                              r.found ? Icons.check_circle : Icons.error_outline,
                              color: r.found ? Colors.green : Colors.red,
                            ),
                            title: Text(r.original, style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (r.found) ...[
                                  Text('Cleaned: ${r.cleaned}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Matched: ${r.matchedName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isSuspiciousMatch(r.original, r.matchedName) ? Colors.orange[700] : Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ] else
                                  Text('No FNRI match for: ${r.cleaned}'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Qty: ${r.grams.toStringAsFixed(0)} g',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    if (r.found) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '× ${r.multiplier.toStringAsFixed(3)}',
                                        style: TextStyle(fontSize: 10, color: Colors.blue[700], fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${r.calories} kcal', style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('F ${r.fat.toStringAsFixed(1)}g  Su ${r.sugar.toStringAsFixed(1)}g  Na ${r.sodium.toStringAsFixed(0)}mg',
                                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              ],
                            ),
                            children: r.found && r.caloriesPer100g != null ? [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '📊 Calculation Breakdown',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildCalculationRow(
                                        'Calories',
                                        r.caloriesPer100g!,
                                        r.multiplier,
                                        r.calories.toDouble(),
                                        'kcal',
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCalculationRow(
                                        'Fat',
                                        r.fatPer100g!,
                                        r.multiplier,
                                        r.fat,
                                        'g',
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCalculationRow(
                                        'Sugar',
                                        r.sugarPer100g!,
                                        r.multiplier,
                                        r.sugar,
                                        'g',
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCalculationRow(
                                        'Sodium',
                                        r.sodiumPer100g!,
                                        r.multiplier,
                                        r.sodium,
                                        'mg',
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Multiplier: ${r.grams.toStringAsFixed(0)}g ÷ 100g = ${r.multiplier.toStringAsFixed(3)}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] : [
                              if (!r.found)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'No nutritional data available - ingredient not found in FNRI database.',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _summaryCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCalculationRow(
    String nutrient,
    double per100g,
    double multiplier,
    double calculated,
    String unit,
  ) {
    final isWholeNumber = per100g == per100g.roundToDouble();
    final per100gDisplay = isWholeNumber ? per100g.toInt().toString() : per100g.toStringAsFixed(2);
    
    final calculatedIsWhole = calculated == calculated.roundToDouble();
    final calculatedDisplay = calculatedIsWhole 
        ? calculated.toInt().toString() 
        : calculated.toStringAsFixed(2);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              nutrient,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              '$calculatedDisplay $unit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            '$per100gDisplay $unit/100g × ${multiplier.toStringAsFixed(3)} = $calculatedDisplay $unit',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  /// Check if a match seems suspicious (e.g., coconut milk -> nightshade)
  bool _isSuspiciousMatch(String original, String matched) {
    final origLower = original.toLowerCase();
    final matchLower = matched.toLowerCase();
    
    // Extract key words from original
    final origKeywords = origLower.split(RegExp(r'[\s,]+')).where((w) => w.length > 3).toSet();
    
    // Check if matched name contains any key words from original
    bool hasCommonKeyword = origKeywords.any((keyword) => matchLower.contains(keyword));
    
    // If no common keywords and they're both substantial strings, it's suspicious
    if (!hasCommonKeyword && origKeywords.isNotEmpty && matchLower.length > 5) {
      // Common ingredient words that should match
      final commonIngredients = ['milk', 'coconut', 'oil', 'chicken', 'pork', 'rice', 'egg', 'fish'];
      final hasCommonIngredient = commonIngredients.any((ing) => 
        origLower.contains(ing) && !matchLower.contains(ing)
      );
      return hasCommonIngredient;
    }
    
    return false;
  }
}

class _IngredientRow {
  final String original;
  final String cleaned;
  final double grams;
  final String matchedName;
  final int calories;
  final double fat;
  final double sugar;
  final double sodium;
  final bool found;
  // Per 100g values from FNRI data
  final double? caloriesPer100g;
  final double? fatPer100g;
  final double? sugarPer100g;
  final double? sodiumPer100g;
  final double multiplier; // Ratio: actualQty / 100g

  _IngredientRow({
    required this.original,
    required this.cleaned,
    required this.grams,
    required this.matchedName,
    required this.calories,
    required this.fat,
    required this.sugar,
    required this.sodium,
    required this.found,
    this.caloriesPer100g,
    this.fatPer100g,
    this.sugarPer100g,
    this.sodiumPer100g,
    this.multiplier = 1.0,
  });
}


