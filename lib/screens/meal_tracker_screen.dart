import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_history_entry.dart';
import '../models/user_nutrition_goals.dart';
import '../widgets/meal_log_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealTrackerScreen extends StatefulWidget {
  final bool showBackButton;
  const MealTrackerScreen({super.key, this.showBackButton = false});

  @override
  State<MealTrackerScreen> createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends State<MealTrackerScreen> {
  DateTime selectedDate = DateTime.now();
  List<MealHistoryEntry> meals = [];
  UserNutritionGoals? goals;
  bool isLoading = true;
  Map<DateTime, bool> datesWithMeals = {};
  Map<DateTime, int> monthlyMealCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchDatesWithMeals();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          meals = [];
          goals = null;
          isLoading = false;
        });
        return;
      }

      // Fetch meals for the selected date
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final mealRes = await Supabase.instance.client
          .from('meal_plan_history')
          .select()
          .eq('user_id', user.id)
          .gte('completed_at', startOfDay.toUtc().toIso8601String())
          .lt('completed_at', endOfDay.toUtc().toIso8601String())
          .order('completed_at', ascending: true);

      // Parse meal data with better error handling
      final mealList = <MealHistoryEntry>[];
      if (mealRes is List) {
        for (final mealData in mealRes) {
          try {
            final meal = MealHistoryEntry.fromMap(mealData);
            mealList.add(meal);
          } catch (e) {
            print('Error parsing meal data: $e');
          }
        }
      }

      // Fetch user nutrition goals
      final prefsRes = await Supabase.instance.client
          .from('user_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      final userGoals = prefsRes != null ? UserNutritionGoals.fromMap(prefsRes) : null;

      setState(() {
        meals = mealList;
        goals = userGoals;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching meal data: $e');
      setState(() {
        meals = [];
        goals = null;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDatesWithMeals() async {
    try {
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
      final Map<DateTime, int> newMonthlyMealCounts = {};
      
      if (mealRes is List) {
        for (final meal in mealRes) {
          try {
            final completedAt = DateTime.parse(meal['completed_at']).toLocal();
            final dateKey = DateTime(completedAt.year, completedAt.month, completedAt.day);
            newDatesWithMeals[dateKey] = true;
            newMonthlyMealCounts[dateKey] = (newMonthlyMealCounts[dateKey] ?? 0) + 1;
          } catch (e) {
            print('Error parsing meal date: $e');
          }
        }
      }
      
      setState(() {
        datesWithMeals = newDatesWithMeals;
        monthlyMealCounts = newMonthlyMealCounts;
      });
    } catch (e) {
      print('Error fetching dates with meals: $e');
    }
  }

  DailySummary _getDailySummary(List<MealHistoryEntry> meals) {
    double calories = 0, protein = 0, carbs = 0, fat = 0, sugar = 0, fiber = 0, sodium = 0, cholesterol = 0;
    for (final meal in meals) {
      calories += meal.calories;
      protein += meal.protein;
      carbs += meal.carbs;
      fat += meal.fat;
      sugar += meal.sugar;
      fiber += meal.fiber;
      sodium += meal.sodium;
      cholesterol += meal.cholesterol;
    }
    return DailySummary(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      sugar: sugar,
      fiber: fiber,
      sodium: sodium,
      cholesterol: cholesterol,
    );
  }

  void _showCalendar() {
    showDialog(
      context: context,
      builder: (context) => _CalendarDialog(
        selectedDate: selectedDate,
        datesWithMeals: datesWithMeals,
        mealCounts: monthlyMealCounts,
        onDateSelected: (date) {
          setState(() {
            selectedDate = date;
          });
          Navigator.of(context).pop();
          _fetchData();
        },
        onRefreshMonth: () {
          _fetchDatesWithMeals();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _getDailySummary(meals);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and profile icon
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (widget.showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  else
                    const SizedBox(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Meal Tracker',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Track your nutrition goals',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab buttons (Today, Weekly, Monthly)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Today',
                    isSelected: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Weekly',
                    isSelected: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Monthly',
                    isSelected: false,
                    onTap: () {},
                  ),
                  const Spacer(),
                  // Calendar button
                  GestureDetector(
                    onTap: _showCalendar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Today's Calories big green card (like the design)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Calories",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            summary.calories.toStringAsFixed(0),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            'consumed',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Goal: ${goals?.calorieGoal?.toStringAsFixed(0) ?? '2000'} cal',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Remaining: ${((goals?.calorieGoal ?? 2000) - summary.calories).toStringAsFixed(0)} cal',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Text(
                                            'Burned: 320 cal',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Circular progress indicator
                                    SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Stack(
                                        children: [
                                          CircularProgressIndicator(
                                            value: (summary.calories / (goals?.calorieGoal ?? 2000)).clamp(0.0, 1.0),
                                            strokeWidth: 8,
                                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                          Center(
                                            child: Text(
                                              '${((summary.calories / (goals?.calorieGoal ?? 2000)) * 100).toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Macro cards in 2x2 grid (like the design)
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                            children: [
                              _MacroCard(
                                icon: Icons.fitness_center,
                                title: 'Protein',
                                value: summary.protein.toStringAsFixed(0),
                                unit: 'g',
                                goal: goals?.proteinGoal ?? 165,
                                color: Colors.blue,
                              ),
                              _MacroCard(
                                icon: Icons.grain,
                                title: 'Carbs',
                                value: summary.carbs.toStringAsFixed(0),
                                unit: 'g',
                                goal: goals?.carbGoal ?? 275,
                                color: Colors.orange,
                              ),
                              _MacroCard(
                                icon: Icons.water_drop,
                                title: 'Fat',
                                value: summary.fat.toStringAsFixed(0),
                                unit: 'g',
                                goal: goals?.fatGoal ?? 75,
                                color: Colors.purple,
                              ),
                              _MacroCard(
                                icon: Icons.local_florist,
                                title: 'Fiber',
                                value: summary.fiber.toStringAsFixed(0),
                                unit: 'g',
                                goal: goals?.fiberGoal ?? 25,
                                color: Colors.green,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Today's Meals section with Add Meal button (like the design)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Today's Meals",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to recipes or meal planner
                                  Navigator.pushNamed(context, '/recipes');
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Meal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Meals list or empty state
                          if (meals.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No meals recorded for today',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first meal to start tracking',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...meals.map((meal) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: MealLogCard(meal: meal),
                            )),
                            
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab Button Widget
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Macro Card Widget (matches the design)
class _MacroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final double goal;
  final Color color;
  
  const _MacroCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (double.tryParse(value) ?? 0) / goal;
    final percentage = (progress * 100).toStringAsFixed(0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'of ${goal.toStringAsFixed(0)}${unit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      'goal',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 4,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    Center(
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// DailySummary class
class DailySummary {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final double cholesterol;
  
  DailySummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.fiber,
    required this.sodium,
    required this.cholesterol,
  });
}

// Calendar dialog (simplified)
class _CalendarDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Map<DateTime, bool> datesWithMeals;
  final Map<DateTime, int> mealCounts;
  final Function(DateTime) onDateSelected;
  final VoidCallback? onRefreshMonth;
  
  const _CalendarDialog({
    required this.selectedDate,
    required this.datesWithMeals,
    required this.mealCounts,
    required this.onDateSelected,
    this.onRefreshMonth,
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(currentMonth),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
