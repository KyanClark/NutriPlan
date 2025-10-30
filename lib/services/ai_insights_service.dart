import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_nutrition_goals.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_nutrition_prompts.dart';
// Removed external cache service; using simple in-memory cache
// Simple in-memory cache entry (top-level private)
class _CacheEntry {
  final String value;
  final DateTime expiresAt;
  _CacheEntry({required this.value, required this.expiresAt});
}

class AIInsightsService {


  // IMPORTANT: Get your free Groq API key from https://console.groq.com/
  // Replace 'YOUR_GROQ_API_KEY_HERE' with your actual API key
  // Read from .env via flutter_dotenv (fallback to --dart-define)
  static String get _groqApiKey =>
      (dotenv.env['GROQ_API_KEY'] ?? const String.fromEnvironment('GROQ_API_KEY', defaultValue: ''));
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static final Map<int, _CacheEntry> _memoryCache = {};


  static Future<String> generateNutritionInsights(
    Map<String, dynamic> weeklyData,
    Map<String, dynamic> monthlyData,
    UserNutritionGoals? goals,
  ) async {
    try {

      if (_groqApiKey.isEmpty) {
        return getDefaultInsights();
      }
      final prompt = AINutritionPrompts.buildNutritionPrompt(weeklyData, monthlyData, goals);

      // Simple in-memory cache keyed by prompt hash
      final cacheKey = prompt.hashCode;
      final now = DateTime.now();
      final existing = _memoryCache[cacheKey];
      if (existing != null && now.isBefore(existing.expiresAt)) {
        return existing.value;
      }

      // Exponential backoff for 429s
      const int maxAttempts = 3;
      int attempt = 0;
      Duration delay = const Duration(milliseconds: 400);
      while (true) {
        attempt++;
        final response = await http.post(
          Uri.parse(_groqUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqApiKey',
          },
          body: jsonEncode({
            'model': 'llama-3.1-8b-instant',
            'temperature': 0.7,
            'max_tokens': 800,
            'messages': [
              {
                'role': 'system',
                'content': 'You are a professional nutritionist generating concise, actionable insights.'
              },
              {
                'role': 'user',
                'content': prompt,
              }
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = (data['choices'] != null && data['choices'].isNotEmpty)
              ? data['choices'][0]['message']['content'] as String
              : getDefaultInsights();
          // Cache for 1 day
          _memoryCache[cacheKey] = _CacheEntry(
            value: content,
            expiresAt: now.add(const Duration(days: 1)),
          );
          return content;
        }

        // If rate limited, backoff and retry
        if (response.statusCode == 429 && attempt < maxAttempts) {
          await Future.delayed(delay);
          delay *= 2;
          continue;
        }

        print('Groq API error: ${response.statusCode} - ${response.body}');
        return getDefaultInsights();
      }
    } catch (e) {
      print('Error generating AI insights: $e');
      return getDefaultInsights();
    }
  }


  /// Generate structured weekly insights for the insights card
  static Future<List<Map<String, String>>> generateWeeklyInsights(
    Map<String, dynamic> weeklyData,
    Map<String, dynamic> monthlyData,
    UserNutritionGoals? goals, {
    List<String> availableRecipes = const [],
  }) async {
    try {
      if (_groqApiKey.isEmpty) {
        return _getDefaultWeeklyInsights();
      }

      final prompt = AINutritionPrompts.buildWeeklyInsightsPrompt(weeklyData, monthlyData, goals, availableRecipes: availableRecipes);
      final cacheKey = prompt.hashCode;
      final now = DateTime.now();
      final existing = _memoryCache[cacheKey];
      if (existing != null && now.isBefore(existing.expiresAt)) {
        return _parseWeeklyInsights(existing.value);
      }

      const int maxAttempts = 3;
      int attempt = 0;
      Duration delay = const Duration(milliseconds: 400);
      
      while (true) {
        attempt++;
        final response = await http.post(
          Uri.parse(_groqUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqApiKey',
          },
          body: jsonEncode({
            'model': 'llama-3.1-8b-instant',
            'temperature': 0.7,
            'max_tokens': 1000,
            'messages': [
              {
                'role': 'system',
                'content': 'You are a professional filipino nutritionist and dietician. Generate exactly 2-5 structured weekly insights in JSON format. Each insight should have a title and description. Focus on actionable advice, positive reinforcement, and meal recommendations. IMPORTANT: Only recommend meals that are in the available recipes list provided. If no recipes are available, provide general nutrition guidance instead.'
              },
              {
                'role': 'user',
                'content': prompt,
              }
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = (data['choices'] != null && data['choices'].isNotEmpty)
              ? data['choices'][0]['message']['content'] as String
              : '';
          
          final insights = _parseWeeklyInsights(content);
          if (insights.isNotEmpty) {
            // Cache for 1 day
            _memoryCache[cacheKey] = _CacheEntry(
              value: content,
              expiresAt: now.add(const Duration(days: 1)),
            );
            return insights;
          }
        }

        if (response.statusCode == 429 && attempt < maxAttempts) {
          await Future.delayed(delay);
          delay *= 2;
          continue;
        }

        print('Groq API error for weekly insights: ${response.statusCode}');
        return _getDefaultWeeklyInsights();
      }
    } catch (e) {
      print('Error generating weekly insights: $e');
      return _getDefaultWeeklyInsights();
    }
  }


  /// Parse AI response into structured insights
  static List<Map<String, String>> _parseWeeklyInsights(String content) {
    try {
      // Try to extract JSON from the response
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = content.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonStr);
        final insights = data['insights'] as List?;
        if (insights != null) {
          return insights.map((insight) => {
            'title': insight['title']?.toString() ?? 'Nutrition Insight',
            'description': insight['description']?.toString() ?? 'Keep tracking your nutrition!'
          }).toList();
        }
      }
    } catch (e) {
      print('Error parsing weekly insights JSON: $e');
    }
    
    // Fallback: try to extract insights from text format
    return _extractInsightsFromText(content);
  }

  /// Extract insights from text format as fallback
  static List<Map<String, String>> _extractInsightsFromText(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final insights = <Map<String, String>>[];
    
    for (int i = 0; i < lines.length && insights.length < 3; i++) {
      final line = lines[i].trim();
      if (line.contains('**') || line.contains('•') || line.contains('-')) {
        final cleanLine = line.replaceAll(RegExp(r'[*•\-]'), '').trim();
        if (cleanLine.isNotEmpty) {
          // Try to split title and description
          final parts = cleanLine.split(':');
          if (parts.length >= 2) {
            insights.add({
              'title': parts[0].trim(),
              'description': parts.sublist(1).join(':').trim(),
            });
          } else {
            insights.add({
              'title': 'Nutrition Insight',
              'description': cleanLine,
            });
          }
        }
      }
    }
    
    return insights.take(3).toList();
  }

  /// Get default insights when AI fails
  static String getDefaultInsights() {
    return '''
📊 **Nutrition Analysis**

**Key Insights:**
• Your nutrition tracking shows consistent monitoring habits
• Consider balancing macronutrients for optimal health

**Recommendations:**
• Aim for balanced meals with adequate protein
• Include more fiber-rich foods
• Monitor sugar intake for better health

**Positive Trends:**
• Regular meal tracking indicates good awareness
• Consistent monitoring helps maintain healthy habits

Keep up the great work with your nutrition tracking! 🎯
''';
  }

  /// Get default weekly insights when AI fails
  static List<Map<String, String>> _getDefaultWeeklyInsights() {
    return [
      {
        'title': 'Consistent Tracking',
        'description': 'Great job maintaining your nutrition tracking! Keep logging your meals for better insights.',
      },
      {
        'title': 'Hydration Focus',
        'description': 'Consider tracking your water intake to optimize your nutrition results and overall health.',
      },
      {
        'title': 'Goal Progress',
        'description': 'You\'re making steady progress toward your nutrition goals. Stay consistent for best results!',
      },
    ];
  }
}
