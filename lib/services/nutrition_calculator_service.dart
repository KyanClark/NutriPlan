class NutritionCalculatorService {
  /// Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  static double calculateBMR({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }
  
  /// Calculate Total Daily Energy Expenditure (TDEE) based on activity level
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    switch (activityLevel) {
      case 'sedentary':
        return bmr * 1.2;
      case 'lightly_active':
        return bmr * 1.375;
      case 'moderately_active':
        return bmr * 1.55;
      case 'very_active':
        return bmr * 1.725;
      case 'extremely_active':
        return bmr * 1.9;
      default:
        return bmr * 1.375; // Default to lightly active
    }
  }
  
  /// Calculate complete nutrition goals based on user profile and weight goal
  static Map<String, double> calculateGoals({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String weightGoal,
  }) {
    // Calculate BMR and TDEE
    final bmr = calculateBMR(
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    
    final tdee = calculateTDEE(
      bmr: bmr,
      activityLevel: activityLevel,
    );
    
    // Adjust calories based on weight goal
    double targetCalories;
    switch (weightGoal) {
      case 'lose_weight':
        targetCalories = tdee - 500; // 500 calorie deficit for ~0.5kg/week loss
        break;
      case 'gain_weight':
        targetCalories = tdee + 500; // 500 calorie surplus for ~0.5kg/week gain
        break;
      case 'maintain_weight':
      default:
        targetCalories = tdee;
        break;
    }
    
    // Ensure minimum calorie intake (1200 for women, 1500 for men)
    final minCalories = gender.toLowerCase() == 'male' ? 1500.0 : 1200.0;
    targetCalories = targetCalories < minCalories ? minCalories : targetCalories;
    
    // Calculate macronutrient goals based on balanced diet recommendations
    double proteinGoal;
    double fatGoal;
    double carbGoal;
    
    if (weightGoal == 'lose_weight') {
      // Higher protein for weight loss (30% protein, 25% fat, 45% carbs)
      proteinGoal = (targetCalories * 0.30) / 4; // 4 calories per gram of protein
      fatGoal = (targetCalories * 0.25) / 9; // 9 calories per gram of fat
      carbGoal = (targetCalories * 0.45) / 4; // 4 calories per gram of carbs
    } else if (weightGoal == 'gain_weight') {
      // Moderate protein for weight gain (20% protein, 30% fat, 50% carbs)
      proteinGoal = (targetCalories * 0.20) / 4;
      fatGoal = (targetCalories * 0.30) / 9;
      carbGoal = (targetCalories * 0.50) / 4;
    } else {
      // Balanced for maintenance (25% protein, 25% fat, 50% carbs)
      proteinGoal = (targetCalories * 0.25) / 4;
      fatGoal = (targetCalories * 0.25) / 9;
      carbGoal = (targetCalories * 0.50) / 4;
    }
    
    // Calculate fiber goal (14g per 1000 calories)
    final fiberGoal = (targetCalories / 1000) * 14;
    
    // Calculate sugar goal (less than 10% of total calories)
    final sugarGoal = (targetCalories * 0.10) / 4;
    
    // Cholesterol goal (less than 300mg per day)
    const cholesterolGoal = 300.0;
    
    // Default micronutrient goals (can be adjusted by health conditions)
    final ironGoal = gender.toLowerCase() == 'male' ? 8.0 : 18.0; // mg (women need more)
    final vitaminCGoal = 90.0; // mg (standard adult requirement)
    const sodiumLimit = 2300.0; // mg (standard daily limit)

    return {
      'calories': targetCalories.round().toDouble(),
      'protein': proteinGoal.round().toDouble(),
      'fat': fatGoal.round().toDouble(),
      'carbs': carbGoal.round().toDouble(),
      'fiber': fiberGoal.round().toDouble(),
      'sugar': sugarGoal.round().toDouble(),
      'cholesterol': cholesterolGoal,
      'iron_goal': ironGoal,
      'vitamin_c_goal': vitaminCGoal,
      'sodium': sodiumLimit,
      'bmr': bmr.round().toDouble(),
      'tdee': tdee.round().toDouble(),
    };
  }
  
  /// Get activity level multiplier for display purposes
  static double getActivityMultiplier(String activityLevel) {
    switch (activityLevel) {
      case 'sedentary':
        return 1.2;
      case 'lightly_active':
        return 1.375;
      case 'moderately_active':
        return 1.55;
      case 'very_active':
        return 1.725;
      case 'extremely_active':
        return 1.9;
      default:
        return 1.375;
    }
  }
  
  /// Get readable activity level description
  static String getActivityDescription(String activityLevel) {
    switch (activityLevel) {
      case 'sedentary':
        return 'Little to no exercise';
      case 'lightly_active':
        return 'Light exercise 1-3 days/week';
      case 'moderately_active':
        return 'Moderate exercise 3-5 days/week';
      case 'very_active':
        return 'Hard exercise 6-7 days/week';
      case 'extremely_active':
        return 'Very hard exercise, physical job';
      default:
        return 'Light exercise 1-3 days/week';
    }
  }
  
  /// Get readable weight goal description
  static String getWeightGoalDescription(String weightGoal) {
    switch (weightGoal) {
      case 'lose_weight':
        return 'Lose 0.5-1 kg per week';
      case 'gain_weight':
        return 'Gain 0.5-1 kg per week';
      case 'maintain_weight':
        return 'Maintain current weight';
      default:
        return 'Maintain current weight';
    }
  }
}
