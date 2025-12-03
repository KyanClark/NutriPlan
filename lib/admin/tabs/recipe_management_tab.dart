import 'package:flutter/material.dart';
import '../../user/models/recipes.dart';
import '../services/admin_recipe_service.dart';
import '../pages/recipe_form_page.dart';
import '../pages/view_recipes_page.dart';
import '../widgets/recipe_card_skeleton.dart';

class RecipeManagementTab extends StatefulWidget {
  const RecipeManagementTab({super.key});

  @override
  State<RecipeManagementTab> createState() => _RecipeManagementTabState();
}

class _RecipeManagementTabState extends State<RecipeManagementTab> {
  static List<Recipe>? _cachedRecipes; // Static cache
  static bool _cacheValid = false; // Cache validity flag
  
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _sortField = 'title'; // 'title', 'calories', 'cost', 'protein', 'carbs', 'fats', 'cost_range'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Use cached data if available
    if (_cacheValid && _cachedRecipes != null) {
      setState(() {
        _recipes = _cachedRecipes!;
        _applySort();
        _isLoading = false;
      });
    } else {
    _loadRecipes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final recipes = await AdminRecipeService.getAllRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _applySort();
        _isLoading = false;
      });
      // Update cache
      _cachedRecipes = recipes;
      _cacheValid = true;
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading recipes: $errorMessage'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _searchRecipes() async {
    if (_searchQuery.trim().isEmpty) {
      _loadRecipes();
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final recipes = await AdminRecipeService.searchRecipes(_searchQuery);
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _applySort();
        _isLoading = false;
      });
      // Update cache
      _cachedRecipes = recipes;
      _cacheValid = true;
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching recipes: $e')),
        );
      }
    }
  }

  /// Invalidate the recipe cache (call this when recipes are added/updated/deleted)
  static void invalidateCache() {
    _cacheValid = false;
    _cachedRecipes = null;
  }

  Future<void> _deleteRecipe(Recipe recipe) async {
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
      // Invalidate cache
      invalidateCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRecipes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _viewRecipe(Recipe recipe) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ViewRecipesPage(recipe: recipe),
      ),
    );

    if (result == true) {
      // Invalidate cache when recipe is updated
      invalidateCache();
      _loadRecipes();
    }
  }

  Future<void> _showRecipeForm({Recipe? recipe}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => RecipeFormPage(recipe: recipe),
      ),
    );

    if (result == true) {
      // Invalidate cache when recipe is created/updated
      invalidateCache();
      _loadRecipes();
    }
  }

  void _applySort() {
    _recipes.sort((a, b) {
      int cmp = 0;
      switch (_sortField) {
        case 'calories':
          cmp = a.calories.compareTo(b.calories);
          break;
        case 'cost':
          cmp = a.cost.compareTo(b.cost);
          break;
        case 'protein':
          final aProtein = (a.macros['protein'] as num?)?.toDouble() ?? 0.0;
          final bProtein = (b.macros['protein'] as num?)?.toDouble() ?? 0.0;
          cmp = aProtein.compareTo(bProtein);
          break;
        case 'carbs':
          final aCarbs = (a.macros['carbs'] as num?)?.toDouble() ?? 0.0;
          final bCarbs = (b.macros['carbs'] as num?)?.toDouble() ?? 0.0;
          cmp = aCarbs.compareTo(bCarbs);
          break;
        case 'fats':
          final aFats = (a.macros['fats'] as num?)?.toDouble() ?? 0.0;
          final bFats = (b.macros['fats'] as num?)?.toDouble() ?? 0.0;
          cmp = aFats.compareTo(bFats);
          break;
        case 'cost_range':
          // Group by cost ranges: 0-200, 200-400, 400-600, 600-800, 800+
          final aRange = _getCostRange(a.cost);
          final bRange = _getCostRange(b.cost);
          cmp = aRange.compareTo(bRange);
          if (cmp == 0) {
            // If same range, sort by actual cost
            cmp = a.cost.compareTo(b.cost);
          }
          break;
        case 'title':
        default:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  int _getCostRange(double cost) {
    if (cost < 200) return 0;
    if (cost < 400) return 1;
    if (cost < 600) return 2;
    if (cost < 800) return 3;
    return 4;
  }

  String _getCostRangeLabel(double cost) {
    if (cost < 200) return '₱0-200';
    if (cost < 400) return '₱200-400';
    if (cost < 600) return '₱400-600';
    if (cost < 800) return '₱600-800';
    return '₱800+';
  }

  void _changeSort(String field) {
    setState(() {
      if (_sortField == field) {
        // Toggle ascending/descending when clicking same field
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
      _applySort();
    });
  }

  String _getSortLabel() {
    switch (_sortField) {
      case 'calories':
        return 'Sort: Calories ${_sortAscending ? '↑' : '↓'}';
      case 'cost':
        return 'Sort: Cost ${_sortAscending ? '↑' : '↓'}';
      case 'protein':
        return 'Sort: Protein ${_sortAscending ? '↑' : '↓'}';
      case 'carbs':
        return 'Sort: Carbs ${_sortAscending ? '↑' : '↓'}';
      case 'fats':
        return 'Sort: Fats ${_sortAscending ? '↑' : '↓'}';
      case 'cost_range':
        return 'Sort: Cost Range ${_sortAscending ? '↑' : '↓'}';
      case 'title':
      default:
        return 'Sort: Title ${_sortAscending ? '↑' : '↓'}';
    }
  }

  Future<void> _showSortDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Recipes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SortOption(
                icon: Icons.sort_by_alpha,
                label: 'Title',
                field: 'title',
                currentField: _sortField,
                ascending: _sortAscending,
                onTap: () {
                  _changeSort('title');
                  Navigator.of(context).pop();
                },
              ),
              _SortOption(
                icon: Icons.local_fire_department,
                label: 'Calories',
                field: 'calories',
                currentField: _sortField,
                ascending: _sortAscending,
                onTap: () {
                  _changeSort('calories');
                  Navigator.of(context).pop();
                },
              ),
              _SortOption(
                icon: Icons.payments,
                label: 'Cost',
                field: 'cost',
                currentField: _sortField,
                ascending: _sortAscending,
                onTap: () {
                  _changeSort('cost');
                  Navigator.of(context).pop();
                },
              ),
              _SortOption(
                icon: Icons.payments,
                label: 'Cost Range (₱0-200, ₱200-400, etc.)',
                field: 'cost_range',
                currentField: _sortField,
                ascending: _sortAscending,
                onTap: () {
                  _changeSort('cost_range');
                  Navigator.of(context).pop();
                },
              ),
              _SortOption(
                icon: Icons.fitness_center,
                label: 'Protein',
                field: 'protein',
                currentField: _sortField,
                ascending: _sortAscending,
                onTap: () {
                  _changeSort('protein');
                  Navigator.of(context).pop();
                },
              ),
              _SortOption(
                icon: Icons.grain,
                label: 'Carbs',
                field: 'carbs',
                currentField: _sortField,
                ascending: _sortAscending,
                onTap: () {
                  _changeSort('carbs');
                  Navigator.of(context).pop();
                },
              ),
              _SortOption(
                icon: Icons.opacity,
                label: 'Fats',
                field: 'fats',
                currentField: _sortField,
                ascending: _sortAscending,
                onTap: () {
                  _changeSort('fats');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Recipe> get _filteredRecipes {
    if (_searchQuery.trim().isEmpty) return _recipes;
    final query = _searchQuery.toLowerCase();
    return _recipes.where((recipe) {
      return recipe.title.toLowerCase().contains(query) ||
          recipe.shortDescription.toLowerCase().contains(query) ||
          recipe.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    
    return Column(
      children: [
        // Recipe count above search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filteredRecipes.length} recipe${_filteredRecipes.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search recipes by title, description, or tags...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadRecipes();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.grey, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.grey, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _searchRecipes();
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Sort button - opens dialog
              ElevatedButton.icon(
                onPressed: () => _showSortDialog(context),
                icon: const Icon(Icons.sort, size: 18),
                label: Text(
                  _getSortLabel(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showRecipeForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Recipe'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _isLoading && _cachedRecipes == null
              ? Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Loading recipes...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: isWideScreen
                          ? GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: 6,
                              itemBuilder: (context, index) {
                                return const RecipeCardSkeleton();
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: 6,
                              itemBuilder: (context, index) {
                                return const RecipeCardSkeleton();
                              },
                            ),
                    ),
                  ],
                )
              : _filteredRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No recipes found'
                                : 'No recipes match your search',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRecipes,
                      child: isWideScreen
                          ? GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _filteredRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = _filteredRecipes[index];
                                return _RecipeCard(
                                  recipe: recipe,
                                  onView: () => _viewRecipe(recipe),
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: _filteredRecipes.length,
                              itemBuilder: (context, index) {
                                final recipe = _filteredRecipes[index];
                                return _RecipeCard(
                                  recipe: recipe,
                                  onView: () => _viewRecipe(recipe),
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onView;

  const _RecipeCard({
    required this.recipe,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;
    
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: recipe.imageUrl.isNotEmpty
                    ? Image.network(
                        recipe.imageUrl,
                        width: double.infinity,
                        height: isWideScreen ? 180 : 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: isWideScreen ? 180 : 120,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 48),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: isWideScreen ? 180 : 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant_menu, size: 48),
                      ),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Description
              Text(
                recipe.shortDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const SizedBox(height: 12),
              // Calorie and Cost display (standalone, larger)
              Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 22, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        '${recipe.calories} cal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      Icon(Icons.payments, size: 22, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        '₱${recipe.cost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
                  ),
              if (recipe.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _InfoChip(
                      icon: Icons.label,
                      label: recipe.tags.first,
                    ),
                ],
              ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SortOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String field;
  final String currentField;
  final bool ascending;
  final VoidCallback onTap;

  const _SortOption({
    required this.icon,
    required this.label,
    required this.field,
    required this.currentField,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentField == field;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF4CAF50) : Colors.grey),
      title: Text(label),
      trailing: isSelected
          ? Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              color: const Color(0xFF4CAF50),
            )
          : null,
      selected: isSelected,
      selectedTileColor: const Color(0xFF4CAF50).withOpacity(0.1),
      onTap: onTap,
    );
  }
}

