class UserNutritionGoals {
  final double calorieGoal;
  final double proteinGoal;
  final double carbGoal;
  final double fatGoal;
  final double sugarGoal;
  final double fiberGoal;
  final double cholesterolGoal;

  UserNutritionGoals({
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
    required this.sugarGoal,
    required this.fiberGoal,
    required this.cholesterolGoal,
  });

  factory UserNutritionGoals.fromMap(Map<String, dynamic> map) {
    return UserNutritionGoals(
      calorieGoal: (map['calorie_goal'] ?? 2000).toDouble(),
      proteinGoal: (map['protein_goal'] ?? 75).toDouble(),
      carbGoal: (map['carb_goal'] ?? 250).toDouble(),
      fatGoal: (map['fat_goal'] ?? 70).toDouble(),
      sugarGoal: (map['sugar_goal'] ?? 50).toDouble(),
      fiberGoal: (map['fiber_goal'] ?? 30).toDouble(),
      cholesterolGoal: (map['cholesterol_goal'] ?? 300).toDouble(),
    );
  }
} 