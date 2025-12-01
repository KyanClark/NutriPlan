import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_nutrition_goals.dart';
// Removed external analytics service; using inline data fetchers
import '../../services/ai_insights_service.dart';
import '../../services/recipe_service.dart';
import '../../widgets/profile_avatar_widget.dart';
import '../profile/profile_screen.dart';
import '../recipes/recipe_info_screen.dart';
import '../../models/recipes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_logger.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _isWeeklyLoading = false;
  bool _isMonthlyLoading = false;
  UserNutritionGoals? _goals;
  Map<String, dynamic> _weeklyData = {};
  Map<String, dynamic> _monthlyData = {};
  final Map<String, Map<String, dynamic>> _weeklyCache = {};
  final Map<String, Map<String, dynamic>> _monthlyCache = {};
  List<Recipe> _allRecipes = [];
  String _selectedPeriod = 'weekly'; // 'weekly' | 'monthly'
  bool _showLastWeekComparison = false; // Toggle for last week comparison
  Map<String, dynamic> _lastWeekData = {}; // Store last week's data for comparison
  List<Map<String, String>> _weeklyInsights = [];
  bool _isGeneratingWeeklyInsights = false;
  String? _avatarUrl;
  String? _gender;
  static String? _cachedAvatarUrl;
  static String? _cachedGender;
  static bool _hasFetchedAvatar = false;
  String? _weeklyInsightsCacheKey; // Prevent redundant AI calls when data hasn't changed
  DateTime? _lastInsightsGeneration; // Track when insights were last generated
  String? _lastMealsHash; // Track meals data hash
  String? _lastPreferencesHash; // Track dietary preferences hash
  List<Map<String, String>>? _cachedInsights; // Cache the insights themselves
  final Set<int> _expandedInsights = {}; // Track which insights are expanded
  final Set<int> _seenInsights = {}; // Track which insights have been tapped (for green glow)
  
  // Cache for analytics data by period to prevent skeleton on every tab switch
  // Similar to meal tracker - cache by specific week/month periods
  static final Map<String, UserNutritionGoals?> _cachedGoalsByPeriod = {};
  static final Map<String, Map<String, dynamic>> _cachedWeeklyDataByPeriod = {};
  static final Map<String, Map<String, dynamic>> _cachedMonthlyDataByPeriod = {};
  
  late TabController _tabController;
  // Week selection for Daily Calorie Intake (defaults to current week)
  late DateTime _selectedWeekStart; // Monday of selected week
  // Month selection for Monthly views (defaults to current month)
  late DateTime _selectedMonthStart; // First day of selected month

  @override
  bool get wantKeepAlive => true; // Preserve state when navigating away

  // Helper to create cache keys for periods
  String _weekKey(DateTime weekStart) =>
      'w:${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  
  String _monthKey(DateTime monthStart) =>
      'm:${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';

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
    
    // Check cache for current periods (like meal tracker)
    _loadAnalyticsData();
    
    // Only fetch avatar if not already cached
    if (!_hasFetchedAvatar) {
    _fetchUserAvatar();
    } else {
      _avatarUrl = _cachedAvatarUrl;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;

    final weekKey = _weekKey(_selectedWeekStart);
    final monthKey = _monthKey(_selectedMonthStart);

    // Check if we have cached data for both current week and month
    final hasCachedWeek = _cachedWeeklyDataByPeriod.containsKey(weekKey);
    final hasCachedMonth = _cachedMonthlyDataByPeriod.containsKey(monthKey);
    final hasCachedGoals = _cachedGoalsByPeriod.containsKey('goals');

    // If we have cached data for current periods, use it immediately without skeleton
    if (hasCachedWeek && hasCachedMonth && hasCachedGoals) {
      setState(() {
        _goals = _cachedGoalsByPeriod['goals'];
        _weeklyData = Map<String, dynamic>.from(_cachedWeeklyDataByPeriod[weekKey] ?? {});
        _monthlyData = Map<String, dynamic>.from(_cachedMonthlyDataByPeriod[monthKey] ?? {});
        _isLoading = false;
      });
    } else {
      // First time for these periods: show skeleton while loading
    setState(() => _isLoading = true);
    }
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _goals = null;
          _isLoading = false;
        });
        _cachedGoalsByPeriod.remove('goals');
        _cachedWeeklyDataByPeriod.remove(weekKey);
        _cachedMonthlyDataByPeriod.remove(monthKey);
        return;
      }

      // Fetch user nutrition goals (cache by 'goals' key since it's user-specific, not period-specific)
      UserNutritionGoals? userGoals;
      if (!hasCachedGoals) {
      final prefsRes = await Supabase.instance.client
          .from('user_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
        userGoals = prefsRes != null ? UserNutritionGoals.fromMap(prefsRes) : null;
        _cachedGoalsByPeriod['goals'] = userGoals;
      } else {
        userGoals = _cachedGoalsByPeriod['goals'];
      }

      // Fetch weekly data if not cached
      Map<String, dynamic> weeklyData;
      if (!hasCachedWeek) {
        weeklyData = await _getWeeklyData(user.id, weekStart: _selectedWeekStart);
        _cachedWeeklyDataByPeriod[weekKey] = Map<String, dynamic>.from(weeklyData);
      } else {
        weeklyData = Map<String, dynamic>.from(_cachedWeeklyDataByPeriod[weekKey] ?? {});
      }

      // Fetch monthly data if not cached
      Map<String, dynamic> monthlyData;
      if (!hasCachedMonth) {
        monthlyData = await _getMonthlyData(user.id, monthStart: _selectedMonthStart);
        _cachedMonthlyDataByPeriod[monthKey] = Map<String, dynamic>.from(monthlyData);
      } else {
        monthlyData = Map<String, dynamic>.from(_cachedMonthlyDataByPeriod[monthKey] ?? {});
      }

      // Always refresh in background for freshness (but don't show skeleton if we had cache)
      if (hasCachedWeek && hasCachedMonth && hasCachedGoals) {
        // Background refresh - fetch fresh data but don't show loading
        _refreshAnalyticsDataInBackground();
      }

      if (!mounted) return;
      setState(() {
        _goals = userGoals;
        _weeklyData = weeklyData;
        _monthlyData = monthlyData;
        _isLoading = false;
      });

      // Generate AI insights
      _generateWeeklyInsights();
    } catch (e) {
      AppLogger.error('Error loading analytics data',  e);
      if (!mounted) return;
      setState(() {
        _goals = null;
        _weeklyData = {};
        _monthlyData = {};
        _isLoading = false;
      });
      // Clear cache on error
      _cachedGoalsByPeriod.remove('goals');
      _cachedWeeklyDataByPeriod.remove(weekKey);
      _cachedMonthlyDataByPeriod.remove(monthKey);
    }
  }

  // Background refresh without showing skeleton
  Future<void> _refreshAnalyticsDataInBackground() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || !mounted) return;

      final weekKey = _weekKey(_selectedWeekStart);
      final monthKey = _monthKey(_selectedMonthStart);

      // Fetch fresh data in background
      final prefsRes = await Supabase.instance.client
          .from('user_preferences')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      final userGoals = prefsRes != null ? UserNutritionGoals.fromMap(prefsRes) : null;
      final weeklyData = await _getWeeklyData(user.id, weekStart: _selectedWeekStart);
      final monthlyData = await _getMonthlyData(user.id, monthStart: _selectedMonthStart);

      // Update cache with fresh data
      _cachedGoalsByPeriod['goals'] = userGoals;
      _cachedWeeklyDataByPeriod[weekKey] = Map<String, dynamic>.from(weeklyData);
      _cachedMonthlyDataByPeriod[monthKey] = Map<String, dynamic>.from(monthlyData);

      // Update UI if still mounted
      if (!mounted) return;
      setState(() {
        _goals = userGoals;
        _weeklyData = weeklyData;
        _monthlyData = monthlyData;
      });

      // Regenerate insights with fresh data
      _generateWeeklyInsights();
    } catch (e) {
      AppLogger.error('Error refreshing analytics data in background', e);
    }
  }

  Future<void> _refreshWeeklyData() async {
    if (!mounted) return;
    
    final weekKey = _weekKey(_selectedWeekStart);
    
    // Check if we have cached data for this week
    final hasCachedWeek = _cachedWeeklyDataByPeriod.containsKey(weekKey);
    
    // Only show loading if we don't have cached data
    if (!hasCachedWeek) {
    setState(() => _isWeeklyLoading = true);
    }
    
    try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

      // Fetch weekly data for the selected week
      final weeklyData = await _getWeeklyData(user.id, weekStart: _selectedWeekStart);
      
      // Update cache
      _cachedWeeklyDataByPeriod[weekKey] = Map<String, dynamic>.from(weeklyData);
      
      if (!mounted) return;
      setState(() {
        _weeklyData = weeklyData;
        _isWeeklyLoading = false;
      });

      // Regenerate insights for the new week
      _generateWeeklyInsights();
    } catch (e) {
      AppLogger.error('Error refreshing weekly data', e);
      if (mounted) {
        setState(() => _isWeeklyLoading = false);
      }
      // Clear cache on error
      _cachedWeeklyDataByPeriod.remove(weekKey);
    }
  }

  Future<void> _refreshMonthlyData() async {
    if (!mounted) return;
    
    final monthKey = _monthKey(_selectedMonthStart);
    
    // Check if we have cached data for this month
    final hasCachedMonth = _cachedMonthlyDataByPeriod.containsKey(monthKey);
    
    // Only show loading if we don't have cached data
    if (!hasCachedMonth) {
      setState(() => _isMonthlyLoading = true);
    }
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final monthlyData = await _getMonthlyData(user.id, monthStart: _selectedMonthStart);
      
      // Update cache
      _cachedMonthlyDataByPeriod[monthKey] = Map<String, dynamic>.from(monthlyData);
      
      if (!mounted) return;
      setState(() {
        _monthlyData = monthlyData;
        _isMonthlyLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error refreshing monthly data', e);
      if (mounted) {
        setState(() => _isMonthlyLoading = false);
      }
      // Clear cache on error
      _cachedMonthlyDataByPeriod.remove(monthKey);
    }
  }


  Future<void> _fetchUserAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch avatar URL
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      
      // Update cached value
      _cachedAvatarUrl = profileData?['avatar_url'] as String?;
      
      // Fetch gender from user_preferences
      final prefsData = await Supabase.instance.client
          .from('user_preferences')
          .select('gender')
          .eq('user_id', user.id)
          .maybeSingle();
      
      _cachedGender = prefsData?['gender'] as String?;
      _hasFetchedAvatar = true;
      
      if (!mounted) return;
      setState(() {
        _avatarUrl = _cachedAvatarUrl;
        _gender = _cachedGender;
      });
    } catch (e) {
      AppLogger.error('Error fetching user avatar', e);
    }
  }

  Future<void> _generateWeeklyInsights() async {
    if (!mounted) return;
    
    try {
      // Check if we should use cached insights
      final now = DateTime.now();
      final shouldUseCache = _cachedInsights != null &&
          _lastInsightsGeneration != null &&
          now.difference(_lastInsightsGeneration!).inDays < 1; // Cache valid for 1 day
      
      if (shouldUseCache) {
        // Check if meals or preferences have changed
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Get current meals hash (last 7 days)
          final weekAgo = now.subtract(const Duration(days: 7));
          final recentMeals = await Supabase.instance.client
              .from('meal_plan_history')
              .select('id, completed_at')
              .eq('user_id', user.id)
              .gte('completed_at', weekAgo.toUtc().toIso8601String())
              .order('completed_at', ascending: false);
          
          final mealsHash = recentMeals.length.toString() + 
              (recentMeals.isNotEmpty ? recentMeals.first['completed_at'].toString() : '');
          
          // Get current preferences hash
          final prefs = await Supabase.instance.client
              .from('user_preferences')
              .select('health_conditions, diet_type, nutrition_needs, updated_at')
              .eq('user_id', user.id)
              .maybeSingle();
          
          final prefsHash = prefs != null 
              ? (prefs['health_conditions']?.toString() ?? '') +
                (prefs['diet_type']?.toString() ?? '') +
                (prefs['nutrition_needs']?.toString() ?? '') +
                (prefs['updated_at']?.toString() ?? '')
              : '';
          
          // If nothing changed, use cached insights
          if (_lastMealsHash == mealsHash && _lastPreferencesHash == prefsHash) {
            if (mounted) {
              setState(() {
                _weeklyInsights = _cachedInsights!;
                _isGeneratingWeeklyInsights = false;
              });
            }
            return;
          }
          
          // Update hashes
          _lastMealsHash = mealsHash;
          _lastPreferencesHash = prefsHash;
        }
      }
      
      setState(() => _isGeneratingWeeklyInsights = true);

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
      if (_weeklyInsightsCacheKey == key && _weeklyInsights.isNotEmpty && shouldUseCache) {
        setState(() => _isGeneratingWeeklyInsights = false);
        return;
      }

      // Fetch available recipes for meal recommendations (allergy-filtered)
      final user = Supabase.instance.client.auth.currentUser;
      final recipes = await RecipeService.fetchRecipes(userId: user?.id);
      final recipeNames = recipes.map((r) => r.title).toList();
      if (mounted) {
        setState(() {
          _allRecipes = recipes;
        });
      }

      // Check if user has logged meals for today
      bool hasMealsToday = false;
      if (user != null) {
        try {
          final today = DateTime.now();
          final startOfDay = DateTime(today.year, today.month, today.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));
          
          final todayMeals = await Supabase.instance.client
              .from('meal_plan_history')
              .select('id')
              .eq('user_id', user.id)
              .gte('completed_at', startOfDay.toUtc().toIso8601String())
              .lt('completed_at', endOfDay.toUtc().toIso8601String())
              .limit(1);
          
          hasMealsToday = todayMeals.isNotEmpty;
        } catch (e) {
          AppLogger.error('Error checking today meals', e);
          // Default to true to avoid false positives
          hasMealsToday = true;
        }
      }

      final insights = await AIInsightsService.generateWeeklyInsights(
        _weeklyData, 
        _monthlyData, 
        _goals,
        availableRecipes: recipeNames,
        hasMealsToday: hasMealsToday,
      );
      if (!mounted) return;
      setState(() {
        _weeklyInsights = insights;
        _cachedInsights = insights; // Cache the insights
        _lastInsightsGeneration = DateTime.now(); // Update generation time
        _weeklyInsightsCacheKey = key;
        _isGeneratingWeeklyInsights = false;
        _seenInsights.clear(); // Reset seen insights when new insights are generated
      });
    } catch (e) {
      AppLogger.error('Error generating weekly insights', e);
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

  // Separate skeleton widgets for each section (like meal tracker)
  Widget _buildSummaryRowSkeleton() {
    return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 100,
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
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 140,
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
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
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
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 40,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
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
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 40,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
    );
  }
          
  Widget _buildCalorieCardSkeleton() {
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
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
    );
  }
          
  Widget _buildInsightsCardSkeleton() {
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
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 150,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(2, (index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 200,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 280,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
    );
  }

  Widget _buildPieChartSkeleton() {
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
                Container(
                  width: 150,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 80, 231, 93),
                  shape: BoxShape.circle,
                ),
                child: ProfileAvatarWidget(
                  avatarUrl: _avatarUrl ?? _cachedAvatarUrl,
                  gender: _gender ?? _cachedGender,
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period switch centered above the summary card - always visible
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
                  _isLoading ? _buildSummaryRowSkeleton() : _buildTopSummaryRow(),
                  const SizedBox(height: 30),
                  // Calorie card - show skeleton if loading
                  _isLoading ? _buildCalorieCardSkeleton() : _buildCalorieCardWithSegmentedArea(),
                  const SizedBox(height: 30),
                
                  // Weekly Insights Section - show skeleton if loading
                  _isLoading ? _buildInsightsCardSkeleton() : _buildWeeklyInsightsCard(),
                const SizedBox(height: 30),
                
                  // Charts - show skeleton if loading
                  _isLoading ? _buildPieChartSkeleton() : _buildWeeklyPieCharts(),
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
            child: _selectedPeriod == 'monthly' && sortedKeys.length > 10
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: sortedKeys.length * 50.0, // 50px per day
                      height: 220,
                      child: LineChart(_buildMonthlyChartData(spots, sortedKeys, dailyGoal)),
                    ),
                  )
                : _buildChartWithComparison(spots, sortedKeys, dailyGoal),
          ),
        ],
      ),
    );
  }

  Widget _buildChartWithComparison(List<FlSpot> spots, List<String> sortedKeys, double dailyGoal) {
    // Build last week's spots if comparison is enabled
    List<FlSpot>? lastWeekSpots;
    List<String>? lastWeekKeys;
    
    if (_showLastWeekComparison && _lastWeekData.isNotEmpty) {
      final Map<String, dynamic> rawLastWeekDaily = (_lastWeekData['dailyData'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final Map<String, Map<String, double>> lastWeekDaily = {
        for (final entry in rawLastWeekDaily.entries)
          entry.key: (entry.value as Map?)
                  ?.map((k, v) => MapEntry<String, double>(k.toString(), _toDouble(v)))
                  .cast<String, double>() ??
              <String, double>{}
      };
      
      // Build last week's keys (same structure as current week)
      final lastWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
      lastWeekKeys = List.generate(7, (i) {
        final d = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day).add(Duration(days: i));
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      });
      
      lastWeekSpots = [];
      for (int i = 0; i < lastWeekKeys.length; i++) {
        final day = lastWeekKeys[i];
        final calories = lastWeekDaily[day]?['calories'] ?? 0;
        lastWeekSpots.add(FlSpot(i.toDouble(), calories));
      }
    }
    
    return LineChart(_buildMonthlyChartData(spots, sortedKeys, dailyGoal, lastWeekSpots: lastWeekSpots, lastWeekKeys: lastWeekKeys));
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
            ..._weeklyInsights.asMap().entries.map((entry) => 
              _buildInsightItem(entry.key, entry.value['title']!, entry.value['description']!))
          else
            _buildEmptyInsights(),
        ],
      ),
    );
  }

  Widget _buildInsightItem(int index, String title, String description) {
    final isExpanded = _expandedInsights.contains(index);
    
    // Extract preview - always truncate to ~100 chars for collapsed view
    String previewText;
    final firstPeriod = description.indexOf('.');
    final firstNewline = description.indexOf('\n');
    int cutPoint = description.length;
    
    // Always create a preview (truncate if longer than 80 chars)
    if (description.length > 80) {
      // Prefer cutting at sentence end or newline
      if (firstPeriod > 0 && firstPeriod < 120) {
        cutPoint = firstPeriod + 1;
      } else if (firstNewline > 0 && firstNewline < 120) {
        cutPoint = firstNewline;
      } else {
        // Find last space before 120 chars to avoid cutting words
        cutPoint = description.lastIndexOf(' ', 120);
        if (cutPoint == -1 || cutPoint < 60) cutPoint = 120;
      }
      previewText = description.substring(0, cutPoint).trim();
      if (cutPoint < description.length) {
        previewText += '...';
      }
    } else {
      // Short description - show full but still allow expand/collapse for consistency
      previewText = description;
    }
    
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

    final hasBeenSeen = _seenInsights.contains(index);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasBeenSeen ? Colors.transparent : Colors.green[400]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasBeenSeen 
                ? Colors.grey.withValues(alpha: 0.05)
                : Colors.green.withValues(alpha: 0.15),
            blurRadius: hasBeenSeen ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (title + expand button) - always visible
          InkWell(
            onTap: () {
              setState(() {
                _seenInsights.add(index); // Mark as seen when tapped
                if (isExpanded) {
                  _expandedInsights.remove(index);
                } else {
                  _expandedInsights.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                        if (!isExpanded) ...[
          const SizedBox(height: 8),
          Text(
                            previewText,
            style: TextStyle(
              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description.length > 80) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Tap to read more',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
              height: 1.4,
            ),
                        ),
                        if (matchedRecipes.isNotEmpty) ...[
                          const SizedBox(height: 12),
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
                  )
                : const SizedBox.shrink(),
          ),
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

  // Single Pie Chart for Macro Distribution with Week/Month Navigation
  Widget _buildWeeklyPieCharts() {
    Map<String, double> totalsFrom(Map<String, dynamic> data) {
      final Map<String, dynamic> rawDaily = (data['dailyData'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
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

    PieChartData pieFromTotals(Map<String, double> t) {
      final total = (t['protein'] ?? 0) + (t['carbs'] ?? 0) + (t['fat'] ?? 0) + (t['fiber'] ?? 0) + (t['sugar'] ?? 0);
      double pct(double v) => total <= 0 ? 0 : (v / total) * 100;
      return PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.red[400]!,
            value: pct(t['protein'] ?? 0),
            title: '${pct(t['protein'] ?? 0).toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
                  ),
          PieChartSectionData(
            color: Colors.blue[400]!,
            value: pct(t['carbs'] ?? 0),
            title: '${pct(t['carbs'] ?? 0).toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(
                          fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
                    ),
          PieChartSectionData(
            color: Colors.green[400]!,
            value: pct(t['fat'] ?? 0),
            title: '${pct(t['fat'] ?? 0).toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(
                            fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              ),
            ),
          PieChartSectionData(
            color: Colors.purple[400]!,
            value: pct(t['fiber'] ?? 0),
            title: '${pct(t['fiber'] ?? 0).toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.orange[400]!,
            value: pct(t['sugar'] ?? 0),
            title: '${pct(t['sugar'] ?? 0).toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(
            fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
          ),
        ),
      ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
    );
  }

    final Map<String, dynamic> selectedData = _selectedPeriod == 'weekly' ? _weeklyData : _monthlyData;
    final currentTotals = totalsFrom(selectedData);
    final bool noData = currentTotals.values.every((v) => (v) == 0);
    final bool isLoading = _selectedPeriod == 'weekly' ? _isWeeklyLoading : _isMonthlyLoading;

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
            'Macro Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
                              ),
                            ),
          const SizedBox(height: 20),
          
          // Single pie chart
          Center(
            child: Column(
              children: [
                if (isLoading)
                  SizedBox(height: 250, child: _buildChartSkeleton())
                else if (noData)
                  SizedBox(
                    height: 250,
                    child: _buildNoDataBanner('No data for this ${_selectedPeriod == 'weekly' ? 'week' : 'month'}'),
                  )
                else
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: PieChart(
                      pieFromTotals(currentTotals),
                              ),
                            ),
                          ],
            ),
          ),
          const SizedBox(height: 20),
          // Legend for pie chart
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

  LineChartData _buildMonthlyChartData(List<FlSpot> spots, List<String> sortedKeys, double dailyGoal, {List<FlSpot>? lastWeekSpots, List<String>? lastWeekKeys}) {
    return LineChartData(
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
          // Navigation removed - chart is now informational only
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
            interval: _selectedPeriod == 'monthly' && sortedKeys.length > 15 ? 2.0 : 1.0, // Show every other date if too many
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
            reservedSize: 50, // Increased to accommodate goal label
            getTitlesWidget: (value, meta) {
              final intValue = value.toInt();
              // Show goal only on the exact goal line or closest to it
              final goalDiff = (intValue - dailyGoal).abs();
              if (goalDiff < 30) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      intValue.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Goal',
                      style: TextStyle(fontSize: 8, color: Colors.orange[700], fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              }
              return Text(intValue.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
            },
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
    );
  }
}