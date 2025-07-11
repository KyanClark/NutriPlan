import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipes.dart';

class RecipeService {
  static Future<List<Recipe>> fetchRecipes() async {
    final response = await Supabase.instance.client
        .from('recipes')
        .select()
        .then((data) => data);

    // If using the latest supabase_flutter, .select() returns a Future<List<Map<String, dynamic>>>
    // So we can map directly:
    return (response as List)
        .map((item) => Recipe.fromMap(item as Map<String, dynamic>))
        .toList();
  }
} 