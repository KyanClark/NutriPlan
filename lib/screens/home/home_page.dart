import 'package:flutter/material.dart';
import '../meal_plan/meal_planner_screen.dart';
import '../profile/profile_screen.dart';
import '../../utils/responsive_design.dart'; 
import '../tracking/meal_tracker_screen.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/bottom_navigation.dart'; 

class HomePage extends StatefulWidget {
  final bool forceMealPlanRefresh;
  final int initialTab;
  const HomePage({super.key, this.forceMealPlanRefresh = false, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}
//try

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String userName = ""; // Start empty, will fetch from Supabase
  late int _selectedIndex;

  bool _didForceRefresh = false;

  int _mealPlanCount = 0;
  bool _loadingCounts = false;

  // Scroll offset for transparency effect
  double _scrollOffset = 0.0;
  static const double _maxScrollOffset = 100.0; // Distance to reach full transparency
  
  // Keys for each screen to force rebuild when navigation changes
  final List<GlobalKey> _pageKeys = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
  ];

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

  void _onScroll(double offset) {
    setState(() {
      _scrollOffset = offset;
    });
  }

  // Reset scroll offset for glass morphism when switching main navigation tabs
  void _resetScrollOffsetForTab(int newIndex) {
    // Force rebuild of the target screen to reset its scroll state
    if (newIndex < _pageKeys.length) {
      final key = _pageKeys[newIndex];
      if (key.currentState != null) {
        // Trigger a rebuild by updating the key
        setState(() {});
      }
    }
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

  Widget _buildHomeContent({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Create Meal Plan',
                Icons.restaurant_menu,
                Colors.green,
                () => setState(() => _selectedIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                'Track Meals',
                Icons.track_changes,
                Colors.blue,
                () => setState(() => _selectedIndex = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

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
          child: Row(
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

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);

  List<Widget> pages = [
    _buildHomeContent(key: _pageKeys[0]),
    MealPlannerScreen(
      key: _pageKeys[1],
      forceRefresh: widget.forceMealPlanRefresh,
      onChanged: _fetchCounts,
    ),
    MealTrackerScreen(
      key: _pageKeys[2],
      onTabActivated: () {
        // This callback is called when MealTrackerScreen is activated
        // The scroll offset is already reset in the screen itself
      },
    ),
    ProfileScreen(
      key: _pageKeys[3],
    ),
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
    bottomNavigationBar: BottomNavigation(
      selectedIndex: _selectedIndex,
      onTap: (index) {
        if (index != _selectedIndex) {
          // Reset scroll offset for glass morphism when switching main navigation tabs
          _resetScrollOffsetForTab(index);
        }
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