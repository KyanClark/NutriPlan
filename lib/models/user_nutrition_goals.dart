class UserNutritionGoals {
  final double calorieGoal;
  final double proteinGoal;
  final double carbGoal;
  final double fatGoal;
  final double sugarGoal;
  final double fiberGoal;
  final double cholesterolGoal;
  
  // Additional user profile fields
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? activityLevel;
  final String? weightGoal;
  final List<String>? dishPreferences;
  final List<String>? allergies;
  final List<String>? healthConditions;
  final double? sodiumLimit;
  final double? bmr;
  final double? tdee;

  UserNutritionGoals({
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
    required this.sugarGoal,
    required this.fiberGoal,
    required this.cholesterolGoal,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.activityLevel,
    this.weightGoal,
    this.dishPreferences,
    this.allergies,
    this.healthConditions,
    this.sodiumLimit,
    this.bmr,
    this.tdee,
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
      age: map['age'],
      gender: map['gender'],
      heightCm: map['height_cm']?.toDouble(),
      weightKg: map['weight_kg']?.toDouble(),
      activityLevel: map['activity_level'],
      weightGoal: map['weight_goal'],
      dishPreferences: map['dish_preferences'] != null 
        ? List<String>.from(map['dish_preferences']) 
        : null,
      allergies: map['allergies'] != null 
        ? List<String>.from(map['allergies']) 
        : null,
      healthConditions: map['health_conditions'] != null 
        ? List<String>.from(map['health_conditions']) 
        : null,
      sodiumLimit: map['sodium_limit']?.toDouble(),
      bmr: map['bmr']?.toDouble(),
      tdee: map['tdee']?.toDouble(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'calorie_goal': calorieGoal,
      'protein_goal': proteinGoal,
      'carb_goal': carbGoal,
      'fat_goal': fatGoal,
      'sugar_goal': sugarGoal,
      'fiber_goal': fiberGoal,
      'cholesterol_goal': cholesterolGoal,
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'activity_level': activityLevel,
      'weight_goal': weightGoal,
      'dish_preferences': dishPreferences,
      'allergies': allergies,
      'health_conditions': healthConditions,
      'sodium_limit': sodiumLimit,
      'bmr': bmr,
      'tdee': tdee,
    };
  }
} 