import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  static Future<List<Map<String, dynamic>>> fetchRecipeFeedbacks(String recipeId) async {
    try {
      final response = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('*')
          .eq('recipe_id', recipeId)
          .order('created_at', ascending: false);
      
      // Get user profiles separately
      final feedbacks = List<Map<String, dynamic>>.from(response);
      final userIds = feedbacks.map((f) => f['user_id']).toSet().toList();
      
      if (userIds.isNotEmpty) {
        final profilesResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, username')
            .inFilter('id', userIds);
        
        final profiles = Map<String, dynamic>.fromEntries(
          (profilesResponse as List).map((p) => MapEntry(p['id'], p))
        );
        
        // Merge feedback with profile data
        for (final feedback in feedbacks) {
          final profile = profiles[feedback['user_id']];
          feedback['profiles'] = profile ?? {'username': 'Anonymous'};
        }
      }
      
      return feedbacks;
    } catch (e) {
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

      // Insert the feedback
      await Supabase.instance.client
          .from('recipe_feedbacks')
          .insert({
            'recipe_id': recipeId,
            'user_id': user.id,
            'rating': rating.toInt(),
            'comment': comment,
          });

      // Fetch the newly created feedback
      final response = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('*')
          .eq('recipe_id', recipeId)
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      // Get user profile information
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, username')
          .eq('id', user.id)
          .single();

      // Merge feedback with profile data
      response['profiles'] = profileResponse;

      return response;
    } catch (e) {
      throw Exception('Failed to add feedback: $e');
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