import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;
// import 'package:flutter_tts/flutter_tts.dart';  // Commented out for Windows build
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/feedback_service.dart';
import '../../services/rice_nutrition_service.dart';
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
  bool _isCompletingMeal = false; // Track if meal completion is in progress

  // Text-to-speech for reading steps aloud
  // Only initialize on non-Windows platforms (mobile devices)
  // final FlutterTts? _tts = Platform.isWindows ? null : FlutterTts();  // Commented out for Windows build
  final dynamic _tts = null;  // TTS disabled
  bool _ttsInitialized = false;

  @override
  void didUpdateWidget(covariant InteractiveRecipePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleTimerOnStepChange();
  }

  @override
  void initState() {
    super.initState();
    // Only initialize TTS on non-Windows platforms (mobile devices)
    if (!Platform.isWindows) {
      _initTts();
    }
    _handleTimerOnStepChange();
  }
  
  Future<void> _initTts() async {
    final tts = _tts;
    if (tts == null) return; // Skip if TTS is not available (Windows)
    try {
      // Configure TTS (offline, using device engine)
      await tts.setLanguage('en-US');
      await tts.setSpeechRate(0.30); // Slightly slower for clarity
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);

      // Ensure speak() awaits completion
      await tts.awaitSpeakCompletion(true);

      if (!mounted) return;
      setState(() {
        _ttsInitialized = true;
      });

      // Read the first step as soon as we start
      await _speakCurrentStepTwice();
    } catch (_) {
      // If TTS fails, just continue silently
      _ttsInitialized = false;
    }
  }

  Future<void> _speakCurrentStepTwice() async {
    final tts = _tts;
    if (tts == null || !_ttsInitialized || !mounted) return;
    if (widget.instructions.isEmpty) return;
    if (_currentStep < 0 || _currentStep >= widget.instructions.length) return;

    final text = widget.instructions[_currentStep];
    if (text.trim().isEmpty) return;

    // Build spoken text with step number and "again" on repeat
    final stepNumber = _currentStep + 1;
    final firstSpokenText = 'Step $stepNumber. $text';
    final secondSpokenText = 'Again. Step $stepNumber. $text';
    final bool isLastStep = _currentStep == widget.instructions.length - 1;
    final int repeatCount = isLastStep ? 1 : 2;

    try {
      await tts.stop();
      // Speak the step twice (repeat 1 time)
      for (int i = 0; i < repeatCount; i++) {
        if (!mounted) break;
        if (i == 0) {
          await tts.speak(firstSpokenText);
        } else {
          await tts.speak(secondSpokenText);
        }
        // Small pause between repeats
        if (i == 0) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    } catch (_) {
      // Ignore TTS errors so they don't break the flow
    }
  }

  // Speak countdown numbers during the last 10 seconds of a timed step
  void _speakCountdownNumber(int seconds) {
    final tts = _tts;
    if (tts == null || !_ttsInitialized || !mounted) return;
    if (seconds <= 0 || seconds > 10) return;
    try {
      tts.stop();
      tts.speak('$seconds');
    } catch (_) {
      // Ignore TTS errors during countdown
    }
  }

  void _handleTimerOnStepChange() {
    final instruction = widget.instructions[_currentStep];
    final timerSeconds = _extractTimerSeconds(instruction);
    if (timerSeconds != null) {
      _timer?.cancel();
      setState(() {
        _remainingSeconds = timerSeconds;
        _timerRunning = true;
        _timerCompleted = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
          // When timer reaches the last 10 seconds, speak the countdown
          if (_remainingSeconds <= 10 && _remainingSeconds > 0) {
            _speakCountdownNumber(_remainingSeconds);
          }
        } else {
          timer.cancel();
          setState(() {
            _timerRunning = false;
            _timerCompleted = true;
          });
          // Automatically proceed to next step if not last
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            if (_currentStep < widget.instructions.length - 1) {
              setState(() {
                _currentStep++;
              });
              _handleTimerOnStepChange();
              _speakCurrentStepTwice();
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
                            onPressed: _isCompletingMeal ? null : () async {
                              if (_isCompletingMeal) return; // Prevent multiple clicks
                              
                              setState(() {
                                _isCompletingMeal = true;
                              });
                              
                              final navigatorContext = context;
                              print('Finish button clicked - first dialog');
                              
                              // Show loading dialog
                              showDialog(
                                context: navigatorContext,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              
                              await _handleMealCompletion();
                              
                              if (navigatorContext.mounted) {
                                Navigator.of(navigatorContext).pop(); // Close loading dialog
                                Navigator.of(navigatorContext).pop(); // Close congratulations dialog
                                // Show feedback dialog instead of finishing
                                _showFeedbackDialog();
                              }
                            },
                            child: Text(_isCompletingMeal ? 'Processing...' : 'Finish'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          });
        }
      });
    } else {
      _timer?.cancel();
      setState(() {
        _timerRunning = false;
        _timerCompleted = false;
        _remainingSeconds = 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts?.stop();
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
      _speakCurrentStepTwice();
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
                    onPressed: _isCompletingMeal ? null : () async {
                      if (_isCompletingMeal) return; // Prevent multiple clicks
                      
                      setState(() {
                        _isCompletingMeal = true;
                      });
                      
                      final navigatorContext = context;
                      print('Finish button clicked - second dialog');
                      
                      // Show loading dialog
                      showDialog(
                        context: navigatorContext,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                      
                      await _handleMealCompletion();
                      
                      if (navigatorContext.mounted) {
                        Navigator.of(navigatorContext).pop(); // Close loading dialog
                        Navigator.of(navigatorContext).pop(); // Close congratulations dialog
                        // Show feedback dialog instead of finishing
                        _showFeedbackDialog();
                      }
                    },
                    child: Text(_isCompletingMeal ? 'Processing...' : 'Finish'),
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
    
    // Ensure profile exists before inserting into meal_plan_history
    // (required by foreign key constraint)
    try {
      final profileExists = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (profileExists == null) {
        // Create profile if it doesn't exist
        await Supabase.instance.client
            .from('profiles')
            .insert({
              'id': user.id,
              'username': user.email?.split('@').first ?? 'User',
            });
      }
    } catch (e) {
      print('Error ensuring profile exists: $e');
      // Continue anyway - might already exist or constraint might be different
    }
    
    // Determine meal category based on current time
    final now = DateTime.now();
    final hour = now.hour;
    String mealCategory;
    
    if (hour >= 4 && hour < 12) {
      mealCategory = 'breakfast';    // 4 AM - 12 PM (more flexible)
    } else if (hour >= 12 && hour < 17) {
      mealCategory = 'lunch';        // 12 PM - 5 PM
    } else if (hour >= 17 && hour < 23) {
      mealCategory = 'dinner';       // 5 PM - 11 PM
    } else {
      mealCategory = 'dinner';        // 11 PM - 4 AM (use dinner for late hours)
    }
    
    // Check if this meal was planned with rice
    // Look for meal plan with this recipe_id (check all dates, not just today)
    Map<String, dynamic> riceNutrition = {};
    if (widget.recipeId != null) {
      try {
        // First, try to find the meal plan for this recipe (check all dates)
        final mealPlans = await Supabase.instance.client
            .from('meal_plans')
            .select('include_rice, rice_serving, date')
            .eq('user_id', user.id)
            .eq('recipe_id', widget.recipeId ?? '')
            .order('date', ascending: false)
            .limit(10);
        
        // Find the most recent meal plan with rice for this recipe
        Map<String, dynamic>? mealPlanWithRice;
        for (final plan in mealPlans) {
          if (plan['include_rice'] == true && plan['rice_serving'] != null) {
            mealPlanWithRice = plan;
            break;
          }
        }
        
        if (mealPlanWithRice != null && mealPlanWithRice['rice_serving'] != null) {
          // Get rice serving and calculate nutrition
          final riceServingLabel = mealPlanWithRice['rice_serving'] as String;
          final availableServings = RiceNutritionService.getAvailableServings();
          final riceServing = availableServings.firstWhere(
            (s) => s.label == riceServingLabel,
            orElse: () => RiceNutritionService.getDefaultServing(),
          );
          
          final riceNutritionData = RiceNutritionService.calculateNutrition(riceServing);
          
          // Add rice nutrition to meal nutrition
          riceNutrition = {
            'rice_serving': riceServingLabel,
            'rice_calories': riceNutritionData.calories,
            'rice_protein': riceNutritionData.protein,
            'rice_carbs': riceNutritionData.carbs,
            'rice_fat': riceNutritionData.fat,
            'rice_fiber': riceNutritionData.fiber,
            'rice_sodium': riceNutritionData.sodium,
          };
          
          print('Rice nutrition added: ${riceNutrition['rice_calories']} kcal, ${riceNutrition['rice_protein']}g protein, ${riceNutrition['rice_carbs']}g carbs');
        } else {
          print('No rice found for recipe ${widget.recipeId}');
        }
      } catch (e) {
        print('Error fetching rice data: $e');
        // Continue without rice if there's an error
      }
    }
    
    // Calculate total nutrition (recipe + rice)
    final recipeCalories = widget.calories ?? 0;
    final riceCalories = (riceNutrition['rice_calories'] as num?)?.toDouble() ?? 0.0;
    final totalCalories = (recipeCalories + riceCalories).round();
    
    final recipeProtein = widget.protein ?? 0.0;
    final riceProtein = (riceNutrition['rice_protein'] as num?)?.toDouble() ?? 0.0;
    final totalProtein = recipeProtein + riceProtein;
    
    final recipeCarbs = widget.carbs ?? 0.0;
    final riceCarbs = (riceNutrition['rice_carbs'] as num?)?.toDouble() ?? 0.0;
    final totalCarbs = recipeCarbs + riceCarbs;
    
    final recipeFat = widget.fat ?? 0.0;
    final riceFat = (riceNutrition['rice_fat'] as num?)?.toDouble() ?? 0.0;
    final totalFat = recipeFat + riceFat;
    
    final recipeFiber = widget.fiber ?? 0.0;
    final riceFiber = (riceNutrition['rice_fiber'] as num?)?.toDouble() ?? 0.0;
    final totalFiber = recipeFiber + riceFiber;
    
    final recipeSodium = widget.sodium ?? 0.0;
    final riceSodium = (riceNutrition['rice_sodium'] as num?)?.toDouble() ?? 0.0;
    final totalSodium = recipeSodium + riceSodium;
    
    print('Nutrition totals - Recipe: ${recipeCalories} kcal, Rice: ${riceCalories} kcal, Total: ${totalCalories} kcal');
    print('Protein totals - Recipe: ${recipeProtein}g, Rice: ${riceProtein}g, Total: ${totalProtein}g');
    
    // Insert into meal history with available nutrition data (including rice)
    try {
      final mealHistoryData = {
        'user_id': user.id,
        'recipe_id': widget.recipeId,
        'title': widget.title,
        'image_url': widget.imageUrl,
        'calories': totalCalories, // Already rounded to int
        'cost': widget.cost,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
        'sugar': widget.sugar ?? 0.0,
        'fiber': totalFiber,
        'sodium': totalSodium,
        'cholesterol': widget.cholesterol ?? 0.0,
        'meal_category': mealCategory,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
      };
      
      // Add rice data if included
      if (riceNutrition.isNotEmpty) {
        mealHistoryData['include_rice'] = true;
        mealHistoryData['rice_serving'] = riceNutrition['rice_serving'];
        mealHistoryData['rice_calories'] = (riceNutrition['rice_calories'] as num?)?.toDouble() ?? 0.0;
        mealHistoryData['rice_protein'] = (riceNutrition['rice_protein'] as num?)?.toDouble() ?? 0.0;
        mealHistoryData['rice_carbs'] = (riceNutrition['rice_carbs'] as num?)?.toDouble() ?? 0.0;
        mealHistoryData['rice_fat'] = (riceNutrition['rice_fat'] as num?)?.toDouble() ?? 0.0;
        mealHistoryData['rice_fiber'] = (riceNutrition['rice_fiber'] as num?)?.toDouble() ?? 0.0;
        mealHistoryData['rice_sodium'] = (riceNutrition['rice_sodium'] as num?)?.toDouble() ?? 0.0;
      } else {
        mealHistoryData['include_rice'] = false;
        mealHistoryData['rice_serving'] = null;
      }
      
      await Supabase.instance.client.from('meal_plan_history').insert(mealHistoryData);
    } catch (e) {
      print('Error inserting meal history: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save meal history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
    
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
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
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
      final recipeId = widget.recipeId ?? '';
      if (recipeId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot submit feedback: missing recipe ID'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        print('Submitting feedback - recipeId: $recipeId, rating: ${result['rating']}, comment: ${result['comment']}');
        await FeedbackService.addFeedback(
          recipeId: recipeId,
          rating: result['rating'] is double ? result['rating'] : (result['rating'] as num).toDouble(),
          comment: result['comment'] ?? '',
        );
        print('Feedback submitted successfully');

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
      } catch (e, stackTrace) {
        print('Error submitting feedback: $e');
        print('Stack trace: $stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit feedback: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
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

  Widget _buildScrollableInstruction(String instruction) {
    return Container(
      // Increase height so more of the instruction text is visible
      // before scrolling, while still fitting comfortably on small screens.
      height: 180,
      child: Stack(
        children: [
          // Scrollable text
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24), // Space for fade effect
              child: Text(
                instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          // Fade indicator at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == widget.instructions.length - 1;
    final instruction = widget.instructions[_currentStep];
    final timerSeconds = _extractTimerSeconds(instruction);
    final showTimer = timerSeconds != null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  ? Column(
                      key: ValueKey(_currentStep),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildScrollableInstruction(instruction),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: _timerRunning && _remainingSeconds <= 5 && _remainingSeconds > 0
                                          ? const Color(0xFFFF6961)
                                          : Colors.green,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _timerRunning ? Colors.orange : Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 23),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _timerRunning ? _pauseTimer : _resumeTimer,
                              child: Text(_timerRunning ? 'Pause' : 'Resume', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_timerCompleted)
                          const Text('Timer complete! You can proceed to the next step.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Column(
                      key: ValueKey(_currentStep),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildScrollableInstruction(instruction),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Subtle Previous Step button
                TextButton(
                  onPressed: _currentStep > 0 ? () {
                    setState(() {
                      _currentStep--;
                    });
                    _handleTimerOnStepChange();
                  } : null,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('Previous'),
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
    )
    );
    
    
  }
} 