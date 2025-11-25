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
  final VoidCallback? onLongPress;
  
  const MealPlannerRecipeCard({
    super.key,
    required this.recipe, 
    this.mealType, 
    this.mealTime, 
    required this.isSmallScreen,
    required this.isDeleteMode,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
              // Time display (top right)
              if (mealTime != null && mealTime!.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatTime(mealTime!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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

  String _formatTime(String timeString) {
    try {
      // Handle different time formats
      String cleanTime = timeString.replaceAll(RegExp(r'[^\d:]'), '');
      
      // If it's already in HH:MM format
      if (cleanTime.contains(':')) {
        final parts = cleanTime.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = parts[1];
          
          if (hour == 0) {
            return '12:${minute.padLeft(2, '0')} AM';
          } else if (hour < 12) {
            return '${hour}:${minute.padLeft(2, '0')} AM';
          } else if (hour == 12) {
            return '12:${minute.padLeft(2, '0')} PM';
          } else {
            return '${hour - 12}:${minute.padLeft(2, '0')} PM';
          }
        }
      }
      
      // If it's just an hour (e.g., "14" for 2 PM)
      final hour = int.parse(cleanTime);
      if (hour == 0) {
        return '12:00 AM';
      } else if (hour < 12) {
        return '$hour:00 AM';
      } else if (hour == 12) {
        return '12:00 PM';
      } else {
        return '${hour - 12}:00 PM';
      }
    } catch (e) {
      // Fallback to original string if parsing fails
      return timeString;
    }
  }
}

/// Empty state when no meals are added
class MealPlannerEmptyState extends StatelessWidget {
  const MealPlannerEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/widgets/no_mea.gif',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'No Meals Planned Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ready to start your meal? Tap the + button below to discover delicious recipes and start building your meal plan!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
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
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
          Text(
            'No meals found',
            style: TextStyle(
                fontSize: 20,
              fontWeight: FontWeight.bold,
                color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
              'Try adjusting your filters or explore more recipes!',
              textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
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