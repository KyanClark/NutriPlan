import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../user/models/recipes.dart';
import '../services/admin_recipe_service.dart';

class RecipeFormPage extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormPage({super.key, this.recipe});

  @override
  State<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
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
  bool _isUploadingImage = false;
  String? _imageUrl;
  XFile? _selectedImageFile;

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
    _imageUrl = recipe.imageUrl;
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

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    
    if (pickedFile == null) return;

    setState(() {
      _selectedImageFile = pickedFile;
      _isUploadingImage = true;
    });

    try {
      final fileBytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'recipe-images/$timestamp.$fileExt';
      final storage = Supabase.instance.client.storage.from('recipe-images');
      
      // Upload the image to Supabase Storage
      await storage.uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExt'),
      );
      
      // Get the public URL
      final publicUrl = storage.getPublicUrl(filePath);
      
      setState(() {
        _imageUrl = publicUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a recipe image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
          imageUrl: _imageUrl!,
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
          imageUrl: _imageUrl!,
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving recipe: $e'),
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
        title: Text(widget.recipe != null ? 'Edit Recipe' : 'Add Recipe'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          margin: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Upload Section
                  _buildSectionTitle('Recipe Image *'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isUploadingImage ? null : _pickAndUploadImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _isUploadingImage
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Uploading image...'),
                                ],
                              ),
                            )
                          : _imageUrl != null && _imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _imageUrl!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                                  ),
                                )
                              : _selectedImageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(_selectedImageFile!.path),
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _buildImagePlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload image',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Basic Info
                  _buildSectionTitle('Basic Information'),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shortDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Short Description *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                          decoration: InputDecoration(
                            labelText: 'Calories *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                          decoration: InputDecoration(
                            labelText: 'Cost (₱) *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                    decoration: InputDecoration(
                      labelText: 'Allergy Warning',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                          decoration: InputDecoration(
                            labelText: 'Protein (g)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _carbsController,
                          decoration: InputDecoration(
                            labelText: 'Carbs (g)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _fatsController,
                          decoration: InputDecoration(
                            labelText: 'Fats (g)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                          decoration: InputDecoration(
                            labelText: 'Fiber (g)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _sugarController,
                          decoration: InputDecoration(
                            labelText: 'Sugar (g)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _sodiumController,
                          decoration: InputDecoration(
                            labelText: 'Sodium (mg)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                    decoration: InputDecoration(
                      labelText: 'Additional Notes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 32),
                  // Save buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveRecipe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(widget.recipe != null ? 'Update Recipe' : 'Create Recipe'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to upload image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
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

