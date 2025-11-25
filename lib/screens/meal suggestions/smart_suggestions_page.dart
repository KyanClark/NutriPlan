import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/smart_suggestion_models.dart';
import '../../models/meal_history_entry.dart';
import '../../models/recipes.dart';
import '../../services/smart_meal_suggestion_service.dart';
import '../../widgets/smart_suggestions_loading_animation.dart';
import '../recipes/recipe_info_screen.dart';
import '../meal_plan/meal_summary_page.dart';
import '../meal_plan/meal_plan_confirmation_page.dart';

class SmartSuggestionsPage extends StatefulWidget {
  const SmartSuggestionsPage({super.key});

  @override
  State<SmartSuggestionsPage> createState() => _SmartSuggestionsPageState();
}

class _SmartSuggestionsPageState extends State<SmartSuggestionsPage> {
  List<SmartMealSuggestion> _smartSuggestions = [];
  bool _loadingSuggestions = false;
  bool _aiWorking = false;
  List<Recipe> _selectedRecipes = [];

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
          // Selected meals indicator and build button
          if (_selectedRecipes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Selected meal images
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: _selectedRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _selectedRecipes[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: recipe.imageUrl.isNotEmpty
                                ? Image.network(
                                    recipe.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.restaurant,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.restaurant,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedRecipes.clear();
                      });
                    },
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _buildMealPlan(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Build Meal Plan'),
                  ),
                ],
              ),
            ),
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
          return _buildSectionHeader(' Unique Meal Suggestions for you', uniqueSuggestions.length);
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
        border: _selectedRecipes.any((r) => r.id == suggestion.recipe.id)
            ? Border.all(color: Colors.green, width: 2)
            : null,
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
            // Toggle selection when tapping the card
            setState(() {
              if (_selectedRecipes.any((r) => r.id == suggestion.recipe.id)) {
                _selectedRecipes.removeWhere((r) => r.id == suggestion.recipe.id);
              } else {
                _selectedRecipes.add(suggestion.recipe);
              }
            });
          },
          onLongPress: () {
            // Long press to view recipe details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeInfoScreen(
                  recipe: suggestion.recipe,
                  addedRecipeIds: _selectedRecipes.map((r) => r.id).toList(),
                ),
              ),
            ).then((_) {
              // Refresh selections when returning from recipe info
              setState(() {});
            });
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
                
                // Selection indicator
                if (_selectedRecipes.any((r) => r.id == suggestion.recipe.id))
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  )
                else
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

  Future<void> _buildMealPlan() async {
    if (_selectedRecipes.isEmpty) return;

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MealSummaryPage(
          meals: _selectedRecipes,
          onBuildMealPlan: (mealsWithTime) async {
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              for (final m in mealsWithTime) {
                try {
                  // Insert one row per meal with required date and time
                  await Supabase.instance.client
                      .from('meal_plans')
                      .insert({
                        'user_id': userId,
                        'recipe_id': m.recipe.id,
                        'title': m.recipe.title,
                        'meal_type': m.mealType ?? 'dinner',
                        'meal_time': m.time != null ? '${m.time!.hour.toString().padLeft(2, '0')}:${m.time!.minute.toString().padLeft(2, '0')}:00' : null,
                        'date': (m.scheduledDate ?? DateTime.now()).toUtc().toIso8601String().split('T').first,
                      });
                  print('Successfully saved meal to plans: ${m.recipe.title}');
                } catch (e) {
                  print('Error saving meal plan: $e');
                }
              }

              // Clear the selected recipes
              if (mounted) {
                setState(() {
                  _selectedRecipes.clear();
                });
              }

              // Navigate to confirmation page
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealPlanConfirmationPage(),
                  ),
                );
              }
            }
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
