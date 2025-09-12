import 'package:flutter/material.dart';
import '../../models/recipes.dart';

class MealSummaryPage extends StatefulWidget {
  final List<Recipe> meals;
  final void Function(List<RecipeWithTime>) onBuildMealPlan;
  final VoidCallback? onChanged;
  const MealSummaryPage({super.key, required this.meals, required this.onBuildMealPlan, this.onChanged});

  @override
  State<MealSummaryPage> createState() => _MealSummaryPageState();
}

class RecipeWithTime {
  final Recipe recipe;
  String? mealType; // 'breakfast', 'lunch', 'dinner'
  TimeOfDay? time;
  RecipeWithTime({required this.recipe, this.mealType, this.time});
}

class _MealSummaryPageState extends State<MealSummaryPage> {
  late List<RecipeWithTime> _mealsWithTime;

  @override
  void initState() {
    super.initState();
    _mealsWithTime = widget.meals.map((r) => RecipeWithTime(recipe: r)).toList();
  }

  // Time restrictions for each meal type (using 12-hour format for display)
  static const Map<String, Map<String, int>> _mealTimeRestrictions = {
    'breakfast': {'startHour': 5, 'endHour': 10}, // 5:00 AM - 10:00 AM
    'lunch': {'startHour': 11, 'endHour': 16}, // 11:00 AM - 4:00 PM
    'dinner': {'startHour': 17, 'endHour': 20}, // 5:00 PM - 8:00 PM
  };

