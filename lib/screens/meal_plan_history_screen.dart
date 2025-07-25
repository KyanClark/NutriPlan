import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealPlanHistoryScreen extends StatefulWidget {
  const MealPlanHistoryScreen({super.key});

  @override
  State<MealPlanHistoryScreen> createState() => _MealPlanHistoryScreenState();
}

class _MealPlanHistoryScreenState extends State<MealPlanHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _history = [];
        _loading = false;
      });
      return;
    }
    final response = await Supabase.instance.client
        .from('meal_plan_history')
        .select()
        .eq('user_id', user.id)
        .order('completed_at', ascending: false);
    setState(() {
      _history = List<Map<String, dynamic>>.from(response);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group meals by date
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final meal in _history) {
      final dt = meal['completed_at'] != null
        ? DateTime.parse(meal['completed_at']).toLocal()
        : null;
      final dateStr = dt != null
        ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
        : 'Unknown';
      grouped.putIfAbsent(dateStr, () => []).add(meal);
    }
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    String formatDateHeader(String date) {
      final dt = DateTime.tryParse(date);
      if (dt == null) return date;
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    }

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
      appBar: AppBar(
        title: const Text('Meal Plan History'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All History',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Meal History'),
                  content: const Text('Are you sure you want to clear all meal history records? This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  await Supabase.instance.client
                    .from('meal_plan_history')
                    .delete()
                    .eq('user_id', user.id);
                  await _fetchHistory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meal history cleared.'), duration: Duration(seconds: 3)),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _loading
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
                  itemCount: dateKeys.length,
                  itemBuilder: (context, dateIdx) {
                    final date = dateKeys[dateIdx];
                    final meals = grouped[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            formatDateHeader(date),
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
          ListTile(
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
                                subtitle: Text(timeStr, style: const TextStyle(fontSize: 15)),
                                trailing: meal['calories'] != null
                                    ? Text('${meal['calories']} kcal', style: TextStyle(color: Colors.black54))
                                    : null,
          ),
                              const Divider(),
        ],
                          );
                        }).toList(),
                      ],
                    );
                  },
      ),
    );
  }
} 