import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_nutrition_goals.dart';
// Removed external analytics service; using inline data fetchers
import '../../services/ai_insights_service.dart';
import '../../services/recipe_service.dart';
import '../profile/profile_screen.dart';
import '../recipes/recipe_info_screen.dart';
import '../../models/recipes.dart';
import '../tracking/meal_tracker_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isWeeklyLoading = false;
  bool _isMonthlyLoading = false;
  UserNutritionGoals? _goals;
  Map<String, dynamic> _weeklyData = {};
  Map<String, dynamic> _lastWeekData = {};
  Map<String, dynamic> _monthlyData = {};
  final Map<String, Map<String, dynamic>> _weeklyCache = {};
  final Map<String, Map<String, dynamic>> _monthlyCache = {};
  List<Recipe> _allRecipes = [];
  String _selectedPeriod = 'weekly'; // 'weekly' | 'monthly'
  List<Map<String, String>> _weeklyInsights = [];
  bool _isGeneratingWeeklyInsights = false;
  String? _avatarUrl;
  String? _weeklyInsightsCacheKey; // Prevent redundant AI calls when data hasn't changed
  
  late TabController _tabController;
  // Week selection for Daily Calorie Intake (defaults to current week)
  late DateTime _selectedWeekStart; // Monday of selected week
  // Month selection for Monthly views (defaults to current month)
  late DateTime _selectedMonthStart; // First day of selected month

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize to current week's Monday
    final now = DateTime.now();
    _selectedWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    // Initialize to current month's first day
    _selectedMonthStart = DateTime(now.year, now.month, 1);
    _loadAnalyticsData();
    _fetchUserAvatar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _goals = null;
          _isLoading = false;
        });
        return;
      }

      // Fetch user nutrition goals
      final prefsRes = await Supabase.instance.client
          .from('user_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      final userGoals = prefsRes != null ? UserNutritionGoals.fromMap(prefsRes) : null;

      // Fetch weekly and monthly data inline (totals/averages)
      final weeklyData = await _getWeeklyData(user.id, weekStart: _selectedWeekStart);
      final prevWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
      final lastWeekData = await _getWeeklyData(user.id, weekStart: prevWeekStart);
      final monthlyData = await _getMonthlyData(user.id, monthStart: _selectedMonthStart);

      if (!mounted) return;
      setState(() {
        _goals = userGoals;
        _weeklyData = weeklyData;
        _lastWeekData = lastWeekData;
        _monthlyData = monthlyData;
        _isLoading = false;
      });

      // Generate AI insights
      _generateWeeklyInsights();
    } catch (e) {
      print('Error loading analytics data: $e');
      if (!mounted) return;
      setState(() {
        _goals = null;
        _weeklyData = {};
        _monthlyData = {};
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshWeeklyData() async {
    if (!mounted) return;
    try {
    setState(() => _isWeeklyLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

      // Fetch weekly data for the selected week
      final weeklyData = await _getWeeklyData(user.id, weekStart: _selectedWeekStart);
      final prevWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
      final lastWeekData = await _getWeeklyData(user.id, weekStart: prevWeekStart);
      
      if (!mounted) return;
      setState(() {
        _weeklyData = weeklyData;
        _lastWeekData = lastWeekData;
        _isWeeklyLoading = false;
      });

      // Regenerate insights for the new week
      _generateWeeklyInsights();
    } catch (e) {
      print('Error refreshing weekly data: $e');
      if (mounted) {
        setState(() => _isWeeklyLoading = false);
      }
    }
  }

  Future<void> _refreshMonthlyData() async {
    if (!mounted) return;
    try {
      setState(() => _isMonthlyLoading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final monthlyData = await _getMonthlyData(user.id, monthStart: _selectedMonthStart);
      if (!mounted) return;
      setState(() {
        _monthlyData = monthlyData;
        _isMonthlyLoading = false;
      });
    } catch (e) {
      print('Error refreshing monthly data: $e');
      if (mounted) {
        setState(() => _isMonthlyLoading = false);
      }
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
      
      if (!mounted) return;
      setState(() {
        _avatarUrl = data?['avatar_url'] as String?;
      });
    } catch (e) {
      print('Error fetching user avatar: $e');
    }
  }

  Future<void> _generateWeeklyInsights() async {
    if (!mounted) return;
    setState(() => _isGeneratingWeeklyInsights = true);

    try {
      // Build a lightweight cache key from weekly averages and key goals
      final Map<String, double> avgs = (_weeklyData['averages'] as Map<String, double>?) ?? const {};
      final key = [
        avgs['calories']?.toStringAsFixed(1) ?? '0',
        avgs['protein']?.toStringAsFixed(1) ?? '0',
        avgs['carbs']?.toStringAsFixed(1) ?? '0',
        avgs['fat']?.toStringAsFixed(1) ?? '0',
        avgs['fiber']?.toStringAsFixed(1) ?? '0',
        avgs['sugar']?.toStringAsFixed(1) ?? '0',
        (_goals?.calorieGoal ?? 0).toStringAsFixed(0),
        (_goals?.proteinGoal ?? 0).toStringAsFixed(0),
        (_goals?.carbGoal ?? 0).toStringAsFixed(0),
        (_goals?.fatGoal ?? 0).toStringAsFixed(0),
      ].join('|');

      // If nothing changed, skip re-generation
      if (_weeklyInsightsCacheKey == key && _weeklyInsights.isNotEmpty) {
        setState(() => _isGeneratingWeeklyInsights = false);
        return;
      }

      // Fetch available recipes for meal recommendations
      final recipes = await RecipeService.fetchRecipes();
      final recipeNames = recipes.map((r) => r.title).toList();
      if (mounted) {
        setState(() {
          _allRecipes = recipes;
        });
      }

      final insights = await AIInsightsService.generateWeeklyInsights(
        _weeklyData, 
        _monthlyData, 
        _goals,
        availableRecipes: recipeNames,
      );
      if (!mounted) return;
      setState(() {
        _weeklyInsights = insights;
        _weeklyInsightsCacheKey = key;
        _isGeneratingWeeklyInsights = false;
      });
    } catch (e) {
      print('Error generating weekly insights: $e');
      if (!mounted) return;
      setState(() {
        _weeklyInsights = [];
        _isGeneratingWeeklyInsights = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getWeeklyData(String userId, {DateTime? weekStart}) async {
    // Use provided weekStart or default to current week's Monday
    final startOfWeek = weekStart ?? 
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final cacheKey = 'w:${startOfWeek.year}-${startOfWeek.month}-${startOfWeek.day}';
    if (_weeklyCache.containsKey(cacheKey)) {
      return _weeklyCache[cacheKey]!;
    }
    final startUtc = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toUtc();
    final endUtc = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59).toUtc();
    final res = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
        .eq('user_id', userId)
        .gte('completed_at', startUtc.toIso8601String())
        .lte('completed_at', endUtc.toIso8601String())
        .order('completed_at', ascending: true);
    final summarized = _summarize(res);
    _weeklyCache[cacheKey] = summarized;
    return summarized;
  }

  Future<Map<String, dynamic>> _getMonthlyData(String userId, {DateTime? monthStart}) async {
    final base = monthStart ?? DateTime.now();
    final startOfMonth = DateTime(base.year, base.month, 1).toUtc();
    final endOfMonth = DateTime(base.year, base.month + 1, 0, 23, 59, 59).toUtc();
    final cacheKey = 'm:${base.year}-${base.month}-01';
    if (_monthlyCache.containsKey(cacheKey)) {
      return _monthlyCache[cacheKey]!;
    }
    final res = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
        .eq('user_id', userId)
        .gte('completed_at', startOfMonth.toIso8601String())
        .lte('completed_at', endOfMonth.toIso8601String())
        .order('completed_at', ascending: true);
    final summarized = _summarize(res);
    _monthlyCache[cacheKey] = summarized;
    return summarized;
  }

  Map<String, dynamic> _summarize(List<dynamic> meals) {
    double calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0, sugar = 0;
    final dailyData = <String, Map<String, double>>{};
    for (final m in meals) {
      final dt = DateTime.parse(m['completed_at']).toLocal();
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      double c(String k) => _toDouble(m[k]);
      calories += c('calories');
      protein += c('protein');
      carbs += c('carbs');
      fat += c('fat');
      fiber += c('fiber');
      sugar += c('sugar');
      dailyData.putIfAbsent(key, () => {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
        'fiber': 0,
        'sugar': 0,
      });
      // Accumulate all nutrients for daily data
      dailyData[key]!['calories'] = (dailyData[key]!['calories'] ?? 0) + c('calories');
      dailyData[key]!['protein'] = (dailyData[key]!['protein'] ?? 0) + c('protein');
      dailyData[key]!['carbs'] = (dailyData[key]!['carbs'] ?? 0) + c('carbs');
      dailyData[key]!['fat'] = (dailyData[key]!['fat'] ?? 0) + c('fat');
      dailyData[key]!['fiber'] = (dailyData[key]!['fiber'] ?? 0) + c('fiber');
      dailyData[key]!['sugar'] = (dailyData[key]!['sugar'] ?? 0) + c('sugar');
    }
    final countMeals = meals.length;
    final count = meals.isEmpty ? 1 : countMeals.toDouble();
    return {
      'totals': {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
      },
      'averages': {
        'calories': calories / count,
        'protein': protein / count,
        'carbs': carbs / count,
        'fat': fat / count,
        'fiber': fiber / count,
        'sugar': sugar / count,
      },
      'count': countMeals,
      'dailyData': dailyData,
    };
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
        automaticallyImplyLeading: false,
        centerTitle: true,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period switch centered above the summary card
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSegmentButton('Week', 'weekly'),
                          _buildSegmentButton('Month', 'monthly'),
                        ],
                      ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Pick a date',
                          child: IconButton(
                            icon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF2E7D32)),
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedWeekStart,
                                firstDate: DateTime(now.year - 2),
                                lastDate: DateTime(now.year + 2),
                              );
                              if (picked != null) {
                                final monday = DateTime(picked.year, picked.month, picked.day)
                                    .subtract(Duration(days: picked.weekday - 1));
                                setState(() => _selectedWeekStart = monday);
                                await _refreshWeeklyData();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Top summary row: Calories + meal counts
                  _buildTopSummaryRow(),
                  const SizedBox(height: 30),
                  _buildCalorieCardWithSegmentedArea(),
                  const SizedBox(height: 30),
                
                // Weekly Insights Section
                _buildWeeklyInsightsCard(),
                const SizedBox(height: 30),
                
                // Charts
                  // Multi-line Chart for Weekly Comparison
                  _buildWeeklyComparisonChart(),
                  const SizedBox(height: 30),
                  
                  // Removed macro comparison per preference
                  
                  // Multiple Pie Charts for Week Comparison
                  _buildWeeklyPieCharts(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // New card matching the provided visual: segmented control + area chart
  Widget _buildCalorieCardWithSegmentedArea() {
    final dailyGoal = _goals?.calorieGoal ?? 2000.0;
    final Map<String, dynamic> dataByPeriod = {
      'weekly': _weeklyData,
      'monthly': _monthlyData,
    };
    final selectedData = dataByPeriod[_selectedPeriod] ?? {};
    // Safely parse daily data regardless of runtime map typing
    final Map<String, dynamic> rawDaily = (selectedData['dailyData'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Map<String, Map<String, double>> daily = {
      for (final entry in rawDaily.entries)
        entry.key: (entry.value as Map?)
                ?.map((k, v) => MapEntry<String, double>(k.toString(), _toDouble(v)))
                .cast<String, double>() ??
            <String, double>{}
    };

    // Build expected keys (for weekly ensure Mon-Sun order even when missing)
    List<String> sortedKeys;
    if (_selectedPeriod == 'weekly') {
      // Use user-selected week start (Monday)
      final startOfWeek = _selectedWeekStart;
      sortedKeys = List.generate(7, (i) {
        final d = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(Duration(days: i));
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      });
    } else {
      sortedKeys = daily.keys.toList()..sort();
    }

    // Build points for area line (calories per day)
    final List<FlSpot> spots = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      final day = sortedKeys[i];
      final calories = daily[day]?['calories'] ?? 0;
      spots.add(FlSpot(i.toDouble(), calories));
    }

    // Empty state detection
    final bool noData = daily.isEmpty || daily.values.every((m) => (m['calories'] ?? 0) == 0);
    final bool isLoading = _selectedPeriod == 'weekly' ? _isWeeklyLoading : _isMonthlyLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period header with navigation
          if (_selectedPeriod == 'weekly')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatWeekRange(_selectedWeekStart),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
                        });
                        _refreshWeeklyData();
                      },
                      tooltip: 'Previous week',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        // Prevent going into future weeks beyond current Monday
                        final now = DateTime.now();
                        final currentMonday = DateTime(now.year, now.month, now.day)
                            .subtract(Duration(days: now.weekday - 1));
                        final next = _selectedWeekStart.add(const Duration(days: 7));
                        setState(() {
                          _selectedWeekStart = next.isAfter(currentMonday) ? currentMonday : next;
                        });
                        _refreshWeeklyData();
                      },
                      tooltip: 'Next week',
                    ),
                  ],
                ),
              ],
            ),
          if (_selectedPeriod == 'monthly')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_shortMonth(_selectedMonthStart.month)} ${_selectedMonthStart.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () async {
                        setState(() {
                          _selectedMonthStart = DateTime(_selectedMonthStart.year, _selectedMonthStart.month - 1, 1);
                        });
                        await _refreshMonthlyData();
                      },
                      tooltip: 'Previous month',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () async {
                        // Prevent going into future months beyond current month
                        final now = DateTime.now();
                        final currentMonth = DateTime(now.year, now.month, 1);
                        final next = DateTime(_selectedMonthStart.year, _selectedMonthStart.month + 1, 1);
                        setState(() {
                          _selectedMonthStart = next.isAfter(currentMonth) ? currentMonth : next;
                        });
                        await _refreshMonthlyData();
                      },
                      tooltip: 'Next month',
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 12),
          const Text(
            'Calorie Intake',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Track your calorie consumption based on your daily goal',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            SizedBox(
              height: 220,
              child: _buildChartSkeleton(),
            )
          else if (noData)
            _buildNoDataBanner('No data for this ${_selectedPeriod == 'weekly' ? 'week' : 'month'}')
          else
            SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        final v = barSpot.y;
                        final goal = _goals?.calorieGoal ?? 0;
                        final pct = goal > 0 ? (v / goal) * 100 : 0;
                        return LineTooltipItem(
                          '${v.toStringAsFixed(0)} kcal\n${pct.toStringAsFixed(0)}% of goal',
                          const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                    if (event is FlTapUpEvent && response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                      final spot = response.lineBarSpots!.first;
                      final dayIndex = spot.x.toInt();
                      if (dayIndex >= 0 && dayIndex < sortedKeys.length) {
                        final dateStr = sortedKeys[dayIndex];
                        final date = DateTime.tryParse(dateStr);
                        if (date != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MealTrackerScreen(
                                showBackButton: true,
                                initialDate: date,
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                minX: 0,
                maxX: (spots.isEmpty ? 6 : (spots.length - 1)).toDouble(),
                minY: 0,
                maxY: (dailyGoal * 1.4).clamp(1000, 3000),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                  getDrawingVerticalLine: (v) => FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sortedKeys.length) return const SizedBox.shrink();
                        final d = DateTime.tryParse(sortedKeys[idx]);
                        final label = d != null ? '${_shortMonth(d.month)} ${d.day}' : '';
                        return Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 600,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
                lineBarsData: [
                  // Filled green curved line
                  LineChartBarData(
                    spots: spots.isEmpty ? [for (int i = 0; i < 7; i++) FlSpot(i.toDouble(), 0)] : spots,
                    isCurved: true,
                    color: Colors.green[600],
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green[100]!.withOpacity(0.6),
                      gradient: LinearGradient(
                        colors: [Colors.green[200]!, Colors.green[50]!],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(show: false),
                  ),
                  // Dashed orange goal line
                  LineChartBarData(
                    spots: [
                      FlSpot(0, dailyGoal),
                      FlSpot((spots.isEmpty ? 6 : (spots.length - 1)).toDouble(), dailyGoal),
                    ],
                    color: Colors.orange,
                    barWidth: 2,
                    isCurved: false,
                    dashArray: [6, 6],
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, String periodKey) {
    final bool selected = _selectedPeriod == periodKey;
    return GestureDetector(
      onTap: () async {
        if (_selectedPeriod == periodKey) return;
        setState(() => _selectedPeriod = periodKey);
        // Ensure data is refreshed when switching periods
        if (periodKey == 'weekly') {
          await _refreshWeeklyData();
        } else {
          await _refreshMonthlyData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.green[700] : Colors.green[700],
          ),
        ),
      ),
    );
  }

  String _shortMonth(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[(m - 1).clamp(0, 11)];
  }

  Widget _buildTopSummaryRow() {
    final weekMeals = (_weeklyData['count'] as int?) ?? 0;
    final monthMeals = (_monthlyData['count'] as int?) ?? 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildScaledCaloriesCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildMealCountCard('This Week', weekMeals)),
        const SizedBox(width: 12),
        Expanded(child: _buildMealCountCard('This Month', monthMeals)),
      ],
    );
  }

  Widget _buildScaledCaloriesCard() {
    final dailyGoal = _goals?.calorieGoal ?? 2000.0;
    final currentData = _selectedPeriod == 'weekly' ? _weeklyData : _monthlyData;
    final totals = currentData['totals'] as Map<String, double>? ?? {};
    final averages = currentData['averages'] as Map<String, double>? ?? {};
    final totalCalories = totals['calories'] ?? 0.0;
    final averageCalories = averages['calories'] ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Calories',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const Spacer(),
              Text(
                _selectedPeriod == 'weekly' ? 'This Week' : 'This Month',
                style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${totalCalories.toStringAsFixed(0)} Kcal',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            'Avg: ${averageCalories.toStringAsFixed(0)} Kcal/day',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            'Target: ${dailyGoal.toStringAsFixed(0)} Kcal/day',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCountCard(String label, int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planned Meals • $label',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  String _formatWeekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final start = '${_shortMonth(monday.month)} ${monday.day}';
    final end = '${_shortMonth(sunday.month)} ${sunday.day}';
    return '$start - $end';
  }

  // Weekly Insights Card matching the provided visual
  Widget _buildWeeklyInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with lightbulb icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.yellow[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nutritional Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32), // Dark greenish-blue
                ),
              ),
              const Spacer(),
              if (_isGeneratingWeeklyInsights)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Insights list
          if (_isGeneratingWeeklyInsights)
            _buildLoadingInsights()
          else if (_weeklyInsights.isNotEmpty)
            ..._weeklyInsights.map((insight) => _buildInsightItem(insight['title']!, insight['description']!))
          else
            _buildEmptyInsights(),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String description) {
    // Find recipe mentions in the description
    final matchedRecipes = <Recipe>[];
    final descLower = description.toLowerCase();
    for (final r in _allRecipes) {
      final name = r.title.trim();
      if (name.isEmpty) continue;
      if (descLower.contains(name.toLowerCase())) {
        matchedRecipes.add(r);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (matchedRecipes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matchedRecipes.map((r) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeInfoScreen(recipe: r),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 6),
                        Text(
                          r.title,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingInsights() {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Generating personalized insights...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is analyzing your nutrition patterns to provide actionable recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  


  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  
  // Multi-line Chart for Weekly Comparison
  Widget _buildWeeklyComparisonChart() {
    // Build current week and last week calorie series from data
    List<double> _seriesFromWeekly(Map<String, dynamic> data, DateTime weekStart) {
      final Map<String, dynamic> rawDaily = (data['dailyData'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final Map<String, Map<String, double>> daily = {
        for (final entry in rawDaily.entries)
          entry.key: (entry.value as Map?)
                  ?.map((k, v) => MapEntry<String, double>(k.toString(), _toDouble(v)))
                  .cast<String, double>() ??
              <String, double>{}
      };
      final keys = List.generate(7, (i) {
        final d = DateTime(weekStart.year, weekStart.month, weekStart.day).add(Duration(days: i));
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      });
      return [
        for (final day in keys) (daily[day]?['calories'] ?? 0.0)
      ];
    }

    final weekStart = _selectedWeekStart;
    final lastWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    final current = _seriesFromWeekly(_weeklyData, weekStart);
    final previous = _seriesFromWeekly(_lastWeekData, lastWeekStart);
    final double maxY = ([...current, ...previous].fold<double>(0, (p, v) => v > p ? v : p) * 1.2).clamp(800, 4000);

    final bool noData = current.every((v) => v == 0) && previous.every((v) => v == 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Comparison',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          if (_isWeeklyLoading)
            SizedBox(height: 250, child: _buildChartSkeleton())
          else if (noData)
            _buildNoDataBanner('No data for this week')
          else
            SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((i) {
                      return const TouchedSpotIndicatorData(
                        FlLine(color: Colors.transparent),
                        FlDotData(show: false),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        final v = barSpot.y;
                        final goal = _goals?.calorieGoal ?? 0;
                        final pct = goal > 0 ? (v / goal) * 100 : 0;
                        return LineTooltipItem(
                          '${v.toStringAsFixed(0)} kcal\n${pct.toStringAsFixed(0)}% of goal',
                          const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                    if (event is FlTapUpEvent && response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                      final spot = response.lineBarSpots!.first;
                      final dayIndex = spot.x.toInt();
                      if (dayIndex >= 0 && dayIndex < 7) {
                        final date = weekStart.add(Duration(days: dayIndex));
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MealTrackerScreen(
                              showBackButton: true,
                              initialDate: date,
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 200,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        Widget text;
                        if (value.toInt() < days.length) {
                          text = Text(days[value.toInt()], style: style);
                        } else {
                          text = const Text('', style: style);
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 200,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  // Current week calories (Mon-Sun)
                  LineChartBarData(
                    spots: [for (int i = 0; i < 7; i++) FlSpot(i.toDouble(), i < current.length ? current[i] : 0)],
                    isCurved: true,
                    color: Colors.green[600]!,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.green[600]!,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                  // Previous week calories
                  LineChartBarData(
                    spots: [for (int i = 0; i < 7; i++) FlSpot(i.toDouble(), i < previous.length ? previous[i] : 0)],
                    isCurved: true,
                    color: Colors.blue[400]!,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.blue[400]!,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                  // Daily goal reference line (dashed)
                  if ((_goals?.calorieGoal ?? 0) > 0)
                    LineChartBarData(
                      spots: [
                        FlSpot(0, _goals!.calorieGoal),
                        FlSpot(6, _goals!.calorieGoal),
                      ],
                      color: Colors.orange,
                      barWidth: 2,
                      isCurved: false,
                      dashArray: [6, 6],
                      dotData: FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
          
          // Legend
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green[600]!, 'This Week'),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.blue[400]!, 'Last Week'),
            ],
          ),
        ],
      ),
    );
  }



  

  Widget _buildMacroLegendItem(String label, Color color) {
    return Semantics(
      label: 'Legend item: $label',
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
          ),
        ),
      ],
      ),
    );
  }

  // Multiple Pie Charts for Week Comparison
  Widget _buildWeeklyPieCharts() {
    Map<String, double> totalsFrom(Map<String, dynamic> weekly) {
      final Map<String, dynamic> rawDaily = (weekly['dailyData'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      double sumKey(String key) {
        double s = 0;
        for (final entry in rawDaily.entries) {
          final dayMap = (entry.value as Map?)
                  ?.map((k, v) => MapEntry<String, double>(k.toString(), _toDouble(v)))
                  .cast<String, double>() ??
              <String, double>{};
          s += dayMap[key] ?? 0;
        }
        return s;
      }
      return {
        'protein': sumKey('protein'),
        'carbs': sumKey('carbs'),
        'fat': sumKey('fat'),
        'fiber': sumKey('fiber'),
        'sugar': sumKey('sugar'),
      };
    }

    PieChartData pieFromTotals(Map<String, double> t, bool isCurrent) {
      final total = (t['protein'] ?? 0) + (t['carbs'] ?? 0) + (t['fat'] ?? 0) + (t['fiber'] ?? 0) + (t['sugar'] ?? 0);
      double pct(double v) => total <= 0 ? 0 : (v / total) * 100;
      return PieChartData(
        sections: [
          PieChartSectionData(
            color: isCurrent ? Colors.red[400] : Colors.red[300],
            value: pct(t['protein'] ?? 0),
            title: '${pct(t['protein'] ?? 0).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: isCurrent ? Colors.blue[400] : Colors.blue[300],
            value: pct(t['carbs'] ?? 0),
            title: '${pct(t['carbs'] ?? 0).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: isCurrent ? Colors.green[400] : Colors.green[300],
            value: pct(t['fat'] ?? 0),
            title: '${pct(t['fat'] ?? 0).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: isCurrent ? Colors.purple[400] : Colors.purple[300],
            value: pct(t['fiber'] ?? 0),
            title: '${pct(t['fiber'] ?? 0).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: isCurrent ? Colors.orange[400] : Colors.orange[300],
            value: pct(t['sugar'] ?? 0),
            title: '${pct(t['sugar'] ?? 0).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        centerSpaceRadius: 30,
        sectionsSpace: 2,
      );
    }

    final currentTotals = totalsFrom(_weeklyData);
    final lastTotals = totalsFrom(_lastWeekData);

    final bool noDataCurrent = currentTotals.values.every((v) => (v) == 0);
    final bool noDataLast = lastTotals.values.every((v) => (v) == 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Macro Distribution',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              // This week pie chart
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'This Week',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isWeeklyLoading)
                      SizedBox(height: 150, child: _buildChartSkeleton())
                    else if (noDataCurrent)
                      _buildNoDataBanner('No data')
                    else
                      SizedBox(
                        height: 150,
                        child: PieChart(
                          pieFromTotals(currentTotals, true),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Last week pie chart
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Last Week',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isWeeklyLoading)
                      SizedBox(height: 150, child: _buildChartSkeleton())
                    else if (noDataLast)
                      _buildNoDataBanner('No data')
                    else
                      SizedBox(
                        height: 150,
                        child: PieChart(
                          pieFromTotals(lastTotals, false),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Legend for pie charts
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMacroLegendItem('Protein', Colors.red[400]!),
              _buildMacroLegendItem('Carbs', Colors.blue[400]!),
              _buildMacroLegendItem('Fat', Colors.green[400]!),
              _buildMacroLegendItem('Fiber', Colors.purple[400]!),
              _buildMacroLegendItem('Sugar', Colors.orange[400]!),
            ],
          ),
          
          // Legend
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMacroLegendItem('Protein', Colors.red[400]!),
              const SizedBox(width: 16),
              _buildMacroLegendItem('Carbs', Colors.blue[400]!),
              const SizedBox(width: 16),
              _buildMacroLegendItem('Fat', Colors.green[400]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataBanner(String message) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined, color: Colors.grey[400], size: 36),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(6, (i) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}