  void _showMealTypeDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Meal Type'),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMealTypeOption(index, 'breakfast', 'Breakfast', Icons.wb_sunny, const Color.fromARGB(255, 157, 168, 0)),
            const SizedBox(height: 16),
            _buildMealTypeOption(index, 'lunch', 'Lunch', Icons.restaurant, const Color.fromARGB(255, 192, 115, 0)),
            const SizedBox(height: 16),
            _buildMealTypeOption(index, 'dinner', 'Dinner', Icons.nightlight, Colors.indigo),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeOption(int index, String type, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        print('Setting meal type for index $index: $type'); // Debug print
        setState(() {
          _mealsWithTime[index].mealType = type;
          _mealsWithTime[index].time = null; // Reset time when meal type changes
        });
        print('Meal type set: ${_mealsWithTime[index].mealType}'); // Debug print
        print('All meals after setting type:');
        for (int i = 0; i < _mealsWithTime.length; i++) {
          print('  Meal $i: ${_mealsWithTime[i].mealType}');
        }
        Navigator.pop(context);
        _showTimePicker(index);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  Text(
                    _getTimeRangeText(type),
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  String _getTimeRangeText(String mealType) {
    final restrictions = _mealTimeRestrictions[mealType]!;
    final startHour = restrictions['startHour']!;
    final endHour = restrictions['endHour']!;
    
    String startTime;
    String endTime;
    
    // Convert to 12-hour format
    if (startHour == 0) {
      startTime = '12:00 AM';
    } else if (startHour < 12) {
      startTime = '$startHour:00 AM';
    } else if (startHour == 12) {
      startTime = '12:00 PM';
    } else {
      startTime = '${startHour - 12}:00 PM';
    }
    
    if (endHour == 0) {
      endTime = '12:00 AM';
    } else if (endHour < 12) {
      endTime = '$endHour:00 AM';
    } else if (endHour == 12) {
      endTime = '12:00 PM';
    } else {
      endTime = '${endHour - 12}:00 PM';
    }
    
    return '$startTime - $endTime';
  }

  void _showTimePicker(int index) async {
    final mealType = _mealsWithTime[index].mealType;
    if (mealType == null) return;

    final restrictions = _mealTimeRestrictions[mealType]!;
    final startHour = restrictions['startHour']!;
    final endHour = restrictions['endHour']!;

    // Create a custom time picker dialog
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _buildCustomTimePicker(startHour, endHour, mealType),
    );

    if (result != null) {
      print('Setting time for index $index: ${result.format(context)}'); // Debug print
      setState(() {
        _mealsWithTime[index].time = result;
      });
      print('Time set: ${_mealsWithTime[index].time?.format(context)}'); // Debug print
    }
  }

  Widget _buildCustomTimePicker(int startHour, int endHour, String mealType) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set ${mealType.capitalize()} Time',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Available: ${_getTimeRangeText(mealType)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              ),
              child: Stack(
                children: [
                  // Center indicator
                  Positioned(
                    top: 80, // Center of the wheel
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  _buildTimeWheel(startHour, endHour),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // The time will be set when user scrolls and confirms
                    Navigator.pop(context, _selectedTime);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _selectedTime = TimeOfDay.now();

  Widget _buildTimeWheel(int startHour, int endHour) {
    return Row(
      children: [
        // Hour wheel
        Expanded(
          child: _buildWheel(
            startHour,
            endHour,
            (value) {
              setState(() {
                _selectedTime = TimeOfDay(hour: value, minute: _selectedTime.minute);
              });
            },
            _selectedTime.hour,
            'Hour',
          ),
        ),
        const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        // Minute wheel
        Expanded(
          child: _buildWheel(
            0,
            59,
            (value) {
              setState(() {
                _selectedTime = TimeOfDay(hour: _selectedTime.hour, minute: value);
              });
            },
            _selectedTime.minute,
            'Minute',
          ),
        ),
      ],
    );
  }

  Widget _buildWheel(int start, int end, Function(int) onChanged, int initialValue, String label) {
    return StatefulBuilder(
      builder: (context, setState) {
        final controller = FixedExtentScrollController(initialItem: initialValue - start);
        int currentIndex = initialValue - start;
        
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              // Calculate which item is currently in the center
              final offset = notification.metrics.pixels;
              final itemExtent = 40.0;
              final centerIndex = (offset / itemExtent).round();
              final clampedIndex = centerIndex.clamp(0, end - start);
              
              if (clampedIndex != currentIndex) {
                currentIndex = clampedIndex;
                final newValue = start + clampedIndex;
                onChanged(newValue);
                setState(() {
                  if (label == 'Hour') {
                    _selectedTime = TimeOfDay(hour: newValue, minute: _selectedTime.minute);
                  } else {
                    _selectedTime = TimeOfDay(hour: _selectedTime.hour, minute: newValue);
                  }
                });
              }
            }
            return false;
          },
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            controller: controller,
            onSelectedItemChanged: (index) {
              currentIndex = index;
              final newValue = start + index;
              onChanged(newValue);
              setState(() {
                if (label == 'Hour') {
                  _selectedTime = TimeOfDay(hour: newValue, minute: _selectedTime.minute);
                } else {
                  _selectedTime = TimeOfDay(hour: _selectedTime.hour, minute: newValue);
                }
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final value = start + index;
                final isSelected = index == currentIndex;
                
                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: isSelected ? 20 : 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.grey, // Changed to green
                    ),
                  ),
                );
              },
              childCount: end - start + 1,
            ),
          ),
        );
      },
    );
  }

  bool _canBuildMealPlan() {
    final canBuild = _mealsWithTime.every((meal) => meal.mealType != null && meal.mealType!.isNotEmpty && meal.time != null);
    print('Can build meal plan: $canBuild'); // Debug print
    for (int i = 0; i < _mealsWithTime.length; i++) {
      final meal = _mealsWithTime[i];
      print('Meal $i: ${meal.recipe.title} - Type: ${meal.mealType} - Time: ${meal.time?.format(context)}');
    }
    return canBuild;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 24),
                        onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(40, 40),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Meal Summary',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(width: 56), // Balance the back button with proper spacing
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _mealsWithTime.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final meal = _mealsWithTime[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            meal.recipe.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                        title: Text(meal.recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (meal.mealType != null)
                              Text(
                                'Meal Type: ${meal.mealType!.capitalize()}',
                                style: TextStyle(
                                  color: _getMealTypeColor(meal.mealType!),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (meal.time != null)
                              Text('Time: ${meal.time!.format(context)}'),
                            if (meal.mealType == null)
                              const Text('Select meal type first'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _showMealTypeDialog(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: meal.mealType == null 
                              ? const Color(0xFF4CAF50)
                              : Colors.white,
                            foregroundColor: meal.mealType == null 
                              ? Colors.white
                              : const Color(0xFF4CAF50),
                            side: meal.mealType == null 
                              ? null 
                              : const BorderSide(color: Color(0xFF4CAF50)),
                          ),
                          child: Text(meal.mealType == null ? 'Set Meal' : 'Change'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 220,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: _canBuildMealPlan() ? () {
            print('Building meal plan with ${_mealsWithTime.length} meals'); // Debug print
            for (int i = 0; i < _mealsWithTime.length; i++) {
              final meal = _mealsWithTime[i];
              print('Meal $i: ${meal.recipe.title} - Type: ${meal.mealType} - Time: ${meal.time?.format(context)}');
            }
            widget.onBuildMealPlan(_mealsWithTime);
            if (widget.onChanged != null) widget.onChanged!();
          } : null,
          label: Text(
            _canBuildMealPlan() ? 'Build this Meal Plan' : 'Set Meal Time Correctly',
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: _canBuildMealPlan() ? Colors.white : const Color.fromARGB(255, 248, 248, 248),
            ),
          ),
          backgroundColor: _canBuildMealPlan() ? Colors.green[600] : Colors.grey[400],
        ),
      ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.amber;
      case 'dinner':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 