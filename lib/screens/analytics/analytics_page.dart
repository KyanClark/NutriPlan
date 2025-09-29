import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_nutrition_goals.dart';
import '../../services/analytics_service.dart';
import '../../services/ai_insights_service.dart';

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

      // Fetch weekly and monthly data
      final weeklyData = await AnalyticsService.getWeeklyData(user.id);
      final monthlyData = await AnalyticsService.getMonthlyData(user.id);

      if (!mounted) return;
      setState(() {
        _goals = userGoals;
        _weeklyData = weeklyData;
        _monthlyData = monthlyData;
        _isLoading = false;
      });

      // Generate AI insights
      _generateAIInsights();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Statistics',
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
                'Calories - ${_selectedPeriod == 'weekly' ? 'Weekly' : 'Monthly'}',
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
            '${_selectedPeriod == 'weekly' ? 'Weekly' : 'Last 7 Days'} Progress',
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI is analyzing your nutrition patterns...',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
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
}