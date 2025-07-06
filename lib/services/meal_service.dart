import '../models/meal.dart';
import '../models/user_profile.dart';
import '../models/meal_plan.dart';

class MealService {
  static final List<Meal> _sampleMeals = [
    Meal(
      id: '1',
      name: 'Grilled Chicken Salad',
      description: 'A healthy and protein-rich salad with grilled chicken',
      ingredients: ['Chicken breast', 'Mixed greens', 'Cherry tomatoes', 'Cucumber', 'Olive oil'],
      instructions: ['Grill chicken breast', 'Chop vegetables', 'Mix ingredients', 'Add dressing'],
      calories: 350,
      protein: 35,
      carbs: 15,
      fat: 12,
      cost: 8.50,
      cookingTime: 20,
      dietaryTags: ['high-protein', 'low-carb'],
    ),
    Meal(
      id: '2',
      name: 'Vegetarian Pasta',
      description: 'Delicious vegetarian pasta with fresh vegetables',
      ingredients: ['Pasta', 'Broccoli', 'Bell peppers', 'Olive oil', 'Garlic'],
      instructions: ['Boil pasta', 'Sauté vegetables', 'Combine ingredients'],
      calories: 450,
      protein: 12,
      carbs: 65,
      fat: 8,
      cost: 6.00,
      cookingTime: 25,
      dietaryTags: ['vegetarian'],
    ),
    Meal(
      id: '3',
      name: 'Salmon with Quinoa',
      description: 'Nutritious salmon served with quinoa and vegetables',
      ingredients: ['Salmon fillet', 'Quinoa', 'Asparagus', 'Lemon', 'Herbs'],
      instructions: ['Cook quinoa', 'Grill salmon', 'Steam asparagus', 'Season with herbs'],
      calories: 520,
      protein: 42,
      carbs: 35,
      fat: 18,
      cost: 12.00,
      cookingTime: 30,
      dietaryTags: ['pescatarian', 'high-protein'],
    ),
    Meal(
      id: '4',
      name: 'Oatmeal with Berries',
      description: 'Healthy breakfast with oats and fresh berries',
      ingredients: ['Oats', 'Milk', 'Berries', 'Honey', 'Nuts'],
      instructions: ['Cook oats with milk', 'Top with berries and nuts', 'Drizzle with honey'],
      calories: 280,
      protein: 8,
      carbs: 45,
      fat: 6,
      cost: 3.50,
      cookingTime: 10,
      dietaryTags: ['vegetarian', 'breakfast'],
    ),
    Meal(
      id: '5',
      name: 'Greek Yogurt Bowl',
      description: 'Protein-rich yogurt bowl with granola and fruits',
      ingredients: ['Greek yogurt', 'Granola', 'Banana', 'Honey', 'Chia seeds'],
      instructions: ['Layer yogurt in bowl', 'Add granola and fruits', 'Drizzle with honey'],
      calories: 320,
      protein: 20,
      carbs: 40,
      fat: 8,
      cost: 4.50,
      cookingTime: 5,
      dietaryTags: ['vegetarian', 'high-protein'],
    ),
    Meal(
      id: '6',
      name: 'Tomato Soup',
      description: 'Warm and comforting tomato soup with herbs',
      ingredients: ['Tomatoes', 'Onion', 'Garlic', 'Vegetable broth', 'Cream', 'Herbs'],
      instructions: ['Sauté onions and garlic', 'Add tomatoes and broth', 'Simmer and blend', 'Add cream'],
      calories: 180,
      protein: 4,
      carbs: 20,
      fat: 8,
      cost: 3.00,
      cookingTime: 25,
      dietaryTags: ['vegetarian', 'soup'],
    ),
    Meal(
      id: '7',
      name: 'Chocolate Cake',
      description: 'Rich and moist chocolate cake with frosting',
      ingredients: ['Flour', 'Cocoa powder', 'Sugar', 'Eggs', 'Milk', 'Butter', 'Vanilla'],
      instructions: ['Mix dry ingredients', 'Cream butter and sugar', 'Add eggs and milk', 'Bake'],
      calories: 450,
      protein: 6,
      carbs: 65,
      fat: 18,
      cost: 8.00,
      cookingTime: 45,
      dietaryTags: ['vegetarian', 'dessert'],
    ),
    Meal(
      id: '8',
      name: 'Rice Cake with Vegetables',
      description: 'Healthy rice cake topped with fresh vegetables',
      ingredients: ['Rice', 'Carrots', 'Cucumber', 'Avocado', 'Soy sauce', 'Sesame seeds'],
      instructions: ['Cook rice', 'Shape into cakes', 'Top with vegetables', 'Drizzle with sauce'],
      calories: 280,
      protein: 6,
      carbs: 55,
      fat: 4,
      cost: 5.50,
      cookingTime: 35,
      dietaryTags: ['vegetarian', 'rice'],
    ),
    Meal(
      id: '9',
      name: 'Hummus with Pita',
      description: 'Creamy hummus served with warm pita bread',
      ingredients: ['Chickpeas', 'Tahini', 'Lemon', 'Garlic', 'Olive oil', 'Pita bread'],
      instructions: ['Blend chickpeas with tahini', 'Add lemon and garlic', 'Serve with pita'],
      calories: 220,
      protein: 8,
      carbs: 30,
      fat: 8,
      cost: 4.00,
      cookingTime: 15,
      dietaryTags: ['vegetarian', 'vegan', 'appetizer'],
    ),
    Meal(
      id: '10',
      name: 'Grilled Cheese Sandwich',
      description: 'Classic grilled cheese with melted cheese and butter',
      ingredients: ['Bread', 'Cheese', 'Butter', 'Herbs'],
      instructions: ['Butter bread', 'Add cheese', 'Grill until golden'],
      calories: 380,
      protein: 15,
      carbs: 35,
      fat: 18,
      cost: 3.50,
      cookingTime: 8,
      dietaryTags: ['vegetarian', 'snack'],
    ),
  ];

