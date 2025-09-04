import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../models/meal_history_entry.dart';
import '../../models/user_nutrition_goals.dart';
import '../../widgets/meal_log_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealTrackerScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onTabActivated;
  const MealTrackerScreen({super.key, this.showBackButton = false, this.onTabActivated});

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
  
  // Add tab state
  String _selectedTab = 'today'; // 'today', 'weekly', 'monthly'
  
  // Flag to track if widget is mounted
  bool _mounted = true;
  
  // Scroll controller for glass morphism effects
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Reset scroll offset when screen is initialized (e.g., when switching from another tab)
    _scrollOffset = 0.0;
    _fetchData();
    _fetchDatesWithMeals();
  }
  
  @override
  void dispose() {
    _mounted = false;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset scroll offset when dependencies change (e.g., when switching back to this tab)
    if (_mounted) {
      _scrollOffset = 0.0;
      // Notify parent that this tab is activated
      widget.onTabActivated?.call();
    }
  }
  
  void _onScroll() {
    if (!_mounted) return;
    // Update scroll offset without triggering setState for smooth scrolling
    _scrollOffset = _scrollController.offset;
  }
  
  // Reset scroll offset to reset glass morphism effects
  void _resetScrollOffset() {
    if (!_mounted) return;
    setState(() {
      _scrollOffset = 0.0;
    });
  }
  
  // Glass morphism header widget
  Widget _buildGlassMorphismHeader() {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        // Calculate opacity based on scroll position
        final opacity = (_scrollOffset / 100).clamp(0.0, 0.8);
        final blurIntensity = (_scrollOffset / 50).clamp(0.0, 15.0);
        
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                child: Padding(
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
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Glass morphism tab section widget
  Widget _buildGlassMorphismTabs() {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        // Calculate opacity based on scroll position
        final opacity = (_scrollOffset / 100).clamp(0.0, 0.6);
        final blurIntensity = (_scrollOffset / 50).clamp(0.0, 10.0);
        
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Today',
                    isSelected: _selectedTab == 'today',
                    onTap: () {
                      if (!_mounted) return;
                      setState(() {
                        _selectedTab = 'today';
                        _scrollOffset = 0.0; // Reset scroll offset for glass morphism
                      });
                      _fetchData();
                    },
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Weekly',
                    isSelected: _selectedTab == 'weekly',
                    onTap: () {
                      if (!_mounted) return;
                      setState(() {
                        _selectedTab = 'weekly';
                        _scrollOffset = 0.0; // Reset scroll offset for glass morphism
                      });
                      _fetchData();
                    },
                  ),
                  const SizedBox(width: 12),
                  _TabButton(
                    label: 'Monthly',
                    isSelected: _selectedTab == 'monthly',
                    onTap: () {
                      if (!_mounted) return;
                      setState(() {
                        _selectedTab = 'monthly';
                        _scrollOffset = 0.0; // Reset scroll offset for glass morphism
                      });
                      _fetchData();
                    },
                  ),
                  const Spacer(),
                  // Calendar button with glass effect
                  GestureDetector(
                    onTap: _showCalendar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchData() async {
    if (!_mounted) return;
    // Reset scroll offset for glass morphism when data is refreshed
    _scrollOffset = 0.0;
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

  // Get weekly summary
  Future<DailySummary> _getWeeklySummary() async {
    final weeklyMeals = await _fetchWeeklyData();
    return _getDailySummary(weeklyMeals);
  }

  // Get monthly summary
  Future<DailySummary> _getMonthlySummary() async {
    final monthlyMeals = await _fetchMonthlyData();
    return _getDailySummary(monthlyMeals);
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
            _scrollOffset = 0.0; // Reset scroll offset for glass morphism
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

  // Fetch weekly data
  Future<List<MealHistoryEntry>> _fetchWeeklyData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];
      
      // Get start and end of current week
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final startOfWeekUtc = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toUtc();
      final endOfWeekUtc = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59).toUtc();
      
      final mealRes = await Supabase.instance.client
          .from('meal_plan_history')
          .select()
          .eq('user_id', user.id)
          .gte('completed_at', startOfWeekUtc.toIso8601String())
          .lte('completed_at', endOfWeekUtc.toIso8601String())
          .order('completed_at', ascending: true);

      final mealList = <MealHistoryEntry>[];
      if (mealRes is List) {
        for (final mealData in mealRes) {
          try {
            final meal = MealHistoryEntry.fromMap(mealData);
            mealList.add(meal);
          } catch (e) {
            print('Error parsing weekly meal data: $e');
          }
        }
      }
      
      if (!_mounted) return [];
      return mealList;
    } catch (e) {
      print('Error fetching weekly data: $e');
      return [];
    }
  }

  // Fetch monthly data
  Future<List<MealHistoryEntry>> _fetchMonthlyData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];
      
      // Get start and end of current month
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final startOfMonthUtc = startOfMonth.toUtc();
      final endOfMonthUtc = DateTime(endOfMonth.year, endOfMonth.month, endOfMonth.day, 23, 59, 59).toUtc();
      
      final mealRes = await Supabase.instance.client
          .from('meal_plan_history')
          .select()
          .eq('user_id', user.id)
          .gte('completed_at', startOfMonthUtc.toIso8601String())
          .lte('completed_at', endOfMonthUtc.toIso8601String())
          .order('completed_at', ascending: true);

      final mealList = <MealHistoryEntry>[];
      if (mealRes is List) {
        for (final mealData in mealRes) {
          try {
            final meal = MealHistoryEntry.fromMap(mealData);
            mealList.add(meal);
          } catch (e) {
            print('Error parsing monthly meal data: $e');
          }
        }
      }
      
      if (!_mounted) return [];
      return mealList;
    } catch (e) {
      print('Error fetching monthly data: $e');
      return [];
    }
  }

  // Build tab content based on selected tab
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'today':
        return _buildTodayContent();
      case 'weekly':
        return _buildWeeklyContent();
      case 'monthly':
        return _buildMonthlyContent();
      default:
        return _buildTodayContent();
    }
  }
  
  // Build today's content with scroll controller
  Widget _buildTodayContent() {
    final summary = _getDailySummary(meals);
    
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Today's Calories big green card
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
                        ],
                      ),
                    ),
                    // Circular progress indicator with centered percentage
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: (summary.calories / (goals?.calorieGoal ?? 2000)).clamp(0.0, 1.0),
                              strokeWidth: 12,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Text(
                            '${((summary.calories / (goals?.calorieGoal ?? 2000)) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
          
          // Macro cards in 2x3 grid (6 macros total)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _MacroCard(
                icon: Icons.grain,
                title: 'Carbs',
                value: summary.carbs.toStringAsFixed(0),
                unit: 'g',
                goal: goals?.carbGoal ?? 275,
                color: Colors.orange,
              ),
              _MacroCard(
                icon: Icons.fitness_center,
                title: 'Protein',
                value: summary.protein.toStringAsFixed(0),
                unit: 'g',
                goal: goals?.proteinGoal ?? 165,
                color: Colors.blue,
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
              _MacroCard(
                icon: Icons.cake,
                title: 'Sugar',
                value: summary.sugar.toStringAsFixed(0),
                unit: 'g',
                goal: goals?.sugarGoal ?? 50,
                color: Colors.pink,
              ),
              _MacroCard(
                icon: Icons.favorite,
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

  // Build weekly content
  Widget _buildWeeklyContent() {
    return FutureBuilder<DailySummary>(
      future: _getWeeklySummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final summary = snapshot.data ?? DailySummary(
          calories: 0, protein: 0, carbs: 0, fat: 0, 
          sugar: 0, fiber: 0, sodium: 0, cholesterol: 0
        );
        
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Weekly Calories card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This Week's Calories",
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
                                'consumed this week',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Weekly Goal: ${(goals?.calorieGoal ?? 2000) * 7} cal',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Circular progress indicator with centered percentage
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: (summary.calories / ((goals?.calorieGoal ?? 2000) * 7)).clamp(0.0, 1.0),
                                  strokeWidth: 12,
                                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              Text(
                                '${((summary.calories / ((goals?.calorieGoal ?? 2000) * 7)) * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
              
              // Weekly macro cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _MacroCard(
                    icon: Icons.grain,
                    title: 'Carbs',
                    value: summary.carbs.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.carbGoal ?? 275) * 7,
                    color: Colors.orange,
                  ),
                  _MacroCard(
                    icon: Icons.fitness_center,
                    title: 'Protein',
                    value: summary.protein.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.proteinGoal ?? 165) * 7,
                    color: Colors.blue,
                  ),
                  _MacroCard(
                    icon: Icons.water_drop,
                    title: 'Fat',
                    value: summary.fat.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.fatGoal ?? 75) * 7,
                    color: Colors.purple,
                  ),
                  _MacroCard(
                    icon: Icons.local_florist,
                    title: 'Fiber',
                    value: summary.fiber.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.fiberGoal ?? 25) * 7,
                    color: Colors.green,
                  ),
                  _MacroCard(
                    icon: Icons.cake,
                    title: 'Sugar',
                    value: summary.sugar.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.sugarGoal ?? 50) * 7,
                    color: Colors.pink,
                  ),
                  _MacroCard(
                    icon: Icons.favorite,
                    title: 'Cholesterol',
                    value: summary.cholesterol.toStringAsFixed(0),
                    unit: 'mg',
                    goal: (goals?.cholesterolGoal ?? 300) * 7,
                    color: Colors.red,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Build monthly content
  Widget _buildMonthlyContent() {
    return FutureBuilder<DailySummary>(
      future: _getMonthlySummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final summary = snapshot.data ?? DailySummary(
          calories: 0, protein: 0, carbs: 0, fat: 0, 
          sugar: 0, fiber: 0, sodium: 0, cholesterol: 0
        );
        
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Monthly Calories card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This Month's Calories",
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
                                'consumed this month',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Monthly Goal: ${(goals?.calorieGoal ?? 2000) * 30} cal',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Circular progress indicator with centered percentage
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: (summary.calories / ((goals?.calorieGoal ?? 2000) * 30)).clamp(0.0, 1.0),
                                  strokeWidth: 12,
                                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              Text(
                                '${((summary.calories / ((goals?.calorieGoal ?? 2000) * 30)) * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
              
              // Monthly macro cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _MacroCard(
                    icon: Icons.grain,
                    title: 'Carbs',
                    value: summary.carbs.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.carbGoal ?? 275) * 30,
                    color: Colors.orange,
                  ),
                  _MacroCard(
                    icon: Icons.fitness_center,
                    title: 'Protein',
                    value: summary.protein.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.proteinGoal ?? 165) * 30,
                    color: Colors.blue,
                  ),
                  _MacroCard(
                    icon: Icons.water_drop,
                    title: 'Fat',
                    value: summary.fat.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.fatGoal ?? 75) * 30,
                    color: Colors.purple,
                  ),
                  _MacroCard(
                    icon: Icons.local_florist,
                    title: 'Fiber',
                    value: summary.fiber.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.fiberGoal ?? 25) * 30,
                    color: Colors.green,
                  ),
                  _MacroCard(
                    icon: Icons.cake,
                    title: 'Sugar',
                    value: summary.sugar.toStringAsFixed(0),
                    unit: 'g',
                    goal: (goals?.sugarGoal ?? 50) * 30,
                    color: Colors.pink,
                  ),
                  _MacroCard(
                    icon: Icons.favorite,
                    title: 'Cholesterol',
                    value: summary.cholesterol.toStringAsFixed(0),
                    unit: 'mg',
                    goal: (goals?.cholesterolGoal ?? 300) * 30,
                    color: Colors.red,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Glass morphism header
            _buildGlassMorphismHeader(),
            
            // Glass morphism tabs
            _buildGlassMorphismTabs(),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTabContent(),
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

// Enhanced Calendar dialog with full calendar view
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

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    });
    if (widget.onRefreshMonth != null) {
      widget.onRefreshMonth!();
    }
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    });
    if (widget.onRefreshMonth != null) {
      widget.onRefreshMonth!();
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
                childAspectRatio: 1.2,
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
                                  : (isCurrentMonth ? Colors.black : Colors.grey[400]),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        // Green dot indicator for days with meals
                        if (hasMeals)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        // Meal count badge
                        if (mealCount > 0)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                mealCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
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
                  width: 12,
                  height: 12,
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
