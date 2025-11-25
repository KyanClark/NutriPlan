import 'package:flutter/material.dart';
import 'dart:async';
import '../meal_plan/meal_planner_screen.dart';
import '../meal_plan/meal_planning_options_page.dart';
import '../analytics/analytics_page.dart';
import '../tracking/meal_tracker_screen.dart';
import '../profile/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/bottom_navigation.dart';
import '../recipes/recipes_page.dart';
import '../recipes/filtered_recipes_page.dart';
import '../meal suggestions/smart_suggestions_page.dart';
import 'meal_categories_page.dart';

class HomePage extends StatefulWidget {
  final bool forceMealPlanRefresh;
  final int initialTab;
  const HomePage({super.key, this.forceMealPlanRefresh = false, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Profile icon widget that maintains its own state to prevent unnecessary rebuilds
class _ProfileIconWidget extends StatefulWidget {
  const _ProfileIconWidget({super.key});

  @override
  State<_ProfileIconWidget> createState() => _ProfileIconWidgetState();
}

class _ProfileIconWidgetState extends State<_ProfileIconWidget> {
  static String? _cachedAvatarUrl;
  static bool _hasFetchedAvatar = false;

  @override
  void initState() {
    super.initState();
    // Only fetch if never fetched before
    if (!_hasFetchedAvatar) {
      _fetchUserAvatar();
    }
  }

  String? get _avatarUrl => _cachedAvatarUrl;

  void refreshAvatar() {
    _fetchUserAvatar();
  }

  Future<void> _fetchUserAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      
      // Update cached value
      _cachedAvatarUrl = data?['avatar_url'] as String?;
      _hasFetchedAvatar = true;
      
      if (mounted) {
        setState(() {
          // Trigger rebuild with new cached value
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _onTap() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
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
    // Refresh avatar when returning from profile screen
    refreshAvatar();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 80, 231, 93),
            shape: BoxShape.circle,
          ),
          child: _avatarUrl != null && _avatarUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: NetworkImage(_avatarUrl!),
                )
              : CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey, size: 20),
                ),
        ),
      ),
    );
  }
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String userName = "";
  late int _selectedIndex;
  final GlobalKey<State<BottomNavigation>> _bottomNavKey = GlobalKey<State<BottomNavigation>>();
  final GlobalKey<_ProfileIconWidgetState> _profileIconKey = GlobalKey<_ProfileIconWidgetState>();
  final GlobalKey _homeContentKey = GlobalKey();
  final GlobalKey _mealPlannerKey = GlobalKey();
  final GlobalKey _mealTrackerKey = GlobalKey();
  final GlobalKey _analyticsKey = GlobalKey();

  bool _didForceRefresh = false;

  int _mealPlanCount = 0;
  bool _loadingCounts = false;
  double _bannerPage = 0.0;
  final PageController _bannerController = PageController(viewportFraction: 0.88);
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
      // Only count meal plans for today's date
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final response = await Supabase.instance.client
          .from('meal_plans')
          .select('*')
          .eq('user_id', user.id)
          .eq('date', todayStr);

      final mealCount = response.length;

      if (!mounted) return;
      setState(() {
        _mealPlanCount = mealCount;
        _loadingCounts = false;
      });
    } catch (e) {
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
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text(
                'NutriPlan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              actions: [
                _ProfileIconWidget(key: _profileIconKey),
              ],
            )
          : null,
      body: _getSelectedScreen(),
      bottomNavigationBar: RepaintBoundary(
        child: BottomNavigation(
          key: _bottomNavKey,
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
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const MealPlanningOptionsPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return RepaintBoundary(
          key: _homeContentKey,
          child: _buildHomeContent(),
        );
      case 1:
        return RepaintBoundary(
          key: _mealPlannerKey,
          child: MealPlannerScreen(
            onChanged: () {
              // Refresh meal counts when meals are added/deleted
              _fetchCounts();
            },
          ),
        );
      case 3:
        return RepaintBoundary(
          key: _mealTrackerKey,
          child: const MealTrackerScreen(),
        );
      case 4:
        return RepaintBoundary(
          key: _analyticsKey,
          child: const AnalyticsPage(),
        );
      default:
        return RepaintBoundary(
          key: _homeContentKey,
          child: _buildHomeContent(),
        );
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

  Widget _buildSectionHeader(String title,
      {bool showSeeAll = true, VoidCallback? onSeeAll}) {
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
                onPressed: onSeeAll ??
                    () async {
                      await Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  RecipesPage(onChanged: _fetchCounts),
                          transitionsBuilder: (context, animation,
                              secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;
                            final tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
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
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _bannerController,
              itemCount: nutritionTips.length,
              itemBuilder: (context, index) {
                final tip = nutritionTips[index];
                
                if (tip['type'] == 'interactive_recipe') {
                  return _buildInteractiveRecipeBanner(tip);
                } else if (tip['type'] == 'stay_hydrated') {
                  return _buildStayHydratedBanner(tip);
                } else {
                  return _buildNutritionTipBanner(tip);
                }
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
                  color: _bannerPage.round() == index
                      ? Colors.green
                      : Colors.grey[300],
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
        const Text(
          'Smart Meal Suggestions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2)    ,
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
                'Discover meals designed around your nutrition goals and daily eating patterns.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SmartSuggestionsPage(),
                    ),
                  );
                },
                child: const Text('View Suggestions'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCategories() {
    final categories = [
      {'name': 'Beef', 'asset': 'assets/widgets/beef_category.gif', 'category': 'beef'},
      {'name': 'Chicken', 'asset': 'assets/widgets/chicken_category.gif', 'category': 'chicken'},
      {'name': 'Desserts', 'asset': 'assets/widgets/soup-vid.gif', 'category': 'desserts'},
      {'name': 'Fish', 'asset': 'assets/widgets/fish.png', 'category': 'fish'},
      {'name': 'Pork', 'asset': 'assets/widgets/pork.png', 'category': 'pork'},
      {'name': 'Silog Meals', 'asset': 'assets/widgets/silog-meals.jpg', 'category': 'silog'},
      {'name': 'Soup', 'asset': 'assets/widgets/soup-vid.gif', 'category': 'soup'},
      {'name': 'Vegetable', 'asset': 'assets/widgets/vegetable_category.gif', 'category': 'vegetable'},
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
      itemCount: 4,
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
            Image.asset(
              category['asset'],
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              category['name'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
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
          Text(
            'Your Meal Plans',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingCounts)
            const Center(child: CircularProgressIndicator())
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
                    '0',
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
      child: Column(
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
    );
  }

  Widget _buildInteractiveRecipeBanner(Map<String, dynamic> banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                banner['imagePath'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: banner['gradientColors'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner['description'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTipBanner(Map<String, dynamic> tip) {
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
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getNutritionTips() {
    return [
      {
        'type': 'interactive_recipe',
        'title': 'Interactive Recipes at Your Fingertips',
        'description': 'Follow step-by-step cooking guides with built-in timers and progress tracking. Never lose your place in a recipe again.',
        'imagePath': 'assets/widgets/interactive_recipe_banner.jpg',
        'gradientColors': [const Color(0xFF6A4C93), const Color(0xFF9C27B0)],
      },
      {
        'type': 'stay_hydrated',
        'title': 'Stay Hydrated! 💧',
        'description':
            'Drink at least 8 glasses of water daily to maintain optimal health and energy levels.',
        'imagePath': 'assets/widgets/stay_hydrated_banner.jpg',
        'gradientColors': [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
      },
      {
        'type': 'tip',
        'title': 'Balanced Nutrition 🥗',
        'description':
            'Include a variety of fruits, vegetables, proteins, and whole grains in your daily meals.',
        'gradientColors': [const Color(0xFF2196F3), const Color(0xFF03DAC6)],
      },
      {
        'type': 'tip',
        'title': 'Regular Exercise 🏃‍♂️',
        'description':
            'Aim for at least 30 minutes of physical activity daily to boost your metabolism and mood.',
        'gradientColors': [const Color(0xFFFF9800), const Color(0xFFFFC107)],
      },
    ];
  }

  Widget _buildStayHydratedBanner(Map<String, dynamic> banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                banner['imagePath'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: banner['gradientColors'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Gradient overlay for better text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Geist',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    banner['description'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.normal,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
