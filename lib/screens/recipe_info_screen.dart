import 'package:flutter/material.dart';
import 'package:nutriplan/screens/interactive_recipe_page.dart';
import '../models/recipes.dart';
import 'package:nutriplan/screens/recipe_steps_summary_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/feedback_service.dart';
import 'feedback_thank_you_page.dart';
import 'package:intl/intl.dart';

class RecipeInfoScreen extends StatefulWidget {
  final Recipe recipe;
  final List<String> addedRecipeIds;
  final bool showStartCooking;
  final bool isFromMealHistory;

  const RecipeInfoScreen({
    super.key, 
    required this.recipe, 
    this.addedRecipeIds = const [], 
    this.showStartCooking = false,
    this.isFromMealHistory = false,
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

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
    _checkDatabaseTable();
  }

  Future<void> _checkDatabaseTable() async {
    try {
      print('Checking if recipe_feedbacks table exists...');
      final result = await Supabase.instance.client
          .from('recipe_feedbacks')
          .select('count')
          .limit(1);
      print('Table exists and is accessible');
    } catch (e) {
      print('Error accessing recipe_feedbacks table: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database table not found: $e')),
      );
    }
  }

  Future<void> _loadFeedbacks() async {
    print('Loading feedbacks for recipe: ${widget.recipe.id}');
    setState(() {
      isLoadingFeedbacks = true;
    });

    try {
      final response = await FeedbackService.fetchRecipeFeedbacks(widget.recipe.id);
      print('Feedbacks loaded: ${response.length} items');
      print('Response data: $response');
      
      if (mounted) {
        setState(() {
          feedbacks = response;
          _calculateAverageRating();
          isLoadingFeedbacks = false;
        });
        print('State updated with ${feedbacks.length} feedbacks');
        print('Feedbacks list: $feedbacks');
      }
    } catch (e) {
      print('Error loading feedbacks: $e');
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

  bool _isCurrentUserFeedback(Map<String, dynamic> feedback) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return false;
    return feedback['user_id'] == currentUser.id;
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

      // Create meal object in the correct format
      final mealJson = {
        'recipe_id': widget.recipe.id,
        'title': widget.recipe.title,
        'image_url': widget.recipe.imageUrl,
        'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      };

      // Add to meal_plans table with correct structure
      await Supabase.instance.client
          .from('meal_plans')
          .insert({
            'user_id': user.id,
            'meals': [mealJson], // Array with single meal
            'date': DateTime.now().toIso8601String().substring(0, 10),
          });

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
            backgroundColor: Colors.red,
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
              backgroundColor: Colors.red,
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
    final alreadyAdded = widget.addedRecipeIds.contains(recipe.id);
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
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () => Navigator.pop(context),
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
                                Text('🍽️ ${recipe.calories} kcal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange)),
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
                            if (recipe.macros.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('Macronutrients Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _MacroChip(label: 'Carbs', value: recipe.macros['carbs'].toString()),
                                      const SizedBox(width: 8),
                                      _MacroChip(label: 'Fat', value: recipe.macros['fat'].toString()),
                                      const SizedBox(width: 8),
                                      _MacroChip(label: 'Fiber', value: recipe.macros['fiber'].toString()),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _MacroChip(label: 'Protein', value: recipe.macros['protein'].toString()),
                                      const SizedBox(width: 8),
                                      _MacroChip(label: 'Sugar', value: recipe.macros['sugar']?.toString() ?? '0'),
                                    ],
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
                                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                                  ...recipe.allergyWarning.split(', ').map((allergy) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      allergy.trim(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
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
                            const Text('Reviews & Ratings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _loadFeedbacks,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Average Rating Display
                            if (isLoadingFeedbacks)
                              const Center(child: CircularProgressIndicator())
                            else if (totalFeedbacks > 0)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${averageRating.toStringAsFixed(1)}/5.0',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('($totalFeedbacks reviews)', style: const TextStyle(color: Color(0xFF757575))),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No reviews yet. Be the first to share your experience!',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            
                            // Individual Feedback Cards
                            if (feedbacks.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Recent Reviews (${feedbacks.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  ...feedbacks.take(5).map((feedback) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Wrap(
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  spacing: 8,
                                                  children: [
                                                    Text(feedback['profiles']['username'] ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    if (feedback['created_at'] != null)
                                                      Text(
                                                        DateFormat('MMM d, yyyy').format(DateTime.tryParse(feedback['created_at']) ?? DateTime.now()),
                                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                      ),
                                                    Wrap(
                                                      spacing: 2,
                                                      children: List.generate(5, (index) => Icon(
                                                        index < (feedback['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      )),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Show "You" badge if it's the current user's feedback
                                              if (_isCurrentUserFeedback(feedback))
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                              // Three dots menu for user's own feedback
                                              if (_isCurrentUserFeedback(feedback))
                                                PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
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
                                                          Icon(Icons.delete, color: Colors.red),
                                                          SizedBox(width: 8),
                                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(feedback['comment'] ?? 'No comment', style: const TextStyle(color: Color(0xFF616161))),
                                        ],
                                      ),
                                    ),
                                  )),
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
                                final finished = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeStepsSummaryPage(
                                      instructions: recipe.instructions,
                                      recipeTitle: recipe.title,
                                      recipeId: recipe.id,
                                      imageUrl: recipe.imageUrl,
                                      calories: recipe.calories,
                                      cost: recipe.cost,
                                      protein: (recipe.macros['protein'] ?? 0).toDouble(),
                                      carbs: (recipe.macros['carbs'] ?? 0).toDouble(),
                                      fat: (recipe.macros['fat'] ?? 0).toDouble(),
                                      sugar: (recipe.macros['sugar'] ?? 0).toDouble(),
                                      fiber: (recipe.macros['fiber'] ?? 0).toDouble(),
                                    ),
                                  ),
                                );
                                if (finished == true) {
                                  Navigator.of(context).pop(true); // Propagate result to MealPlannerScreen
                                }
                              }
                            }
                          : widget.isFromMealHistory
                            ? () => _showReAddConfirmation()
                            : alreadyAdded
                              ? null
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

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  const _MacroChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: ${value}g', style: const TextStyle(fontSize: 13, color: Colors.green)),
    );
  }
} 