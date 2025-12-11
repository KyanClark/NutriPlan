import '../models/user_nutrition_goals.dart';

/// Service class for building AI nutrition analysis prompts
class AINutritionPrompts {
  /// Build nutrition analysis prompt for comprehensive insights
  static String buildNutritionPrompt(
    Map<String, dynamic> weeklyData,
    Map<String, dynamic> monthlyData,
    UserNutritionGoals? goals, {
    List<String> healthConditions = const [],
  }) {
    final weeklyAverages = weeklyData['averages'] as Map<String, double>;
    final monthlyAverages = monthlyData['averages'] as Map<String, double>;

    final calorieGoal = goals?.calorieGoal ?? 2000.0;
    final proteinGoal = goals?.proteinGoal ?? 150.0;
    final carbGoal = goals?.carbGoal ?? 250.0;
    final fatGoal = goals?.fatGoal ?? 65.0;

    return '''
As a professional nutritionist and dietician with 10+ years of experience, analyze this user's comprehensive nutrition data and provide personalized, actionable insights.

USER'S NUTRITION PROFILE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WEEKLY AVERAGES:
• Calories: ${weeklyAverages['calories']!.toStringAsFixed(0)} kcal (Goal: ${calorieGoal.toStringAsFixed(0)} kcal) - ${((weeklyAverages['calories']! / calorieGoal) * 100).toStringAsFixed(0)}% of goal
• Protein: ${weeklyAverages['protein']!.toStringAsFixed(1)}g (Goal: ${proteinGoal.toStringAsFixed(0)}g) - ${((weeklyAverages['protein']! / proteinGoal) * 100).toStringAsFixed(0)}% of goal
• Carbohydrates: ${weeklyAverages['carbs']!.toStringAsFixed(1)}g (Goal: ${carbGoal.toStringAsFixed(0)}g) - ${((weeklyAverages['carbs']! / carbGoal) * 100).toStringAsFixed(0)}% of goal
• Fat: ${weeklyAverages['fat']!.toStringAsFixed(1)}g (Goal: ${fatGoal.toStringAsFixed(0)}g) - ${((weeklyAverages['fat']! / fatGoal) * 100).toStringAsFixed(0)}% of goal
• Fiber: ${weeklyAverages['fiber']!.toStringAsFixed(1)}g (Recommended: 25-30g daily)
• Sugar: ${weeklyAverages['sugar']!.toStringAsFixed(1)}g (Recommended: <50g daily)

MONTHLY TRENDS:
• Average Calories: ${monthlyAverages['calories']!.toStringAsFixed(0)} kcal
• Average Protein: ${monthlyAverages['protein']!.toStringAsFixed(1)}g
• Average Carbohydrates: ${monthlyAverages['carbs']!.toStringAsFixed(1)}g
• Average Fat: ${monthlyAverages['fat']!.toStringAsFixed(1)}g
• Average Fiber: ${monthlyAverages['fiber']!.toStringAsFixed(1)}g
• Average Sugar: ${monthlyAverages['sugar']!.toStringAsFixed(1)}g
• Average Sodium: ${monthlyAverages['sodium']?.toStringAsFixed(1) ?? '0.0'}mg

${healthConditions.isNotEmpty && !healthConditions.contains('none') ? '''
⚠️ CRITICAL HEALTH CONDITIONS TO MONITOR:
${healthConditions.map((c) {
  switch (c.toLowerCase()) {
    case 'diabetes':
      return '• Diabetes: Monitor carbs (<60g per meal), sugar (<15g per meal), and fiber (>3g per meal). Weekly average carbs: ${weeklyAverages['carbs']!.toStringAsFixed(1)}g, sugar: ${weeklyAverages['sugar']!.toStringAsFixed(1)}g, fiber: ${weeklyAverages['fiber']!.toStringAsFixed(1)}g';
    case 'hypertension':
    case 'high_blood_pressure':
      return '• Hypertension: Monitor sodium (<500mg per meal, <2000mg daily). Weekly average sodium: ${weeklyAverages['sodium']?.toStringAsFixed(1) ?? '0.0'}mg';
    default:
      return '• $c: Monitor general health metrics';
  }
}).join('\n')}

PRIORITY: Pay special attention to metrics that affect these health conditions. Highlight any concerns or violations immediately.
''' : ''}

ANALYSIS REQUIRED:
Please provide comprehensive insights covering:

1. STRENGTHS & ACHIEVEMENTS:
   - What nutrition patterns are working well?
   - Which macro/micro nutrients are on track?
   - Positive habits to celebrate and maintain

2. AREAS FOR IMPROVEMENT:
   - Specific macro/micro nutrient gaps
   - Nutritional imbalances to address
   - Actionable steps to reach goals

3. PERSONALIZED RECOMMENDATIONS:
   - Specific food suggestions based on deficiencies
   - Meal timing and portion recommendations
   - Lifestyle adjustments for better nutrition

4. MOTIVATION & PROGRESS:
   - Highlights of positive trends
   - Progress tracking metrics
   - Encouragement for continued success

STYLE GUIDE:
- Use specific numbers and percentages
- Provide actionable, implementable advice
- Balance encouragement with practical guidance
- Keep insights professional yet warm
- Focus on sustainable habits
- Use bullet points and clear structure

Generate a comprehensive analysis that empowers this user to optimize their nutrition journey.
''';
  }

