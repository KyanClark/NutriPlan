import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';
import '../models/meal_history_entry.dart';

class AnalyticsService {
  /// Fetch weekly nutrition data
  static Future<Map<String, dynamic>> getWeeklyData(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final startOfWeekUtc = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toUtc();
      final endOfWeekUtc = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59).toUtc();
      
      final mealRes = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
          .eq('user_id', userId)
          .gte('completed_at', startOfWeekUtc.toIso8601String())
          .lte('completed_at', endOfWeekUtc.toIso8601String())
        .order('completed_at', ascending: true);

      final meals = <MealHistoryEntry>[];
      for (final mealData in mealRes) {
        try {
          final meal = MealHistoryEntry.fromMap(mealData);
          meals.add(meal);
        } catch (e) {
          AppLogger.error('Error parsing meal data', e);
        }
      }

      return _calculateNutritionData(meals, startOfWeek, endOfWeek);
    } catch (e) {
      AppLogger.error('Error fetching weekly data', e);
      return _getEmptyData();
    }
  }

  /// Fetch monthly nutrition data
  static Future<Map<String, dynamic>> getMonthlyData(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final startOfMonthUtc = startOfMonth.toUtc();
      final endOfMonthUtc = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59).toUtc();
      
      final mealRes = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
          .eq('user_id', userId)
          .gte('completed_at', startOfMonthUtc.toIso8601String())
          .lte('completed_at', endOfMonthUtc.toIso8601String())
        .order('completed_at', ascending: true);

      final meals = <MealHistoryEntry>[];
      for (final mealData in mealRes) {
        try {
          final meal = MealHistoryEntry.fromMap(mealData);
          meals.add(meal);
    } catch (e) {
          AppLogger.error('Error parsing meal data', e);
        }
      }

      return _calculateNutritionData(meals, startOfMonth, endOfMonth);
    } catch (e) {
      AppLogger.error('Error fetching monthly data', e);
      return _getEmptyData();
    }
  }

  /// Calculate nutrition data from meals
  static Map<String, dynamic> _calculateNutritionData(List<MealHistoryEntry> meals, DateTime startDate, DateTime endDate) {
    final dailyData = <String, Map<String, double>>{};
    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;
    double totalSugar = 0.0;

    // Initialize daily data
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
      final dateKey = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
      dailyData[dateKey] = {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
      };
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Aggregate meal data
    for (final meal in meals) {
      final dateKey = '${meal.completedAt.year}-${meal.completedAt.month.toString().padLeft(2, '0')}-${meal.completedAt.day.toString().padLeft(2, '0')}';
      
      if (dailyData.containsKey(dateKey)) {
        dailyData[dateKey]!['calories'] = dailyData[dateKey]!['calories']! + meal.calories;
        dailyData[dateKey]!['protein'] = dailyData[dateKey]!['protein']! + meal.protein;
        dailyData[dateKey]!['carbs'] = dailyData[dateKey]!['carbs']! + meal.carbs;
        dailyData[dateKey]!['fat'] = dailyData[dateKey]!['fat']! + meal.fat;
        dailyData[dateKey]!['fiber'] = dailyData[dateKey]!['fiber']! + meal.fiber;
        dailyData[dateKey]!['sugar'] = dailyData[dateKey]!['sugar']! + meal.sugar;

        totalCalories += meal.calories;
        totalProtein += meal.protein;
        totalCarbs += meal.carbs;
        totalFat += meal.fat;
        totalFiber += meal.fiber;
        totalSugar += meal.sugar;
      }
    }

    return {
      'dailyData': dailyData,
      'totals': {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'fiber': totalFiber,
        'sugar': totalSugar,
      },
      'averages': {
        'calories': totalCalories / dailyData.length,
        'protein': totalProtein / dailyData.length,
        'carbs': totalCarbs / dailyData.length,
        'fat': totalFat / dailyData.length,
        'fiber': totalFiber / dailyData.length,
        'sugar': totalSugar / dailyData.length,
      },
    };
  }

  /// Get empty data structure
  static Map<String, dynamic> _getEmptyData() {
    return {
      'dailyData': <String, Map<String, double>>{},
      'totals': {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
      },
      'averages': {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
      },
    };
  }
}