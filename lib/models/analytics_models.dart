import 'package:flutter/material.dart';

/// Nutrition summary for a specific time period
class NutritionSummary {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalSugar;
  final double totalFiber;
  final double totalSodium;
  final double totalCholesterol;
  final int mealCount;
  final DateTime periodStart;
  final DateTime periodEnd;

  NutritionSummary({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalSugar,
    required this.totalFiber,
    required this.totalSodium,
    required this.totalCholesterol,
    required this.mealCount,
    required this.periodStart,
    required this.periodEnd,
  });

  /// Calculate average daily values
  int get daysInPeriod => periodEnd.difference(periodStart).inDays + 1;
  
  double get averageDailyCalories => totalCalories / daysInPeriod;
  double get averageDailyProtein => totalProtein / daysInPeriod;
  double get averageDailyCarbs => totalCarbs / daysInPeriod;
  double get averageDailyFat => totalFat / daysInPeriod;
  double get averageDailySugar => totalSugar / daysInPeriod;
  double get averageDailyFiber => totalFiber / daysInPeriod;
  double get averageDailySodium => totalSodium / daysInPeriod;
  double get averageDailyCholesterol => totalCholesterol / daysInPeriod;
  double get averageMealsPerDay => mealCount / daysInPeriod;
}

/// Comparative analysis between two periods
class ComparativeAnalysis {
  final NutritionSummary currentPeriod;
  final NutritionSummary previousPeriod;
  final Map<String, double> percentageChanges;
  final List<String> insights;
  final List<String> recommendations;

  ComparativeAnalysis({
    required this.currentPeriod,
    required this.previousPeriod,
    required this.percentageChanges,
    required this.insights,
    required this.recommendations,
  });

  /// Calculate percentage change for a metric
  double getPercentageChange(String metric) {
    return percentageChanges[metric] ?? 0.0;
  }

  /// Check if a metric improved (positive change for good metrics, negative for bad)
  bool isImprovement(String metric) {
    final change = getPercentageChange(metric);
    switch (metric) {
      case 'calories':
      case 'protein':
      case 'carbs':
      case 'fat':
      case 'sugar':
      case 'sodium':
      case 'cholesterol':
        return change < 0; // Lower is better for these
      case 'fiber':
        return change > 0; // Higher is better for fiber
      default:
        return false;
    }
  }
}

/// AI-powered nutritional insight
class NutritionalInsight {
  final String title;
  final String description;
  final InsightType type;
  final double confidence;
  final List<String> actionableSteps;
  final Map<String, dynamic> data;

  NutritionalInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.confidence,
    required this.actionableSteps,
    required this.data,
  });
}

enum InsightType {
  positive,
  warning,
  recommendation,
  trend,
  goal,
}

/// Meal pattern analysis
class MealPatternAnalysis {
  final Map<String, int> mealFrequencyByCategory;
  final Map<String, double> averageNutritionByMeal;
  final List<String> mostFrequentRecipes;
  final Map<String, double> weeklyPatterns;
  final List<String> insights;

  MealPatternAnalysis({
    required this.mealFrequencyByCategory,
    required this.averageNutritionByMeal,
    required this.mostFrequentRecipes,
    required this.weeklyPatterns,
    required this.insights,
  });
}

/// Chart data point for visualization
class ChartDataPoint {
  final String label;
  final double value;
  final Color? color;
  final DateTime? date;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
    this.date,
  });
}

/// Analytics time period
enum AnalyticsPeriod {
  week,
  month,
  quarter,
  year,
}

/// Analytics filter options
class AnalyticsFilter {
  final AnalyticsPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> mealCategories;
  final List<String> recipeTypes;

  AnalyticsFilter({
    required this.period,
    this.startDate,
    this.endDate,
    this.mealCategories = const [],
    this.recipeTypes = const [],
  });

  AnalyticsFilter copyWith({
    AnalyticsPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? mealCategories,
    List<String>? recipeTypes,
  }) {
    return AnalyticsFilter(
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mealCategories: mealCategories ?? this.mealCategories,
      recipeTypes: recipeTypes ?? this.recipeTypes,
    );
  }
}
