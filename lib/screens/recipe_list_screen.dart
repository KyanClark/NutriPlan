import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/meal_service.dart';
import 'recipe_info_screen.dart';
import '../main.dart'; // Import for ResponsiveDesign utilities

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  List<Meal> recipes = [];
  int _selectedCategoryIndex = 0; // Default to "All" (index 0)
  String _sortBy = 'name'; // 'name', 'price', 'calories', 'time'
  String _searchQuery = '';
  final List<String> _selectedDietaryPreferences = [];
  final ScrollController _categoryScrollController = ScrollController();

  // Category names
  final categories = [
    'All',
    'Main Dishes',
    'Appetizers',
    'Soups',
    'Side Dishes',
    'Rice Cakes'
  ];

  // Dietary preferences
  final dietaryPreferences = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Low-Carb',
    'High-Protein',
    'Keto',
    'Paleo'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
    
    // Add scroll listener to update underline position
    _categoryScrollController.addListener(() {
      setState(() {
        // Trigger rebuild to update underline position
      });
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _loadRecipes() {
    recipes = MealService.getAllMeals();
  }

  List<Meal> get filteredAndSortedRecipes {
    List<Meal> filtered = recipes.where((recipe) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        if (!recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !recipe.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategoryIndex != 0) {
        final category = categories[_selectedCategoryIndex];
        switch (category) {
          case 'Main Dishes':
            return recipe.calories >= 400 && recipe.cookingTime > 20;
          case 'Appetizers':
            return recipe.calories < 300 && recipe.cookingTime < 20;
          case 'Soups':
            return recipe.name.toLowerCase().contains('soup') || 
                   recipe.description.toLowerCase().contains('soup');
          case 'Snacks':
            return recipe.calories < 250 && recipe.cookingTime < 15;
          case 'Side Dishes':
            return recipe.calories < 400 && recipe.cookingTime < 30;
          case 'Baked Goods':
            return recipe.name.toLowerCase().contains('bread') || 
                   recipe.name.toLowerCase().contains('cake') ||
                   recipe.name.toLowerCase().contains('bake');
          case 'Rice Cakes':
            return recipe.name.toLowerCase().contains('rice') || 
                   recipe.name.toLowerCase().contains('cake');
          default:
            return true;
        }
      }

      // Dietary preferences filter
      if (_selectedDietaryPreferences.isNotEmpty) {
        bool matchesPreference = false;
        for (String preference in _selectedDietaryPreferences) {
          if (recipe.dietaryTags.contains(preference.toLowerCase().replaceAll('-', ''))) {
            matchesPreference = true;
            break;
          }
        }
        if (!matchesPreference) return false;
      }

      return true;
    }).toList();

    // Sort recipes
    switch (_sortBy) {
      case 'price':
        filtered.sort((a, b) => a.cost.compareTo(b.cost));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.cost.compareTo(a.cost));
        break;
      case 'calories':
        filtered.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case 'calories_high':
        filtered.sort((a, b) => b.calories.compareTo(a.calories));
        break;
      case 'time':
        filtered.sort((a, b) => a.cookingTime.compareTo(b.cookingTime));
        break;
      case 'time_high':
        filtered.sort((a, b) => b.cookingTime.compareTo(a.cookingTime));
        break;
      default: // 'name'
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);
    
    return SafeArea(
      child: Container(
        color: const Color(0xFFC1E7AF),
        child: Column(
          children: [
            // Search Bar with Preferences Dialog
            Padding(
              padding: ResponsiveDesign.responsivePadding(context),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search any recipes...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  IconButton(
                    icon: Icon(Icons.sort, size: isSmallScreen ? 20 : 24),
                    onPressed: () {
                      _showSortDialog();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, size: isSmallScreen ? 20 : 24),
                    onPressed: () {
                      _showPreferencesDialog();
                    },
                  ),
                ],
              ),
            ),

            // Category Section with sliding underline animation
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16.0 : 20.0, 
                vertical: isSmallScreen ? 6 : 8,
              ),
              child: Column(
                children: [
                  // Category text items
                  SizedBox(
                    height: isSmallScreen ? 28 : 32,
                    child: ListView.separated(
                      controller: _categoryScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => SizedBox(width: isSmallScreen ? 20 : 24),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                            // Scroll to the selected category
                            _scrollToCategory(index);
                          },
                          child: Text(
                            categories[index],
                            style: TextStyle(
                              fontSize: ResponsiveDesign.responsiveFontSize(context, 16),
                              fontWeight: _selectedCategoryIndex == index ? FontWeight.bold : FontWeight.normal,
                              color: _selectedCategoryIndex == index ? Colors.black : Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  // Animated sliding underline
                  SizedBox(
                    height: 2,
                    child: Stack(
                      children: [
                        // Background line (optional, for visual reference)
                        Container(
                          height: 2,
                          width: double.infinity,
                          color: Colors.grey[200],
                        ),
                        // Animated underline
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: _getUnderlinePosition(),
                          child: Container(
                            height: 2,
                            width: categories[_selectedCategoryIndex].length * (isSmallScreen ? 7.0 : 8.0),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveDesign.responsiveSpacing(context)),

            // Recipe List (grid layout with cards)
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 20, 
                  vertical: isSmallScreen ? 6 : 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredAndSortedRecipes.length,
                itemBuilder: (context, i) {
                  final recipe = filteredAndSortedRecipes[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeInfoScreen(
                            imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
                            title: recipe.name,
                            description: recipe.description,
                            price: recipe.cost,
                            timeMinutes: recipe.cookingTime,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: isSmallScreen ? 8 : 12,
                            offset: Offset(0, isSmallScreen ? 3 : 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recipe Image
                          Expanded(
                            flex: 3,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(isSmallScreen ? 16 : 20),
                                ),
                                image: const DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Favorite icon overlay
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        recipe.dietaryTags.contains('favorite') ? Icons.favorite : Icons.favorite_border,
                                        color: recipe.dietaryTags.contains('favorite') ? Colors.red : Colors.grey[400],
                                        size: isSmallScreen ? 16 : 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Recipe Details
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Recipe Name
                                  Text(
                                    recipe.name,
                                    style: TextStyle(
                                      fontSize: ResponsiveDesign.responsiveFontSize(context, 14),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  // Recipe Info
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${recipe.calories} cal • ${recipe.cookingTime} min',
                                        style: TextStyle(
                                          fontSize: ResponsiveDesign.responsiveFontSize(context, 11),
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₱${recipe.cost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: ResponsiveDesign.responsiveFontSize(context, 13),
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, int index) {
    final isSelected = _selectedCategoryIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.green[100],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Meal recipe) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeInfoScreen(
                imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
                title: recipe.name,
                description: recipe.description,
                price: recipe.cost,
                timeMinutes: recipe.cookingTime,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Icon and Name
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Recipe Details
              Text(
                'Calories: ${recipe.calories}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Cost: ₱${recipe.cost.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Time: ${recipe.cookingTime} min',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              
              // Dietary tags
              if (recipe.dietaryTags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: recipe.dietaryTags.take(2).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Recipes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('Name (A-Z)', 'name'),
            _buildSortOption('Price (Low to High)', 'price'),
            _buildSortOption('Price (High to Low)', 'price_high'),
            _buildSortOption('Calories (Low to High)', 'calories'),
            _buildSortOption('Calories (High to Low)', 'calories_high'),
            _buildSortOption('Cooking Time (Low to High)', 'time'),
            _buildSortOption('Cooking Time (High to Low)', 'time_high'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _sortBy,
      onChanged: (newValue) {
        setState(() {
          _sortBy = newValue!;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dietary Preferences'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: dietaryPreferences.map((preference) {
                return CheckboxListTile(
                  title: Text(preference),
                  value: _selectedDietaryPreferences.contains(preference),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedDietaryPreferences.add(preference);
                      } else {
                        _selectedDietaryPreferences.remove(preference);
                      }
                    });
                    this.setState(() {});
                  },
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDietaryPreferences.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  double _getUnderlinePosition() {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);
    double position = 0;
    
    // Calculate position based on selected index
    for (int i = 0; i < _selectedCategoryIndex; i++) {
      position += categories[i].length * (isSmallScreen ? 7.0 : 8.0) + (isSmallScreen ? 20 : 24);
    }
    
    // Adjust for scroll offset if the controller is attached
    if (_categoryScrollController.hasClients) {
      final scrollOffset = _categoryScrollController.offset;
      position -= scrollOffset;
    }
    
    return position;
  }

  void _scrollToCategory(int index) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);
    double targetPosition = 0;
    
    // Calculate the position for the selected category
    for (int i = 0; i < index; i++) {
      targetPosition += categories[i].length * (isSmallScreen ? 7.0 : 8.0) + (isSmallScreen ? 20 : 24);
    }
    
    // Ensure the scroll position is within bounds
    if (_categoryScrollController.hasClients) {
      final maxScroll = _categoryScrollController.position.maxScrollExtent;
      targetPosition = targetPosition.clamp(0.0, maxScroll);
      
      // Smoothly scroll to the target position
      _categoryScrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
} 