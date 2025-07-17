import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class InteractiveRecipePage extends StatefulWidget {
  final List<String> instructions;
  final String? recipeId;
  final String? title;
  final String? imageUrl;
  final int? calories;
  final num? cost;
  const InteractiveRecipePage({Key? key, required this.instructions, this.recipeId, this.title, this.imageUrl, this.calories, this.cost}) : super(key: key);

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
        _timerRunning = true;
        _timerCompleted = false;
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
          // Automatically proceed to next step if not last
          if (_currentStep < widget.instructions.length - 1) {
            setState(() {
              _currentStep++;
            });
            _handleTimerOnStepChange();
          } else {
            _handleMealCompletion();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Congratulations!'),
                content: const Text('You have completed all the steps. Enjoy your meal!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Pop with result to trigger refresh
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Finish'),
                  ),
                ],
              ),
            );
          }
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
      _handleMealCompletion();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You have completed all the steps. Enjoy your meal!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Pop with result to trigger refresh
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Finish'),
            ),
          ],
        ),
      );
    }
  }

  void _handleMealCompletion() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    await Supabase.instance.client.from('meal_plan_history').insert({
      'user_id': user.id,
      'recipe_id': widget.recipeId,
      'title': widget.title,
      'image_url': widget.imageUrl,
      'calories': widget.calories,
      'cost': widget.cost,
      'completed_at': DateTime.now().toIso8601String(),
    });

    // Remove only the completed meal from meal_plans
    final mealPlans = await Supabase.instance.client
      .from('meal_plans')
      .select()
      .eq('user_id', user.id);
    for (final plan in mealPlans) {
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
    }
  }

  // Helper to extract timer duration from instruction (e.g., 'Wait 5 minutes')
  int? _extractTimerSeconds(String instruction) {
    final regex = RegExp(r'(wait|rest|bake|cook|simmer|boil|steam|chill|freeze|let stand|let sit)[^\d]*(\d+)[^\d]*(minute|second)', caseSensitive: false);
    final match = regex.firstMatch(instruction);
    if (match != null) {
      final value = int.tryParse(match.group(2) ?? '');
      final unit = match.group(3)?.toLowerCase();
      if (value != null) {
        if (unit != null && unit.contains('second')) return value;
        if (unit != null && unit.contains('minute')) return value * 60;
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
      appBar: AppBar(
        title: const Text('Interactive Cooking'),
        centerTitle: true,
        backgroundColor: Colors.green[600],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
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
              child: Center(
                child: showTimer
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          _remainingSeconds > 0
                            ? '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}'
                            : '${(timerSeconds! ~/ 60).toString().padLeft(2, '0')}:${(timerSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 20),
                        if (_timerRunning)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _pauseTimer,
                            child: const Text('Pause', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        if (!_timerRunning && !_timerCompleted && _remainingSeconds > 0)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _resumeTimer,
                            child: const Text('Resume', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        if (_timerCompleted)
                          const Text('Timer complete! You can proceed to the next step.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Text(
                      instruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                    ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
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
                child: Text(isLastStep ? 'Finish' : 'Next', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 