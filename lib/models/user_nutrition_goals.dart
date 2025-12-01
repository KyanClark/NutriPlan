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

  /// Helper function to safely convert a value to List<String>
  /// Handles cases where the value might be a List, String (JSON), or null
  static List<String>? _safeStringList(dynamic value) {
    if (value == null) return null;
    
    // If it's already a List, convert it
    if (value is List) {
      try {
        return value.map((e) => e.toString()).toList();
      } catch (_) {
        return null;
      }
    }
    
    // If it's a String, try to parse it as JSON
    if (value is String) {
      if (value.isEmpty) return null;
      try {
        // Simple parsing for common cases
        if (value.startsWith('[') && value.endsWith(']')) {
          // Remove brackets and quotes, split by comma
          final cleaned = value
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll("'", '')
              .trim();
          if (cleaned.isEmpty) return null;
          return cleaned.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        // If it's a single string value, return as single-item list
        return [value.trim()];
      } catch (_) {
        // If parsing fails, return as single-item list
        return [value.toString()];
      }
    }
    
    return null;
  }

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
      dishPreferences: _safeStringList(map['dish_preferences'] ?? map['like_dishes']),
      allergies: _safeStringList(map['allergies']),
      healthConditions: _safeStringList(map['health_conditions']),
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
      'like_dishes': dishPreferences, // Use like_dishes to match database schema
      'allergies': allergies,
      'health_conditions': healthConditions,
      'sodium_limit': sodiumLimit,
      'bmr': bmr,
      'tdee': tdee,
    };
  }
} 