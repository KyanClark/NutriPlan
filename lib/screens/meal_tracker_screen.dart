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
  Map<DateTime, bool> datesWithMeals = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchDatesWithMeals();
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
    // Fetch a 2-day UTC window to ensure we get all possible local meals
    final startOfWindow = DateTime(selectedDate.year, selectedDate.month, selectedDate.day).subtract(const Duration(hours: 12));
    final endOfWindow = startOfWindow.add(const Duration(days: 2));
    final mealRes = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
        .eq('user_id', user.id)
        .gte('completed_at', startOfWindow.toUtc().toIso8601String())
        .lt('completed_at', endOfWindow.toUtc().toIso8601String())
        .order('completed_at', ascending: true);
    final prefsRes = await Supabase.instance.client
        .from('user_preferences')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
    // Filter meals to only those that match the selected local day
    final startOfDayLocal = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDayLocal = startOfDayLocal.add(const Duration(days: 1));
    final mealList = (mealRes as List?)?.map((m) => MealHistoryEntry.fromMap(m)).where((meal) {
      final localCompleted = meal.completedAt.toLocal();
      return localCompleted.isAfter(startOfDayLocal.subtract(const Duration(microseconds: 1))) &&
             localCompleted.isBefore(endOfDayLocal);
    }).toList() ?? [];
    final userGoals = prefsRes != null ? UserNutritionGoals.fromMap(prefsRes) : null;
    final summary = _getDailySummary(mealList);
    final generatedInsights = userGoals != null ? _generateInsights(summary, userGoals, mealList) : [];
    setState(() {
      meals = mealList;
      goals = userGoals;
      insights = generatedInsights.cast<String>();
      isLoading = false;
    });
  }

  Future<void> _fetchDatesWithMeals() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    // Fetch all meal records for the current month
    final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    
    final mealRes = await Supabase.instance.client
        .from('meal_plan_history')
        .select('completed_at')
        .eq('user_id', user.id)
        .gte('completed_at', startOfMonth.toUtc().toIso8601String())
        .lt('completed_at', endOfMonth.add(const Duration(days: 1)).toUtc().toIso8601String());
    
    final Map<DateTime, bool> newDatesWithMeals = {};
    for (final meal in mealRes as List) {
      final completedAt = DateTime.parse(meal['completed_at']).toLocal();
      final dateKey = DateTime(completedAt.year, completedAt.month, completedAt.day);
      newDatesWithMeals[dateKey] = true;
    }
    
    setState(() {
      datesWithMeals = newDatesWithMeals;
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

  List<String> _generateInsights(DailySummary summary, UserNutritionGoals goals, List<MealHistoryEntry> meals) {
    List<String> insights = [];
    
    // AI-powered nutritional insights based on eating patterns
    if (summary.protein < 0.8 * goals.proteinGoal) {
      insights.add("💪 Add more protein! Try lean meats, eggs, or legumes to reach your ${goals.proteinGoal}g goal.");
    }
    
    if (summary.carbs < 0.7 * goals.carbGoal) {
      insights.add("🌾 Low on carbs today. Consider whole grains, fruits, or starchy vegetables for energy.");
    }
    
    if (summary.fat < 0.6 * goals.fatGoal) {
      insights.add("🥑 Healthy fats are important! Add nuts, avocados, or olive oil to your meals.");
    }
    
    if (summary.sugar > goals.sugarGoal) {
      insights.add("🍭 Sugar intake exceeded! Try natural sweeteners or reduce processed foods.");
    }
    
    if (summary.fiber < 0.5 * goals.fiberGoal) {
      insights.add("🥬 More fiber needed! Add vegetables, fruits, and whole grains for better digestion.");
    }
    
    // Calorie balance insights
    if (summary.calories < 0.7 * goals.calorieGoal) {
      insights.add("🍽️ You're under your calorie goal. Consider adding a healthy snack or larger portions.");
    } else if (summary.calories > 1.1 * goals.calorieGoal) {
      insights.add("⚖️ Calorie intake is high today. Focus on portion control and nutrient-dense foods.");
    } else if ((summary.calories - goals.calorieGoal).abs() < 0.1 * goals.calorieGoal) {
      insights.add("🎯 Perfect calorie balance! You're right on track with your daily goal.");
    }
    
    // Meal timing insights
    if (meals.length < 3) {
      insights.add("⏰ Consider eating 3-4 meals per day for better metabolism and energy levels.");
    }
    
    // If no specific insights, provide general encouragement
    if (insights.isEmpty) {
      insights.add("🌟 Great job today! Your meals are well-balanced and nutritious.");
    }
    
    // Limit to 3 most important insights
    return insights.take(3).toList();
  }



  void _showCalendar() {
    showDialog(
      context: context,
      builder: (context) => _CalendarDialog(
        selectedDate: selectedDate,
        datesWithMeals: datesWithMeals,
        onDateSelected: (date) {
          setState(() {
            selectedDate = date;
          });
          Navigator.of(context).pop();
          _fetchData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _getDailySummary(meals);
    
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50), // Green background like the design
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Date container that can be tapped
            GestureDetector(
              onTap: _showCalendar,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, color: const Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM d, EEE').format(selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_drop_down, color: const Color(0xFF4CAF50)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main nutrition display
                              _MainNutritionDisplay(
                                summary: summary,
                                goals: goals,
                              ),
                              const SizedBox(height: 30),
                              // Finished meals section
                              const Text(
                                'Daily',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (insights.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.green[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lightbulb, color: Colors.green[600]),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          insights.first,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.green[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (meals.isEmpty)
                                SizedBox(
                                  height: 200,
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.restaurant,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No meals recorded for this day',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...meals.map((meal) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _MealLogCard(meal: meal),
                                )),
                              // Add bottom padding for better scrolling
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
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
                        Text(DateFormat('h:mm a').format(meal.completedAt.toLocal()), style: const TextStyle(color: Colors.grey)),
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
                    _MacroChip(label: 'Protein', value: meal.protein, color: Colors.blue, unit: 'g'),
                    _MacroChip(label: 'Carbs', value: meal.carbs, color: Colors.green, unit: 'g'),
                    _MacroChip(label: 'Fat', value: meal.fat, color: Colors.orange, unit: 'g'),
                    _MacroChip(label: 'Sugar', value: meal.sugar, color: Colors.pink, unit: 'g'),
                    _MacroChip(label: 'Fiber', value: meal.fiber, color: Colors.purple, unit: 'g'),
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
  final String unit;
  const _MacroChip({required this.label, required this.value, required this.color, required this.unit});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: ${value.toStringAsFixed(1)}$unit', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _MainNutritionDisplay extends StatelessWidget {
  final DailySummary summary;
  final UserNutritionGoals? goals;
  
  const _MainNutritionDisplay({
    required this.summary, 
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    final calorieGoal = goals?.calorieGoal ?? 2000.0;
    final progress = summary.calories / calorieGoal;
    final remaining = calorieGoal - summary.calories;
    
    return Column(
      children: [
        // Main calorie circle with progress
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 1.0 ? Colors.red : Colors.orange,
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  summary.calories.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'KCAL EATEN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Eaten and Remaining calories stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(
              value: summary.calories.toStringAsFixed(0),
              label: 'EATEN',
              icon: Icons.restaurant,
              color: Colors.blue,
            ),
            _StatItem(
              value: remaining > 0 ? remaining.toStringAsFixed(0) : '0',
              label: 'REMAINING',
              icon: Icons.trending_up,
              color: remaining > 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 30),
        
        // All 6 Macro bars
        Column(
          children: [
            _MacroBar(
              label: 'PROTEIN',
              value: summary.protein,
              goal: goals?.proteinGoal ?? 75,
              color: Colors.blue,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _MacroBar(
              label: 'CARBS',
              value: summary.carbs,
              goal: goals?.carbGoal ?? 250,
              color: Colors.green,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _MacroBar(
              label: 'FAT',
              value: summary.fat,
              goal: goals?.fatGoal ?? 70,
              color: Colors.orange,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _MacroBar(
              label: 'SUGAR',
              value: summary.sugar,
              goal: goals?.sugarGoal ?? 50,
              color: Colors.pink,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _MacroBar(
              label: 'FIBER',
              value: summary.fiber,
              goal: goals?.fiberGoal ?? 30,
              color: Colors.purple,
              unit: 'g',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  final String unit;
  
  const _MacroBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / goal).clamp(0.0, 1.0);
    final remaining = goal - value;
    
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${remaining > 0 ? remaining.toStringAsFixed(0) : '0'}$unit left',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Map<DateTime, bool> datesWithMeals;
  final Function(DateTime) onDateSelected;
  
  const _CalendarDialog({
    required this.selectedDate,
    required this.datesWithMeals,
    required this.onDateSelected,
  });

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime currentMonth;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    selectedDate = widget.selectedDate;
  }

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    });
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = currentMonth;
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    List<DateTime> days = [];
    
    // Add days from previous month to fill first week
    final firstWeekday = firstDay.weekday;
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }
    
    // Add days of current month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, i));
    }
    
    // Add days from next month to fill last week
    final lastWeekday = lastDay.weekday;
    for (int i = 1; i <= 7 - lastWeekday; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Weekday headers
            Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            
            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isCurrentMonth = day.month == currentMonth.month;
                final isSelected = day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;
                final hasMeals = widget.datesWithMeals[DateTime(day.year, day.month, day.day)] ?? false;
                
                return GestureDetector(
                  onTap: () {
                    if (isCurrentMonth) {
                      setState(() {
                        selectedDate = day;
                      });
                      widget.onDateSelected(day);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : hasMeals
                              ? Colors.green[100]
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: hasMeals && !isSelected
                          ? Border.all(color: Colors.green[300]!, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isCurrentMonth
                                  ? Colors.black
                                  : Colors.grey,
                          fontWeight: isSelected || hasMeals
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            
            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
} 