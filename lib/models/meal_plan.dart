import 'meal.dart';

enum MealType { breakfast, lunch, dinner, snack }

class MealPlan {
  final String id;
  final DateTime date;
  final MealType mealType;
  final Meal meal;
  final String? notes;

  MealPlan({
    required this.id,
    required this.date,
    required this.mealType,
    required this.meal,
    this.notes,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      mealType: MealType.values.firstWhere(
        (e) => e.toString() == 'MealType.${json['mealType']}',
        orElse: () => MealType.breakfast,
      ),
      meal: Meal.fromJson(json['meal']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mealType': mealType.toString().split('.').last,
      'meal': meal.toJson(),
      'notes': notes,
    };
  }

  String get mealTypeDisplay {
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
} 