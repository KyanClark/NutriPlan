import 'package:supabase_flutter/supabase_flutter.dart';

// Test script to verify feedback table functionality
void testFeedbackTable() async {
  try {
    // Test 1: Check if table exists
    print('Testing feedback table...');
    
    // Test 2: Try to insert a test feedback
    final testFeedback = {
      'recipe_id': 'test_recipe_123',
      'user_id': 'test_user_123',
      'rating': 5,
      'comment': 'Test feedback from script',
    };
    
    print('Attempting to insert test feedback...');
    final insertResult = await Supabase.instance.client
        .from('recipe_feedbacks')
        .insert(testFeedback)
        .select();
    
    print('Insert successful: $insertResult');
    
    // Test 3: Try to fetch feedbacks
    print('Attempting to fetch feedbacks...');
    final fetchResult = await Supabase.instance.client
        .from('recipe_feedbacks')
        .select('*')
        .eq('recipe_id', 'test_recipe_123');
    
    print('Fetch successful: $fetchResult');
    
  } catch (e) {
    print('Error testing feedback table: $e');
  }
} 