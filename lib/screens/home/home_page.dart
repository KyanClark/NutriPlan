import 'package:flutter/material.dart';
import 'dart:async';
import '../meal_plan/meal_planner_screen.dart';
import '../profile/profile_screen.dart';
import '../tracking/meal_tracker_screen.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/bottom_navigation.dart'; 
import '../recipes/recipes_page.dart';
import '../recipes/filtered_recipes_page.dart';
import '../suggestions/smart_suggestions_page.dart';
import 'meal_categories_page.dart';

class HomePage extends StatefulWidget {
  final bool forceMealPlanRefresh;
  final int initialTab;
  const HomePage({super.key, this.forceMealPlanRefresh = false, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String userName = ""; // Start empty, will fetch from Supabase
  late int _selectedIndex;

  bool _didForceRefresh = false;

  int _mealPlanCount = 0;
  bool _loadingCounts = false;
  final PageController _bannerController = PageController(viewportFraction: 0.88);
  double _bannerPage = 0.0;
  Timer? _bannerAutoTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialTab;
    _fetchCounts();
    _fetchRecentMeals();
    _bannerController.addListener(() {
      setState(() {
        _bannerPage = _bannerController.page ?? 0.0;
      });
    });
    _startBannerAutoplay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerController.dispose();
    _bannerAutoTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchCounts();
    }
  }

  Future<void> _fetchCounts() async {
    if (!mounted) return;
    setState(() => _loadingCounts = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loadingCounts = false);
      return;
    }

    try {
      final mealCount = await Supabase.instance.client
        .from('meal_plans')
          .select('id')
          .eq('user_id', user.id)
          .count();

    if (!mounted) return;
    setState(() {
        _mealPlanCount = mealCount.count;
      _loadingCounts = false;
    });
    } catch (e) {
      print('Error fetching counts: $e');
      if (!mounted) return;
      setState(() => _loadingCounts = false);
    }
  }

  void _startBannerAutoplay() {
    _bannerAutoTimer?.cancel();
    final total = _getNutritionTips().length;
    if (total <= 1) return;
    _bannerAutoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_bannerController.hasClients) {
      final current = (_bannerController.page ?? 0).round();
      final next = (current + 1) % total;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.forceMealPlanRefresh && !_didForceRefresh) {
      if (!mounted) return;
      setState(() {
        _didForceRefresh = true;
      });
      _fetchCounts();
    }
  }

  Future<void> _fetchRecentMeals() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('first_name')
          .eq('id', user.id)
          .single();

      if (!mounted) return;
      setState(() {
        userName = response['first_name'] ?? 'User';
      });
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _selectedIndex == 0 ? AppBar(
        title: const Text(
          'NutriPlan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ) : null,
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        mealPlanCount: _mealPlanCount,
        isSmallScreen: MediaQuery.of(context).size.width < 600,
        onAddMealPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecipesPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const MealPlannerScreen();
      case 3:
        return const MealTrackerScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 20),
            _buildSmartSuggestionsSection(),
            const SizedBox(height: 20),
            _buildSectionHeader('Meal Categories', showSeeAll: true, onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AllMealCategoriesPage(),
                ),
              );
            }),
              const SizedBox(height: 12),
              _buildMealCategories(),
              const SizedBox(height: 20),
            _buildSectionHeader('Recent Activity', showSeeAll: false),
              const SizedBox(height: 12),
              _buildRecentActivity(),
            ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showSeeAll = true, VoidCallback? onSeeAll}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showSeeAll)
            TextButton(
                onPressed: onSeeAll ?? () async {
                await Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => RecipesPage(onChanged: _fetchCounts),
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
                child: const Text('See More'),
              ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildBanner() {
    final nutritionTips = _getNutritionTips();
    return SizedBox(
      height: 180,
      child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _bannerController,
              itemCount: nutritionTips.length,
                    itemBuilder: (context, index) {
                final tip = nutritionTips[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tip['gradientColors'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                        Text(
                          'Welcome back, $userName! 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tip['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                                    child: Text(
                            tip['description'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
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
          const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              nutritionTips.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                      decoration: BoxDecoration(
                  color: _bannerPage.round() == index ? Colors.green : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
            ),
                ),
              ],
            ),
    );
  }

  Widget _buildSmartSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Smart Meal Suggestions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SmartSuggestionsPage(),
          ),
        );
      },
              icon: const Icon(Icons.lightbulb_outline, size: 16),
              label: const Text('Get Suggestions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
          child: Column(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 48,
                color: Colors.green[300],
              ),
              const SizedBox(height: 12),
              Text(
                'Get Personalized Meal Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
                          Text(
                'AI-powered recommendations based on your nutrition goals and eating patterns',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SmartSuggestionsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View Suggestions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCategories() {
    final categories = [
      // Categories in alphabetical order
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: 4, // Show only first 4 categories
        itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
          return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilteredRecipesPage(
              category: category['category'],
              categoryName: category['name'],
            ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            if (category['assetType'] == 'gif')
              Image.asset(
                category['asset'],
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              )
            else
              Image.asset(
                category['asset'],
                width: 100,
                height: 100,
                      fit: BoxFit.contain,
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
                child: Text(
                category['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                    ),
                  ],
              ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
        borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
                          Text(
                'Your Meal Plans',
                            style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
          const SizedBox(height: 12),
          if (_loadingCounts)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildActivityItem(
                    'Total Plans',
                    _mealPlanCount.toString(),
                    Icons.restaurant_menu,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActivityItem(
                    'This Week',
                    '0', // You can implement this later
                    Icons.calendar_today,
                    Colors.green,
                  ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                  style: TextStyle(
                  fontSize: 18,
                    fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
        ),
      ],
    ),
        ],
    ),
  );
}

  List<Map<String, dynamic>> _getNutritionTips() {
    return [
      {
        'title': 'Stay Hydrated! 💧',
        'description': 'Drink at least 8 glasses of water daily to maintain optimal health and energy levels.',
        'gradientColors': [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
      },
      {
        'title': 'Balanced Nutrition 🥗',
        'description': 'Include a variety of fruits, vegetables, proteins, and whole grains in your daily meals.',
        'gradientColors': [const Color(0xFF2196F3), const Color(0xFF03DAC6)],
      },
      {
        'title': 'Regular Exercise 🏃‍♂️',
        'description': 'Aim for at least 30 minutes of physical activity daily to boost your metabolism and mood.',
        'gradientColors': [const Color(0xFFFF9800), const Color(0xFFFFC107)],
      },
    ];
  }
}
