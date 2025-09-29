import 'package:flutter/material.dart';
import 'skeleton_loading_animation.dart';

class RecipeListSkeleton extends StatefulWidget {
  final int itemCount;
  final String? loadingMessage;
  
  const RecipeListSkeleton({
    super.key,
    this.itemCount = 6,
    this.loadingMessage,
  });

  @override
  State<RecipeListSkeleton> createState() => _RecipeListSkeletonState();
}

class _RecipeListSkeletonState extends State<RecipeListSkeleton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.loadingMessage != null) _buildLoadingHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.itemCount,
            itemBuilder: (context, index) {
              return RecipeCardSkeleton(
                delay: index * 200,
                shimmerAnimation: _shimmerAnimation,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.restaurant_menu,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.loadingMessage ?? 'Loading recipes...',
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
        ],
      ),
    );
  }
}

class MealHistorySkeleton extends StatefulWidget {
  final int itemCount;
  final String? loadingMessage;
  
  const MealHistorySkeleton({
    super.key,
    this.itemCount = 5,
    this.loadingMessage,
  });

  @override
  State<MealHistorySkeleton> createState() => _MealHistorySkeletonState();
}

class _MealHistorySkeletonState extends State<MealHistorySkeleton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.loadingMessage != null) _buildLoadingHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.itemCount,
            itemBuilder: (context, index) {
              return MealHistoryCardSkeleton(
                delay: index * 150,
                shimmerAnimation: _shimmerAnimation,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            widget.loadingMessage ?? 'Loading meal history...',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
          ),
        ],
      ),
    );
  }
}
