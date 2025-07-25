import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'meal_planner_screen.dart';
import 'profile_screen.dart';
import 'analytics_page.dart';
import '../main.dart'; // Import for ResponsiveDesign utilities
import 'favorites_page.dart'; // Added import for FavoritesPage
import 'package:supabase_flutter/supabase_flutter.dart'; // Added import for Supabase
import '../services/recipe_service.dart'; // Import RecipeService for favorite count

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
  int _favoriteCount = 0;
  bool _loadingCounts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialTab;
    _fetchUserName(); // Fetch the user's name from Supabase
    _fetchCounts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      setState(() {
        _mealPlanCount = 0;
        _favoriteCount = 0;
        _loadingCounts = false;
      });
      return;
    }
    // Fetch meal plan count
    final mealPlans = await Supabase.instance.client
        .from('meal_plans')
        .select()
        .eq('user_id', user.id);
    int mealCount = 0;
    for (final plan in mealPlans) {
      final meals = List<Map<String, dynamic>>.from(plan['meals'] ?? []);
      mealCount += meals.length;
    }
    // Fetch favorite count using RecipeService
    final favoriteIds = await RecipeService.fetchFavoriteRecipeIds(user.id);
    if (!mounted) return;
    setState(() {
      _mealPlanCount = mealCount;
      _favoriteCount = favoriteIds.length;
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

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);
    final isMediumScreen = ResponsiveDesign.isMediumScreen(context);
    List<Widget> pages = [
      HomePageContent(
        userName: userName,
        onQuickAction: (int tabIndex) {
          setState(() {
            _selectedIndex = tabIndex;
          });
        },
      ),
      MealPlannerScreen(forceRefresh: widget.forceMealPlanRefresh, onChanged: _fetchCounts),
      AnalyticsPage(),
      FavoritesPage(onChanged: _fetchCounts),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isSmallScreen ? 70 : 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'NutriPlan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveDesign.responsiveFontSize(context, 20),
                  color: Colors.black87,
                ),
              ),
              centerTitle: true,
              actions: [],
            ),
            Container(
              height: 1,
              color: Colors.grey.withOpacity(0.25),
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 193, 231, 175),
      body: Column(
        children: [
          if (_selectedIndex == 0)
            Expanded(child: pages[0])
          else
            Expanded(child: pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        unselectedItemColor: const Color.fromARGB(255, 136, 136, 136),
        selectedItemColor: Colors.green,
        iconSize: isSmallScreen ? 22 : 24,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: ResponsiveDesign.responsiveFontSize(context, 12),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: ResponsiveDesign.responsiveFontSize(context, 12),
        ),
        items: [
          _buildBottomNavItem(Icons.home, 'Home', 0),
          _buildBottomNavItem(Icons.restaurant_menu, 'Meal Plan', 1, badgeCount: _mealPlanCount),
          _buildBottomNavItem(Icons.analytics, 'Analytics', 2),
          _buildBottomNavItem(Icons.favorite, 'Favorites', 3, badgeCount: _favoriteCount),
          _buildBottomNavItem(Icons.person, 'Profile', 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
      IconData icon, String label, int index, {int badgeCount = 0}) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: index == _selectedIndex
                    ? [
                        Color.fromRGBO(142, 190, 155, 1.0),
                        Color.fromRGBO(125, 189, 228, 1.0),
                      ]
                    : [Colors.grey, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Icon(icon, color: Colors.white),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -6,
              right: -12,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(100),
                ),
                constraints: const BoxConstraints(
                  minWidth: 21,
                  minHeight: 15,
                ),
                child: Center(
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      label: label,
    );
  }
}