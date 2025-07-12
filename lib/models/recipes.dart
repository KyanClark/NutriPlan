class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String shortDescription;
  final List<String> ingredients;
  final List<String> instructions;
  final Map<String, dynamic> macros;
  final String allergyWarning;
  final int calories;
  final List<String> dietTypes;
  final double cost;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.shortDescription,
    required this.ingredients,
    required this.instructions,
    required this.macros,
    required this.allergyWarning,
    required this.calories,
    required this.dietTypes,
    required this.cost,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      imageUrl: map['image_url'] ?? '',
      shortDescription: map['short_description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      macros: Map<String, dynamic>.from(map['macros'] ?? {}),
      allergyWarning: map['allergy_warning'] ?? '',
      calories: map['calories'] is int ? map['calories'] : int.tryParse(map['calories']?.toString() ?? '0') ?? 0,
      dietTypes: List<String>.from(map['diet_types'] ?? []),
      cost: map['cost'] is double ? map['cost'] : double.tryParse(map['cost']?.toString() ?? '0') ?? 0.0,
    );
  }
}