  /// Build prompt for structured weekly insights
  static String buildWeeklyInsightsPrompt(
    Map<String, dynamic> weeklyData,
    Map<String, dynamic> monthlyData,
    UserNutritionGoals? goals, {
    List<String> availableRecipes = const [],
    bool hasMealsToday = true,
    List<String> healthConditions = const [],
  }) {
    final weeklyAverages = weeklyData['averages'] as Map<String, double>? ?? {};
    final dailyData = weeklyData['dailyData'] as Map<String, Map<String, double>>? ?? {};
    
    final calorieGoal = goals?.calorieGoal ?? 2000.0;
    final proteinGoal = goals?.proteinGoal ?? 150.0;
    final carbGoal = goals?.carbGoal ?? 250.0;
    final fatGoal = goals?.fatGoal ?? 65.0;

    // Calculate consistency metrics
    final dailyCalories = dailyData.values.map((day) => day['calories'] ?? 0).toList();
    final avgCalories = weeklyAverages['calories'] ?? 0;
    final calorieConsistency = dailyCalories.where((c) => (c - avgCalories).abs() < avgCalories * 0.2).length;
    
    final proteinConsistency = dailyData.values.where((day) => (day['protein'] ?? 0) >= proteinGoal * 0.8).length;
    final goalAchievement = dailyCalories.where((c) => c >= calorieGoal * 0.8).length;

    return '''
As a professional dietician analyzing this user's weekly nutrition data, generate exactly 3 personalized, actionable insights in this JSON format:

{
  "insights": [
    {
      "title": "Insight Title (max 6 words)",
      "description": "Specific actionable description with numbers, percentages, and encouragement"
    },
    {
      "title": "Insight Title (max 6 words)", 
      "description": "Specific actionable description with numbers, percentages, and encouragement"
    },
    {
      "title": "Insight Title (max 6 words)",
      "description": "Specific actionable description with numbers, percentages, and encouragement"
    }
  ]
}

NUTRITION DATA ANALYSIS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WEEKLY AVERAGES:
• Daily Calories: ${avgCalories.toStringAsFixed(0)} kcal (Goal: ${calorieGoal.toStringAsFixed(0)} kcal) - ${((avgCalories / calorieGoal) * 100).toStringAsFixed(0)}% of target
• Daily Protein: ${(weeklyAverages['protein'] ?? 0).toStringAsFixed(1)}g (Goal: ${proteinGoal.toStringAsFixed(0)}g) - ${(((weeklyAverages['protein'] ?? 0) / proteinGoal) * 100).toStringAsFixed(0)}% of target
• Daily Carbohydrates: ${(weeklyAverages['carbs'] ?? 0).toStringAsFixed(1)}g (Goal: ${carbGoal.toStringAsFixed(0)}g) - ${(((weeklyAverages['carbs'] ?? 0) / carbGoal) * 100).toStringAsFixed(0)}% of target
• Daily Fat: ${(weeklyAverages['fat'] ?? 0).toStringAsFixed(1)}g (Goal: ${fatGoal.toStringAsFixed(0)}g) - ${(((weeklyAverages['fat'] ?? 0) / fatGoal) * 100).toStringAsFixed(0)}% of target
• Daily Fiber: ${(weeklyAverages['fiber'] ?? 0).toStringAsFixed(1)}g (Recommended: 25-30g)
• Daily Sugar: ${(weeklyAverages['sugar'] ?? 0).toStringAsFixed(1)}g (Recommended: <50g)
• Daily Sodium: ${(weeklyAverages['sodium'] ?? 0).toStringAsFixed(1)}mg (Recommended: <2300mg, <2000mg for hypertension)

${healthConditions.isNotEmpty && !healthConditions.contains('none') ? '''
⚠️ HEALTH CONDITIONS TO MONITOR:
${healthConditions.map((c) {
  switch (c.toLowerCase()) {
    case 'diabetes':
      final avgCarbs = weeklyAverages['carbs'] ?? 0;
      final avgSugar = weeklyAverages['sugar'] ?? 0;
      final avgFiber = weeklyAverages['fiber'] ?? 0;
      final carbsStatus = avgCarbs > 420 ? '⚠️ HIGH' : avgCarbs > 350 ? '⚠️ MODERATE' : '✅ GOOD';
      final sugarStatus = avgSugar > 105 ? '⚠️ HIGH' : avgSugar > 70 ? '⚠️ MODERATE' : '✅ GOOD';
      final fiberStatus = avgFiber < 21 ? '⚠️ LOW' : avgFiber < 25 ? '⚠️ MODERATE' : '✅ GOOD';
      return '• Diabetes: Carbs ${avgCarbs.toStringAsFixed(1)}g/day ($carbsStatus), Sugar ${avgSugar.toStringAsFixed(1)}g/day ($sugarStatus), Fiber ${avgFiber.toStringAsFixed(1)}g/day ($fiberStatus)';
    case 'hypertension':
    case 'high_blood_pressure':
      final avgSodium = weeklyAverages['sodium'] ?? 0;
      final sodiumStatus = avgSodium > 14000 ? '⚠️ HIGH' : avgSodium > 10000 ? '⚠️ MODERATE' : '✅ GOOD';
      return '• Hypertension: Sodium ${avgSodium.toStringAsFixed(1)}mg/day ($sodiumStatus) - Target: <14000mg/week (<2000mg/day)';
    default:
      return '• $c: Monitor general health metrics';
  }
}).join('\n')}

CRITICAL: If any health condition metrics are in ⚠️ status, prioritize addressing those in insights. Highlight concerns immediately.
''' : ''}

CONSISTENCY METRICS:
• Days with consistent calorie intake: $calorieConsistency/7 days (${((calorieConsistency / 7) * 100).toStringAsFixed(0)}% consistency)
• Days meeting protein goals: $proteinConsistency/7 days (${((proteinConsistency / 7) * 100).toStringAsFixed(0)}% achievement)
• Days meeting calorie goals: $goalAchievement/7 days (${((goalAchievement / 7) * 100).toStringAsFixed(0)}% achievement)

AVAILABLE RECIPES:
${availableRecipes.isEmpty ? 'No recipes available' : availableRecipes.take(50).join(', ')}
${availableRecipes.length > 50 ? '... and ${availableRecipes.length - 50} more recipes' : ''}

TODAY'S MEAL LOGGING STATUS:
${hasMealsToday ? '✅ User has logged meals for today' : '⚠️ User has NOT logged any meals for today yet'}

TASK:
${hasMealsToday 
  ? 'Generate exactly 3 insights that provide:\n1. CELEBRATION: Highlight positive patterns and achievements\n2. IMPROVEMENT: Identify specific nutrient gaps with actionable solutions (RECOMMEND SPECIFIC MEALS from the available recipes list above)\n3. MOTIVATION: Provide progress tracking and encouragement'
  : 'IMPORTANT: User has NOT logged any meals for today. Generate exactly 1-2 insights that:\n1. Gently remind them to start logging their meals for today\n2. Explain the benefits of meal tracking (optional second insight)\nDO NOT generate random nutrition advice when they haven\'t logged meals yet. Focus on encouraging meal logging first.'}

REQUIREMENTS:
- Titles must be concise (max 8 words)
- Descriptions must include specific numbers and percentages (when applicable)
- Focus on actionable, implementable advice
- IMPORTANT: When recommending meals, ONLY use recipe names from the "AVAILABLE RECIPES" list above
- If recommending meals, mention 1-3 specific recipe names that would help address nutrient gaps
- Balance encouragement with practical guidance
- Make each insight unique and valuable
${!hasMealsToday ? '- CRITICAL: If user hasn\'t logged meals today, prioritize reminding them to log meals instead of giving random nutrition advice' : ''}

Return ONLY valid JSON.
''';
  }
}

