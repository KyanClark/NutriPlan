class MealHistoryEntry {
  final String id;
  final String recipeId;
  final String title;
  final String imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final DateTime completedAt;

  MealHistoryEntry({
    required this.id,
    required this.recipeId,
    required this.title,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.fiber,
    required this.completedAt,
  });

  factory MealHistoryEntry.fromMap(Map<String, dynamic> map) {
    double parseNum(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MealHistoryEntry(
      id: map['id'].toString(),
      recipeId: map['recipe_id'].toString(),
      title: map['title'] ?? '',
      imageUrl: map['image_url'] ?? '',
      calories: parseNum(map['calories']),
      protein: parseNum(map['protein']),
      carbs: parseNum(map['carbs']),
      fat: parseNum(map['fat']),
      sugar: parseNum(map['sugar']),
      fiber: parseNum(map['fiber']),
      completedAt: DateTime.parse(map['completed_at']),
    );
  }
} 