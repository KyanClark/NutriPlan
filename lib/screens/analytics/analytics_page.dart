import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/user_nutrition_goals.dart';
// Removed external analytics service; using inline data fetchers
import '../../services/ai_insights_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  UserNutritionGoals? _goals;
  Map<String, dynamic> _weeklyData = {};
  Map<String, dynamic> _monthlyData = {};
  String _aiInsights = '';
  bool _isGeneratingInsights = false;
  String _selectedPeriod = 'weekly'; // 'weekly' or 'monthly'
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalyticsData();
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
      final weeklyData = await _getWeeklyData(user.id);
      final monthlyData = await _getMonthlyData(user.id);

      if (!mounted) return;
      setState(() {
        _goals = userGoals;
        _weeklyData = weeklyData;
        _monthlyData = monthlyData;
        _isLoading = false;
      });

      // Generate AI insights
      _generateAIInsights();
      
      // Start generating insights
      setState(() { _isGeneratingInsights = true; });
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

  Future<void> _generateAIInsights() async {
    if (!mounted) return;
    setState(() => _isGeneratingInsights = true);

    try {
      final insights = await AIInsightsService.generateNutritionInsights(_weeklyData, _monthlyData, _goals);
      if (!mounted) return;
      setState(() {
        _aiInsights = insights;
        _isGeneratingInsights = false;
      });
    } catch (e) {
      print('Error generating AI insights: $e');
      if (!mounted) return;
      setState(() {
        _aiInsights = AIInsightsService.getDefaultInsights();
        _isGeneratingInsights = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getWeeklyData(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final startUtc = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).toUtc();
    final endUtc = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59).toUtc();
    final res = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
        .eq('user_id', userId)
        .gte('completed_at', startUtc.toIso8601String())
        .lte('completed_at', endUtc.toIso8601String())
        .order('completed_at', ascending: true);
    return _summarize(res);
  }

  Future<Map<String, dynamic>> _getMonthlyData(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toUtc();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toUtc();
    final res = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
        .eq('user_id', userId)
        .gte('completed_at', startOfMonth.toIso8601String())
        .lte('completed_at', endOfMonth.toIso8601String())
        .order('completed_at', ascending: true);
    return _summarize(res);
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
      dailyData[key]!['calories'] = (dailyData[key]!['calories'] ?? 0) + c('calories');
    }
    final count = meals.isEmpty ? 1 : meals.length.toDouble();
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
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Add menu options if needed
            },
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
                  // Calories Section
                  _buildCaloriesCard(),
                  const SizedBox(height: 30),
                  
                  // Weekly Chart
                  _buildWeeklyChart(),
                  const SizedBox(height: 30),
                  
                  // Multi-line Chart for Weekly Comparison
                  _buildWeeklyComparisonChart(),
                  const SizedBox(height: 30),
                  
                  // Stacked Bar Chart for Macro Comparison
                  _buildMacroComparisonChart(),
                  const SizedBox(height: 30),
                  
                  // Multiple Pie Charts for Week Comparison
                  _buildWeeklyPieCharts(),
                  const SizedBox(height: 30),
                  
                  // AI Insights Section
                  _buildAIInsightsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildCaloriesCard() {
    final dailyGoal = _goals?.calorieGoal ?? 2000.0;
    final currentData = _selectedPeriod == 'weekly' ? _weeklyData : _monthlyData;
    final totals = currentData['totals'] as Map<String, double>? ?? {};
    final averages = currentData['averages'] as Map<String, double>? ?? {};
    final totalCalories = totals['calories'] ?? 0.0;
    final averageCalories = averages['calories'] ?? 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
              Text(
                'Calories • ${_selectedPeriod == 'weekly' ? 'This Week' : 'This Month'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              // Period selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = 'weekly'),
                      child: Text(
                        'Weekly',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedPeriod == 'weekly' ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = 'monthly'),
                      child: Text(
                        'Monthly',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedPeriod == 'monthly' ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${totalCalories.toStringAsFixed(0)} Kcal',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Avg: ${averageCalories.toStringAsFixed(0)} Kcal/day',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${dailyGoal.toStringAsFixed(0)} Kcal/day',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Progress indicator
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: (averageCalories / dailyGoal).clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        averageCalories >= dailyGoal * 0.8 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${((averageCalories / dailyGoal) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
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

  Widget _buildWeeklyChart() {
    final dailyGoal = _goals?.calorieGoal ?? 2000.0;
    final currentData = _selectedPeriod == 'weekly' ? _weeklyData : _monthlyData;
    final dailyData = currentData['dailyData'] as Map<String, Map<String, double>>? ?? {};
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Get daily calories for the current period
    final dailyCalories = <double>[];
    if (_selectedPeriod == 'weekly') {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyCalories.add(dailyData[dateKey]?['calories'] ?? 0.0);
      }
    } else {
      // For monthly, show last 7 days
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyCalories.add(dailyData[dateKey]?['calories'] ?? 0.0);
      }
    }
    
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
            _selectedPeriod == 'weekly' ? 'Weekly Progress' : 'Monthly Snapshot',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // Chart
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailyCalories.asMap().entries.map((entry) {
                final index = entry.key;
                final calories = entry.value;
                final percentage = dailyGoal > 0 ? (calories / dailyGoal * 100) : 0.0;
                final barHeight = (percentage / 100 * 120).clamp(10.0, 120.0);
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Percentage label
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Bars container
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Target bar (dashed)
                        Container(
                          width: 8,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        
                        // Actual calories bar
                        Container(
                          width: 12,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: percentage >= 80 && percentage <= 120
                                ? Colors.green
                                : percentage < 80
                                    ? Colors.orange
                                    : Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Day label
                    Text(
                      _selectedPeriod == 'weekly' ? days[index] : '${DateTime.now().subtract(Duration(days: 6 - index)).day}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.grey[300]!, 'Target'),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.green, 'On Track'),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.orange, 'Under Target'),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.red, 'Over Target'),
            ],
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

  Widget _buildAIInsightsCard() {
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
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.green[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Nutrition Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_isGeneratingInsights)
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
          
          if (_isGeneratingInsights)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green[50]!,
                    Colors.blue[50]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green[200]!.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green[100]!.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Simple loading indicator (typing cursor removed)
                  const SizedBox(width: 4),
                  const SizedBox(
                    width: 28,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI is analyzing your nutrition patterns...',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generating personalized insights',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_aiInsights.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                _aiInsights,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Text(
                'AI insights will appear here once your nutrition data is analyzed.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Multi-line Chart for Weekly Comparison
  Widget _buildWeeklyComparisonChart() {
    // This will show multiple weeks of data for comparison
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
          
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
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
                maxY: 2000,
                lineBarsData: [
                  // Current week calories
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 1200),
                      FlSpot(1, 1500),
                      FlSpot(2, 1800),
                      FlSpot(3, 1600),
                      FlSpot(4, 2000),
                      FlSpot(5, 1400),
                      FlSpot(6, 1700),
                    ],
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
                    spots: [
                      FlSpot(0, 1000),
                      FlSpot(1, 1300),
                      FlSpot(2, 1600),
                      FlSpot(3, 1400),
                      FlSpot(4, 1800),
                      FlSpot(5, 1200),
                      FlSpot(6, 1500),
                    ],
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


  // Stacked Bar Chart for Macro Comparison
  Widget _buildMacroComparisonChart() {
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
            'Macro Comparison',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Macro toggles
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMacroToggle('Protein', Colors.red[400]!),
              _buildMacroToggle('Carbs', Colors.blue[400]!),
              _buildMacroToggle('Fat', Colors.green[400]!),
              _buildMacroToggle('Fiber', Colors.purple[400]!),
              _buildMacroToggle('Sugar', Colors.orange[400]!),
            ],
          ),
          const SizedBox(height: 12),
          
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 2000,
                barTouchData: BarTouchData(
                  enabled: false,
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
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const weeks = ['This Week', 'Last Week'];
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        Widget text;
                        if (value.toInt() < weeks.length) {
                          text = Text(weeks[value.toInt()], style: style);
                        } else {
                          text = const Text('', style: style);
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: text,
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 400,
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
                barGroups: _buildSelectedMacroBarGroups(),
              ),
            ),
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

  // Toggle state (defaults: Protein, Carbs, Fat on; Fiber, Sugar off)
  final Set<String> _selectedMacros = {'Protein', 'Carbs', 'Fat'};

  Widget _buildMacroToggle(String label, Color color) {
    final bool selected = _selectedMacros.contains(label);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? color : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedMacros.add(label);
          } else {
            _selectedMacros.remove(label);
          }
        });
      },
      backgroundColor: Colors.grey[100],
      shape: StadiumBorder(side: BorderSide(color: selected ? color : Colors.grey[300]!)),
    );
  }

  List<BarChartGroupData> _buildSelectedMacroBarGroups() {
    // Example static numbers; wire to real weekly data if available
    final currentWeek = <String, double>{
      'Protein': 600,
      'Carbs': 1200,
      'Fat': 1600,
      'Fiber': 400,
      'Sugar': 500,
    };
    final lastWeek = <String, double>{
      'Protein': 500,
      'Carbs': 1000,
      'Fat': 1300,
      'Fiber': 350,
      'Sugar': 450,
    };

    List<BarChartRodData> rodsFrom(Map<String, double> data, bool isCurrent) {
      final rods = <BarChartRodData>[];
      void addRod(String key, Color? color) {
        if (_selectedMacros.contains(key)) {
          rods.add(BarChartRodData(
            toY: data[key] ?? 0,
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ));
        }
      }

      addRod('Protein', isCurrent ? Colors.red[400] : Colors.red[300]);
      addRod('Carbs', isCurrent ? Colors.blue[400] : Colors.blue[300]);
      addRod('Fat', isCurrent ? Colors.green[400] : Colors.green[300]);
      addRod('Fiber', isCurrent ? Colors.purple[400] : Colors.purple[300]);
      addRod('Sugar', isCurrent ? Colors.orange[400] : Colors.orange[300]);
      return rods;
    }

    return [
      BarChartGroupData(x: 0, barRods: rodsFrom(currentWeek, true)),
      BarChartGroupData(x: 1, barRods: rodsFrom(lastWeek, false)),
    ];
  }

  Widget _buildMacroLegendItem(String label, Color color) {
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Multiple Pie Charts for Week Comparison
  Widget _buildWeeklyPieCharts() {
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
                    SizedBox(
                      height: 150,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              color: Colors.red[400],
                              value: 40,
                              title: '40%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.blue[400],
                              value: 35,
                              title: '35%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.green[400],
                              value: 25,
                              title: '25%',
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
                        ),
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
                    SizedBox(
                      height: 150,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              color: Colors.red[300],
                              value: 35,
                              title: '35%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.blue[300],
                              value: 40,
                              title: '40%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: Colors.green[300],
                              value: 25,
                              title: '25%',
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
}