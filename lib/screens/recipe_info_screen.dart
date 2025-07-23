import 'package:flutter/material.dart';
import 'package:nutriplan/screens/interactive_recipe_page.dart';
import '../models/recipes.dart';
import 'package:nutriplan/screens/recipe_steps_summary_page.dart';

class RecipeInfoScreen extends StatefulWidget {
  final Recipe recipe;
  final List<String> addedRecipeIds;
  final bool showStartCooking;

  const RecipeInfoScreen({super.key, required this.recipe, this.addedRecipeIds = const [], this.showStartCooking = false});

  @override
  State<RecipeInfoScreen> createState() => _RecipeInfoScreenState();
}

class _RecipeInfoScreenState extends State<RecipeInfoScreen> {
  bool showMealPlanBar = false;

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
                                Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                                const SizedBox(width: 4),
                                Text('${recipe.calories} cal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange)),
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
                              Row(
                                children: [
                                  const Icon(Icons.eco, color: Colors.green, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    recipe.dietTypes.join(', '),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            if (recipe.macros.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('Macros', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _MacroChip(label: 'Carbs', value: recipe.macros['carbs'].toString()),
                                      const SizedBox(width: 8),
                                      _MacroChip(label: 'Fat', value: recipe.macros['fats'].toString()),
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
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                                  const SizedBox(width: 6),
                                  Text('Allergy: ${recipe.allergyWarning}', style: const TextStyle(color: Colors.red)),
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
                                  Navigator.pop(context, true); // Propagate result to MealPlannerScreen
                                }
                              }
                            }
                          : alreadyAdded
                            ? null
                            : () {
                                Navigator.pop(context, recipe);
                              },
                        child: Text(
                          widget.showStartCooking
                            ? "Let's Cook"
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
      child: Text('$label: $value', style: const TextStyle(fontSize: 13, color: Colors.green)),
    );
  }
} 