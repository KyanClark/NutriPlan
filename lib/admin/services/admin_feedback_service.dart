import 'package:supabase_flutter/supabase_flutter.dart';
import '../../user/utils/app_logger.dart';
import 'admin_service.dart';

class AdminFeedbackService {
  /// Get all feedbacks across all recipes (admin view)
  static Future<List<Map<String, dynamic>>> getAllFeedbacks({
    String? recipeId,
    int? rating,
    int? limit,
    int? offset,
  }) async {
    await AdminService.requireAdmin();

    try {
      // Check if user is authenticated
      final user = Supabase.instance.client.auth.currentUser;
      AppLogger.info('Fetching feedbacks. Authenticated user: ${user?.email ?? "none"}');

      // Fetch feedbacks without relationships
      dynamic query = Supabase.instance.client
          .from('recipe_feedbacks')
          .select('*');

      if (recipeId != null) {
        query = query.eq('recipe_id', recipeId);
      }

      if (rating != null) {
        query = query.eq('rating', rating);
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 100) - 1);
      }

      final feedbacksResponse = await query;
      final feedbacks = List<Map<String, dynamic>>.from(feedbacksResponse);

      if (feedbacks.isEmpty) {
        AppLogger.info('No feedbacks found');
        return [];
      }

      // Get unique recipe IDs and user IDs
      final recipeIds = feedbacks.map((f) => f['recipe_id']).whereType<String>().toSet().toList();
      final userIds = feedbacks.map((f) => f['user_id']).whereType<String>().toSet().toList();

      // Fetch recipes
      final recipesMap = <String, Map<String, dynamic>>{};
      if (recipeIds.isNotEmpty) {
        try {
          final recipesResponse = await Supabase.instance.client
              .from('recipes')
              .select('id, title')
              .inFilter('id', recipeIds);
          final recipes = List<Map<String, dynamic>>.from(recipesResponse);
          for (final recipe in recipes) {
            recipesMap[recipe['id'].toString()] = recipe;
          }
        } catch (e) {
          AppLogger.warning('Error fetching recipes for feedbacks: $e');
        }
      }

