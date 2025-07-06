
class Meal {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double cost;
  final int cookingTime; // in minutes
  final List<String> dietaryTags; // e.g., ['vegetarian', 'gluten-free']

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.cost,
    required this.cookingTime,
    required this.dietaryTags,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      calories: json['calories'] ?? 0,
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      cookingTime: json['cookingTime'] ?? 0,
      dietaryTags: List<String>.from(json['dietaryTags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'cost': cost,
      'cookingTime': cookingTime,
      'dietaryTags': dietaryTags,
    };
  }
} 