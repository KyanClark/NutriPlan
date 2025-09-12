import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/feedback_service.dart';
import '../feedback/feedback_thank_you_page.dart';
import '../home/home_page.dart'; // Added import for HomePage

class InteractiveRecipePage extends StatefulWidget {
  final List<String> instructions;
  final String? recipeId;
  final String? title;
  final String? imageUrl;
  final int? calories;
  final num? cost;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? sugar;
  final double? fiber;
  final double? sodium;
  final double? cholesterol;
  
  const InteractiveRecipePage({
    super.key, 
    required this.instructions, 
    this.recipeId, 
    this.title, 
    this.imageUrl, 
    this.calories, 
    this.cost, 
    this.protein, 
    this.carbs, 
    this.fat, 
    this.sugar, 
    this.fiber,
    this.sodium,
    this.cholesterol,
  });

  @override
  State<InteractiveRecipePage> createState() => _InteractiveRecipePageState();
}

class _InteractiveRecipePageState extends State<InteractiveRecipePage> {
  int _currentStep = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerRunning = false;
  bool _timerCompleted = false;

  @override
  void didUpdateWidget(covariant InteractiveRecipePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleTimerOnStepChange();
  }

  @override
  void initState() {
    super.initState();
    _handleTimerOnStepChange();
  }