      // Fetch profiles
      final profilesMap = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profilesResponse = await Supabase.instance.client
              .from('profiles')
              .select('id, username, email, full_name')
              .inFilter('id', userIds);
          final profiles = List<Map<String, dynamic>>.from(profilesResponse);
          for (final profile in profiles) {
            profilesMap[profile['id'].toString()] = profile;
          }
        } catch (e) {
          AppLogger.warning('Error fetching profiles for feedbacks: $e');
        }
      }

      // Join the data
      final result = feedbacks.map((feedback) {
        final recipeId = feedback['recipe_id']?.toString();
        final userId = feedback['user_id']?.toString();
        
        final joinedFeedback = {
          ...feedback,
          'recipes': recipeId != null ? recipesMap[recipeId] : null,
          'profiles': userId != null ? profilesMap[userId] : null,
        };
        
        // Log profile data for debugging
        if (userId != null && profilesMap[userId] != null) {
          AppLogger.info('Feedback user ${userId}: ${profilesMap[userId]}');
        } else if (userId != null) {
          AppLogger.warning('Profile not found for user ID: $userId');
        }
        
        return joinedFeedback;
      }).toList();

      AppLogger.info('Feedbacks fetched successfully: ${result.length} feedbacks');
      AppLogger.info('Profiles found: ${profilesMap.length} out of ${userIds.length} user IDs');
      return result;
    } catch (e) {
      AppLogger.error('Error fetching all feedbacks', e);
      // Provide more detailed error message
      final errorMsg = e.toString().toLowerCase();
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        throw Exception('Not authenticated. Please log out and log back in.');
      }
      
      if (errorMsg.contains('permission') || errorMsg.contains('policy') || errorMsg.contains('rls') || errorMsg.contains('row-level')) {
        throw Exception('Permission denied (RLS). Please ensure RLS policies allow authenticated users to read recipe_feedbacks. Current user: ${user.email}');
      }
      if (errorMsg.contains('jwt') || errorMsg.contains('token') || errorMsg.contains('unauthorized')) {
        throw Exception('Authentication failed. Please log out and log back in.');
      }
      throw Exception('Failed to fetch feedbacks: $e');
    }
  }

  /// Get feedback statistics across all recipes
  static Future<Map<String, dynamic>> getOverallFeedbackStats() async {
    await AdminService.requireAdmin();

    try {
      final response = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('rating, recipe_id');

      final feedbacks = List<Map<String, dynamic>>.from(response);

      if (feedbacks.isEmpty) {
        return {
          'totalFeedbacks': 0,
          'averageRating': 0.0,
          'ratingDistribution': <int, int>{},
          'totalRecipes': 0,
        };
      }

      double totalRating = 0.0;
      final ratingDistribution = <int, int>{};
      final recipeIds = <String>{};

      for (final feedback in feedbacks) {
        final rating = feedback['rating'] as int;
        totalRating += rating;
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
        recipeIds.add(feedback['recipe_id'].toString());
      }

      return {
        'totalFeedbacks': feedbacks.length,
        'averageRating': totalRating / feedbacks.length,
        'ratingDistribution': ratingDistribution,
        'totalRecipes': recipeIds.length,
      };
    } catch (e) {
      AppLogger.error('Error fetching feedback stats', e);
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('permission') || errorMsg.contains('policy') || errorMsg.contains('rls') || errorMsg.contains('row-level')) {
        throw Exception('Permission denied. Please ensure:\n1. You are logged in as admin\n2. The admin user exists in Supabase Auth\n3. RLS policies allow admin access to recipe_feedbacks table');
      }
      if (errorMsg.contains('jwt') || errorMsg.contains('token') || errorMsg.contains('unauthorized')) {
        throw Exception('Authentication failed. Please log out and log back in.');
      }
      throw Exception('Failed to fetch feedback stats: $e');
    }
  }

  /// Get feedbacks by recipe
  static Future<List<Map<String, dynamic>>> getFeedbacksByRecipe(String recipeId) async {
    await AdminService.requireAdmin();

    try {
      // Fetch feedbacks
      final feedbacksResponse = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('*')
          .eq('recipe_id', recipeId)
          .order('created_at', ascending: false);

      final feedbacks = List<Map<String, dynamic>>.from(feedbacksResponse);

      if (feedbacks.isEmpty) {
        return [];
      }

      // Get unique user IDs
      final userIds = feedbacks.map((f) => f['user_id']).whereType<String>().toSet().toList();

      // Fetch profiles
      final profilesMap = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profilesResponse = await Supabase.instance.client
              .from('profiles')
              .select('id, username, email, full_name')
              .inFilter('id', userIds);
          final profiles = List<Map<String, dynamic>>.from(profilesResponse);
          for (final profile in profiles) {
            profilesMap[profile['id'].toString()] = profile;
          }
        } catch (e) {
          AppLogger.warning('Error fetching profiles for feedbacks: $e');
        }
      }

      // Join the data
      return feedbacks.map((feedback) {
        final userId = feedback['user_id']?.toString();
        return {
          ...feedback,
          'profiles': userId != null ? profilesMap[userId] : null,
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching feedbacks by recipe', e);
      throw Exception('Failed to fetch feedbacks: $e');
    }
  }

  /// Delete a feedback (admin can delete any feedback)
  static Future<void> deleteFeedback(String feedbackId) async {
    await AdminService.requireAdmin();

    try {
      await Supabase.instance.client
          .from('recipe_feedbacks')
          .delete()
          .eq('id', feedbackId);
    } catch (e) {
      AppLogger.error('Error deleting feedback', e);
      throw Exception('Failed to delete feedback: $e');
    }
  }

  /// Update a feedback (admin can update any feedback)
  static Future<void> updateFeedback({
    required String feedbackId,
    int? rating,
    String? comment,
  }) async {
    await AdminService.requireAdmin();

    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (rating != null) updateData['rating'] = rating;
      if (comment != null) updateData['comment'] = comment;

      await Supabase.instance.client
          .from('recipe_feedbacks')
          .update(updateData)
          .eq('id', feedbackId);
    } catch (e) {
      AppLogger.error('Error updating feedback', e);
      throw Exception('Failed to update feedback: $e');
    }
  }

  /// Get recent feedbacks (last N days)
  static Future<List<Map<String, dynamic>>> getRecentFeedbacks(int days) async {
    await AdminService.requireAdmin();

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      // Fetch feedbacks
      final feedbacksResponse = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('*')
          .gte('created_at', cutoffDate.toIso8601String())
          .order('created_at', ascending: false);

      final feedbacks = List<Map<String, dynamic>>.from(feedbacksResponse);

      if (feedbacks.isEmpty) {
        return [];
      }

      // Get unique recipe IDs and user IDs
      final recipeIds = feedbacks.map((f) => f['recipe_id']).whereType<String>().toSet().toList();
      final userIds = feedbacks.map((f) => f['user_id']).whereType<String>().toSet().toList();

      // Fetch recipes
      final recipesMap = <String, Map<String, dynamic>>{};
      if (recipeIds.isNotEmpty) {
        try {
          final recipesResponse = await Supabase.instance.client
              .from('recipes')
              .select('id, title')
              .inFilter('id', recipeIds);
          final recipes = List<Map<String, dynamic>>.from(recipesResponse);
          for (final recipe in recipes) {
            recipesMap[recipe['id'].toString()] = recipe;
          }
        } catch (e) {
          AppLogger.warning('Error fetching recipes for feedbacks: $e');
        }
      }

      // Fetch profiles
      final profilesMap = <String, Map<String, dynamic>>{};
      if (userIds.isNotEmpty) {
        try {
          final profilesResponse = await Supabase.instance.client
              .from('profiles')
              .select('id, username, email, full_name')
              .inFilter('id', userIds);
          final profiles = List<Map<String, dynamic>>.from(profilesResponse);
          for (final profile in profiles) {
            profilesMap[profile['id'].toString()] = profile;
          }
        } catch (e) {
          AppLogger.warning('Error fetching profiles for feedbacks: $e');
        }
      }

      // Join the data
      return feedbacks.map((feedback) {
        final recipeId = feedback['recipe_id']?.toString();
        final userId = feedback['user_id']?.toString();
        
        return {
          ...feedback,
          'recipes': recipeId != null ? recipesMap[recipeId] : null,
          'profiles': userId != null ? profilesMap[userId] : null,
        };
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching recent feedbacks', e);
      throw Exception('Failed to fetch recent feedbacks: $e');
    }
  }
}

