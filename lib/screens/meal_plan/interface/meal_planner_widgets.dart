import 'package:flutter/material.dart';
import '../../../models/recipes.dart';

/// Enhanced Recipe Card widget for meal planner
class MealPlannerRecipeCard extends StatefulWidget {
  final Recipe recipe;
  final String? mealType;
  final String? mealTime;
  final bool isFavorite;
  final VoidCallback? onTap;
  final bool isSmallScreen;
  final bool isDeleteMode;
  final bool isSelected;
  
  const MealPlannerRecipeCard({
    super.key,
    required this.recipe, 
    this.mealType, 
    this.mealTime, 
    this.isFavorite = false, 
    this.onTap,
    this.isSmallScreen = false,
    this.isDeleteMode = false,
    this.isSelected = false,
  });

  @override
  State<MealPlannerRecipeCard> createState() => _MealPlannerRecipeCardState();
}

class _MealPlannerRecipeCardState extends State<MealPlannerRecipeCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = widget.isSmallScreen 
            ? constraints.maxWidth * 0.95 
            : constraints.maxWidth < 220 ? constraints.maxWidth : 200.0;
        
        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTapDown: (_) => _animationController.forward(),
                  onTapUp: (_) {
                    _animationController.reverse();
                    widget.onTap?.call();
                  },
                  onTapCancel: () => _animationController.reverse(),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: widget.isSelected 
                          ? BorderSide(color: const Color(0xFFFF6961), width: 2)
                          : BorderSide.none,
                    ),
                      color: widget.isSelected 
                        ? const Color(0xFFFF6961).withValues(alpha: 0.1) 
                          : Colors.white,
                    child: SizedBox(
                      width: cardWidth,
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recipe image section
                        Expanded(
                          flex: 3,
                    child: Stack(
                      children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                                  image: DecorationImage(
                                    image: NetworkImage(widget.recipe.imageUrl),
                                    fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              // Time display at top right
                              if (widget.mealTime != null && widget.mealTime!.isNotEmpty)
                                  Positioned(
                                  top: 8,
                                  right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                          Icons.access_time,
                                          size: 12,
                                                  color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                          widget.mealTime!,
                                          style: const TextStyle(
                                                    color: Colors.white,
                                              fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Geist',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              // Calories at bottom right
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                        Icons.local_fire_department,
                                        size: 12,
                                        color: Colors.orange[300],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                        '${widget.recipe.calories} kcal',
                                        style: const TextStyle(
                                                    color: Colors.white,
                                          fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                          fontFamily: 'Geist',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                        ),
                        // Selection indicator for delete mode
                        if (widget.isDeleteMode)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: widget.isSelected ? const Color(0xFFFF6961) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF6961),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: widget.isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                          ),
                        ),
                        // Recipe title section
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              widget.recipe.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Geist',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            ),
                          ),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Filter buttons widget for meal types
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
    final filters = [
      // Time-based categories only
      {'key': 'all', 'label': 'All', 'icon': Icons.restaurant_menu},
      {'key': 'breakfast', 'label': 'Breakfast', 'icon': Icons.wb_sunny},
      {'key': 'lunch', 'label': 'Lunch', 'icon': Icons.wb_sunny_outlined},
      {'key': 'dinner', 'label': 'Dinner', 'icon': Icons.nights_stay},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Colors.white, Color(0xFFE8F5E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => onFilterChanged(filter['key'] as String),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter['icon'] as IconData,
                          size: isSmallScreen ? 16 : 18,
                          color: isSelected ? const Color(0xFF4CAF50) : Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filter['label'] as String,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? const Color(0xFF4CAF50) : Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Empty state widget when no meals are found with current filter
class MealPlannerEmptyFilterState extends StatelessWidget {
  const MealPlannerEmptyFilterState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No meals found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing the filter or add more meals to your plan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Empty state widget when no meal plans exist
class MealPlannerEmptyState extends StatelessWidget {
  const MealPlannerEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  const Color(0xFF66BB6A).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.restaurant_menu_outlined,
              size: 64,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Meal Plans Added',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start planning your meals by adding recipes to your meal planner',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add Your First Meal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension MealPlannerStringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
