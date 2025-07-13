import 'package:flutter/material.dart';
import '../models/recipes.dart';

class RecipeInfoScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeInfoScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                                child: Text('Cost: \$${recipe.cost.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Macros', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _MacroChip(label: 'Fat', value: recipe.macros['fats'].toString()),
                                      _MacroChip(label: 'Protein', value: recipe.macros['protein'].toString()),
                                      _MacroChip(label: 'Fiber', value: recipe.macros['fiber'].toString()),
                                      _MacroChip(label: 'Carbs', value: recipe.macros['carbs'].toString()),
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
                            ...recipe.ingredients.map((ing) => Text('• $ing')).toList(),
                            const SizedBox(height: 16),
                            const Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ...recipe.instructions.asMap().entries.map((entry) => Text('${entry.key + 1}. ${entry.value}')).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Fixed bottom button (move this to the end so it's always on top)
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
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          // TODO: Add to Meal Plan functionality
                        },
                        child: const Text(
                          'Add to Meal Plan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
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