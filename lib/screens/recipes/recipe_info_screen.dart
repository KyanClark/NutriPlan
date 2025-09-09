import 'package:flutter/material.dart';
import '../../models/recipes.dart';
import 'package:nutriplan/screens/recipes/recipe_steps_summary_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/feedback_service.dart';
import '../../services/fnri_nutrition_service.dart';
import '../feedback/feedback_thank_you_page.dart';

/// Macro chip widget for displaying nutrition information
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _MacroChip({required this.label, required this.value, this.unit = 'g'});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value$unit', style: const TextStyle(fontSize: 13, color: Colors.green)),
    );
  }
}

class RecipeInfoScreen extends StatefulWidget {
  final Recipe recipe;
  final List<String> addedRecipeIds;
  final bool showStartCooking;
  final bool isFromMealHistory;
  final Function(Recipe)? onAddToMealPlan;

  const RecipeInfoScreen({
    super.key, 
    required this.recipe, 
    this.addedRecipeIds = const [], 
    this.showStartCooking = false,
    this.isFromMealHistory = false,
    this.onAddToMealPlan,
  });

  @override
  State<RecipeInfoScreen> createState() => _RecipeInfoScreenState();
}

class _RecipeInfoScreenState extends State<RecipeInfoScreen> {
  bool showMealPlanBar = false;
  List<Map<String, dynamic>> feedbacks = [];
  bool isLoadingFeedbacks = true;
  double averageRating = 0.0;
  int totalFeedbacks = 0;
  
