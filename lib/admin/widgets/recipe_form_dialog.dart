import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../user/models/recipes.dart';
import '../services/admin_recipe_service.dart';

class RecipeFormDialog extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormDialog({super.key, this.recipe});

  @override
  State<RecipeFormDialog> createState() => _RecipeFormDialogState();
}

class _RecipeFormDialogState extends State<RecipeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _allergyWarningController = TextEditingController();
  final _notesController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _costController = TextEditingController();
  
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _instructionControllers = [];
  final List<TextEditingController> _tagControllers = [];
  
  // Macro fields
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sugarController = TextEditingController();
  final _sodiumController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _loadRecipeData();
    } else {
      _addIngredientField();
      _addInstructionField();
      _addTagField();
    }
  }

  void _loadRecipeData() {
    final recipe = widget.recipe!;
    _titleController.text = recipe.title;
    _imageUrlController.text = recipe.imageUrl;
    _shortDescriptionController.text = recipe.shortDescription;
    _allergyWarningController.text = recipe.allergyWarning;
    _notesController.text = recipe.notes;
    _caloriesController.text = recipe.calories.toString();
    _costController.text = recipe.cost.toString();

    // Load ingredients
    for (final ingredient in recipe.ingredients) {
      final controller = TextEditingController(text: ingredient);
      _ingredientControllers.add(controller);
    }
    if (_ingredientControllers.isEmpty) _addIngredientField();

    // Load instructions
    for (final instruction in recipe.instructions) {
      final controller = TextEditingController(text: instruction);
      _instructionControllers.add(controller);
    }
    if (_instructionControllers.isEmpty) _addInstructionField();

    // Load tags
    for (final tag in recipe.tags) {
      final controller = TextEditingController(text: tag);
      _tagControllers.add(controller);
    }
    if (_tagControllers.isEmpty) _addTagField();

    // Load macros
    final macros = recipe.macros;
    _proteinController.text = (macros['protein'] ?? 0).toString();
    _carbsController.text = (macros['carbs'] ?? 0).toString();
    _fatsController.text = (macros['fats'] ?? 0).toString();
    _fiberController.text = (macros['fiber'] ?? 0).toString();
    _sugarController.text = (macros['sugar'] ?? 0).toString();
    _sodiumController.text = (macros['sodium'] ?? 0).toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _shortDescriptionController.dispose();
    _allergyWarningController.dispose();
    _notesController.dispose();
    _caloriesController.dispose();
    _costController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    for (final controller in _ingredientControllers) {
      controller.dispose();
    }
    for (final controller in _instructionControllers) {
      controller.dispose();
    }
    for (final controller in _tagControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addIngredientField() {
    setState(() {
      _ingredientControllers.add(TextEditingController());
    });
  }

  void _removeIngredientField(int index) {
    if (_ingredientControllers.length > 1) {
      setState(() {
        _ingredientControllers[index].dispose();
        _ingredientControllers.removeAt(index);
      });
    }
  }

  void _addInstructionField() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstructionField(int index) {
    if (_instructionControllers.length > 1) {
      setState(() {
        _instructionControllers[index].dispose();
        _instructionControllers.removeAt(index);
      });
    }
  }

  void _addTagField() {
    setState(() {
      _tagControllers.add(TextEditingController());
    });
  }

  void _removeTagField(int index) {
    if (_tagControllers.length > 1) {
      setState(() {
        _tagControllers[index].dispose();
        _tagControllers.removeAt(index);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      // In a real app, you'd upload this to Supabase Storage and get the URL
      // For now, we'll just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected. Please upload to storage and enter URL manually.'),
          ),
        );
      }
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ingredients = _ingredientControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final instructions = _instructionControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final tags = _tagControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final macros = {
        'protein': double.tryParse(_proteinController.text) ?? 0.0,
        'carbs': double.tryParse(_carbsController.text) ?? 0.0,
        'fats': double.tryParse(_fatsController.text) ?? 0.0,
        'fiber': double.tryParse(_fiberController.text) ?? 0.0,
        'sugar': double.tryParse(_sugarController.text) ?? 0.0,
        'sodium': double.tryParse(_sodiumController.text) ?? 0.0,
      };

      if (widget.recipe != null) {
        await AdminRecipeService.updateRecipe(
          id: widget.recipe!.id,
          title: _titleController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          shortDescription: _shortDescriptionController.text.trim(),
          ingredients: ingredients,
          instructions: instructions,
          macros: macros,
          allergyWarning: _allergyWarningController.text.trim(),
          calories: int.tryParse(_caloriesController.text) ?? 0,
          tags: tags,
          cost: double.tryParse(_costController.text) ?? 0.0,
          notes: _notesController.text.trim(),
        );
      } else {
        await AdminRecipeService.createRecipe(
          title: _titleController.text.trim(),
          imageUrl: _imageUrlController.text.trim(),
          shortDescription: _shortDescriptionController.text.trim(),
          ingredients: ingredients,
          instructions: instructions,
          macros: macros,
          allergyWarning: _allergyWarningController.text.trim(),
          calories: int.tryParse(_caloriesController.text) ?? 0,
          tags: tags,
          cost: double.tryParse(_costController.text) ?? 0.0,
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.recipe != null
                ? 'Recipe updated successfully'
                : 'Recipe created successfully'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recipe: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.recipe != null ? 'Edit Recipe' : 'Add Recipe',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info
                      _buildSectionTitle('Basic Information'),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Image URL',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.image),
                            onPressed: _pickImage,
                            tooltip: 'Pick image',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _shortDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Short Description *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Short description is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _caloriesController,
                              decoration: const InputDecoration(
                                labelText: 'Calories *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Calories is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _costController,
                              decoration: const InputDecoration(
                                labelText: 'Cost (₱) *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Cost is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _allergyWarningController,
                        decoration: const InputDecoration(
                          labelText: 'Allergy Warning',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Ingredients'),
                      ...List.generate(_ingredientControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ingredientControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Ingredient ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              if (_ingredientControllers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  onPressed: () => _removeIngredientField(index),
                                  color: Colors.red,
                                ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: _addIngredientField,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Ingredient'),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Instructions'),
                      ...List.generate(_instructionControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, right: 8),
                                child: Text(
                                  '${index + 1}.',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _instructionControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Step ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              if (_instructionControllers.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  onPressed: () => _removeInstructionField(index),
                                  color: Colors.red,
                                ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: _addInstructionField,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Step'),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Nutritional Information'),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _proteinController,
                              decoration: const InputDecoration(
                                labelText: 'Protein (g)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _carbsController,
                              decoration: const InputDecoration(
                                labelText: 'Carbs (g)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _fatsController,
                              decoration: const InputDecoration(
                                labelText: 'Fats (g)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fiberController,
                              decoration: const InputDecoration(
                                labelText: 'Fiber (g)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _sugarController,
                              decoration: const InputDecoration(
                                labelText: 'Sugar (g)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _sodiumController,
                              decoration: const InputDecoration(
                                labelText: 'Sodium (mg)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Tags'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_tagControllers.length, (index) {
                          return SizedBox(
                            width: 150,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _tagControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Tag ${index + 1}',
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_tagControllers.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, size: 20),
                                    onPressed: () => _removeTagField(index),
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                      TextButton.icon(
                        onPressed: _addTagField,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Tag'),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Notes'),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveRecipe,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.recipe != null ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

