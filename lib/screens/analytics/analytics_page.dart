import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/analytics_models.dart';
import '../../services/analytics_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.week;
  String _selectedMetric = 'calories';
  bool _isLoading = true;
  
  // Data storage
  NutritionSummary? _currentSummary;
  ComparativeAnalysis? _comparativeAnalysis;
  List<NutritionalInsight> _insights = [];
  List<ChartDataPoint> _trendData = [];
  Map<String, List<ChartDataPoint>> _multipleTrendData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final now = DateTime.now();
      final currentStart = _getPeriodStart(now, _selectedPeriod);
      final currentEnd = now;
      final previousStart = _getPeriodStart(currentStart.subtract(const Duration(days: 1)), _selectedPeriod);
      final previousEnd = currentStart.subtract(const Duration(days: 1));

      // Load current period summary
      _currentSummary = await AnalyticsService.getNutritionSummary(
        startDate: currentStart,
        endDate: currentEnd,
      );

      if (!mounted) return;

      // Previous period summary is loaded as part of comparative analysis

      // Load comparative analysis
      _comparativeAnalysis = await AnalyticsService.getComparativeAnalysis(
        currentStart: currentStart,
        currentEnd: currentEnd,
        previousStart: previousStart,
        previousEnd: previousEnd,
      );

      if (!mounted) return;

      // Load AI insights
      _insights = await AnalyticsService.generateNutritionalInsights(
        startDate: currentStart,
        endDate: currentEnd,
      );

      if (!mounted) return;

      // Load trend data
      _trendData = await AnalyticsService.getNutritionTrendData(
        period: _selectedPeriod,
        metric: _selectedMetric,
      );

      if (!mounted) return;

      // Load multiple metrics data for comprehensive chart
      _multipleTrendData = await AnalyticsService.getMultipleNutritionTrendData(
        period: _selectedPeriod,
      );

    } catch (e) {
      print('Error loading analytics data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _getPeriodStart(DateTime date, AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.week:
        return date.subtract(Duration(days: date.weekday - 1));
      case AnalyticsPeriod.month:
        return DateTime(date.year, date.month, 1);
      case AnalyticsPeriod.quarter:
        final quarter = ((date.month - 1) / 3).floor();
        return DateTime(date.year, quarter * 3 + 1, 1);
      case AnalyticsPeriod.year:
        return DateTime(date.year, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Nutrition Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6961),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFFFF6961),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up, size: 20)),
            Tab(text: 'Insights', icon: Icon(Icons.lightbulb, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6961)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_currentSummary == null || _comparativeAnalysis == null) {
      return const Center(
        child: Text('No data available', style: TextStyle(fontSize: 16)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          
          // Summary cards
          _buildSummaryCards(),
          const SizedBox(height: 20),
          
          // Comparative analysis
          _buildComparativeAnalysis(),
          const SizedBox(height: 20),
          
          // Quick insights
          _buildQuickInsights(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [AnalyticsPeriod.week, AnalyticsPeriod.month].map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() => _selectedPeriod = period);
                _loadAnalyticsData();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6961) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getPeriodLabel(period),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.week:
        return 'Week';
      case AnalyticsPeriod.month:
        return 'Month';
      case AnalyticsPeriod.quarter:
        return 'Quarter';
      case AnalyticsPeriod.year:
        return 'Year';
    }
  }

  Widget _buildSummaryCards() {
    final summary = _currentSummary!;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Calories',
                '${summary.averageDailyCalories.toStringAsFixed(0)}',
                'kcal/day',
                Icons.local_fire_department,
                const Color(0xFFFF6961),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Protein',
                '${summary.averageDailyProtein.toStringAsFixed(1)}',
                'g/day',
                Icons.fitness_center,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Carbs',
                '${summary.averageDailyCarbs.toStringAsFixed(1)}',
                'g/day',
                Icons.grain,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Fat',
                '${summary.averageDailyFat.toStringAsFixed(1)}',
                'g/day',
                Icons.opacity,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Fiber',
                '${summary.averageDailyFiber.toStringAsFixed(1)}',
                'g/day',
                Icons.eco,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Sodium',
                '${summary.averageDailySodium.toStringAsFixed(0)}',
                'mg/day',
                Icons.water_drop,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
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
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativeAnalysis() {
    final analysis = _comparativeAnalysis!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Period Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...analysis.percentageChanges.entries.map((entry) {
            final change = entry.value;
            final isImprovement = analysis.isImprovement(entry.key);
            final color = isImprovement ? Colors.green : Colors.red;
            final icon = isImprovement ? Icons.trending_up : Icons.trending_down;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _capitalizeFirst(entry.key),
                    style: const TextStyle(fontSize: 14),
                  ),
                  Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickInsights() {
    if (_insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._insights.take(3).map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(NutritionalInsight insight) {
    Color cardColor;
    IconData icon;
    
    switch (insight.type) {
      case InsightType.positive:
        cardColor = Colors.green.shade50;
        icon = Icons.check_circle;
        break;
      case InsightType.warning:
        cardColor = Colors.orange.shade50;
        icon = Icons.warning;
        break;
      case InsightType.recommendation:
        cardColor = Colors.blue.shade50;
        icon = Icons.lightbulb;
        break;
      case InsightType.trend:
        cardColor = Colors.purple.shade50;
        icon = Icons.trending_up;
        break;
      case InsightType.goal:
        cardColor = Colors.pink.shade50;
        icon = Icons.flag;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cardColor.withOpacity(0.8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric selector
          _buildMetricSelector(),
          const SizedBox(height: 20),
          
          // Trend chart
          _buildTrendChart(),
          const SizedBox(height: 20),
          
          // Trend insights
          _buildTrendInsights(),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    final metrics = ['calories', 'protein', 'carbs', 'fat', 'fiber', 'sodium'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _selectedMetric,
        isExpanded: true,
        underline: const SizedBox(),
        items: metrics.map((metric) {
          return DropdownMenuItem(
            value: metric,
            child: Text(_capitalizeFirst(metric)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null && mounted) {
            setState(() => _selectedMetric = value);
            _loadAnalyticsData();
          }
        },
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_trendData.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No trend data available',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nutrition Trends',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF64B5F6)),
                    onPressed: () {
                      if (mounted) {
                        _loadAnalyticsData();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.code, color: Color(0xFF64B5F6)),
                    onPressed: () {
                      // Could show chart data or export functionality
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Legend
          _buildChartLegend(),
          const SizedBox(height: 10),
          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatYAxisLabel(value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _trendData.length) {
                          return Text(
                            _trendData[index].label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                lineBarsData: _buildMultipleLineData(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        return LineTooltipItem(
                          '${_trendData[touchedSpot.x.toInt()].label}: ${touchedSpot.y.toStringAsFixed(1)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> _buildMultipleLineData() {
    // Create multiple lines for different nutrition metrics
    final metrics = ['calories', 'protein', 'carbs', 'fat'];
    final colors = [
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
    ];

    return metrics.map((metric) {
      // Use real data if available, otherwise fall back to demo data
      final dataPoints = _multipleTrendData[metric] ?? _trendData;
      
      return LineChartBarData(
        spots: dataPoints.asMap().entries.map((entry) {
          double value = entry.value.value;
          
          // If using fallback data, adjust values for different metrics
          if (_multipleTrendData[metric] == null) {
            switch (metric) {
              case 'protein':
                value = entry.value.value * 0.3; // Protein is typically lower
                break;
              case 'carbs':
                value = entry.value.value * 0.4; // Carbs are typically higher
                break;
              case 'fat':
                value = entry.value.value * 0.2; // Fat is typically lower
                break;
              default:
                value = entry.value.value; // Calories as base
            }
          }
          
          return FlSpot(entry.key.toDouble(), value);
        }).toList(),
        isCurved: true,
        color: colors[metrics.indexOf(metric)],
        barWidth: 4,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 4,
              color: colors[metrics.indexOf(metric)],
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          color: colors[metrics.indexOf(metric)].withOpacity(0.1),
        ),
      );
    }).toList();
  }

  String _formatYAxisLabel(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildChartLegend() {
    final metrics = ['Calories', 'Protein', 'Carbs', 'Fat'];
    final colors = [
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: metrics.asMap().entries.map((entry) {
        final index = entry.key;
        final metric = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 3,
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              metric,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTrendInsights() {
    if (_trendData.length < 2) {
      return const SizedBox.shrink();
    }

    final firstValue = _trendData.first.value;
    final lastValue = _trendData.last.value;
    final trend = lastValue > firstValue ? 'increasing' : 'decreasing';
    final change = ((lastValue - firstValue) / firstValue * 100).abs();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trend Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your ${_capitalizeFirst(_selectedMetric)} intake is $trend by ${change.toStringAsFixed(1)}% over this period.',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI-Powered Insights',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personalized recommendations based on your nutrition data',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          if (_insights.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No insights available yet.\nComplete more meals to get personalized recommendations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            ..._insights.map((insight) => _buildDetailedInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildDetailedInsightCard(NutritionalInsight insight) {
    Color cardColor;
    IconData icon;
    
    switch (insight.type) {
      case InsightType.positive:
        cardColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case InsightType.warning:
        cardColor = Colors.orange;
        icon = Icons.warning;
        break;
      case InsightType.recommendation:
        cardColor = Colors.blue;
        icon = Icons.lightbulb;
        break;
      case InsightType.trend:
        cardColor = Colors.purple;
        icon = Icons.trending_up;
        break;
      case InsightType.goal:
        cardColor = Colors.pink;
        icon = Icons.flag;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: cardColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Confidence: ${(insight.confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.description,
                  style: const TextStyle(fontSize: 14),
                ),
                if (insight.actionableSteps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Actionable Steps:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...insight.actionableSteps.map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
