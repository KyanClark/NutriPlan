import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_history_entry.dart';

class MealLogCard extends StatefulWidget {
  final MealHistoryEntry meal;
  
  const MealLogCard({
    super.key,
    required this.meal,
  });

  @override
  State<MealLogCard> createState() => _MealLogCardState();
}

class _MealLogCardState extends State<MealLogCard> {
  bool expanded = false;
  
  Color _getMealCategoryColor(MealCategory category) {
    switch (category) {
      case MealCategory.breakfast:
        return Colors.orange;
      case MealCategory.lunch:
        return Colors.green;
      case MealCategory.dinner:
        return Colors.purple;
      case MealCategory.snack:
        return Colors.blue;
    }
  }

  String _getMealCategoryDisplayName(MealCategory category) {
    switch (category) {
      case MealCategory.breakfast:
        return 'Breakfast';
      case MealCategory.lunch:
        return 'Lunch';
      case MealCategory.dinner:
        return 'Dinner';
      case MealCategory.snack:
        return 'Snack';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => setState(() => expanded = !expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Recipe image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      meal.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Meal details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getMealCategoryColor(meal.category).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getMealCategoryDisplayName(meal.category),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getMealCategoryColor(meal.category),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Time
                            Text(
                              DateFormat('h:mm a').format(meal.completedAt.toLocal()),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Calories and expand icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${meal.calories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              
              // Expanded nutrition details
              if (expanded) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Nutrition macros
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _MacroChip(
                      label: 'Protein',
                      value: meal.protein,
                      color: Colors.blue,
                      unit: 'g',
                    ),
                    _MacroChip(
                      label: 'Carbs',
                      value: meal.carbs,
                      color: Colors.green,
                      unit: 'g',
                    ),
                    _MacroChip(
                      label: 'Fat',
                      value: meal.fat,
                      color: Colors.orange,
                      unit: 'g',
                    ),
                    _MacroChip(
                      label: 'Sugar',
                      value: meal.sugar,
                      color: Colors.pink,
                      unit: 'g',
                    ),
                    _MacroChip(
                      label: 'Fiber',
                      value: meal.fiber,
                      color: Colors.purple,
                      unit: 'g',
                    ),
                    _MacroChip(
                      label: 'Sodium',
                      value: meal.sodium,
                      color: Colors.red,
                      unit: 'mg',
                    ),
                    _MacroChip(
                      label: 'Cholesterol',
                      value: meal.cholesterol,
                      color: Colors.indigo,
                      unit: 'mg',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String unit;
  
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.unit,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(1)}$unit',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
