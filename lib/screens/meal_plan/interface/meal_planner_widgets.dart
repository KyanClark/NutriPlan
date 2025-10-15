import 'package:flutter/material.dart';
import '../../../models/recipes.dart';

/// Filter buttons for meal planner
class MealPlannerFilterButtons extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final bool isSmallScreen;

  const MealPlannerFilterButtons({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Breakfast', 'Lunch', 'Dinner'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((filter) {
        final isSelected = selectedFilter == filter;
        return GestureDetector(
          onTap: () => onFilterChanged(filter),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              filter,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Recipe card for meal planner
class MealPlannerRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String? mealType;
  final String? mealTime;
  final bool isSmallScreen;
  final bool isDeleteMode;
  final bool isSelected;
  final VoidCallback onTap;
  
  const MealPlannerRecipeCard({
    super.key,
    required this.recipe, 
    this.mealType, 
    this.mealTime, 
    required this.isSmallScreen,
    required this.isDeleteMode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
                          ),
                      ],
                    ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
              // Recipe image
              Positioned.fill(
                child: recipe.imageUrl.isNotEmpty
                    ? Image.network(
                        recipe.imageUrl,
                                    fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('DEBUG CARD: Image load error for ${recipe.title}: $error');
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                                      child: Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Colors.grey,
                          ),
                                      ),
                                    ),
                                  ),
              // Gradient overlay
              Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                        Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
              // Selection overlay
              if (isDeleteMode)
                Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFFFF6961).withOpacity(0.3)
                          : Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                        size: 40,
                                      ),
                                    ),
                                  ),
                ),
              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                        recipe.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                      const SizedBox(height: 4),
                      if (mealTime != null && mealTime!.isNotEmpty)
                                                Text(
                          mealTime!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (recipe.calories > 0)
                                                Text(
                          '${recipe.calories} cal',
                          style: const TextStyle(
                                                    color: Colors.white,
                            fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

/// Empty state when no meals are added
class MealPlannerEmptyState extends StatelessWidget {
  const MealPlannerEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/widgets/no_mea.gif',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'No meals planned yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
                        Text(
              'Start planning your meals by adding recipes from the Recipes page',
              textAlign: TextAlign.center,
                          style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
      ),
    );
  }
}

/// Empty state when filter returns no results
class MealPlannerEmptyFilterState extends StatelessWidget {
  const MealPlannerEmptyFilterState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Image.asset(
              'assets/widgets/no_mea.gif',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
          Text(
            'No meals found',
            style: TextStyle(
                fontSize: 24,
              fontWeight: FontWeight.bold,
                color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
              'There’s more to explore, your next favorite meal could surprise you.',
              textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
                color: Colors.grey[500],
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

extension MealPlannerStringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
