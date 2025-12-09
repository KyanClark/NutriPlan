import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/smart_suggestion_models.dart';
import '../../models/meal_history_entry.dart';
import '../../models/recipes.dart';
import '../../services/smart_meal_suggestion_service.dart';
import '../../services/health_condition_suggestions_service.dart';
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
  List<SmartMealSuggestion> _healthConditionSuggestions = [];
  bool _loadingSuggestions = false;
  bool _aiWorking = false;
  List<Recipe> _selectedRecipes = [];
  List<String> _userHealthConditions = [];

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

      // Fetch health condition suggestions if user has health conditions
      final healthConditions = await HealthConditionSuggestionsService.getUserHealthConditions(user.id);
      List<SmartMealSuggestion> healthConditionSuggestions = [];
      if (healthConditions.isNotEmpty && !healthConditions.contains('none')) {
        healthConditionSuggestions = await HealthConditionSuggestionsService.getHealthConditionSuggestions(
          userId: user.id,
          healthConditions: healthConditions,
          limit: 6,
        );
      }

      if (!mounted) return;
      setState(() {
        _smartSuggestions = suggestions;
        _healthConditionSuggestions = healthConditionSuggestions;
        _userHealthConditions = healthConditions;
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
                  Flexible(
                    flex: 2,
                    child: SizedBox(
                      height: 100,
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
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedRecipes.clear();
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _buildMealPlan(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text('Build Meal Plan'),
                      ),
                    ),
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

    // Group suggestions by type (excluding healthBoost if we have health condition section)
    final groupedSuggestions = <SuggestionType, List<SmartMealSuggestion>>{};
    for (final suggestion in _smartSuggestions) {
      // Skip healthBoost type if we have a separate health condition section
      if (_healthConditionSuggestions.isNotEmpty && suggestion.type == SuggestionType.healthBoost) {
        continue;
      }
      if (!groupedSuggestions.containsKey(suggestion.type)) {
        groupedSuggestions[suggestion.type] = [];
      }
      groupedSuggestions[suggestion.type]!.add(suggestion);
    }

    // Calculate total sections: regular groups + health condition section (if exists)
    final hasHealthSection = _healthConditionSuggestions.isNotEmpty;
    final regularGroupCount = groupedSuggestions.length;
    final totalSections = regularGroupCount + (hasHealthSection ? 1 : 0);

    // Build sections for each group
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: totalSections * 2, // Header + Grid for each section
      itemBuilder: (context, index) {
        final sectionIndex = index ~/ 2;
        final isHeader = index % 2 == 0;
        
        // Check if this is the health condition section (always last)
        if (hasHealthSection && sectionIndex == totalSections - 1) {
          if (isHeader) {
            return _buildHealthConditionSectionHeader();
          } else {
            return _buildRecipeGrid(_healthConditionSuggestions);
          }
        }
        
        // Regular suggestion groups
        final groups = groupedSuggestions.entries.toList();
        if (sectionIndex >= groups.length) {
          return const SizedBox.shrink();
        }
        
        final group = groups[sectionIndex];
        final suggestions = group.value;
        
        if (isHeader) {
          // Section header with friendly message
          return _buildSectionWithMessage(
            type: group.key,
            suggestions: suggestions,
          );
        } else {
          // 2-column grid of recipes
          return _buildRecipeGrid(suggestions);
        }
      },
    );
  }
  
  Widget _buildSectionWithMessage({
    required SuggestionType type,
    required List<SmartMealSuggestion> suggestions,
  }) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    final message = _getFriendlyMessage(type, suggestions);
    
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _getTypeColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getTypeColor(type).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(List<SmartMealSuggestion> suggestions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return _buildSuggestionCard(suggestions[index]);
      },
    );
  }

  String _getFriendlyMessage(SuggestionType type, List<SmartMealSuggestion> suggestions) {
    switch (type) {
      case SuggestionType.fillGap:
        return "These meals are perfect for filling your nutritional gaps today. They're rich in nutrients you still need to reach your daily goals.";
      case SuggestionType.perfectTiming:
        return "Great timing! These recipes are ideal for your current meal time and will help you maintain a balanced eating schedule.";
      case SuggestionType.userFavorites:
        return "We noticed you enjoy similar dishes! These recipes match your taste preferences and eating patterns.";
      case SuggestionType.trySomethingNew:
        return "Ready to explore? These meals offer variety while still aligning with your nutritional goals and preferences.";
      case SuggestionType.healthBoost:
        return "These recipes are specially chosen to support your health conditions. They're nutritious and tailored to your needs.";
      case SuggestionType.budgetFriendly:
        return "Smart choices that won't break the bank! These affordable meals still meet your nutritional requirements.";
      case SuggestionType.quickPrep:
        return "Short on time? These quick and easy recipes fit perfectly into your busy schedule without compromising nutrition.";
    }
  }

  Color _getTypeColor(SuggestionType type) {
    switch (type) {
      case SuggestionType.fillGap:
        return Colors.blue;
      case SuggestionType.perfectTiming:
        return Colors.green;
      case SuggestionType.userFavorites:
        return Colors.purple;
      case SuggestionType.trySomethingNew:
        return Colors.orange;
      case SuggestionType.healthBoost:
        return Colors.red;
      case SuggestionType.budgetFriendly:
        return Colors.teal;
      case SuggestionType.quickPrep:
        return Colors.indigo;
    }
  }

  IconData _getTypeIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.fillGap:
        return Icons.insights;
      case SuggestionType.perfectTiming:
        return Icons.access_time;
      case SuggestionType.userFavorites:
        return Icons.favorite;
      case SuggestionType.trySomethingNew:
        return Icons.explore;
      case SuggestionType.healthBoost:
        return Icons.health_and_safety;
      case SuggestionType.budgetFriendly:
        return Icons.account_balance_wallet;
      case SuggestionType.quickPrep:
        return Icons.timer;
    }
  }

  Widget _buildHealthConditionSectionHeader() {
    if (_healthConditionSuggestions.isEmpty) return const SizedBox.shrink();
    
    final conditionNames = _userHealthConditions.map((c) {
      switch (c.toLowerCase()) {
        case 'diabetes':
          return 'diabetes';
        case 'hypertension':
        case 'high_blood_pressure':
          return 'high blood pressure';
        case 'stroke_recovery':
          return 'stroke recovery';
        case 'malnutrition':
          return 'malnutrition';
        case 'kidney_disease':
          return 'kidney health';
        case 'heart_disease':
          return 'heart health';
        default:
          return c.replaceAll('_', ' ');
      }
    }).join(', ');
    
    final message = "These recipes are carefully selected to support your health conditions ($conditionNames). "
        "They're tailored to meet your specific nutritional needs and dietary requirements.";
    
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.health_and_safety,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(SmartMealSuggestion suggestion) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: _selectedRecipes.any((r) => r.id == suggestion.recipe.id)
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe image
              AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: suggestion.recipe.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            suggestion.recipe.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.restaurant,
                                color: Colors.grey[400],
                                size: 40,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.restaurant,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                ),
              ),
              
              // Recipe details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          suggestion.recipe.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '₱${suggestion.recipe.cost.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Selection indicator
                          if (_selectedRecipes.any((r) => r.id == suggestion.recipe.id))
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            )
                          else
                            Icon(
                              Icons.circle_outlined,
                              color: Colors.grey[300],
                              size: 20,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Helper function to format date using local time (not UTC) to prevent date shift
  String _formatDateForMealPlan(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
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
                  final Map<String, dynamic> mealData = {
                    'user_id': userId,
                    'recipe_id': m.recipe.id,
                    'title': m.recipe.title,
                    'meal_type': m.mealType ?? 'dinner',
                    'meal_time': m.time != null ? '${m.time!.hour.toString().padLeft(2, '0')}:${m.time!.minute.toString().padLeft(2, '0')}:00' : null,
                    'date': _formatDateForMealPlan(m.scheduledDate ?? DateTime.now()),
                  };
                  
                  // Add rice data if included (only if columns exist in database)
                  if (m.includeRice && m.riceServing != null) {
                    mealData['include_rice'] = true;
                    mealData['rice_serving'] = m.riceServing!.label;
                  }
                  
                  await Supabase.instance.client
                      .from('meal_plans')
                      .insert(mealData);
                  print('Successfully saved meal to plans: ${m.recipe.title}');
                } catch (e) {
                  // If error is due to missing rice columns, try again without rice data
                  if (e.toString().contains('include_rice') || e.toString().contains('rice_serving') || (e.toString().contains('column') && e.toString().contains('does not exist'))) {
                    try {
                      final Map<String, dynamic> mealDataWithoutRice = {
                        'user_id': userId,
                        'recipe_id': m.recipe.id,
                        'title': m.recipe.title,
                        'meal_type': m.mealType ?? 'dinner',
                        'meal_time': m.time != null ? '${m.time!.hour.toString().padLeft(2, '0')}:${m.time!.minute.toString().padLeft(2, '0')}:00' : null,
                        'date': _formatDateForMealPlan(m.scheduledDate ?? DateTime.now()),
                      };
                      await Supabase.instance.client
                          .from('meal_plans')
                          .insert(mealDataWithoutRice);
                      print('Successfully saved meal to plans (without rice): ${m.recipe.title}');
                    } catch (e2) {
                      print('Error saving meal plan: $e2');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving meal: ${m.recipe.title}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } else {
                    print('Error saving meal plan: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error saving meal: ${m.recipe.title}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
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
