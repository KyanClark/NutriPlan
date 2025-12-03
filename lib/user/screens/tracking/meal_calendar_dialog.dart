import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MealCalendarDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Map<DateTime, bool> datesWithMeals;
  final Map<DateTime, int> mealCounts;
  final Function(DateTime) onDateSelected;
  final VoidCallback? onRefreshMonth;

  const MealCalendarDialog({
    super.key,
    required this.selectedDate,
    required this.datesWithMeals,
    required this.mealCounts,
    required this.onDateSelected,
    this.onRefreshMonth,
  });

  @override
  State<MealCalendarDialog> createState() => _MealCalendarDialogState();
}

class _MealCalendarDialogState extends State<MealCalendarDialog> {
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
    widget.onRefreshMonth?.call();
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    });
    widget.onRefreshMonth?.call();
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = currentMonth;
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    final firstDayOfWeek = firstDay.weekday; // Monday = 1
    final List<DateTime> days = [];

    for (int i = firstDayOfWeek - 1; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, i));
    }
    final remainingDays = 42 - days.length; // 6 rows * 7 days
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _previousMonth, icon: const Icon(Icons.chevron_left)),
                Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
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
                final isSelected =
                    day.year == selectedDate.year && day.month == selectedDate.month && day.day == selectedDate.day;
                final hasMeals = widget.datesWithMeals[DateTime(day.year, day.month, day.day)] == true;
                final mealCount = widget.mealCounts[DateTime(day.year, day.month, day.day)] ?? 0;

                return GestureDetector(
                  onTap: () {
                    if (isCurrentMonth) {
                      setState(() => selectedDate = day);
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
                                  : (isCurrentMonth ? (hasMeals ? Colors.green : Colors.black) : Colors.grey[400]),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(width: 8),
                const Text('Days with completed meals', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}


