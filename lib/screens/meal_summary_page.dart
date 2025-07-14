import 'package:flutter/material.dart';
import '../models/recipes.dart';

class MealSummaryPage extends StatefulWidget {
  final List<Recipe> meals;
  final void Function(List<RecipeWithTime>) onBuildMealPlan;
  const MealSummaryPage({Key? key, required this.meals, required this.onBuildMealPlan}) : super(key: key);

  @override
  State<MealSummaryPage> createState() => _MealSummaryPageState();
}

class RecipeWithTime {
  final Recipe recipe;
  TimeOfDay? time;
  RecipeWithTime({required this.recipe, this.time});
}

class _MealSummaryPageState extends State<MealSummaryPage> {
  late List<RecipeWithTime> _mealsWithTime;

  @override
  void initState() {
    super.initState();
    _mealsWithTime = widget.meals.map((r) => RecipeWithTime(recipe: r)).toList();
  }

  void _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _mealsWithTime[index].time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _mealsWithTime[index].time = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Meal Summary',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(width: 48), // To balance the back button
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _mealsWithTime.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final meal = _mealsWithTime[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              meal.recipe.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                            ),
                          ),
                          title: Text(meal.recipe.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: meal.time != null
                              ? Text('Time: ${meal.time!.format(context)}')
                              : const Text('No time set'),
                          trailing: ElevatedButton(
                            onPressed: () => _pickTime(index),
                            child: const Text('Set Time'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 220,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: () {
            widget.onBuildMealPlan(_mealsWithTime);
          },
          label: const Text('Build this Meal Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green[600],
        ),
      ),
    );
  }
} 