import 'package:flutter/material.dart';
import 'meal_planner_screen.dart';
import 'profile_screen.dart';
import 'analytics_page.dart';
import '../utils/responsive_design.dart'; 
import 'meal_tracker_screen.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_navigation.dart'; 

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

  // Scroll controller for transparency effect
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;
  static const double _maxScrollOffset = 100.0; // Distance to reach full transparency

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialTab;
    _fetchUserName(); // Fetch the user's name from Supabase
    _fetchCounts();
    
    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
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


  List<Widget> pages = [
    HomePageContent(
      userName: userName,
      onQuickAction: (int tabIndex) {
        setState(() {
          _selectedIndex = tabIndex;
        });
      },
    ),
    MealPlannerScreen(
      forceRefresh: widget.forceMealPlanRefresh,
      onChanged: _fetchCounts,
    ),
    AnalyticsPage(),
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
                _onScroll();
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