  static List<Meal> getAllMeals() {
    return _sampleMeals;
  }

  static List<Meal> getMealSuggestions(UserProfile profile) {
    List<Meal> suggestions = [];
    
    for (Meal meal in _sampleMeals) {
      bool isCompatible = true;
      
      // Check dietary preferences
      for (String preference in profile.dietaryPreferences) {
        if (preference.toLowerCase() == 'vegetarian' && 
            !meal.dietaryTags.contains('vegetarian')) {
          isCompatible = false;
          break;
        }
        if (preference.toLowerCase() == 'vegan' && 
            !meal.dietaryTags.contains('vegan')) {
          isCompatible = false;
          break;
        }
        if (preference.toLowerCase() == 'pescatarian' && 
            !meal.dietaryTags.contains('pescatarian')) {
          isCompatible = false;
          break;
        }
      }
      
      // Check budget
      if (meal.cost > profile.budget) {
        isCompatible = false;
      }
      
      // Check allergies (simple check - in real app would be more sophisticated)
      for (String allergy in profile.allergies) {
        for (String ingredient in meal.ingredients) {
          if (ingredient.toLowerCase().contains(allergy.toLowerCase())) {
            isCompatible = false;
            break;
          }
        }
      }
      
      if (isCompatible) {
        suggestions.add(meal);
      }
    }
    
    return suggestions;
  }

  static double calculateTotalCost(List<MealPlan> mealPlans) {
    return mealPlans.fold(0.0, (sum, mealPlan) => sum + mealPlan.meal.cost);
  }

  static Map<String, double> calculateNutritionalTotals(List<MealPlan> mealPlans) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    for (MealPlan mealPlan in mealPlans) {
      totalCalories += mealPlan.meal.calories;
      totalProtein += mealPlan.meal.protein;
      totalCarbs += mealPlan.meal.carbs;
      totalFat += mealPlan.meal.fat;
    }
    
    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }
} 