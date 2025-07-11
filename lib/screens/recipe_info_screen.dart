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
            // Main card
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 24),
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
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
                      const SizedBox(height: 12),
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
            ),
            // Hero image (overlapping)
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 90,
                    backgroundImage: NetworkImage(recipe.imageUrl),
                  ),
                ),
              ),
            ),
            // Back button
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