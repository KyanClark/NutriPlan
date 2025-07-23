import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_history_entry.dart';
import '../models/user_nutrition_goals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealTrackerScreen extends StatefulWidget {
  const MealTrackerScreen({super.key});

  @override
  State<MealTrackerScreen> createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends State<MealTrackerScreen> {
  DateTime selectedDate = DateTime.now();
  List<MealHistoryEntry> meals = [];
  UserNutritionGoals? goals;
  List<String> insights = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        meals = [];
        goals = null;
        insights = [];
        isLoading = false;
      });
      return;
    }
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startOfDayIso = startOfDay.toIso8601String();
    final endOfDayIso = endOfDay.toIso8601String();
    final mealRes = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
        .eq('user_id', user.id)
        .gte('completed_at', startOfDayIso)
        .lt('completed_at', endOfDayIso)
        .order('completed_at', ascending: true);
    final prefsRes = await Supabase.instance.client
        .from('user_preferences')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    final mealList = (mealRes as List?)?.map((m) => MealHistoryEntry.fromMap(m)).toList() ?? [];
    final userGoals = prefsRes != null ? UserNutritionGoals.fromMap(prefsRes) : null;
    final summary = _getDailySummary(mealList);
    final generatedInsights = userGoals != null ? _generateInsights(summary, userGoals) : [];
    setState(() {
      meals = mealList;
      goals = userGoals;
      isLoading = false;
    });
  }

  DailySummary _getDailySummary(List<MealHistoryEntry> meals) {
    double calories = 0, protein = 0, carbs = 0, fat = 0, sugar = 0, fiber = 0;
    for (final meal in meals) {
      calories += meal.calories;
      protein += meal.protein;
      carbs += meal.carbs;
      fat += meal.fat;
      sugar += meal.sugar;
      fiber += meal.fiber;
    }
    return DailySummary(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      sugar: sugar,
      fiber: fiber,
    );
  }

  List<String> _generateInsights(DailySummary summary, UserNutritionGoals goals) {
    List<String> insights = [];
    if (summary.protein < 0.8 * goals.proteinGoal) {
      insights.add("Try to add more protein to your meals.");
    }
    if (summary.sugar > goals.sugarGoal) {
      insights.add("You've exceeded your sugar goal today.");
    }
    if ((summary.calories - goals.calorieGoal).abs() < 0.1 * goals.calorieGoal) {
      insights.add("Great job staying on track with your calories!");
    }
    if (summary.fiber < 0.5 * goals.fiberGoal) {
      insights.add("Consider adding more fiber-rich foods.");
    }
    if (insights.isEmpty) {
      insights.add("You're doing great! Keep it up!");
    }
    return insights;
  }

  void _changeDate(int offset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: offset));
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _getDailySummary(meals);
    return Scaffold(
      // Remove the AppBar and use a custom back button
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Date navigation row (moved below back button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDate(-1),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDate(1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Use side-by-side layout if wide enough, else stack vertically
                          if (constraints.maxWidth > 700) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nutritional summary
                                SizedBox(
                                  width: 350,
                                  child: _NutritionalSummary(
                                    summary: summary,
                                    goals: goals,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Finished meals
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text('Finished Meals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      const SizedBox(height: 8),
                                      if (insights.isNotEmpty)
                                        Card(
                                          color: Colors.green[50],
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(insights.first, style: const TextStyle(fontSize: 16)),
                                          ),
                                        ),
                                      Expanded(
                                        child: meals.isEmpty
                                            ? const Center(child: Text('No meals recorded for this day.'))
                                            : ListView.builder(
                                                itemCount: meals.length,
                                                itemBuilder: (context, idx) {
                                                  return _MealLogCard(meal: meals[idx]);
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Stacked layout for mobile
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _NutritionalSummary(
                                  summary: summary,
                                  goals: goals,
                                ),
                                const SizedBox(height: 12),
                                const Text('Finished Meals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(height: 8),
                                if (insights.isNotEmpty)
                                  Card(
                                    color: Colors.green[50],
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(insights.first, style: const TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                Expanded(
                                  child: meals.isEmpty
                                      ? const Center(child: Text('No meals recorded for this day.'))
                                      : ListView.builder(
                                          itemCount: meals.length,
                                          itemBuilder: (context, idx) {
                                            return _MealLogCard(meal: meals[idx]);
                                          },
                                        ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailySummary {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  DailySummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.fiber,
  });
}

class _NutritionalSummary extends StatelessWidget {
  final DailySummary summary;
  final UserNutritionGoals? goals;
  const _NutritionalSummary({required this.summary, required this.goals});

  Widget _macroContainer(String label, double value, double? goal, Color color) {
    return Container(
      width: 85, // smaller
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(8), // smaller
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8), // smaller radius
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
          const SizedBox(height: 2),
          Text('${value.toStringAsFixed(1)} g', style: TextStyle(fontSize: 13, color: color)),
          if (goal != null)
            Text('Goal: ${goal.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0), // reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nutritional Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), // smaller font
            const SizedBox(height: 6),
            // Calories container at the top
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18), // smaller
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12), // smaller radius
                ),
                child: Text(
                  '${summary.calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange), // smaller font
                ),
              ),
            ),
            // Macros in containers
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                _macroContainer('Protein', summary.protein, goals?.proteinGoal, Colors.blue),
                _macroContainer('Carbs', summary.carbs, goals?.carbGoal, Colors.purple),
                _macroContainer('Fat', summary.fat, goals?.fatGoal, Colors.red),
                _macroContainer('Sugar', summary.sugar, goals?.sugarGoal, Colors.brown),
                _macroContainer('Fiber', summary.fiber, goals?.fiberGoal, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MealLogCard extends StatefulWidget {
  final MealHistoryEntry meal;
  const _MealLogCard({required this.meal});

  @override
  State<_MealLogCard> createState() => _MealLogCardState();
}

class _MealLogCardState extends State<_MealLogCard> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => setState(() => expanded = !expanded),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      meal.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(DateFormat('h:mm a').format(meal.completedAt), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('${meal.calories.toStringAsFixed(0)} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MacroChip(label: 'Protein', value: meal.protein, color: Colors.blue),
                    _MacroChip(label: 'Carbs', value: meal.carbs, color: Colors.purple),
                    _MacroChip(label: 'Fat', value: meal.fat, color: Colors.red),
                    _MacroChip(label: 'Sugar', value: meal.sugar, color: Colors.brown),
                    _MacroChip(label: 'Fiber', value: meal.fiber, color: Colors.green),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MacroChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: ${value.toStringAsFixed(1)}g', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
} 