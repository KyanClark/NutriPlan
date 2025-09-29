import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_nutrition_goals.dart';

class AIInsightsService {
  static const String _geminiApiKey = 'AIzaSyA58P35E85fvoML8AkqKIME9n4dC26M4GQ';
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  /// Generate AI insights for nutrition data
  static Future<String> generateNutritionInsights(Map<String, dynamic> weeklyData, Map<String, dynamic> monthlyData, UserNutritionGoals? goals) async {
    try {
      final prompt = _buildNutritionPrompt(weeklyData, monthlyData, goals);
      
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        return content;
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
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
