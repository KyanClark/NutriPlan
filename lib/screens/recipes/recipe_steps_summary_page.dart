import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'interactive_recipe_page.dart';
import '../../services/feedback_service.dart';
import '../feedback/feedback_thank_you_page.dart';
import '../home/home_page.dart';

class RecipeStepsSummaryPage extends StatefulWidget {
  final List<String> instructions;
  final String recipeTitle;
  final String recipeId;
  final String imageUrl;
  final int calories;
  final num cost;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;
  final double sodium;
  final double cholesterol;

  const RecipeStepsSummaryPage({
    super.key,
    required this.instructions,
    required this.recipeTitle,
    required this.recipeId,
    required this.imageUrl,
    required this.calories,
    required this.cost,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.fiber,
    required this.sodium,
    required this.cholesterol,
  });

  @override
  State<RecipeStepsSummaryPage> createState() => _RecipeStepsSummaryPageState();
}

class _RecipeStepsSummaryPageState extends State<RecipeStepsSummaryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Steps'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(widget.imageUrl, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.recipeTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: widget.instructions.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 16),
              itemBuilder: (context, idx) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.orange,
                    child: Text('${idx + 1}', style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.instructions[idx],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Skip button
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final navigatorContext = context;
                        Navigator.of(navigatorContext).push(
                          MaterialPageRoute(
                            builder: (context) => InteractiveRecipePage(
                              instructions: widget.instructions,
                              recipeId: widget.recipeId,
                              title: widget.recipeTitle,
                              imageUrl: widget.imageUrl,
                              calories: widget.calories,
                              cost: widget.cost,
                              protein: widget.protein,
                              carbs: widget.carbs,
                              fat: widget.fat,
                              sugar: widget.sugar,
                              fiber: widget.fiber,
                              sodium: widget.sodium,
                              cholesterol: widget.cholesterol,
                              initialStep: widget.instructions.length - 1,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Start Cooking button
                Expanded(
                  flex: 2,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Cooking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final navigatorContext = context;
                  final result = await Navigator.push(
                    navigatorContext,
                    MaterialPageRoute(
                      builder: (context) => InteractiveRecipePage(
                              instructions: widget.instructions,
                              recipeId: widget.recipeId,
                              title: widget.recipeTitle,
                              imageUrl: widget.imageUrl,
                              calories: widget.calories,
                              cost: widget.cost,
                              protein: widget.protein,
                              carbs: widget.carbs,
                              fat: widget.fat,
                              sugar: widget.sugar,
                              fiber: widget.fiber,
                              sodium: widget.sodium,
                              cholesterol: widget.cholesterol,
                      ),
                    ),
                  );
                  if (result == true && navigatorContext.mounted) {
                    Navigator.of(navigatorContext).pop(true);
                  }
                },
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

  void _showCongratulationsDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Completed',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              title: const Text('Congratulations!'),
              content: const Text('You have completed all the steps. Enjoy your meal!'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final navigatorContext = context;
                      Navigator.of(navigatorContext).pop(); // Close congratulations dialog
                      // Show feedback dialog instead of going back
                      await _showFeedbackDialog();
                    },
                    child: const Text('Finish'),
                  ),
                ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFeedbackDialog() async {
    // Check if user is authenticated first
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.of(context).pop(true); // Pop back to previous screen
      return;
    }

    double rating = 0;
    final commentController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Experience'),
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
            onPressed: () {
              Navigator.of(context).pop(); // Close feedback dialog
              // Navigate back to home page
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text('Skip'),
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
      try {
        await FeedbackService.addFeedback(
          recipeId: widget.recipeId,
          rating: result['rating'],
          comment: result['comment'],
        );

        // Navigate to thank you page
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => FeedbackThankYouPage(
                recipeTitle: widget.recipeTitle,
              ),
            ),
          );
        }
      } catch (e) {
        // If feedback submission fails, just go back to home
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
            (route) => false,
          );
        }
      }
    } else {
      // User skipped feedback, go back to home
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
          (route) => false,
        );
      }
    }
  }
} 