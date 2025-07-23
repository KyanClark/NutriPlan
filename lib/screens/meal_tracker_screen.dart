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
      appBar: AppBar(
        title: const Text('Meal Tracker'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDate(-1),
          ),
          Center(
            child: Text(
              DateFormat('MMM d, yyyy').format(selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NutritionalSummary(
                    summary: summary,
                    goals: goals,
                  ),
                  const SizedBox(height: 12),
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

  Widget _buildBar(String label, double value, double? goal, Color color) {
    final percent = (goal != null && goal > 0) ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(width: 8),
          Text(goal != null ? '${value.toStringAsFixed(0)}/${goal.toStringAsFixed(0)}' : value.toStringAsFixed(0)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nutritional Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            _buildBar('Calories', summary.calories, goals?.calorieGoal, Colors.orange),
            _buildBar('Protein', summary.protein, goals?.proteinGoal, Colors.blue),
            _buildBar('Carbs', summary.carbs, goals?.carbGoal, Colors.purple),
            _buildBar('Fat', summary.fat, goals?.fatGoal, Colors.red),
            _buildBar('Sugar', summary.sugar, goals?.sugarGoal, Colors.brown),
            _buildBar('Fiber', summary.fiber, goals?.fiberGoal, Colors.green),
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
                Row(
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