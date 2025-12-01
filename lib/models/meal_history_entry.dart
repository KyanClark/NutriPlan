import 'package:flutter/material.dart';

enum MealCategory {
  breakfast,
  lunch,
  dinner,
}

class MealHistoryEntry {
  final String id;
  final String recipeId;
  final String title;
  final String imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final double cholesterol;
  final DateTime completedAt;
  final MealCategory category;
  final bool includeRice;
  final String? riceServing;
  final double? riceCalories;
  final double? riceProtein;
  final double? riceCarbs;
  final double? riceFat;
  final double? riceFiber;
  final double? riceSodium;

  MealHistoryEntry({
    required this.id,
    required this.recipeId,
    required this.title,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.fiber,
    required this.sodium,
    required this.cholesterol,
    required this.completedAt,
    required this.category,
    this.includeRice = false,
    this.riceServing,
    this.riceCalories,
    this.riceProtein,
    this.riceCarbs,
    this.riceFat,
    this.riceFiber,
    this.riceSodium,
  });

  factory MealHistoryEntry.fromMap(Map<String, dynamic> map) {
    double parseNum(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MealHistoryEntry(
      id: map['id'].toString(),
      recipeId: map['recipe_id'].toString(),
      title: map['title'] ?? '',
      imageUrl: map['image_url'] ?? '',
      calories: parseNum(map['calories']),
      protein: parseNum(map['protein']),
      carbs: parseNum(map['carbs']),
      fat: parseNum(map['fat']),
      sugar: parseNum(map['sugar']),
      fiber: parseNum(map['fiber']),
      sodium: parseNum(map['sodium']),
      cholesterol: parseNum(map['cholesterol']),
      completedAt: DateTime.parse(map['completed_at']),
      category: _parseMealCategory(map['meal_category'] ?? 'dinner'),
      includeRice: map['include_rice'] == true,
      riceServing: map['rice_serving']?.toString(),
      riceCalories: map['rice_calories'] != null ? parseNum(map['rice_calories']) : null,
      riceProtein: map['rice_protein'] != null ? parseNum(map['rice_protein']) : null,
      riceCarbs: map['rice_carbs'] != null ? parseNum(map['rice_carbs']) : null,
      riceFat: map['rice_fat'] != null ? parseNum(map['rice_fat']) : null,
      riceFiber: map['rice_fiber'] != null ? parseNum(map['rice_fiber']) : null,
      riceSodium: map['rice_sodium'] != null ? parseNum(map['rice_sodium']) : null,
    );
  }

  static MealCategory _parseMealCategory(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return MealCategory.breakfast;
      case 'lunch':
        return MealCategory.lunch;
      case 'dinner':
        return MealCategory.dinner;
      default:
        return MealCategory.dinner; // Default fallback
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case MealCategory.breakfast:
        return 'Breakfast';
      case MealCategory.lunch:
        return 'Lunch';
      case MealCategory.dinner:
        return 'Dinner';
    }
  }

  Color get categoryColor {
    switch (category) {
      case MealCategory.breakfast:
        return Colors.orange;
      case MealCategory.lunch:
        return Colors.green;
      case MealCategory.dinner:
        return Colors.purple;
    }
  }
} 