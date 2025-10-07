import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/recipes.dart';
import '../meal_plan/meal_summary_page.dart';

class MealPlanHistoryScreen extends StatefulWidget {
  const MealPlanHistoryScreen({super.key});

  @override
  State<MealPlanHistoryScreen> createState() => _MealPlanHistoryScreenState();
}

class _MealPlanHistoryScreenState extends State<MealPlanHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String _sortBy = 'days'; // 'days', 'weeks', 'months'
  // Removed bulk add plan; tapping a meal navigates directly to summary

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
      setState(() {
        _history = [];
        _loading = false;
      });
      }
      return;
    }
    final response = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
        .eq('user_id', user.id)
        .order('completed_at', ascending: false);
    if (mounted) {
    setState(() {
      _history = List<Map<String, dynamic>>.from(response);
      _loading = false;
        // No bulk collection needed; we map per tap
      });
    }
  }

  // Group meals by different time periods
  Map<String, List<Map<String, dynamic>>> _groupMealsByPeriod() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (final meal in _history) {
      final dt = meal['completed_at'] != null
          ? DateTime.parse(meal['completed_at']).toLocal()
          : null;
      
      if (dt == null) continue;
      
      String periodKey;
      switch (_sortBy) {
        case 'weeks':
          // Group by week (Monday to Sunday)
          final startOfWeek = dt.subtract(Duration(days: dt.weekday - 1));
          periodKey = '${startOfWeek.year}-W${_getWeekNumber(startOfWeek)}';
          break;
        case 'months':
          // Group by month
          periodKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          break;
        case 'days':
        default:
          // Group by day
          periodKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          break;
      }
      
      grouped.putIfAbsent(periodKey, () => []).add(meal);
    }
    
    return grouped;
  }

  // Get week number of the year
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  // Format period header based on sort type
  String _formatPeriodHeader(String periodKey) {
    switch (_sortBy) {
      case 'weeks':
        final parts = periodKey.split('-W');
        final year = int.parse(parts[0]);
        final weekNum = int.parse(parts[1]);
        final firstDayOfYear = DateTime(year, 1, 1);
        final weekStart = firstDayOfYear.add(Duration(days: (weekNum - 1) * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Week $weekNum, $year (${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month})';
      
      case 'months':
        final parts = periodKey.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${months[month - 1]} $year';
      
      case 'days':
      default:
        final dt = DateTime.tryParse(periodKey);
        if (dt == null) return periodKey;
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    }
  }

  // Show sorting options dialog
  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Meal History'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('By Days'),
              subtitle: const Text('Group meals by individual days'),
              value: 'days',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('By Weeks'),
              subtitle: const Text('Group meals by weeks (Monday-Sunday)'),
              value: 'weeks',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('By Months'),
              subtitle: const Text('Group meals by months'),
              value: 'months',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }



  // Removed unused _createRecipeFromMeal


  // Removed bulk add meal plan from history

  @override
  Widget build(BuildContext context) {
    // Group meals by selected period
    final grouped = _groupMealsByPeriod();
    final periodKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    String formatTime(DateTime? dt) {
      if (dt == null) return '';
      int hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $ampm';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Meal Plan History'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by Period',
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sorting indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                    ),
                  ],
                ),
            child: Row(
              children: [
                Icon(
                  _sortBy == 'days' ? Icons.calendar_today :
                  _sortBy == 'weeks' ? Icons.date_range :
                  Icons.calendar_month,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sorted by ${_sortBy == 'days' ? 'Days' : _sortBy == 'weeks' ? 'Weeks' : 'Months'}',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${periodKeys.length} ${_sortBy == 'days' ? 'days' : _sortBy == 'weeks' ? 'weeks' : 'months'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
          ),
        ],
      ),
          ),
          // Main content
          Expanded(
            child: _loading
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => AnimatedContainer(
                  duration: Duration(milliseconds: 400),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(i == DateTime.now().second % 3 ? 1 : 0.4),
                    shape: BoxShape.circle,
                  ),
                )),
              ),
            )
          : _history.isEmpty
              ? const Center(child: Text('No completed meals yet.'))
              : ListView.builder(
        padding: const EdgeInsets.all(20),
                  itemCount: periodKeys.length,
                  itemBuilder: (context, periodIdx) {
                    final periodKey = periodKeys[periodIdx];
                    final meals = grouped[periodKey]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _formatPeriodHeader(periodKey),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
                        ),
                        ...meals.map((meal) {
                          final dt = meal['completed_at'] != null
                            ? DateTime.parse(meal['completed_at']).toLocal()
                            : null;
                          final timeStr = formatTime(dt);
                          return Column(
                            children: [
                              Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: meal['image_url'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            meal['image_url'],
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(Icons.restaurant, color: Colors.green),
                                  title: Text(meal['title'] ?? 'Meal'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(timeStr, style: const TextStyle(fontSize: 15)),
                                      if (meal['calories'] != null)
                                        Text('${meal['calories']} kcal', style: TextStyle(color: Colors.black54)),
                                    ],
                                  ),
                                  onTap: () async {
                                    // Navigate directly to meal summary with this meal
                                    final recipe = Recipe(
                                      id: (meal['recipe_id'] ?? '').toString(),
                                      title: meal['title'] ?? meal['recipe_name'] ?? 'Unknown Recipe',
                                      imageUrl: meal['image_url'] ?? meal['recipe_image_url'] ?? '',
                                      shortDescription: meal['description'] ?? meal['recipe_description'] ?? '',
                                      calories: meal['calories'] ?? 0,
                                      ingredients: List<String>.from(meal['ingredients'] ?? []),
                                      instructions: List<String>.from(meal['instructions'] ?? []),
                                      macros: {
                                        'protein': (meal['protein'] ?? 0).toDouble(),
                                        'carbs': (meal['carbs'] ?? 0).toDouble(),
                                        'fat': (meal['fat'] ?? 0).toDouble(),
                                      },
                                      allergyWarning: meal['allergy_warning'] ?? '',
                                      dietTypes: List<String>.from(meal['diet_types'] ?? []),
                                      cost: (meal['cost'] ?? 0.0).toDouble(),
                                    );
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MealSummaryPage(
                                          meals: [recipe],
                                          onBuildMealPlan: (mealsWithTime) async {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
} 