  // Nutrition update state
  bool isUpdatingNutrition = false;
  Map<String, dynamic>? updatedNutrition;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
    _checkDatabaseTable();
    _checkAndUpdateNutrition(); // Auto-update nutrition if missing
  }

  Future<void> _checkDatabaseTable() async {
    try {
      final result = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('count')
          .limit(1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database table not found: $e')),
      );
    }
  }

  Future<void> _loadFeedbacks() async {
    setState(() {
      isLoadingFeedbacks = true;
    });

    try {
      final response = await FeedbackService.fetchRecipeFeedbacks(widget.recipe.id);
      
      if (mounted) {
        setState(() {
          feedbacks = response;
          _calculateAverageRating();
          isLoadingFeedbacks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingFeedbacks = false;
        });
      }
    }
  }

  void _calculateAverageRating() {
    if (feedbacks.isEmpty) {
      averageRating = 0.0;
      totalFeedbacks = 0;
      return;
    }

    double totalRating = 0.0;
    for (final feedback in feedbacks) {
      totalRating += (feedback['rating'] ?? 0).toDouble();
    }
    averageRating = totalRating / feedbacks.length;
    totalFeedbacks = feedbacks.length;
  }

  /// Get safe nutrition values with fallbacks for missing data
  Map<String, dynamic> get safeNutrition {
    final macros = updatedNutrition ?? widget.recipe.macros;
    
    // Provide fallback values for missing nutrition data
    // This prevents null check operator errors when nutrition data is missing
    return {
      'calories': widget.recipe.calories ?? 0,
      'protein': _safeDouble(macros?['protein'], 0.0),
      'carbs': _safeDouble(macros?['carbs'], 0.0),
      'fat': _safeDouble(macros?['fat'], 0.0),
      'fiber': _safeDouble(macros?['fiber'], 0.0),
      'sugar': _safeDouble(macros?['sugar'], 0.0),
      'sodium': _safeDouble(macros?['sodium'], 0.0),
      'cholesterol': _safeDouble(macros?['cholesterol'], 0.0),
    };
  }

  /// Safely convert any value to double with fallback
  double _safeDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? fallback;
    }
    return fallback;
  }

  /// Estimate ingredient quantities for nutrition calculation
  Map<String, double> _estimateIngredientQuantities(List<String> ingredients) {
    final quantities = <String, double>{};
    
    print('🔍 Estimating quantities for ${ingredients.length} ingredients:');
    
    for (final ingredient in ingredients) {
      final ingredientLower = ingredient.toLowerCase();
      
      // Try to extract quantity from ingredient string first
      double quantity = _extractQuantityFromString(ingredientLower);
      
      // If no quantity found, estimate based on ingredient type
      if (quantity <= 0) {
        quantity = _estimateIngredientQuantity(ingredientLower);
        print('     $ingredient: No quantity found, estimated ${quantity}g');
      } else {
        print('     $ingredient: Extracted ${quantity}g from string');
      }
      
      quantities[ingredient] = quantity;
    }
    
    print('📊 Final quantities: $quantities');
    return quantities;
  }

  /// Extract quantity from ingredient string (e.g., "12 oz mung bean sprouts" -> 340.2g, "300g chicken pieces" -> 300g, "½ cup string beans" -> 120g)
  double _extractQuantityFromString(String ingredientStr) {
    // Handle fractions first (½, 1/2, 1/3, etc.)
    double fractionValue = 0.0;
    if (ingredientStr.contains('½') || ingredientStr.contains('1/2')) {
      fractionValue = 0.5;
    } else if (ingredientStr.contains('⅓') || ingredientStr.contains('1/3')) {
      fractionValue = 0.333;
    } else if (ingredientStr.contains('⅔') || ingredientStr.contains('2/3')) {
      fractionValue = 0.667;
    } else if (ingredientStr.contains('¼') || ingredientStr.contains('1/4')) {
      fractionValue = 0.25;
    } else if (ingredientStr.contains('¾') || ingredientStr.contains('3/4')) {
      fractionValue = 0.75;
    }
    
    // Handle grams (g) - most common format
    final gramMatch = RegExp(r'(\d+(?:\.\d+)?)\s*g').firstMatch(ingredientStr);
    if (gramMatch != null) {
      final grams = double.tryParse(gramMatch.group(1) ?? '1');
      return grams ?? 0;
    }
    
    // Handle kilograms (kg)
    final kgMatch = RegExp(r'(\d+(?:\.\d+)?)\s*kg').firstMatch(ingredientStr);
    if (kgMatch != null) {
      final kg = double.tryParse(kgMatch.group(1) ?? '1');
      return (kg ?? 1) * 1000; // Convert to grams
    }
    
    // Handle ounces (oz)
    final ozMatch = RegExp(r'(\d+(?:\.\d+)?)\s*oz').firstMatch(ingredientStr);
    if (ozMatch != null) {
      final oz = double.tryParse(ozMatch.group(1) ?? '1');
      return (oz ?? 1) * 28.35; // Convert to grams
    }
    
    // Handle pounds (lb)
    final lbMatch = RegExp(r'(\d+(?:\.\d+)?)\s*lb').firstMatch(ingredientStr);
    if (lbMatch != null) {
      final lb = double.tryParse(lbMatch.group(1) ?? '1');
      return (lb ?? 1) * 453.59; // Convert to grams
    }
    
    // Handle cups (including fractions)
    final cupMatch = RegExp(r'(\d+(?:\.\d+)?)\s*cup').firstMatch(ingredientStr);
    if (cupMatch != null) {
      final cups = double.tryParse(cupMatch.group(1) ?? '1');
      return (cups ?? 1) * 240; // Convert to grams (1 cup ≈ 240g for most ingredients)
    } else if (ingredientStr.contains('cup') && fractionValue > 0) {
      // Handle fraction cups like "½ cup"
      return fractionValue * 240;
    }
    
    // Handle tablespoons (including fractions)
    final tbspMatch = RegExp(r'(\d+(?:\.\d+)?)\s*tbsp').firstMatch(ingredientStr);
    if (tbspMatch != null) {
      final tbsp = double.tryParse(tbspMatch.group(1) ?? '1');
      return (tbsp ?? 1) * 15; // Convert to grams (1 tbsp ≈ 15g)
    } else if (ingredientStr.contains('tbsp') && fractionValue > 0) {
      // Handle fraction tablespoons like "½ tbsp"
      return fractionValue * 15;
    }
    
    // Handle teaspoons (including fractions)
    final tspMatch = RegExp(r'(\d+(?:\.\d+)?)\s*tsp').firstMatch(ingredientStr);
    if (tspMatch != null) {
      final tsp = double.tryParse(tspMatch.group(1) ?? '1');
      return (tsp ?? 1) * 5; // Convert to grams (1 tsp ≈ 5g)
    } else if (ingredientStr.contains('tsp') && fractionValue > 0) {
      // Handle fraction teaspoons like "½ tsp"
      return fractionValue * 5;
    }
    
    // Handle pieces/units (e.g., "2 pieces", "3 pcs")
    final pieceMatch = RegExp(r'(\d+)\s*(?:piece|pieces|pc|pcs)').firstMatch(ingredientStr);
    if (pieceMatch != null) {
      final pieces = int.tryParse(pieceMatch.group(1) ?? '1');
      if (pieces != null) {
        // Estimate weight based on ingredient type
        if (ingredientStr.contains('chicken') || ingredientStr.contains('pork') || ingredientStr.contains('beef')) {
          return pieces * 100; // ~100g per piece of meat
        } else if (ingredientStr.contains('tomato') || ingredientStr.contains('onion')) {
          return pieces * 60; // ~60g per medium vegetable
        } else if (ingredientStr.contains('egg')) {
          return pieces * 50; // ~50g per egg
        } else {
          return pieces * 50; // Default estimate
        }
      }
    }
    
    // Handle single items without specific quantities
    if (ingredientStr.contains('1 ') && !ingredientStr.contains('cup') && !ingredientStr.contains('tbsp') && !ingredientStr.contains('tsp')) {
      // Single items like "1 eggplant", "1 onion", "1 banana"
      if (ingredientStr.contains('eggplant')) return 120; // 1 medium eggplant
      if (ingredientStr.contains('banana') || ingredientStr.contains('saba')) return 120; // 1 medium banana
      if (ingredientStr.contains('onion')) return 80; // 1 medium onion
      if (ingredientStr.contains('garlic') && ingredientStr.contains('cloves')) return 15; // 4 cloves ≈ 15g
      return 60; // Default for single items
    }
    
    return 0; // No quantity found
  }

  /// Estimate ingredient quantities based on common Filipino recipe amounts
  double _estimateIngredientQuantity(String ingredient) {
    final ingredientLower = ingredient.toLowerCase();
    
    // Mung bean sprouts and togue - common in Filipino dishes
    if (ingredientLower.contains('mung bean') || ingredientLower.contains('togue') || ingredientLower.contains('bean sprout')) {
      return 100; // 1 cup of mung bean sprouts is about 100g
    }
    
    // Meat and protein - more realistic portions
    if (ingredientLower.contains('pork') || ingredientLower.contains('beef') || ingredientLower.contains('chicken')) {
      if (ingredientLower.contains('ribs') || ingredientLower.contains('chunk') || ingredientLower.contains('cut')) return 120;
      if (ingredientLower.contains('thigh') || ingredientLower.contains('breast') || ingredientLower.contains('fillet')) return 100;
      if (ingredientLower.contains('ground') || ingredientLower.contains('minced')) return 80;
      return 80; // Default meat portion
    }
    
    // Vegetables - more realistic portions
    if (ingredientLower.contains('tomato')) return 60; // 1 medium tomato
    if (ingredientLower.contains('onion')) return 50; // 1 medium onion
    if (ingredientLower.contains('carrot')) return 40; // 1 medium carrot
    if (ingredientLower.contains('garlic')) return 15; // 3-4 cloves
    if (ingredientLower.contains('ginger')) return 10; // 1 thumb-sized piece
    
    // Condiments and seasonings - smaller amounts
    if (ingredientLower.contains('fish sauce') || ingredientLower.contains('patis')) return 15;
    if (ingredientLower.contains('soy sauce') || ingredientLower.contains('toyo')) return 10;
    if (ingredientLower.contains('vinegar') || ingredientLower.contains('suka')) return 10;
    if (ingredientLower.contains('oil') || ingredientLower.contains('mantika')) return 10;
    
    // Default quantity - more conservative
    return 30;
  }

  /// Check if recipe needs nutrition update and update automatically
  Future<void> _checkAndUpdateNutrition() async {
    // Check if recipe is missing nutrition data
    if (widget.recipe.macros != null && 
        widget.recipe.macros.isNotEmpty && 
        widget.recipe.calories != null && 
        widget.recipe.calories! > 0) {
      // Recipe already has nutrition data
      return;
    }

    setState(() {
      isUpdatingNutrition = true;
    });

    try {
      print('🍽️ Updating nutrition for: ${widget.recipe.title}');
      
      // Calculate nutrition using FNRI data
      final nutrition = await FNRINutritionService.calculateRecipeNutrition(
        widget.recipe.ingredients,
        _estimateIngredientQuantities(widget.recipe.ingredients)
      );

      // Update the recipe in Supabase
      final client = Supabase.instance.client;
      await client
          .from('recipes')
          .update({
            'macros': nutrition['summary'],
            'calories': nutrition['summary']['calories'],
          })
          .eq('id', widget.recipe.id);

      // Store updated nutrition data locally
      updatedNutrition = nutrition['summary'];

      // Note: Recipe object fields are final, so we can't update them directly
      // The updatedNutrition state variable will handle displaying the new data

      setState(() {
        updatedNutrition = nutrition['summary'];
        isUpdatingNutrition = false;
      });

      print('✅ Nutrition updated successfully for ${widget.recipe.title}');
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Nutrition data updated automatically!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating nutrition: $e');
      setState(() {
        isUpdatingNutrition = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update nutrition: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Manually update nutrition data for the recipe
  Future<void> _updateNutrition() async {
    setState(() {
      isUpdatingNutrition = true;
    });

    try {
      print('🍽️ Manually updating nutrition for: ${widget.recipe.title}');
      
      // Calculate nutrition using FNRI data
      final nutrition = await FNRINutritionService.calculateRecipeNutrition(
        widget.recipe.ingredients,
        _estimateIngredientQuantities(widget.recipe.ingredients)
      );

      // Update the recipe in Supabase
      final client = Supabase.instance.client;
      await client
          .from('recipes')
          .update({
            'macros': nutrition['summary'],
            'calories': nutrition['summary']['calories'],
          })
          .eq('id', widget.recipe.id);

      // Store updated nutrition data locally
      updatedNutrition = nutrition['summary'];

      setState(() {
        updatedNutrition = nutrition['summary'];
        isUpdatingNutrition = false;
      });

      print('✅ Nutrition updated successfully for ${widget.recipe.title}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Nutrition data updated manually!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating nutrition: $e');
      setState(() {
        isUpdatingNutrition = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to update nutrition: $e'),
            backgroundColor: const Color(0xFFFF6961),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Manually delete nutrition data for the recipe

  bool _isCurrentUserFeedback(Map<String, dynamic> feedback) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return false;
    return feedback['user_id'] == currentUser.id;
  }

  /// Get time ago string (e.g., "2 days ago", "1 week ago")
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays > 0) {
      final days = difference.inDays;
      return days == 1 ? '1 day ago' : '$days days ago';
    } else if (difference.inHours > 0) {
      final hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    } else if (difference.inMinutes > 0) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
        } else {
      return 'Just now';
    }
  }


  Future<void> _showReAddConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-add Meal Plan'),
        content: Text('Would you like to add "${widget.recipe.title}" back to your meal plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _showTimeSelection();
    }
  }

  Future<void> _showTimeSelection() async {
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Meal Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What time would you like to set for this meal?'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  Navigator.of(context).pop(time);
                }
              },
              child: const Text('Select Time'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _addToMealPlan(result);
    }
  }

  Future<void> _addToMealPlan(TimeOfDay time) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Determine meal type based on time
      String mealType;
      if (time.hour >= 5 && time.hour < 11) {
        mealType = 'breakfast';
      } else if (time.hour >= 11 && time.hour < 16) {
        mealType = 'lunch';
      } else if (time.hour >= 16 && time.hour < 22) {
        mealType = 'dinner';
      } else {
        mealType = 'snack';
      }

      // Save to meal_plans table as one row per meal (with required date and time)
      try {
        await Supabase.instance.client
            .from('meal_plans')
            .insert({
              'user_id': user.id,
              'recipe_id': widget.recipe.id,
              'title': widget.recipe.title,
              'meal_type': mealType,
              'meal_time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00',
              'date': DateTime.now().toUtc().toIso8601String().split('T').first,
            });
      } catch (e) {
        print('Failed to save to meal_plans: $e');
        // Continue without saving
      }

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.recipe.title} was added back to your meal plan!'),
            duration: const Duration(milliseconds: 1500),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add meal: $e'),
            backgroundColor: const Color(0xFFFF6961),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> feedback) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6961),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteFeedback(feedback);
    }
  }

  Future<void> _deleteFeedback(Map<String, dynamic> feedback) async {
    try {
      await FeedbackService.deleteFeedback(feedback['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted successfully')),
      );

      // Remove the feedback from the local list
      if (mounted) {
        setState(() {
          feedbacks.removeWhere((f) => f['id'] == feedback['id']);
          _calculateAverageRating();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete review: ${e.toString()}')),
      );
    }
  }

  Future<void> _showAddFeedbackDialog() async {
    // Check if user is authenticated first
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to leave feedback')),
      );
      return;
    }

    print('User authenticated: ${user.id}');
    print('Recipe ID: ${widget.recipe.id}');

    double rating = 0;
    final commentController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate this Recipe'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How would you rate this recipe?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                    child: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your experience with this recipe...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (rating > 0) {
                Navigator.of(context).pop({
                  'rating': rating,
                  'comment': commentController.text.trim(),
                });
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _submitFeedback(result['rating'], result['comment']);
    }
  }

  Future<void> _submitFeedback(double rating, String comment) async {
    try {
      print('Submitting feedback for recipe: ${widget.recipe.id}');
      print('Rating: $rating, Comment: $comment');
      
      final newFeedback = await FeedbackService.addFeedback(
        recipeId: widget.recipe.id,
        rating: rating,
        comment: comment,
      );

      print('Feedback submitted successfully, navigating to thank you page...');
      
      // Navigate to thank you page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FeedbackThankYouPage(
              recipeTitle: widget.recipe.title,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final alreadyAdded = widget.addedRecipeIds.contains(widget.recipe.id);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Stack(
          children: [
            // Main card (scrollable, image at top, no padding)
            Positioned.fill(
              top: 0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    // Full-width square image at the top
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        // Back button on top of image
                        Positioned(
                          top: 24,
                          left: 16,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.3),
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Card content below image
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 24),
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    recipe.title,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                                                 Text(
                                   '🍽️ ${updatedNutrition?['calories'] ?? recipe.calories ?? 'Calculating...'} kcal', 
                                   style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange)
                                 ),
                              ],
                            ),
                            if (recipe.cost > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                                child: Text('Cost: ₱${recipe.cost.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                              ),
                            Text(
                              recipe.shortDescription,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 16),
                            if (recipe.dietTypes.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Icon(Icons.eco, color: Colors.green, size: 18),
                                  ...recipe.dietTypes.map((type) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      type,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  )),
                                ],
                              ),
                            const SizedBox(height: 16),
                            // Nutrition Section with Auto-Update
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Macronutrients Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    if (isUpdatingNutrition)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                  ],
                                ),
                                  const SizedBox(height: 6),
                                
                                // Test buttons for nutrition data management
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: isUpdatingNutrition ? null : _updateNutrition,
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Update Nutrition'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Show loading state while updating
                                if (isUpdatingNutrition)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    child: const Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text('Updating nutrition data...', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                // Show nutrition data (either original or updated)
                                else if ((recipe.macros.isNotEmpty && recipe.calories != null && recipe.calories! > 0) || updatedNutrition != null)
                                  Column(
                                    children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                          _MacroChip(
                                            label: 'Carbs', 
                                            value: (updatedNutrition?['carbs'] ?? recipe.macros['carbs'] ?? 0).toString(),
                                            unit: 'g'
                                          ),
                                      const SizedBox(width: 8),
                                          _MacroChip(
                                            label: 'Fat', 
                                            value: (updatedNutrition?['fat'] ?? recipe.macros['fat'] ?? 0).toString(),
                                            unit: 'g'
                                          ),
                                      const SizedBox(width: 8),
                                          _MacroChip(
                                            label: 'Fiber', 
                                            value: (updatedNutrition?['fiber'] ?? recipe.macros['fiber'] ?? 0).toString(),
                                            unit: 'g'
                                          ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                          _MacroChip(
                                            label: 'Protein', 
                                            value: (updatedNutrition?['protein'] ?? recipe.macros['protein'] ?? 0).toString(),
                                            unit: 'g'
                                          ),
                                      const SizedBox(width: 8),
                                          _MacroChip(
                                            label: 'Sugar', 
                                            value: (updatedNutrition?['sugar'] ?? recipe.macros['sugar'] ?? 0).toString(),
                                            unit: 'g'
                                          ),
                                        ],
                                      ),
                                      // Show additional nutrients if available
                                      if (updatedNutrition != null && (updatedNutrition!['sodium'] != null || updatedNutrition!['cholesterol'] != null))
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              if (updatedNutrition!['sodium'] != null)
                                                _MacroChip(
                                                  label: 'Sodium', 
                                                  value: updatedNutrition!['sodium'].toStringAsFixed(1),
                                                  unit: 'mg'
                                                ),
                                              if (updatedNutrition!['sodium'] != null && updatedNutrition!['cholesterol'] != null)
                                                const SizedBox(width: 8),
                                              if (updatedNutrition!['cholesterol'] != null)
                                                _MacroChip(
                                                  label: 'Cholesterol', 
                                                  value: updatedNutrition!['cholesterol'].toStringAsFixed(1),
                                                  unit: 'mg'
                                                ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  )
                                // Show message when no nutrition data available
                                else
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange[200]!),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.orange, size: 24),
                                        SizedBox(height: 8),
                                        Text(
                                          'Nutrition data not available',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Nutrition data will be calculated automatically',
                                          style: TextStyle(fontSize: 12, color: Colors.orange),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            if (recipe.allergyWarning.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6961), size: 18),
                                  ...recipe.allergyWarning.split(', ').map((allergy) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6961).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      allergy.trim(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6961)),
                                    ),
                                  )),
                                ],
                              ),
                            const SizedBox(height: 16),
                            const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ...recipe.ingredients.map((ing) => Text('• $ing')),
                            const SizedBox(height: 16),
                            const Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ...recipe.instructions.asMap().entries.map((entry) => Text('${entry.key + 1}. ${entry.value}')),
                            const SizedBox(height: 16),
                            
                                                        // Feedback Section Header
            
                            const SizedBox(height: 20),
                            
                            // Reviews Section Header
                            if (isLoadingFeedbacks)
                              const Center(child: CircularProgressIndicator())
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Reviews Header with Overall Rating
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Reviews',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      if (totalFeedbacks > 0)
                                        Row(
                                  children: [
                                            Icon(Icons.star, color: Colors.amber, size: 20),
                                            const SizedBox(width: 4),
                                    Text(
                                              '${averageRating.toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            Text(
                                              ' ($totalFeedbacks reviews)',
                                              style: const TextStyle(
                                                color: Color(0xFF757575),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                              ),
                            const SizedBox(height: 16),
                            
                                  // Individual Review Cards
                            if (feedbacks.isNotEmpty)
                                  ...feedbacks.take(5).map((feedback) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Container(
                                        padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE9ECEF),
                                            width: 1,
                                          ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            // Review Header Row
                                          Row(
                                            children: [
                                                // Reviewer Name
                                                      Text(
                                                  feedback['profiles']['username'] ?? 'Anonymous',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const Spacer(),
                                                // Star Rating
                                                    Wrap(
                                                      spacing: 2,
                                                      children: List.generate(5, (index) => Icon(
                                                    index < (feedback['rating'] ?? 0) 
                                                        ? Icons.star 
                                                        : Icons.star_border,
                                                        color: Colors.amber,
                                                    size: 18,
                                                  )),
                                                ),
                                                const SizedBox(width: 8),
                                                // Time Since Review
                                                if (feedback['created_at'] != null)
                                                  Text(
                                                    _getTimeAgo(DateTime.tryParse(feedback['created_at']) ?? DateTime.now()),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF6C757D),
                                                    ),
                                                    ),
                                                  ],
                                                ),
                                            const SizedBox(height: 8),
                                            // Review Comment
                                            Text(
                                              feedback['comment'] ?? 'No comment',
                                              style: const TextStyle(
                                                color: Color(0xFF495057),
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Action Row
                                            Row(
                                              children: [
                                              // Show "You" badge if it's the current user's feedback
                                              if (_isCurrentUserFeedback(feedback))
                                                Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF4CAF50),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Text(
                                                    'You',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                              // Three dots menu for user's own feedback
                                              if (_isCurrentUserFeedback(feedback))
                                                PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert, color: Color(0xFF6C757D)),
                                                  onSelected: (value) {
                                                    if (value == 'delete') {
                                                      _showDeleteConfirmation(feedback);
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem<String>(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete, color: const Color(0xFFFF6961)),
                                                          SizedBox(width: 8),
                                                          Text('Delete', style: TextStyle(color: const Color(0xFFFF6961))),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    ))
                                  else
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE9ECEF),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.rate_review_outlined,
                                              size: 48,
                                              color: Color(0xFF6C757D),
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'No reviews yet',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF495057),
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Be the first to share your experience!',
                                              style: TextStyle(
                                                color: Color(0xFF6C757D),
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  // end reviews column
                                ],
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Fixed bottom meal plan bar (appears after Add to Meal Plan is tapped)
            // (No need for showMealPlanBar logic anymore)
            // Fixed bottom button (always at the bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 145, 240, 145),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: 70,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.showStartCooking ? Colors.orange : (alreadyAdded ? Colors.grey : const Color(0xFF4CAF50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: widget.showStartCooking
                          ? () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Start Cooking"),
                                  content: const Text('Are you ready to start cooking this meal?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                ),
                              );
                              if (result == true) {
                                // Navigate to the steps summary page
                                final navigatorContext = context;
                                final finished = await Navigator.push(
                                  navigatorContext,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeStepsSummaryPage(
                                      instructions: recipe.instructions,
                                      recipeTitle: recipe.title,
                                      recipeId: recipe.id,
                                      imageUrl: recipe.imageUrl,
                                      calories: recipe.calories,
                                      cost: recipe.cost,
                                                                             protein: (updatedNutrition?['protein'] ?? recipe.macros['protein'] ?? 0).toDouble(),
                                       carbs: (updatedNutrition?['carbs'] ?? recipe.macros['carbs'] ?? 0).toDouble(),
                                       fat: (updatedNutrition?['fat'] ?? recipe.macros['fat'] ?? 0).toDouble(),
                                       sugar: (updatedNutrition?['sugar'] ?? recipe.macros['sugar'] ?? 0).toDouble(),
                                       fiber: (updatedNutrition?['fiber'] ?? recipe.macros['fiber'] ?? 0).toDouble(),
                                       sodium: (updatedNutrition?['sodium'] ?? recipe.macros['sodium'] ?? 0).toDouble(),
                                       cholesterol: (updatedNutrition?['cholesterol'] ?? recipe.macros['cholesterol'] ?? 0).toDouble(),
                                    ),
                                  ),
                                );
                                if (finished == true && navigatorContext.mounted) {
                                  Navigator.of(context).pop(true); // Propagate result to MealPlannerScreen
                                }
                              }
                            }
                          : widget.isFromMealHistory
                            ? () => _showReAddConfirmation()
                            : alreadyAdded
                              ? null
                              : (widget.onAddToMealPlan != null)
                                ? () {
                                    widget.onAddToMealPlan!(recipe);
                                    Navigator.pop(context);
                                  }
                              : () {
                                  Navigator.pop(context, recipe);
                                },
                        child: Text(
                          widget.showStartCooking
                            ? "Let's Cook"
                            : widget.isFromMealHistory
                              ? 'Re-add Meal Plan'
                              : (alreadyAdded ? 'Already Added' : 'Add to Meal Plan'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 