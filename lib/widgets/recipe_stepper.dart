import 'package:flutter/material.dart';
import 'dart:async';

class RecipeStepper extends StatefulWidget {
  final List<String> steps;
  const RecipeStepper({super.key, required this.steps});

  @override
  State<RecipeStepper> createState() => _RecipeStepperState();
}

class _RecipeStepperState extends State<RecipeStepper> {
  int _currentStep = 0;
  List<bool> _completed = [];
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _completed = List.filled(widget.steps.length, false);
    _parseTimerForStep();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _parseTimerForStep() {
    _timer?.cancel();
    _remainingSeconds = _extractSeconds(widget.steps[_currentStep]);
    if (_remainingSeconds > 0) {
      _startTimer();
    }
  }

  int _extractSeconds(String step) {
    final regex = RegExp(r'(\d+)\s*(minutes|min|seconds|sec)');
    final match = regex.firstMatch(step.toLowerCase());
    if (match != null) {
      int value = int.parse(match.group(1)!);
      String unit = match.group(2)!;
      if (unit.startsWith('min')) return value * 60;
      return value;
    }
    return 0;
  }

  void _startTimer() {
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds == 0) {
          timer.cancel();
        }
      }
    });
  }

  void _pauseResumeTimer() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      _parseTimerForStep();
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final hasTimer = _extractSeconds(step) > 0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _completed[_currentStep],
                  onChanged: (val) {
                    setState(() {
                      _completed[_currentStep] = val ?? false;
                    });
                  },
                ),
                Text('Step ${_currentStep + 1} of ${widget.steps.length}',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(step, style: Theme.of(context).textTheme.bodyLarge),
            if (hasTimer) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(_formatTime(_remainingSeconds),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_isPaused ? 'Resume' : 'Pause'),
                    onPressed: _pauseResumeTimer,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentStep > 0 ? () => _goToStep(_currentStep - 1) : null,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _currentStep < widget.steps.length - 1
                      ? () => _goToStep(_currentStep + 1)
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}${seconds == 0 ? ' (Done!)' : ''}';
  }
} 