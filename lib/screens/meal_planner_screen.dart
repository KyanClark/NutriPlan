import 'package:flutter/material.dart';
import 'dart:async';
import '../models/meal.dart';
import '../models/meal_plan.dart';
import '../models/user_profile.dart';
import '../services/meal_service.dart';

class MealPlannerScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const MealPlannerScreen({super.key, this.userProfile});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  List<MealPlan> mealPlans = [];
  List<Meal> mealSuggestions = [];
  DateTime selectedDate = DateTime.now();
  int _selectedMealTypeIndex = 0;
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  final List<MealType> mealTypes = [MealType.breakfast, MealType.lunch, MealType.dinner];
  final List<String> mealTypeLabels = ['Breakfast', 'Lunch', 'Dinner'];

  @override
  void initState() {
    super.initState();
    _loadMealSuggestions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
        // Only update selectedDate if it's today's date (not manually selected)
        final now = DateTime.now();
        if (selectedDate.year == now.year && 
            selectedDate.month == now.month && 
            selectedDate.day == now.day) {
          selectedDate = now;
        }
      });
    });
  }

  void _loadMealSuggestions() {
    if (widget.userProfile != null) {
      mealSuggestions = MealService.getMealSuggestions(widget.userProfile!);
    } else {
      mealSuggestions = MealService.getAllMeals();
    }
  }

  void _addMealToPlan(Meal meal, MealType mealType, DateTime date) {
    final mealPlan = MealPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      mealType: mealType,
      meal: meal,
    );
    setState(() {
      mealPlans.add(mealPlan);
    });
  }

  void _editMeal(MealPlan mealPlan) {
    // TODO: Implement edit meal functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit meal functionality coming soon!')),
    );
  }

  List<MealPlan> _getMealsForType(MealType mealType) {
    return mealPlans.where((plan) =>
      plan.date.year == selectedDate.year &&
      plan.date.month == selectedDate.month &&
      plan.date.day == selectedDate.day &&
      plan.mealType == mealType
    ).toList();
  }

  List<DateTime> get _weekDates {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      body: Column(
        children: [
          // Calendar container and Meal Plan button row
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              child: Row(
                children: [
                  // Calendar container
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fullDate(selectedDate),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getCurrentTime(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null && picked != selectedDate) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Meal Plan button
                  Container(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddMealDialog(),
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      label: const Text(
                        'Add\nMeal Plan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Feature cards (calories and meals planned)
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Calories Today',
                      value: _getTotalCaloriesForDate().toString(),
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Meals Planned',
                      value: _getTotalMealsForDate().toString(),
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Meal type categories and meal content container
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Meal Type Category Selector
                    SizedBox(
                      height: 38,
                      child: Stack(
                        children: [
                          // Category text items
                          ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: mealTypes.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 24),
                            itemBuilder: (context, i) {
                              final isSelected = i == _selectedMealTypeIndex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedMealTypeIndex = i;
                                  });
                                },
                                child: Text(
                                  mealTypeLabels[i],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.black : Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Sliding underline
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            left: _getMealTypeUnderlinePosition(),
                            bottom: 0,
                            child: Container(
                              height: 2,
                              width: mealTypeLabels[_selectedMealTypeIndex].length * 9.0,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Meal content
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        children: [
                          _buildMealSection(mealTypes[_selectedMealTypeIndex], mealTypeLabels[_selectedMealTypeIndex].toUpperCase()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMealTypeUnderlinePosition() {
    double position = 0;
    for (int i = 0; i < _selectedMealTypeIndex; i++) {
      position += mealTypeLabels[i].length * 9.0 + 24;
    }
    return position;
  }

  Widget _buildMealSection(MealType mealType, String label) {
    final meals = _getMealsForType(mealType);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (meals.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                'No meal planned',
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ),
            )
          else
            ...meals.map((plan) => _buildMealCard(plan)).toList(),
        ],
      ),
    );
  }

  Widget _buildMealCard(MealPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.meal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1 serving',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 22),
            onPressed: () => _editMeal(plan),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMealTypeOption(MealType.breakfast),
            _buildMealTypeOption(MealType.lunch),
            _buildMealTypeOption(MealType.dinner),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeOption(MealType mealType) {
    return ListTile(
      leading: Icon(_getMealTypeIcon(mealType), color: _getMealTypeColor(mealType)),
      title: Text(_getMealTypeDisplay(mealType)),
      onTap: () {
        Navigator.pop(context);
        _showMealSuggestions(mealType);
      },
    );
  }

  void _showMealSuggestions(MealType mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose ${_getMealTypeDisplay(mealType)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: mealSuggestions.length,
                        itemBuilder: (context, index) {
                          final meal = mealSuggestions[index];
                          return GestureDetector(
                            onTap: () {
                              _addMealToPlan(meal, mealType, selectedDate);
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: const DecorationImage(
                                        image: NetworkImage('https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meal.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${meal.calories} cal • ${meal.cookingTime} min',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₱${meal.cost.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  String _formatFullDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getMealTypeDisplay(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  IconData _getMealTypeIcon(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.restaurant;
      case MealType.dinner:
        return Icons.nights_stay;
      case MealType.snack:
        return Icons.coffee;
    }
  }

  Color _getMealTypeColor(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return Colors.orange;
      case MealType.lunch:
        return Colors.green;
      case MealType.dinner:
        return Colors.purple;
      case MealType.snack:
        return Colors.blue;
    }
  }

  String _fullDate(DateTime date) {
    final weekday = _weekdayLong(date);
    final month = _monthShort(date);
    return '$month ${date.day}, $weekday';
  }

  String _getCurrentTime() {
    final now = _currentTime;
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _monthShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }

  String _weekdayShort(DateTime date) {
    const weekdays = [
      'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
    ];
    return weekdays[date.weekday - 1];
  }
  String _weekdayLong(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }
  String _monthLong(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

  int _getTotalCaloriesForDate() {
    final mealsForDate = mealPlans.where((plan) =>
      plan.date.year == selectedDate.year &&
      plan.date.month == selectedDate.month &&
      plan.date.day == selectedDate.day
    ).toList();
    
    final nutritionalTotals = MealService.calculateNutritionalTotals(mealsForDate);
    return nutritionalTotals['calories']?.toInt() ?? 0;
  }

  int _getTotalMealsForDate() {
    return mealPlans.where((plan) =>
      plan.date.year == selectedDate.year &&
      plan.date.month == selectedDate.month &&
      plan.date.day == selectedDate.day
    ).length;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 