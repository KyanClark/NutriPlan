import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/smart_suggestion_models.dart';
import '../../models/meal_history_entry.dart';
import '../../services/smart_meal_suggestion_service.dart';
import '../../widgets/smart_suggestions_loading_animation.dart';
import '../recipes/recipe_info_screen.dart';

class SmartSuggestionsPage extends StatefulWidget {
  const SmartSuggestionsPage({super.key});

  @override
  State<SmartSuggestionsPage> createState() => _SmartSuggestionsPageState();
}

class _SmartSuggestionsPageState extends State<SmartSuggestionsPage> {
  List<SmartMealSuggestion> _smartSuggestions = [];
  bool _loadingSuggestions = false;
  bool _aiWorking = false;

  @override
  void initState() {
    super.initState();
    _testAIIntegration();
  }

  Future<void> _testAIIntegration() async {
    setState(() {
      _loadingSuggestions = true;
    });

    try {
      // Test AI integration
      _aiWorking = await SmartMealSuggestionService.testAIIntegration();
      print('AI Integration Status: ${_aiWorking ? "Working" : "Failed"}');
      
      if (_aiWorking) {
        await _fetchSmartSuggestions();
      } else {
        setState(() {
          _loadingSuggestions = false;
        });
      }
    } catch (e) {
      print('Error testing AI integration: $e');
      setState(() {
        _loadingSuggestions = false;
      });
    }
  }

  Future<void> _fetchSmartSuggestions() async {
    if (!mounted) return;
    setState(() {
      _loadingSuggestions = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _smartSuggestions = [];
          _loadingSuggestions = false;
        });
        return;
      }

      // Get suggestions for the current meal time
      final now = DateTime.now();
      final currentMealCategory = now.hour < 11 ? MealCategory.breakfast : 
                                 now.hour < 15 ? MealCategory.lunch : MealCategory.dinner;

      // Fetch fresh suggestions
      final suggestions = await SmartMealSuggestionService.getSmartSuggestions(
        userId: user.id,
        mealCategory: currentMealCategory,
        targetTime: now,
        useAI: _aiWorking,
      );

      if (!mounted) return;
      setState(() {
        _smartSuggestions = suggestions;
        _loadingSuggestions = false;
      });
    } catch (e) {
      print('Error fetching smart suggestions: $e');
      if (!mounted) return;
      setState(() {
        _smartSuggestions = [];
        _loadingSuggestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Smart Meal Suggestions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fetchSmartSuggestions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Get Fresh Suggestions',
          ),
        ],
      ),
      body: Column(
        children: [
          // AI Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _aiWorking ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _aiWorking ? Colors.green[200]! : Colors.orange[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _aiWorking ? Icons.check_circle : Icons.warning,
                  color: _aiWorking ? Colors.green[600] : Colors.orange[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _aiWorking ? 'AI Integration: Working' : 'AI Integration: Failed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _aiWorking ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                      Text(
                        _aiWorking 
                          ? 'Getting personalized AI suggestions'
                          : 'Using rule-based suggestions',
                        style: TextStyle(
                          fontSize: 12,
                          color: _aiWorking ? Colors.green[600] : Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Suggestions Content
          Expanded(
            child: _buildSuggestionsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsContent() {
    if (_loadingSuggestions) {
      return const Center(
        child: SmartSuggestionsLoadingAnimation(
          loadingMessage: 'Analyzing your eating patterns...',
        ),
      );
    }

    if (_smartSuggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No suggestions available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking meals to get personalized recommendations!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchSmartSuggestions,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Separate recipes from unique AI suggestions
    final recipesSuggestions = _smartSuggestions.where((s) => 
      s.recipe.title.isNotEmpty && 
      s.recipe.imageUrl.isNotEmpty &&
      s.tags.contains('recipe')
    ).toList();
    
    final uniqueSuggestions = _smartSuggestions.where((s) => 
      !recipesSuggestions.contains(s)
    ).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 2 + recipesSuggestions.length + uniqueSuggestions.length,
      itemBuilder: (context, index) {
        // Recipes Section Header
        if (index == 0) {
          return _buildSectionHeader('📋 Recipes from Database', recipesSuggestions.length);
        }
        
        // Recipes
        if (index <= recipesSuggestions.length) {
          final suggestion = recipesSuggestions[index - 1];
          return _buildSuggestionCard(suggestion);
        }
        
        // Unique Suggestions Section Header
        if (index == recipesSuggestions.length + 1) {
          return _buildSectionHeader('✨ AI-Generated Unique Suggestions', uniqueSuggestions.length);
        }
        
        // Unique Suggestions
        final uniqueIndex = index - recipesSuggestions.length - 2;
        final suggestion = uniqueSuggestions[uniqueIndex];
        return _buildSuggestionCard(suggestion);
      },
    );
  }
  
  Widget _buildSectionHeader(String title, int count) {
    if (count == 0) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(SmartMealSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeInfoScreen(
                  recipe: suggestion.recipe,
                  addedRecipeIds: [],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Recipe image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: suggestion.recipe.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            suggestion.recipe.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.restaurant,
                                color: Colors.grey[400],
                                size: 32,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.restaurant,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                
                // Recipe details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.recipe.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        suggestion.reasoning,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildSuggestionTypeChip(suggestion.type),
                          const SizedBox(width: 8),
                          Text(
                            '₱${suggestion.recipe.cost.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTypeChip(SuggestionType type) {
    Color chipColor;
    String chipText;
    
    switch (type) {
      case SuggestionType.fillGap:
        chipColor = Colors.blue;
        chipText = 'Fill Gap';
        break;
      case SuggestionType.perfectTiming:
        chipColor = Colors.green;
        chipText = 'Perfect Timing';
        break;
      case SuggestionType.userFavorites:
        chipColor = Colors.purple;
        chipText = 'Your Favorites';
        break;
      case SuggestionType.trySomethingNew:
        chipColor = Colors.orange;
        chipText = 'Try New';
        break;
      case SuggestionType.healthBoost:
        chipColor = Colors.red;
        chipText = 'Health Boost';
        break;
      case SuggestionType.budgetFriendly:
        chipColor = Colors.teal;
        chipText = 'Budget Friendly';
        break;
      case SuggestionType.quickPrep:
        chipColor = Colors.indigo;
        chipText = 'Quick Prep';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        chipText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: chipColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}
