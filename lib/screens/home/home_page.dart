import 'package:flutter/material.dart';
import 'dart:async';
import '../meal_plan/meal_planner_screen.dart';
import '../profile/profile_screen.dart';
import '../../utils/responsive_design.dart'; 
import '../tracking/meal_tracker_screen.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/bottom_navigation.dart'; 
import '../recipes/recipes_page.dart';
import '../../models/recipes.dart';
import '../../services/recipe_service.dart';

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
  bool _loadingRecipes = false;
  List<Recipe> _recipes = [];
  final PageController _bannerController = PageController(viewportFraction: 0.88);
  double _bannerPage = 0.0;
  Timer? _bannerAutoTimer;

  // Scroll offset for transparency effect
  double _scrollOffset = 0.0;
  static const double _maxScrollOffset = 100.0; // Distance to reach full transparency

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialTab;
    _fetchUserName(); // Fetch the user's name from Supabase
    _fetchCounts();
    _fetchRecipes();
    _bannerController.addListener(() {
      setState(() {
        _bannerPage = _bannerController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerController.dispose();
    _bannerAutoTimer?.cancel();
    super.dispose();
  }

  void _onScroll(double offset) {
    setState(() {
      _scrollOffset = offset;
    });
  }

  // Calculate opacity based on scroll position
  double get _appBarOpacity {
    final progress = (_scrollOffset / _maxScrollOffset).clamp(0.0, 1.0);
    return 1.0 - (progress * 0.8); // Start at 1.0, go down to 0.2
  }

  double get _bottomNavOpacity {
    final progress = (_scrollOffset / _maxScrollOffset).clamp(0.0, 1.0);
    return 1.0 - (progress * 0.6); // Start at 1.0, go down to 0.4
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
      setState(() {
        _mealPlanCount = 0;
        _loadingCounts = false;
      });
      return;
    }
    // Fetch meal plan count - each record is now a separate meal
    final mealPlans = await Supabase.instance.client
        .from('meal_plans')
        .select()
        .eq('user_id', user.id);
    int mealCount = mealPlans.length; // Each record is a meal
    if (!mounted) return;
    setState(() {
      _mealPlanCount = mealCount;
      _loadingCounts = false;
    });
  }

  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('username')
        .eq('id', user.id)
        .maybeSingle();
    if (profile != null && profile['username'] != null) {
      final fullName = profile['username'] as String;
      final firstName = fullName.split(' ').first;
      if (!mounted) return;
      setState(() {
        userName = firstName;
      });
    }
  }

  Future<void> _fetchRecipes() async {
    setState(() => _loadingRecipes = true);
    try {
      final list = await RecipeService.fetchRecipes();
      if (!mounted) return;
      setState(() {
        _recipes = list;
        _loadingRecipes = false;
      });
      _startBannerAutoplay();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRecipes = false);
    }
  }

  void _startBannerAutoplay() {
    _bannerAutoTimer?.cancel();
    final total = _recipes.take(5).length;
    if (total <= 1) return;
    _bannerAutoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final current = (_bannerController.page ?? 0).round();
      final next = (current + 1) % total;
      if (_bannerController.hasClients) {
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
    }
  }

  // _buildHeroSection removed per latest design; greeting banner replaced
  // _buildBadge removed as badges are no longer displayed

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0FFF4), Color(0xFFE6F3FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 20),
              _buildSectionHeader('Recipe Features'),
              const SizedBox(height: 12),
              _buildFeaturesGrid(),
              const SizedBox(height: 20),
              _buildSectionHeader('Best Sales'),
              const SizedBox(height: 12),
              _buildBestSalesList(),
              const SizedBox(height: 20),
              _buildRecentActivity(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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
            TextButton(
              onPressed: () async {
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
              child: const Text('See All'),
            )
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 4,
          width: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF58A872), Color(0xFF4E9DD6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    final bannerItems = _recipes.take(5).toList();
    return SizedBox(
      height: 160,
      child: bannerItems.isEmpty
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF58A872), Color(0xFF4E9DD6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(Icons.ramen_dining, color: Colors.white, size: 36),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _bannerController,
                    physics: const BouncingScrollPhysics(),
                    allowImplicitScrolling: true,
                    clipBehavior: Clip.none,
                    itemCount: bannerItems.length,
                    itemBuilder: (context, index) {
                      final recipe = bannerItems[index];
                      final distance = (_bannerPage - index).abs().clamp(0.0, 1.0);
                      final scale = 0.92 + (1 - distance) * 0.08; // 0.92..1.00
                      final opacity = 0.6 + (1 - distance) * 0.4;   // 0.6..1.0

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10 * opacity),
                                  blurRadius: 8 + (1 - distance) * 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  recipe.imageUrl.isNotEmpty
                                      ? Image.network(
                                          recipe.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image))),
                                        )
                                      : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image, color: Colors.grey))),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 12,
                                    bottom: 12,
                                    right: 12,
                                    child: Text(
                                      recipe.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(bannerItems.length, (i) {
                    final active = _bannerPage.round() == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 10 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF58A872) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(100),
                      ),
                    );
                  }),
                ),
              ],
            ),
    );
  }

  Widget _buildFeaturesGrid() {
    if (_loadingRecipes) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = _recipes;
    if (items.isEmpty) {
      return const Text('No recipes available');
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        return _buildFeatureCard(r);
      },
    );
  }

  Widget _buildFeatureCard(Recipe recipe) {
    return GestureDetector(
      onTap: () async {
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              recipe.imageUrl.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                    )
                  : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.ramen_dining, size: 36, color: Colors.grey))),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            recipe.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text('₱${recipe.cost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBestSalesList() {
    final items = _recipes.take(10).toList();
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          if (items.isEmpty) {
            return Container();
          }
          final recipe = items[index];
          return GestureDetector(
            onTap: () async {
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
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    recipe.imageUrl.isNotEmpty
                        ? Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
                          )
                        : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image, color: Colors.grey))),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            recipe.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text('₱${recipe.cost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }

  // Search bar, Quick Actions, and Why NutriPlan sections removed per request

  // Explore Recipes and How it works sections removed per request

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _loadingCounts
              ? Row(
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.green[400],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading activity...',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meal Plans',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '$_mealPlanCount active meals',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // CTA removed per request

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);


  List<Widget> pages = [
    _buildHomeContent(),
    MealPlannerScreen(
      forceRefresh: widget.forceMealPlanRefresh,
      onChanged: _fetchCounts,
    ),
    const MealTrackerScreen(),
    const ProfileScreen(),
  ];

  return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size.fromHeight(isSmallScreen ? 70 : 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _appBarOpacity,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _appBarOpacity),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1 * _appBarOpacity),
                    blurRadius: 8 * _appBarOpacity,
                    offset: Offset(0, 2 * _appBarOpacity),
                  ),
                ],
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  'NutriPlan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        ResponsiveDesign.responsiveFontSize(context, 20),
                    color: Colors.black87,
                  ),
                ),
                centerTitle: true,
                actions: [],
              ),
            ),
          ),
          Container(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.25),
          ),
        ],
      ),
    ),
    backgroundColor: Colors.grey[50],
    body: Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                _onScroll(notification.metrics.pixels);
              }
              return false;
            },
            child: pages[_selectedIndex],
          ),
        ),
      ],
    ),
    floatingActionButton: _selectedIndex == 0
        ? FloatingActionButton(
            onPressed: () async {
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
              // Ensure counts refresh in case onChanged wasn't triggered
              await _fetchCounts();
            },
            backgroundColor: const Color.fromARGB(255, 81, 209, 87),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          )
        : null,
    bottomNavigationBar: BottomNavigation(
      selectedIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      mealPlanCount: _mealPlanCount,
      opacity: _bottomNavOpacity,
      isSmallScreen: isSmallScreen,
    ),
  );
}
}