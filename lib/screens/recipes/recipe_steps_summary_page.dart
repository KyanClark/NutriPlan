import 'package:flutter/material.dart';
import 'interactive_recipe_page.dart';

class RecipeStepsSummaryPage extends StatelessWidget {
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
          if (imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              recipeTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              itemCount: instructions.length,
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
                      instructions[idx],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
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
                        instructions: instructions,
                        recipeId: recipeId,
                        title: recipeTitle,
                        imageUrl: imageUrl,
                        calories: calories,
                        cost: cost,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        sugar: sugar,
                        fiber: fiber,
                        sodium: sodium,
                        cholesterol: cholesterol,
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
    );
  }
} 