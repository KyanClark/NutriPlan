import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_nutrition_goals.dart';
import '../models/analytics_models.dart';

class AnalyticsService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Fetch nutrition summary for a specific period
  static Future<NutritionSummary> getNutritionSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    final user = userId ?? _client.auth.currentUser?.id;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('meal_plan_history')
        .select()
        .eq('user_id', user)
        .gte('completed_at', startDate.toUtc().toIso8601String())
        .lte('completed_at', endDate.toUtc().toIso8601String())
        .order('completed_at', ascending: true);

    if (response.isEmpty) return _emptySummary(startDate, endDate);

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalSugar = 0;
    double totalFiber = 0;
    double totalSodium = 0;
    double totalCholesterol = 0;
    int mealCount = 0;

    for (final meal in response) {
      totalCalories += _parseDouble(meal['calories']) ?? 0;
      totalProtein += _parseDouble(meal['protein']) ?? 0;
      totalCarbs += _parseDouble(meal['carbs']) ?? 0;
      totalFat += _parseDouble(meal['fat']) ?? 0;
      totalSugar += _parseDouble(meal['sugar']) ?? 0;
      totalFiber += _parseDouble(meal['fiber']) ?? 0;
      totalSodium += _parseDouble(meal['sodium']) ?? 0;
      totalCholesterol += _parseDouble(meal['cholesterol']) ?? 0;
      mealCount++;
    }

    return NutritionSummary(
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalSugar: totalSugar,
      totalFiber: totalFiber,
      totalSodium: totalSodium,
      totalCholesterol: totalCholesterol,
      mealCount: mealCount,
      periodStart: startDate,
      periodEnd: endDate,
    );
  }

  /// Get comparative analysis between two periods
  static Future<ComparativeAnalysis> getComparativeAnalysis({
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
    String? userId,
  }) async {
    final currentSummary = await getNutritionSummary(
      startDate: currentStart,
      endDate: currentEnd,
      userId: userId,
    );

    final previousSummary = await getNutritionSummary(
      startDate: previousStart,
      endDate: previousEnd,
      userId: userId,
    );

    final percentageChanges = _calculatePercentageChanges(
      currentSummary,
      previousSummary,
    );

    final insights = _generateComparativeInsights(
      currentSummary,
      previousSummary,
      percentageChanges,
    );

    final recommendations = _generateRecommendations(
      currentSummary,
      previousSummary,
      percentageChanges,
    );

    return ComparativeAnalysis(
      currentPeriod: currentSummary,
      previousPeriod: previousSummary,
      percentageChanges: percentageChanges,
      insights: insights,
      recommendations: recommendations,
    );
  }

  /// Generate AI-powered nutritional insights
  static Future<List<NutritionalInsight>> generateNutritionalInsights({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    final summary = await getNutritionSummary(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );

    final userGoals = await _getUserNutritionGoals(userId);
    final mealPatterns = await _getMealPatternAnalysis(startDate, endDate, userId);

    final insights = <NutritionalInsight>[];

    // Calorie analysis
    if (userGoals != null) {
      final calorieInsight = _analyzeCalorieIntake(summary, userGoals);
      if (calorieInsight != null) insights.add(calorieInsight);
    }

    // Protein analysis
    if (userGoals != null) {
      final proteinInsight = _analyzeProteinIntake(summary, userGoals);
      if (proteinInsight != null) insights.add(proteinInsight);
    }

    // Fiber analysis
    if (userGoals != null) {
      final fiberInsight = _analyzeFiberIntake(summary, userGoals);
      if (fiberInsight != null) insights.add(fiberInsight);
    }

    // Sodium analysis
    final sodiumInsight = _analyzeSodiumIntake(summary);
    if (sodiumInsight != null) insights.add(sodiumInsight);

    // Meal pattern insights
    final patternInsights = _analyzeMealPatterns(mealPatterns);
    insights.addAll(patternInsights);

    // Trend analysis
    final trendInsights = await _analyzeTrends(startDate, endDate, userId);
    insights.addAll(trendInsights);

    return insights;
  }

  /// Get meal pattern analysis
  static Future<MealPatternAnalysis> getMealPatternAnalysis({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    final user = userId ?? _client.auth.currentUser?.id;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('meal_plan_history')
        .select()
        .eq('user_id', user)
        .gte('completed_at', startDate.toUtc().toIso8601String())
        .lte('completed_at', endDate.toUtc().toIso8601String())
        .order('completed_at', ascending: true);

    if (response.isEmpty) {
      return MealPatternAnalysis(
        mealFrequencyByCategory: {},
        averageNutritionByMeal: {},
        mostFrequentRecipes: [],
        weeklyPatterns: {},
        insights: [],
      );
    }

    final mealFrequencyByCategory = <String, int>{};
    final nutritionByMeal = <String, List<double>>{};
    final recipeFrequency = <String, int>{};
    final weeklyPatterns = <String, double>{};

    for (final meal in response) {
      final category = meal['meal_category'] ?? 'unknown';
      final recipeTitle = meal['title'] ?? 'Unknown Recipe';

      // Count meal frequency by category
      mealFrequencyByCategory[category] = (mealFrequencyByCategory[category] ?? 0) + 1;

      // Count recipe frequency
      recipeFrequency[recipeTitle] = (recipeFrequency[recipeTitle] ?? 0) + 1;

      // Collect nutrition data by meal category
      if (!nutritionByMeal.containsKey(category)) {
        nutritionByMeal[category] = [];
      }
      nutritionByMeal[category]!.add(_parseDouble(meal['calories']) ?? 0);

      // Weekly patterns (day of week)
      final completedAt = DateTime.parse(meal['completed_at']);
      final dayOfWeek = _getDayOfWeek(completedAt.weekday);
      weeklyPatterns[dayOfWeek] = (weeklyPatterns[dayOfWeek] ?? 0) + 1;
    }

    // Calculate average nutrition by meal category
    final averageNutritionByMeal = <String, double>{};
    nutritionByMeal.forEach((category, values) {
      if (values.isNotEmpty) {
        averageNutritionByMeal[category] = values.reduce((a, b) => a + b) / values.length;
      }
    });

    // Get most frequent recipes
    final sortedRecipes = recipeFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostFrequentRecipes = sortedRecipes.take(5).map((e) => e.key).toList();

    // Generate insights
    final insights = _generateMealPatternInsights(
      mealFrequencyByCategory,
      averageNutritionByMeal,
      mostFrequentRecipes,
      weeklyPatterns,
    );

    return MealPatternAnalysis(
      mealFrequencyByCategory: mealFrequencyByCategory,
      averageNutritionByMeal: averageNutritionByMeal,
      mostFrequentRecipes: mostFrequentRecipes,
      weeklyPatterns: weeklyPatterns,
      insights: insights,
    );
  }

  /// Get chart data for nutrition trends
  static Future<List<ChartDataPoint>> getNutritionTrendData({
    required AnalyticsPeriod period,
    required String metric,
    String? userId,
  }) async {
    final now = DateTime.now();
    final dataPoints = <ChartDataPoint>[];

    switch (period) {
      case AnalyticsPeriod.week:
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final startOfDay = DateTime(date.year, date.month, date.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));

          final summary = await getNutritionSummary(
            startDate: startOfDay,
            endDate: endOfDay,
            userId: userId,
          );

          final value = _getMetricValue(summary, metric);
          dataPoints.add(ChartDataPoint(
            label: _formatDateLabel(date),
            value: value,
            date: date,
          ));
        }
        break;

      case AnalyticsPeriod.month:
        for (int i = 29; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final startOfDay = DateTime(date.year, date.month, date.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));

          final summary = await getNutritionSummary(
            startDate: startOfDay,
            endDate: endOfDay,
            userId: userId,
          );

          final value = _getMetricValue(summary, metric);
          dataPoints.add(ChartDataPoint(
            label: _formatDateLabel(date),
            value: value,
            date: date,
          ));
        }
        break;

      case AnalyticsPeriod.quarter:
        for (int i = 11; i >= 0; i--) {
          final date = now.subtract(Duration(days: i * 7));
          final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));

          final summary = await getNutritionSummary(
            startDate: startOfWeek,
            endDate: endOfWeek,
            userId: userId,
          );

          final value = _getMetricValue(summary, metric);
          dataPoints.add(ChartDataPoint(
            label: 'Week ${12 - i}',
            value: value,
            date: startOfWeek,
          ));
        }
        break;

      case AnalyticsPeriod.year:
        for (int i = 11; i >= 0; i--) {
          final date = now.subtract(Duration(days: i * 30));
          final startOfMonth = DateTime(date.year, date.month, 1);
          final endOfMonth = DateTime(date.year, date.month + 1, 0);

          final summary = await getNutritionSummary(
            startDate: startOfMonth,
            endDate: endOfMonth,
            userId: userId,
          );

          final value = _getMetricValue(summary, metric);
          dataPoints.add(ChartDataPoint(
            label: _formatMonthLabel(startOfMonth),
            value: value,
            date: startOfMonth,
          ));
        }
        break;
    }

    return dataPoints;
  }

  // Helper methods

  static double? _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    return 0.0;
  }

  static NutritionSummary _emptySummary(DateTime start, DateTime end) {
    return NutritionSummary(
      totalCalories: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      totalSugar: 0,
      totalFiber: 0,
      totalSodium: 0,
      totalCholesterol: 0,
      mealCount: 0,
      periodStart: start,
      periodEnd: end,
    );
  }

  static Map<String, double> _calculatePercentageChanges(
    NutritionSummary current,
    NutritionSummary previous,
  ) {
    final changes = <String, double>{};

    changes['calories'] = _calculatePercentageChange(
      current.averageDailyCalories,
      previous.averageDailyCalories,
    );
    changes['protein'] = _calculatePercentageChange(
      current.averageDailyProtein,
      previous.averageDailyProtein,
    );
    changes['carbs'] = _calculatePercentageChange(
      current.averageDailyCarbs,
      previous.averageDailyCarbs,
    );
    changes['fat'] = _calculatePercentageChange(
      current.averageDailyFat,
      previous.averageDailyFat,
    );
    changes['sugar'] = _calculatePercentageChange(
      current.averageDailySugar,
      previous.averageDailySugar,
    );
    changes['fiber'] = _calculatePercentageChange(
      current.averageDailyFiber,
      previous.averageDailyFiber,
    );
    changes['sodium'] = _calculatePercentageChange(
      current.averageDailySodium,
      previous.averageDailySodium,
    );
    changes['cholesterol'] = _calculatePercentageChange(
      current.averageDailyCholesterol,
      previous.averageDailyCholesterol,
    );

    return changes;
  }

  static double _calculatePercentageChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  static List<String> _generateComparativeInsights(
    NutritionSummary current,
    NutritionSummary previous,
    Map<String, double> changes,
  ) {
    final insights = <String>[];

    // Calorie insights
    final calorieChange = changes['calories'] ?? 0;
    if (calorieChange.abs() > 10) {
      if (calorieChange > 0) {
        insights.add('Your daily calorie intake increased by ${calorieChange.toStringAsFixed(1)}% compared to the previous period.');
      } else {
        insights.add('Your daily calorie intake decreased by ${(-calorieChange).toStringAsFixed(1)}% compared to the previous period.');
      }
    }

    // Protein insights
    final proteinChange = changes['protein'] ?? 0;
    if (proteinChange.abs() > 15) {
      if (proteinChange > 0) {
        insights.add('Great! Your protein intake increased by ${proteinChange.toStringAsFixed(1)}%.');
      } else {
        insights.add('Your protein intake decreased by ${(-proteinChange).toStringAsFixed(1)}%. Consider adding more protein-rich foods.');
      }
    }

    // Fiber insights
    final fiberChange = changes['fiber'] ?? 0;
    if (fiberChange.abs() > 20) {
      if (fiberChange > 0) {
        insights.add('Excellent! Your fiber intake increased by ${fiberChange.toStringAsFixed(1)}%.');
      } else {
        insights.add('Your fiber intake decreased by ${(-fiberChange).toStringAsFixed(1)}%. Try adding more vegetables and whole grains.');
      }
    }

    // Sodium insights
    final sodiumChange = changes['sodium'] ?? 0;
    if (sodiumChange > 20) {
      insights.add('Your sodium intake increased by ${sodiumChange.toStringAsFixed(1)}%. Consider reducing processed foods.');
    } else if (sodiumChange < -20) {
      insights.add('Great job! Your sodium intake decreased by ${(-sodiumChange).toStringAsFixed(1)}%.');
    }

    return insights;
  }

  static List<String> _generateRecommendations(
    NutritionSummary current,
    NutritionSummary previous,
    Map<String, double> changes,
  ) {
    final recommendations = <String>[];

    // Protein recommendations
    if (current.averageDailyProtein < 50) {
      recommendations.add('Consider increasing protein intake. Try adding lean meats, fish, or legumes to your meals.');
    }

    // Fiber recommendations
    if (current.averageDailyFiber < 25) {
      recommendations.add('Increase fiber intake by adding more vegetables, fruits, and whole grains to your diet.');
    }

    // Sodium recommendations
    if (current.averageDailySodium > 2300) {
      recommendations.add('Reduce sodium intake by choosing fresh foods over processed ones and using herbs for flavor.');
    }

    // Meal frequency recommendations
    if (current.averageMealsPerDay < 2) {
      recommendations.add('Consider eating more regularly throughout the day for better energy levels.');
    }

    return recommendations;
  }

  static Future<UserNutritionGoals?> _getUserNutritionGoals(String? userId) async {
    final user = userId ?? _client.auth.currentUser?.id;
    if (user == null) return null;

    try {
      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', user)
          .maybeSingle();

      return response != null ? UserNutritionGoals.fromMap(response) : null;
    } catch (e) {
      print('Error fetching user goals: $e');
      return null;
    }
  }

  static Future<MealPatternAnalysis> _getMealPatternAnalysis(
    DateTime startDate,
    DateTime endDate,
    String? userId,
  ) async {
    return await getMealPatternAnalysis(
      startDate: startDate,
      endDate: endDate,
      userId: userId,
    );
  }

  static NutritionalInsight? _analyzeCalorieIntake(
    NutritionSummary summary,
    UserNutritionGoals goals,
  ) {
    final calorieRatio = summary.averageDailyCalories / goals.calorieGoal;
    
    if (calorieRatio < 0.8) {
      return NutritionalInsight(
        title: 'Low Calorie Intake',
        description: 'Your daily calorie intake is ${(calorieRatio * 100).toStringAsFixed(1)}% of your goal. Consider adding healthy snacks.',
        type: InsightType.warning,
        confidence: 0.9,
        actionableSteps: [
          'Add healthy snacks between meals',
          'Include more nutrient-dense foods',
          'Consider consulting a nutritionist',
        ],
        data: {'ratio': calorieRatio, 'goal': goals.calorieGoal},
      );
    } else if (calorieRatio > 1.2) {
      return NutritionalInsight(
        title: 'High Calorie Intake',
        description: 'Your daily calorie intake is ${(calorieRatio * 100).toStringAsFixed(1)}% of your goal.',
        type: InsightType.warning,
        confidence: 0.9,
        actionableSteps: [
          'Consider portion control',
          'Add more vegetables to meals',
          'Choose lower-calorie cooking methods',
        ],
        data: {'ratio': calorieRatio, 'goal': goals.calorieGoal},
      );
    } else if (calorieRatio >= 0.9 && calorieRatio <= 1.1) {
      return NutritionalInsight(
        title: 'Balanced Calorie Intake',
        description: 'Great job! Your calorie intake is well-balanced with your goals.',
        type: InsightType.positive,
        confidence: 0.95,
        actionableSteps: [
          'Continue maintaining this balance',
          'Focus on nutrient quality',
        ],
        data: {'ratio': calorieRatio, 'goal': goals.calorieGoal},
      );
    }
    
    return null;
  }

  static NutritionalInsight? _analyzeProteinIntake(
    NutritionSummary summary,
    UserNutritionGoals goals,
  ) {
    final proteinRatio = summary.averageDailyProtein / goals.proteinGoal;
    
    if (proteinRatio < 0.8) {
      return NutritionalInsight(
        title: 'Low Protein Intake',
        description: 'Your protein intake is ${(proteinRatio * 100).toStringAsFixed(1)}% of your goal.',
        type: InsightType.recommendation,
        confidence: 0.85,
        actionableSteps: [
          'Add lean meats, fish, or poultry to meals',
          'Include eggs, dairy, or plant-based proteins',
          'Consider protein-rich snacks',
        ],
        data: {'ratio': proteinRatio, 'goal': goals.proteinGoal},
      );
    }
    
    return null;
  }

  static NutritionalInsight? _analyzeFiberIntake(
    NutritionSummary summary,
    UserNutritionGoals goals,
  ) {
    final fiberRatio = summary.averageDailyFiber / goals.fiberGoal;
    
    if (fiberRatio < 0.7) {
      return NutritionalInsight(
        title: 'Low Fiber Intake',
        description: 'Your fiber intake is ${(fiberRatio * 100).toStringAsFixed(1)}% of your goal.',
        type: InsightType.recommendation,
        confidence: 0.8,
        actionableSteps: [
          'Add more vegetables to every meal',
          'Choose whole grains over refined grains',
          'Include fruits and nuts as snacks',
        ],
        data: {'ratio': fiberRatio, 'goal': goals.fiberGoal},
      );
    }
    
    return null;
  }

  static NutritionalInsight? _analyzeSodiumIntake(NutritionSummary summary) {
    if (summary.averageDailySodium > 2300) {
      return NutritionalInsight(
        title: 'High Sodium Intake',
        description: 'Your sodium intake (${summary.averageDailySodium.toStringAsFixed(0)}mg) exceeds the recommended limit of 2300mg.',
        type: InsightType.warning,
        confidence: 0.9,
        actionableSteps: [
          'Reduce processed and packaged foods',
          'Use herbs and spices instead of salt',
          'Choose fresh ingredients when possible',
        ],
        data: {'sodium': summary.averageDailySodium, 'limit': 2300},
      );
    }
    
    return null;
  }

  static List<NutritionalInsight> _analyzeMealPatterns(MealPatternAnalysis patterns) {
    final insights = <NutritionalInsight>[];

    // Analyze meal frequency
    final totalMeals = patterns.mealFrequencyByCategory.values.fold(0, (a, b) => a + b);
    if (totalMeals > 0) {
      final breakfastRatio = (patterns.mealFrequencyByCategory['breakfast'] ?? 0) / totalMeals;
      if (breakfastRatio < 0.2) {
        insights.add(NutritionalInsight(
          title: 'Irregular Breakfast Pattern',
          description: 'You\'re skipping breakfast frequently. Regular breakfast can improve energy and metabolism.',
          type: InsightType.recommendation,
          confidence: 0.8,
          actionableSteps: [
            'Try simple breakfast options like oatmeal or eggs',
            'Prepare breakfast the night before',
            'Start with small portions if you\'re not hungry',
          ],
          data: {'breakfast_ratio': breakfastRatio},
        ));
      }
    }

    return insights;
  }

  static Future<List<NutritionalInsight>> _analyzeTrends(
    DateTime startDate,
    DateTime endDate,
    String? userId,
  ) async {
    final insights = <NutritionalInsight>[];

    // Get weekly summaries for trend analysis
    final weeks = <NutritionSummary>[];
    var currentDate = startDate;
    
    while (currentDate.isBefore(endDate)) {
      final weekEnd = currentDate.add(const Duration(days: 6));
      final weekSummary = await getNutritionSummary(
        startDate: currentDate,
        endDate: weekEnd.isAfter(endDate) ? endDate : weekEnd,
        userId: userId,
      );
      weeks.add(weekSummary);
      currentDate = currentDate.add(const Duration(days: 7));
    }

    if (weeks.length >= 2) {
      // Analyze calorie trend
      final firstWeek = weeks.first;
      final lastWeek = weeks.last;
      final calorieTrend = (lastWeek.averageDailyCalories - firstWeek.averageDailyCalories) / firstWeek.averageDailyCalories;

      if (calorieTrend.abs() > 0.1) {
        insights.add(NutritionalInsight(
          title: calorieTrend > 0 ? 'Increasing Calorie Trend' : 'Decreasing Calorie Trend',
          description: 'Your calorie intake has ${calorieTrend > 0 ? 'increased' : 'decreased'} by ${(calorieTrend * 100).toStringAsFixed(1)}% over the period.',
          type: InsightType.trend,
          confidence: 0.7,
          actionableSteps: calorieTrend > 0 ? [
            'Monitor portion sizes',
            'Consider your activity level',
          ] : [
            'Ensure you\'re eating enough',
            'Add nutrient-dense foods',
          ],
          data: {'trend': calorieTrend},
        ));
      }
    }

    return insights;
  }

  static List<String> _generateMealPatternInsights(
    Map<String, int> mealFrequency,
    Map<String, double> averageNutrition,
    List<String> frequentRecipes,
    Map<String, double> weeklyPatterns,
  ) {
    final insights = <String>[];

    // Meal frequency insights
    final totalMeals = mealFrequency.values.fold(0, (a, b) => a + b);
    if (totalMeals > 0) {
      final breakfastRatio = (mealFrequency['breakfast'] ?? 0) / totalMeals;
      if (breakfastRatio < 0.2) {
        insights.add('You\'re skipping breakfast frequently. Consider adding a morning meal for better energy.');
      }
    }

    // Recipe variety insights
    if (frequentRecipes.length < 3) {
      insights.add('You have limited recipe variety. Try exploring new Filipino dishes for better nutrition diversity.');
    }

    return insights;
  }

  static double _getMetricValue(NutritionSummary summary, String metric) {
    switch (metric) {
      case 'calories':
        return summary.averageDailyCalories;
      case 'protein':
        return summary.averageDailyProtein;
      case 'carbs':
        return summary.averageDailyCarbs;
      case 'fat':
        return summary.averageDailyFat;
      case 'fiber':
        return summary.averageDailyFiber;
      case 'sodium':
        return summary.averageDailySodium;
      default:
        return 0.0;
    }
  }

  static String _formatDateLabel(DateTime date) {
    return '${date.month}/${date.day}';
  }

  static String _formatMonthLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }

  static String _getDayOfWeek(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Get multiple nutrition metrics trend data for comprehensive charts
  static Future<Map<String, List<ChartDataPoint>>> getMultipleNutritionTrendData({
    required AnalyticsPeriod period,
    String? userId,
  }) async {
    final metrics = ['calories', 'protein', 'carbs', 'fat'];
    final result = <String, List<ChartDataPoint>>{};

    for (final metric in metrics) {
      final data = await getNutritionTrendData(
        period: period,
        metric: metric,
        userId: userId,
      );
      result[metric] = data;
    }

    return result;
  }
}
