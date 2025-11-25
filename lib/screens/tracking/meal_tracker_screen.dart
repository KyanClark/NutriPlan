import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/meal_history_entry.dart';
import '../../models/user_nutrition_goals.dart';
import '../../widgets/meal_log_card.dart';
import '../profile/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealTrackerScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onTabActivated;
  final DateTime? initialDate;
  const MealTrackerScreen({super.key, this.showBackButton = false, this.onTabActivated, this.initialDate});

  @override
  State<MealTrackerScreen> createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends State<MealTrackerScreen> {
  late DateTime selectedDate;
  List<MealHistoryEntry> meals = [];
  UserNutritionGoals? goals;
  bool isLoading = true;
  Map<DateTime, bool> datesWithMeals = {};
  Map<DateTime, int> monthlyMealCounts = {};
  String? _avatarUrl;
  static String? _cachedAvatarUrl;
  static bool _hasFetchedAvatar = false;
  
  // Flag to track if widget is mounted
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
    _fetchData();
    _fetchDatesWithMeals();
    // Only fetch if not already cached
    if (!_hasFetchedAvatar) {
      _fetchUserAvatar();
    } else {
      _avatarUrl = _cachedAvatarUrl;
    }
  }
  
  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // Build tab content based on selected tab
  Widget _buildTabContent() {
    return Column(
      children: [
        // Tab content - only Today tab now
        Expanded(
          child: _buildTodayContent(),
        ),
      ],
    );
  }

  Future<void> _fetchData() async {
    if (!_mounted) return;
    setState(() => isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!_mounted) return;
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
        for (final mealData in mealRes) {
          try {
            final meal = MealHistoryEntry.fromMap(mealData);
            mealList.add(meal);
          } catch (e) {
            print('Error parsing meal data: $e');
        }
      }

      // Fetch user nutrition goals
      final prefsRes = await Supabase.instance.client
          .from('user_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      final userGoals = prefsRes != null ? UserNutritionGoals.fromMap(prefsRes) : null;

      if (!_mounted) return;
      setState(() {
        meals = mealList;
        goals = userGoals;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching meal data: $e');
      if (!_mounted) return;
      setState(() {
        meals = [];
        goals = null;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      
      // Update cached value
      _cachedAvatarUrl = data?['avatar_url'] as String?;
      _hasFetchedAvatar = true;
      
      if (!_mounted) return;
      setState(() {
        _avatarUrl = _cachedAvatarUrl;
      });
    } catch (e) {
      print('Error fetching user avatar: $e');
    }
  }

  Future<void> _fetchDatesWithMeals([DateTime? targetMonth]) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      // Use targetMonth if provided, otherwise use selectedDate
      final monthToFetch = targetMonth ?? selectedDate;
      
      // Fetch data for a broader range to cover all visible months in calendar
      // This includes previous month's trailing days and next month's leading days
      final startOfRange = DateTime(monthToFetch.year, monthToFetch.month - 1, 1);
      final endOfRange = DateTime(monthToFetch.year, monthToFetch.month + 2, 0);
      
      // Debug logs removed
      
      final mealRes = await Supabase.instance.client
          .from('meal_plan_history')
          .select('completed_at')
          .eq('user_id', user.id)
          .gte('completed_at', startOfRange.toUtc().toIso8601String())
          .lt('completed_at', endOfRange.add(const Duration(days: 1)).toUtc().toIso8601String());
      
      // Debug logs removed
      
      final Map<DateTime, bool> newDatesWithMeals = {};
      final Map<DateTime, int> newMonthlyMealCounts = {};
      
        for (final meal in mealRes) {
          try {
            final completedAt = DateTime.parse(meal['completed_at']).toLocal();
            final dateKey = DateTime(completedAt.year, completedAt.month, completedAt.day);
            newDatesWithMeals[dateKey] = true;
            newMonthlyMealCounts[dateKey] = (newMonthlyMealCounts[dateKey] ?? 0) + 1;
          // Debug logs removed
          } catch (e) {
            print('Error parsing meal date: $e');
        }
      }
      
      // Debug logs removed
      
      if (!_mounted) return;
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
          if (!_mounted) return;
          setState(() {
            selectedDate = date;
          });
          Navigator.of(context).pop();
          _fetchData();
        },
        onRefreshMonth: (DateTime month) {
          // Fetch data for extended range covering all visible months
          _fetchDatesWithMeals(month);
        },
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Header skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 280,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          
          // Date selector skeleton
          Container(
            width: 200,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          
          // Calorie tracker skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Macro cards grid skeleton
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: List.generate(6, (index) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 1),
                    blurRadius: 1,
                    spreadRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            )),
          ),
          
          const SizedBox(height: 24),
          
          // Meals section header skeleton
          Container(
            width: 120,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Meal cards skeleton
          ...List.generate(3, (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Build today's content with scroll controller
  Widget _buildTodayContent() {
    final summary = _getDailySummary(meals);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Meal Tracker Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meal Tracker',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Track your daily nutrition intake and monitor your calorie goals',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          // Full date display above the green container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: GestureDetector(
              onTap: _showCalendar,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Big Odometer-Style Calorie Tracker (only the calorie card)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring (dark green background)
                    Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2E7D32),
                      ),
                      child: CustomPaint(
                        size: const Size(160, 160),
                        painter: _OdometerPainter(
                          progress: (summary.calories / (goals?.calorieGoal ?? 2000)).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                    // Center content with white background circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    // Center text with green color
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ((goals?.calorieGoal ?? 2000) - summary.calories).toStringAsFixed(0),
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'kcal left',
                          style: TextStyle(
                            color: Color(0xFF81C784),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Macro cards in 2-column grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _MacroCard(
                icon: null,
                title: 'Carbs',
                value: summary.carbs.toStringAsFixed(0),
                unit: 'g',
                goal: goals?.carbGoal ?? 275,
                color: Colors.orange,
              ),
              _MacroCard(
                icon: null,
                title: 'Protein',
                value: summary.protein.toStringAsFixed(0),
                unit: 'g',
                goal: goals?.proteinGoal ?? 165,
                color: Colors.blue,
              ),
              _MacroCard(
                icon: null,
                title: 'Fat',
                value: summary.fat.toStringAsFixed(0),
                unit: 'g',
                goal: goals?.fatGoal ?? 75,
                color: Colors.purple,
              ),
              _MacroCard(
                icon: null,
                title: 'Fiber',
                value: summary.fiber.toStringAsFixed(0),
                unit: 'g',
                goal: goals?.fiberGoal ?? 25,
                color: Colors.green,
              ),
              _MacroCard(
                icon: null,
                title: 'Sugar',
                value: summary.sugar.toStringAsFixed(0),
                unit: 'g',
                goal: goals?.sugarGoal ?? 50,
                color: Colors.pink,
              ),
              _MacroCard(
                icon: null,
                title: 'Cholesterol',
                value: summary.cholesterol.toStringAsFixed(0),
                unit: 'mg',
                goal: goals?.cholesterolGoal ?? 300,
                color: Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Today's Meals section
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'NutriPlan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        centerTitle: true,
        leading: widget.showBackButton 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
        actions: [
          RepaintBoundary(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;
                      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 80, 231, 93),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey, size: 20)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
        ? _buildSkeletonLoader()
        : _buildTabContent(),
    );
  }

}

// Macro Card Widget (matches the design)
class _MacroCard extends StatelessWidget {
  final IconData? icon;
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
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // more vertical padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 1),
            blurRadius: 1,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
              ],
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
          Column(
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
                'of ${goal.toStringAsFixed(0)}$unit',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
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

// Enhanced Calendar dialog with full calendar view
class _CalendarDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Map<DateTime, bool> datesWithMeals;
  final Map<DateTime, int> mealCounts;
  final Function(DateTime) onDateSelected;
  final Function(DateTime)? onRefreshMonth;
  
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
    
    // Fetch initial data for extended range covering all visible months
    if (widget.onRefreshMonth != null) {
      widget.onRefreshMonth!(currentMonth);
    }
  }

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    });
    // Refresh meal data for the new extended range
    if (widget.onRefreshMonth != null) {
      widget.onRefreshMonth!(currentMonth);
    }
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    });
    // Refresh meal data for the new extended range
    if (widget.onRefreshMonth != null) {
      widget.onRefreshMonth!(currentMonth);
    }
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = currentMonth;
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // Get the first day of the week (Monday = 1, Sunday = 7)
    final firstDayOfWeek = firstDay.weekday;
    
    List<DateTime> days = [];
    
    // Add days from previous month to fill the first week
    for (int i = firstDayOfWeek - 1; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }
    
    // Add days of current month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, i));
    }
    
    // Add days from next month to fill the last week
    final remainingDays = 42 - days.length; // 6 rows * 7 days = 42
    for (int i = 1; i <= remainingDays; i++) {
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
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with month navigation
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
            
            // Day headers
            Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
              physics: const NeverScrollableScrollPhysics(),
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
                final hasMeals = widget.datesWithMeals[DateTime(day.year, day.month, day.day)] == true;
                final mealCount = widget.mealCounts[DateTime(day.year, day.month, day.day)] ?? 0;
                
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
                          ? Colors.blue 
                          : (isCurrentMonth ? Colors.white : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : (isCurrentMonth
                                      ? (hasMeals ? Colors.green : Colors.black)
                                      : Colors.grey[400]),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        // Meal count badge - fixed positioning and visibility
                        if (mealCount > 0 && isCurrentMonth)
                          Positioned(
                            top: 1,
                            right: 1,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                mealCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Days with completed meals',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Close button
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

// Custom painter for odometer-style filled arc
class _OdometerPainter extends CustomPainter {
  final double progress;

  _OdometerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10; // Account for stroke width

    // Convert to radians
    const double pi = 3.1415926535897932;
    
    // Start from top (-90 degrees in radians)
    final startAngle = -90 * (pi / 180);
    
    // Draw a fixed small arc segment regardless of progress
    // This creates the "cut odometer" effect - always showing a small piece of the ring
    // Typical odometer shows about 20-30 degrees of arc
    const fixedArcDegrees = 25.0; // Fixed arc size in degrees
    final sweepAngle = fixedArcDegrees * (pi / 180); // Convert to radians

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false, // Don't draw interior
      paint,
    );
  }

  @override
  bool shouldRepaint(_OdometerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

