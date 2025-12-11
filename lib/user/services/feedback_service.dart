import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  static Future<List<Map<String, dynamic>>> fetchRecipeFeedbacks(String recipeId) async {
    try {
      print('Fetching feedbacks for recipe: $recipeId');
      
      // Try to fetch with profile join
      try {
        final response = await Supabase.instance.client
            .from('recipe_feedbacks')
            .select('*, profiles (id, username, full_name, email)')
            .eq('recipe_id', recipeId)
            .order('created_at', ascending: false);
        
        final feedbacks = List<Map<String, dynamic>>.from(response);
        print('Successfully fetched ${feedbacks.length} feedbacks with profiles');
        
        // Debug: Check the structure of the first feedback
        if (feedbacks.isNotEmpty) {
          print('First feedback structure: ${feedbacks.first}');
          print('Profile data in first feedback: ${feedbacks.first['profiles']}');
        }
        
        return feedbacks;
      } catch (joinError) {
        print('Profile join failed, trying without join: $joinError');
        // Fallback: fetch without profile join
        final response = await Supabase.instance.client
            .from('recipe_feedbacks')
            .select('*')
            .eq('recipe_id', recipeId)
            .order('created_at', ascending: false);
        
        final feedbacks = List<Map<String, dynamic>>.from(response);
        print('Successfully fetched ${feedbacks.length} feedbacks without profiles');
        
        // Try to fetch profile data separately for each feedback
        final feedbacksWithProfiles = <Map<String, dynamic>>[];
        for (final feedback in feedbacks) {
          try {
            final userId = feedback['user_id'];
            if (userId != null) {
              print('Fetching profile for user: $userId');
              final profileResponse = await Supabase.instance.client
                  .from('profiles')
                  .select('id, username, full_name, email')
                  .eq('id', userId)
                  .maybeSingle();
              
              print('Profile response for user $userId: $profileResponse');
              
              if (profileResponse != null) {
                feedback['profiles'] = profileResponse;
                print('Added profile to feedback: ${feedback['profiles']}');
              } else {
                print('No profile found for user $userId');
              }
            } else {
              print('No user_id in feedback: $feedback');
            }
          } catch (e) {
            print('Could not fetch profile for user ${feedback['user_id']}: $e');
          }
          feedbacksWithProfiles.add(feedback);
        }
        
        print('Returning ${feedbacksWithProfiles.length} feedbacks with profiles');
        
        return feedbacksWithProfiles;
      }
    } catch (e) {
      print('Error fetching feedbacks: $e');
      throw Exception('Failed to fetch feedbacks: $e');
    }
  }

  static Future<Map<String, dynamic>> addFeedback({
    required String recipeId,
    required double rating,
    required String comment,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate inputs
      if (recipeId.isEmpty) {
        throw Exception('Recipe ID cannot be empty');
      }
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Insert the feedback
      final response = await Supabase.instance.client
          .from('recipe_feedbacks')
          .insert({
            'recipe_id': recipeId,
            'user_id': user.id,
            'rating': rating.toInt(),
            'comment': comment.trim(),
          })
          .select();

      // Convert response to List and get first item
      final responseList = List<Map<String, dynamic>>.from(response);
      if (responseList.isNotEmpty) {
        return responseList.first;
      } else {
        // If select doesn't return data, create a minimal response
        return {
          'recipe_id': recipeId,
          'user_id': user.id,
          'rating': rating.toInt(),
          'comment': comment.trim(),
        };
      }
    } catch (e) {
      // Provide more detailed error message
      final errorMessage = e.toString();
      print('Error adding feedback: $e');
      
      if (errorMessage.contains('foreign key') || errorMessage.contains('recipe_id')) {
        throw Exception('Invalid recipe ID. Please try again.');
      } else if (errorMessage.contains('duplicate') || errorMessage.contains('unique')) {
        throw Exception('You have already submitted feedback for this recipe.');
      } else if (errorMessage.contains('permission') || errorMessage.contains('policy')) {
        throw Exception('Permission denied. Please check your account settings.');
      } else {
        throw Exception('Failed to submit feedback: ${e.toString()}');
      }
    }
  }

  static Future<void> updateFeedback({
    required String feedbackId,
    required double rating,
    required String comment,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client
          .from('recipe_feedbacks')
          .update({
            'rating': rating.toInt(),
            'comment': comment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', feedbackId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to update feedback: $e');
    }
  }

  static Future<void> deleteFeedback(String feedbackId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await Supabase.instance.client
          .from('recipe_feedbacks')
          .delete()
          .eq('id', feedbackId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
    }
  }

  static Future<Map<String, dynamic>> getFeedbackStats(String recipeId) async {
    try {
      final response = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('rating')
          .eq('recipe_id', recipeId);

      final feedbacks = List<Map<String, dynamic>>.from(response);
      
      if (feedbacks.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalFeedbacks': 0,
          'ratingDistribution': {},
        };
      }

      double totalRating = 0.0;
      Map<int, int> ratingDistribution = {};

      for (final feedback in feedbacks) {
        final rating = feedback['rating'] as int;
        totalRating += rating;
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
      }

      return {
        'averageRating': totalRating / feedbacks.length,
        'totalFeedbacks': feedbacks.length,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      throw Exception('Failed to get feedback stats: $e');
    }
  }

  static Future<bool> hasUserReviewed(String recipeId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return false;
      }

      final response = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('id')
          .eq('recipe_id', recipeId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUserFeedback(String recipeId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('*')
          .eq('recipe_id', recipeId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
} 