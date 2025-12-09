import 'package:flutter/material.dart';
import '../../user/models/recipes.dart';
import '../services/admin_recipe_service.dart';
import 'recipe_form_page.dart';

class ViewRecipesPage extends StatelessWidget {
  final Recipe recipe;

  const ViewRecipesPage({super.key, required this.recipe});

  Future<void> _deleteRecipe(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AdminRecipeService.deleteRecipe(recipe.id);
      if (context.mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe "${recipe.title}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Image
                Expanded(
                  flex: 2,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: recipe.imageUrl.isNotEmpty
                          ? Image.network(
                              recipe.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: double.infinity,
                                height: 400,
                                color: Colors.grey[300],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 64),
                                    SizedBox(height: 8),
                                    Text('Image not available'),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              width: double.infinity,
                              height: 400,
                              color: Colors.grey[300],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant_menu, size: 64),
                                  SizedBox(height: 8),
                                  Text('No image'),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // Right side - Details
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with Edit/Delete buttons
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipe.title,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit Recipe',
                            color: const Color(0xFF4CAF50),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => RecipeFormPage(recipe: recipe),
                ),
              );
              if (result == true && context.mounted) {
                // Cache will be invalidated by the form page
                Navigator.of(context).pop(true); // Refresh the list
              }
            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete Recipe',
                            color: Colors.red,
                            onPressed: () => _deleteRecipe(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Short Description
                      Text(
                        recipe.shortDescription,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Info chips
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _InfoChip(
                            leading: Image.asset(
                              'assets/meal-tracker-icons/calories.png',
                              height: 18,
                              width: 18,
                              fit: BoxFit.contain,
                            ),
                            label: '${recipe.calories} cal',
                          ),
                          _InfoChip(
                            icon: Icons.payments,
                            label: '₱${recipe.cost.toStringAsFixed(2)}',
                          ),
                          if (recipe.tags.isNotEmpty)
                            ...recipe.tags.map((tag) => _InfoChip(
                                  icon: Icons.label,
                                  label: tag,
                                )),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Allergy Warning
                      if (recipe.allergyWarning.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  recipe.allergyWarning,
                                  style: TextStyle(
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      // Ingredients
                      _buildSectionTitle('Ingredients'),
                      const SizedBox(height: 12),
                      ...recipe.ingredients.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key + 1}.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      // Instructions
                      _buildSectionTitle('Instructions'),
                      const SizedBox(height: 12),
                      ...recipe.instructions.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      // Nutritional Information
                      _buildSectionTitle('Nutritional Information'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: [
                            _NutritionItem(
                              label: 'Protein',
                              value: '${recipe.macros['protein']?.toStringAsFixed(1) ?? '0'} g',
                            ),
                            _NutritionItem(
                              label: 'Carbs',
                              value: '${recipe.macros['carbs']?.toStringAsFixed(1) ?? '0'} g',
                            ),
                            _NutritionItem(
                              label: 'Fats',
                              value: '${recipe.macros['fats']?.toStringAsFixed(1) ?? '0'} g',
                            ),
                            _NutritionItem(
                              label: 'Fiber',
                              value: '${recipe.macros['fiber']?.toStringAsFixed(1) ?? '0'} g',
                            ),
                            _NutritionItem(
                              label: 'Sugar',
                              value: '${recipe.macros['sugar']?.toStringAsFixed(1) ?? '0'} g',
                            ),
                            _NutritionItem(
                              label: 'Sodium',
                              value: '${recipe.macros['sodium']?.toStringAsFixed(0) ?? '0'} mg',
                            ),
                            _NutritionItem(
                              label: 'Cholesterol',
                              value: '${recipe.macros['cholesterol']?.toStringAsFixed(0) ?? '0'} mg',
                            ),
                          ],
                        ),
                      ),
                      // Notes
                      if (recipe.notes.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildSectionTitle('Notes'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            recipe.notes,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;

  const _InfoChip({this.icon, this.leading, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: leading ?? (icon != null ? Icon(icon, size: 18) : null),
      label: Text(label, style: const TextStyle(fontSize: 14)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

