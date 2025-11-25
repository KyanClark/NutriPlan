import 'package:flutter/material.dart';
import '../recipes/filtered_recipes_page.dart';

class AllMealCategoriesPage extends StatelessWidget {
  const AllMealCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      // All categories in alphabetical order
      {
        'name': 'Beef',
        'asset': 'assets/widgets/beef_category.gif',
        'assetType': 'gif',
        'category': 'beef',
      },
      {
        'name': 'Chicken',
        'asset': 'assets/widgets/chicken_category.gif',
        'assetType': 'gif',
        'category': 'chicken',
      },
      {
        'name': 'Desserts',
        'asset': 'assets/widgets/soup-vid.gif', // Using soup as placeholder
        'assetType': 'gif',
        'category': 'desserts',
      },
      {
        'name': 'Fish',
        'asset': 'assets/widgets/fish.png',
        'assetType': 'image',
        'category': 'fish',
      },
      {
        'name': 'Pork',
        'asset': 'assets/widgets/pork.png',
        'assetType': 'image',
        'category': 'pork',
      },
      {
        'name': 'Silog Meals',
        'asset': 'assets/widgets/silog-meals.jpg',
        'assetType': 'image',
        'category': 'silog',
      },
      {
        'name': 'Soup',
        'asset': 'assets/widgets/soup-vid.gif',
        'assetType': 'gif',
        'category': 'soup',
      },
      {
        'name': 'Vegetable',
        'asset': 'assets/widgets/vegetable_category.gif',
        'assetType': 'gif',
        'category': 'vegetable',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFC1E7AF),
      appBar: AppBar(
        title: const Text(
          'All Meal Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(
              context,
              category['name'] as String,
              category['asset'] as String,
              category['assetType'] as String,
              category['category'] as String,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String name,
    String asset,
    String assetType,
    String category,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FilteredRecipesPage(
              category: category,
              categoryName: name,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.ease;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Centered asset (image or gif) with padding for floating effect, positioned slightly higher
              Align(
                alignment: const Alignment(0, -0.9),
                child: Container(
                  padding: const EdgeInsets.all(16),  
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      width: category == 'chicken' || category == 'pork' ? 70 : 100,
                      height: category == 'chicken' || category == 'pork' ? 70 : 100,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: category == 'chicken' || category == 'pork' ? 70 : 100,
                        height: category == 'chicken' || category == 'pork' ? 70 : 100,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.restaurant,
                          size: 32,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Category name
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.white54,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
