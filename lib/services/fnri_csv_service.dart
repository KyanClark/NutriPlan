import 'package:flutter/services.dart';
import 'fnri_nutrition_service.dart';
import '../utils/app_logger.dart';

/// Local CSV-based FNRI nutrition service for faster debugging
class LocalFNRIService {
  static List<FNRIIngredientNutrition>? _cachedData;
  static bool _isLoading = false;

  /// Load FNRI data from local CSV asset
  static Future<List<FNRIIngredientNutrition>> loadFromCSV() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedData ?? [];
    }

    _isLoading = true;
    try {
      final csvContent = await rootBundle.loadString('assets/data/fnri_detailed_nutritional_data.csv');
      final lines = csvContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      if (lines.isEmpty) {
        _isLoading = false;
        return [];
      }

      final headerRow = _parseCSVLine(lines[0]);
      final columnIndices = <String, int>{};
      for (int i = 0; i < headerRow.length; i++) {
        columnIndices[headerRow[i].trim()] = i;
      }

      final ingredients = <FNRIIngredientNutrition>[];

      for (int i = 1; i < lines.length; i++) {
        try {
          final row = _parseCSVLine(lines[i]);
          if (row.length < 5) continue;

          final data = <String, dynamic>{};
          for (final entry in columnIndices.entries) {
            final idx = entry.value;
            if (idx < row.length) {
              data[entry.key] = row[idx].trim();
            }
          }

          final ingredient = FNRIIngredientNutrition.fromSupabase(data);
          ingredients.add(ingredient);
        } catch (e) {
          continue;
        }
      }

      _cachedData = ingredients;
      AppLogger.info('✅ Loaded ${ingredients.length} FNRI ingredients from CSV');
      _isLoading = false;
      return ingredients;
    } catch (e) {
      AppLogger.error('❌ Error loading FNRI CSV', e);
      _isLoading = false;
      return [];
    }
  }

  static List<String> _parseCSVLine(String line) {
    final result = <String>[];
    String current = '';
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current);
    return result;
  }

  static List<String> _extractKeyWords(String query) {
    final importantWords = ['coconut', 'milk', 'chicken', 'pork', 'rice', 'egg', 'fish', 
                            'oil', 'onion', 'garlic', 'tomato', 'lemon', 'grass', 'pepper'];
    final words = query.toLowerCase().split(RegExp(r'[\s,]+')).where((w) => w.length > 2).toList();
    final important = words.where((w) => importantWords.any((iw) => w.contains(iw) || iw.contains(w))).toList();
    return important.isNotEmpty ? important : words;
  }

  static Future<List<FNRIIngredientNutrition>> searchIngredients(String query) async {
    final ingredients = await loadFromCSV();
    if (ingredients.isEmpty) return [];

    final queryLower = query.toLowerCase().trim();
    final results = <(FNRIIngredientNutrition, int)>[];

    final cleanQuery = queryLower
        .replaceAll(',', ' ')
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final keyWords = _extractKeyWords(cleanQuery);

    for (final ingredient in ingredients) {
      final foodName = ingredient.foodName.toLowerCase();
      final alternateNames = ingredient.alternateNames.toLowerCase();
      
      if (foodName == cleanQuery) {
        results.add((ingredient, 1000));
        continue;
      }

      if (foodName.startsWith(cleanQuery)) {
        results.add((ingredient, 800));
        continue;
      }

      if (foodName.contains(cleanQuery)) {
        results.add((ingredient, 600));
        continue;
      }

      bool hasAllKeyWords = true;
      int matchedKeyWords = 0;
      for (final keyWord in keyWords) {
        if (foodName.contains(keyWord) || alternateNames.contains(keyWord)) {
          matchedKeyWords++;
        } else {
          hasAllKeyWords = false;
        }
      }

      if (hasAllKeyWords && keyWords.length > 0) {
        results.add((ingredient, 400 + (matchedKeyWords * 50)));
        continue;
      }

      if (alternateNames.contains(cleanQuery)) {
        results.add((ingredient, 300));
        continue;
      }
    }

    results.sort((a, b) {
      if (a.$2 != b.$2) {
        return b.$2.compareTo(a.$2);
      }
      return a.$1.foodName.toLowerCase().compareTo(b.$1.foodName.toLowerCase());
    });

    return results.take(20).map((r) => r.$1).toList();
  }

  static Future<FNRIIngredientNutrition?> findBestMatch(String ingredientName) async {
    final results = await searchIngredients(ingredientName);
    if (results.isEmpty) return null;

    final validResults = results.where((ingredient) => 
      ingredient.energyKcal >= 0 && 
      ingredient.energyKcal <= 900 &&
      ingredient.protein >= 0 &&
      ingredient.totalFat >= 0
    ).toList();

    if (validResults.isEmpty) return null;
    
    final best = validResults.first;
    AppLogger.debug('🎯 Best match for "$ingredientName": "${best.foodName}"');
    return best;
  }
}

