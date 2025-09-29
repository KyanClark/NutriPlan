import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealPlannerService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Fetch meal plans from Supabase
  static Future<List<Map<String, dynamic>>> fetchMealPlans() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      // Fetch from meal_plans table with recipe details
      final plansResponse = await _client
          .from('meal_plans')
          .select('*, recipes(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      List<Map<String, dynamic>> allMeals = [];
      
      // Process each meal plan record
      for (final meal in plansResponse) {
        allMeals.add({
          ...meal,
          'plan_id': meal['id'],
          'is_legacy_format': false,
        });
      }
      
      return allMeals;
    } catch (e) {
      print('Error fetching meal plans: $e');
      return [];
    }
  }

  /// Delete selected meals
  static Future<bool> deleteSelectedMeals(List<String> mealIds) async {
    try {
      for (final mealId in mealIds) {
        await _client.from('meal_plans').delete().eq('id', mealId);
      }
      return true;
    } catch (e) {
      print('Error deleting meals: $e');
      return false;
    }
  }

  /// Format meal time from database TIME format to readable string
  static String? formatMealTime(String? timeString) {
    if (timeString == null) return null;
    
    try {
      // Parse time string like "08:30:00" to "8:30 AM"
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        // Format manually to avoid context dependency
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        
        return '$displayHour:$displayMinute $period';
      }
    } catch (e) {
      print('Error formatting meal time: $e');
    }
    
    return timeString; // Return original if parsing fails
  }

  /// Get filtered meals based on selected filter
  static List<Map<String, dynamic>> getFilteredMeals(
    List<Map<String, dynamic>> meals, 
    String selectedFilter
  ) {
    if (selectedFilter == 'all') {
      return meals;
    }
    
    // Time-based filters only
    return meals.where((meal) => meal['meal_type'] == selectedFilter).toList();
  }

  /// Get meal type color
  static Color getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.amber;
      case 'dinner':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// Get meal type icon
  static IconData getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nights_stay;
      default:
        return Icons.restaurant_menu;
    }
  }
}
