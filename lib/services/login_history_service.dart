import 'package:shared_preferences/shared_preferences.dart';

class LoginHistoryService {
  static const String _loginHistoryKey = 'login_history';
  static const int _maxHistorySize = 10;

  /// Save email to login history
  static Future<void> saveEmailToHistory(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = await getLoginHistory();
      
      // Remove the email if it already exists (to move it to the top)
      history.remove(email);
      
      // Add the email to the beginning of the list
      history.insert(0, email);
      
      // Keep only the most recent emails
      if (history.length > _maxHistorySize) {
        history = history.take(_maxHistorySize).toList();
      }
      
      await prefs.setStringList(_loginHistoryKey, history);
    } catch (e) {
      print('Error saving email to history: $e');
    }
  }

  /// Get login history
  static Future<List<String>> getLoginHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_loginHistoryKey) ?? [];
    } catch (e) {
      print('Error getting login history: $e');
      return [];
    }
  }

  /// Get filtered login history based on input
  static Future<List<String>> getFilteredHistory(String input) async {
    try {
      final history = await getLoginHistory();
      if (input.isEmpty) {
        return history;
      }
      
      return history
          .where((email) => email.toLowerCase().contains(input.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error filtering login history: $e');
      return [];
    }
  }

  /// Clear login history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginHistoryKey);
    } catch (e) {
      print('Error clearing login history: $e');
    }
  }
} 