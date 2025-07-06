
class UserProfile {
  final String name;
  final List<String> dietaryPreferences;
  final String healthGoal;
  final List<String> allergies;
  final double budget;

  UserProfile({
    required this.name,
    required this.dietaryPreferences,
    required this.healthGoal,
    required this.allergies,
    required this.budget,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      dietaryPreferences: List<String>.from(json['dietaryPreferences'] ?? []),
      healthGoal: json['healthGoal'] ?? '',
      allergies: List<String>.from(json['allergies'] ?? []),
      budget: (json['budget'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dietaryPreferences': dietaryPreferences,
      'healthGoal': healthGoal,
      'allergies': allergies,
      'budget': budget,
    };
  }
} 