import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_nutrition_goals.dart';
// Removed external cache service; using simple in-memory cache
// Simple in-memory cache entry (top-level private)
class _CacheEntry {
  final String value;
  final DateTime expiresAt;
  _CacheEntry({required this.value, required this.expiresAt});
}

class AIInsightsService {
  // Groq-only configuration
  static const String _groqApiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static final Map<int, _CacheEntry> _memoryCache = {};

  /// Generate AI insights for nutrition data
  static Future<String> generateNutritionInsights(
    Map<String, dynamic> weeklyData,
    Map<String, dynamic> monthlyData,
    UserNutritionGoals? goals,
  ) async {
    try {
      // If API key is missing, return default insights gracefully
      if (_groqApiKey.isEmpty) {
        return getDefaultInsights();
      }
      final prompt = _buildNutritionPrompt(weeklyData, monthlyData, goals);

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
            'model': 'llama-3.1-70b-versatile',
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
          // Cache for 10 minutes
          _memoryCache[cacheKey] = _CacheEntry(
            value: content,
            expiresAt: now.add(const Duration(minutes: 10)),
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

  /// Build nutrition analysis prompt for Gemini
  static String _buildNutritionPrompt(Map<String, dynamic> weeklyData, Map<String, dynamic> monthlyData, UserNutritionGoals? goals) {
    final weeklyAverages = weeklyData['averages'] as Map<String, double>;
    final monthlyAverages = monthlyData['averages'] as Map<String, double>;

    final calorieGoal = goals?.calorieGoal ?? 2000.0;
    final proteinGoal = goals?.proteinGoal ?? 150.0;
    final carbGoal = goals?.carbGoal ?? 250.0;
    final fatGoal = goals?.fatGoal ?? 65.0;

    return '''
As a professional nutritionist, analyze this user's nutrition data and provide personalized insights:

WEEKLY DATA:
- Average Calories: ${weeklyAverages['calories']!.toStringAsFixed(0)} kcal (Goal: ${calorieGoal.toStringAsFixed(0)} kcal)
- Average Protein: ${weeklyAverages['protein']!.toStringAsFixed(1)}g (Goal: ${proteinGoal.toStringAsFixed(0)}g)
- Average Carbs: ${weeklyAverages['carbs']!.toStringAsFixed(1)}g (Goal: ${carbGoal.toStringAsFixed(0)}g)
- Average Fat: ${weeklyAverages['fat']!.toStringAsFixed(1)}g (Goal: ${fatGoal.toStringAsFixed(0)}g)
- Average Fiber: ${weeklyAverages['fiber']!.toStringAsFixed(1)}g
- Average Sugar: ${weeklyAverages['sugar']!.toStringAsFixed(1)}g

MONTHLY DATA:
- Average Calories: ${monthlyAverages['calories']!.toStringAsFixed(0)} kcal
- Average Protein: ${monthlyAverages['protein']!.toStringAsFixed(1)}g
- Average Carbs: ${monthlyAverages['carbs']!.toStringAsFixed(1)}g
- Average Fat: ${monthlyAverages['fat']!.toStringAsFixed(1)}g
- Average Fiber: ${monthlyAverages['fiber']!.toStringAsFixed(1)}g
- Average Sugar: ${monthlyAverages['sugar']!.toStringAsFixed(1)}g

Please provide:
1. Key insights about their nutrition patterns
2. Areas for improvement
3. Specific recommendations
4. Positive trends to maintain

Keep the response concise, actionable, and encouraging. Focus on practical advice that can be implemented immediately.
''';
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
}