  void _handleTimerOnStepChange() {
    final instruction = widget.instructions[_currentStep];
    final timerSeconds = _extractTimerSeconds(instruction);
    if (timerSeconds != null) {
      _timer?.cancel();
      setState(() {
        _remainingSeconds = timerSeconds;
        _timerRunning = false; // Don't auto-start the timer
        _timerCompleted = false;
      });
      // Don't start the timer automatically - wait for user to click play
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
    });
  }

  void _resumeTimer() {
    if (_remainingSeconds > 0) {
      setState(() {
        _timerRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
          setState(() {
            _timerRunning = false;
            _timerCompleted = true;
          });
        }
      });
    }
  }

  void _nextStep() {
    setState(() {
      _timer?.cancel();
      _timerRunning = false;
      _timerCompleted = false;
      _remainingSeconds = 0;
    });
    if (_currentStep < widget.instructions.length - 1) {
      setState(() {
        _currentStep++;
      });
      _handleTimerOnStepChange();
    } else {
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
                      print('Finish button clicked - second dialog');
                      await _handleMealCompletion();
                      if (navigatorContext.mounted) {
                        Navigator.of(navigatorContext).pop(); // Close the dialog
                        // Show feedback dialog instead of finishing
                        _showFeedbackDialog();
                      }
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
  }

  Future<void> _handleMealCompletion() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    // Determine meal category based on current time
    final now = DateTime.now();
    final hour = now.hour;
    String mealCategory;
    
    if (hour >= 5 && hour < 11) {
      mealCategory = 'breakfast';
    } else if (hour >= 11 && hour < 16) {
      mealCategory = 'lunch';
    } else if (hour >= 16 && hour < 22) {
      mealCategory = 'dinner';
    } else {
      mealCategory = 'snack';
    }
    
    // Insert into meal history with available nutrition data
    await Supabase.instance.client.from('meal_plan_history').insert({
      'user_id': user.id,
      'recipe_id': widget.recipeId,
      'title': widget.title,
      'image_url': widget.imageUrl,
      'calories': widget.calories,
      'cost': widget.cost,
      'protein': widget.protein,
      'carbs': widget.carbs,
      'fat': widget.fat,
      'sugar': widget.sugar,
      'fiber': widget.fiber,
      'sodium': widget.sodium ?? 0.0,
      'cholesterol': widget.cholesterol ?? 0.0,
      'meal_category': mealCategory,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    });
    
    // Remove the completed meal from meal_plans (handle both old and new formats)
    final mealPlans = await Supabase.instance.client
      .from('meal_plans')
      .select()
      .eq('user_id', user.id);
      
    for (final plan in mealPlans) {
      if (plan['meals'] != null && plan['meals'] is List) {
        // Legacy format: meals stored as array within a single record
        final meals = List<Map<String, dynamic>>.from(plan['meals'] ?? []);
        final planId = plan['id'];
        final updatedMeals = meals.where((m) => m['recipe_id'] != widget.recipeId).toList();
        if (updatedMeals.length != meals.length) {
          if (updatedMeals.isEmpty) {
            // Delete the whole meal plan row if no meals left
            await Supabase.instance.client.from('meal_plans').delete().eq('id', planId);
          } else {
            // Update the meal plan row with the new meals array
            await Supabase.instance.client.from('meal_plans').update({'meals': updatedMeals}).eq('id', planId);
          }
        }
      } else if (plan['recipe_id'] == widget.recipeId) {
        // New format: delete individual meal record
        await Supabase.instance.client.from('meal_plans').delete().eq('id', plan['id']);
      }
    }
    // Do NOT pop here; let the dialog's Finish button handle it
  }

  Future<void> _showFeedbackDialog() async {
    print('_showFeedbackDialog called');
    // Check if user is authenticated first
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('User not authenticated, popping');
      Navigator.of(context).pop(true); // Pop InteractiveRecipePage with result true
      return;
    }
    print('User authenticated: ${user.id}');

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
            onPressed: () async {
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
          recipeId: widget.recipeId ?? '',
          rating: result['rating'],
          comment: result['comment'],
        );

        // Navigate to thank you page
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => FeedbackThankYouPage(
                recipeTitle: widget.title ?? 'Recipe',
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

  // Helper to extract timer duration from instruction (e.g., 'Wait 5 minutes', '10-12 min', 'Rest 3 min', '5 mins', etc.)
  int? _extractTimerSeconds(String instruction) {
    final regex = RegExp(
      r'(?:(wait|rest|bake|cook|simmer|boil|steam|chill|freeze|let stand|let sit)[^\d]*)?(\d+)(?:\s*-\s*\d+)?\s*(minute|minutes|min|mins|second|seconds|sec|secs)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(instruction);
    if (match != null) {
      final value = int.tryParse(match.group(2) ?? '');
      final unit = match.group(3)?.toLowerCase();
      if (value != null) {
        if (unit != null && (unit.contains('second') || unit.contains('sec'))) {
          return value;
        }
        if (unit != null && (unit.contains('minute') || unit.contains('min'))) {
          return value * 60;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == widget.instructions.length - 1;
    final instruction = widget.instructions[_currentStep];
    final timerSeconds = _extractTimerSeconds(instruction);
    final showTimer = timerSeconds != null;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated progress bar at the top
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: (_currentStep + 1) / widget.instructions.length,
              ),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Step ${_currentStep + 1}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 60),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: showTimer
                  ? Center(
                      key: ValueKey(_currentStep),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Timer at the top
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _timerRunning ? Colors.orange : Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _timerRunning ? _pauseTimer : _resumeTimer,
                                child: Icon(
                                  _timerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 16),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 1, end: _remainingSeconds.toDouble()),
                                duration: const Duration(milliseconds: 500),
                                builder: (context, value, child) {
                                  final pulse = (_timerRunning && _remainingSeconds > 0)
                                      ? (1 + 0.1 * (1 - (_remainingSeconds % 2)))
                                      : 1.0;
                                  return AnimatedScale(
                                    scale: pulse,
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      _remainingSeconds > 0
                                          ? '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}'
                                          : '${(timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(timerSeconds % 60).toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: _timerRunning && _remainingSeconds <= 5 && _remainingSeconds > 0
                                            ? const Color(0xFFFF6961)
                                            : Colors.green,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          // Description below the timer
                          Text(
                            instruction,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 10),
                          // Completion message at the bottom
                          if (_timerCompleted)
                            const Text('Timer complete! You can proceed to the next step.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : Center(
                      key: ValueKey(_currentStep),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            instruction,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous Step button
                TextButton(
                  onPressed: _currentStep > 0 ? () {
                    setState(() {
                      _currentStep--;
                    });
                    _handleTimerOnStepChange();
                  } : null,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[600],
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  child: const Text('Previous'),
                ),
                // Skip All button in the middle (not shown on last step)
                if (_currentStep < widget.instructions.length - 1)
                  TextButton(
                    onPressed: () {
                      // Skip to the last step (completion)
                      setState(() {
                        _currentStep = widget.instructions.length - 1;
                      });
                      _handleTimerOnStepChange();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange[600],
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Skip All'),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 120),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _nextStep,
                        child: Text(isLastStep ? 'Done' : 'Next Step', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 