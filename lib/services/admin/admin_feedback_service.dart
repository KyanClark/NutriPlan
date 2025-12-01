import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_logger.dart';
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
      dynamic query = Supabase.instance.client
          .from('recipe_feedbacks')
          .select('*, recipes(id, title), profiles(id, username, email)');

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

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Error fetching all feedbacks', e);
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
      throw Exception('Failed to fetch feedback stats: $e');
    }
  }

  /// Get feedbacks by recipe
  static Future<List<Map<String, dynamic>>> getFeedbacksByRecipe(String recipeId) async {
    await AdminService.requireAdmin();

    try {
      final response = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('*, profiles(id, username, email)')
          .eq('recipe_id', recipeId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
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
      
      final response = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('*, recipes(id, title), profiles(id, username, email)')
          .gte('created_at', cutoffDate.toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Error fetching recent feedbacks', e);
      throw Exception('Failed to fetch recent feedbacks: $e');
    }
  }
}

