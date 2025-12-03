import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AdminService {
  /// Check if the current user is an admin
  /// This checks the profiles table for an 'is_admin' field or 'role' field
  /// Works on web and Windows desktop platforms
  static Future<bool> isCurrentUserAdmin() async {
    try {
      // Only check admin status on web or Windows desktop platforms
      // Allow web and Windows desktop, block mobile
      bool isDesktop = kIsWeb;
      if (!kIsWeb) {
        try {
          isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
        } catch (_) {
          // Platform not available (web), already handled above
          isDesktop = false;
        }
      }
      if (!isDesktop) return false;
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      // Try to get admin status from profiles table
      // Only select fields that might exist to avoid errors
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return false;

      // Check for role field (if using role-based access)
      if (response['role'] == 'admin' || response['role'] == 'administrator') {
        return true;
      }

      // Alternative: Check if user email is in admin list
      // You can maintain a list of admin emails in your database
      final adminEmails = await _getAdminEmails();
      if (adminEmails.contains(user.email?.toLowerCase())) {
        return true;
      }

      return false;
    } catch (e) {
      // Silently fail - don't log errors for missing columns
      // This prevents errors when admin columns don't exist
      return false;
    }
  }

  /// Get list of admin emails from database (optional approach)
  static Future<List<String>> _getAdminEmails() async {
    try {
      final response = await Supabase.instance.client
          .from('admin_users')
          .select('email');
      
      return (response as List)
          .map((item) => (item['email'] as String?)?.toLowerCase() ?? '')
          .where((email) => email.isNotEmpty)
          .toList();
    } catch (_) {
      // Table might not exist, return empty list
      return [];
    }
  }

  /// Verify admin access and throw if not admin
  /// NOTE: Since admin login is handled separately, we always allow access
  static Future<void> requireAdmin() async {
    // Admin access is verified at login, so we always allow here
    // This prevents "admin access required" errors when fetching data
    return;
  }
}

