import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'meal_planner_screen.dart';
import 'profile_screen.dart';
import '../main.dart'; // Import for ResponsiveDesign utilities
import 'favorites_page.dart'; // Added import for FavoritesPage
import 'package:supabase_flutter/supabase_flutter.dart'; // Added import for Supabase
import '../services/recipe_service.dart'; // Import RecipeService for favorite count

class HomePage extends StatefulWidget {
  final bool forceMealPlanRefresh;
  const HomePage({super.key, this.forceMealPlanRefresh = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  late List<Widget> _pages;
  bool _didForceRefresh = false;

  int _mealPlanCount = 0;~
  int _favoriteCount = 0;
  bool _loadingCounts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = [
      MealPlannerScreen(forceRefresh: widget.forceMealPlanRefresh, onChanged: _fetchCounts),
      const AnalyticsPage(),
      FavoritesPage(onChanged: _fetchCounts),
      const ProfileScreen(),
    ];
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
    setState(() => _loadingCounts = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
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
    setState(() {
      _mealPlanCount = mealCount;
      _favoriteCount = favoriteIds.length;
      _loadingCounts = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.forceMealPlanRefresh && !_didForceRefresh) {
      setState(() {
        _pages[0] = MealPlannerScreen(forceRefresh: true);
        _didForceRefresh = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);
    final isMediumScreen = ResponsiveDesign.isMediumScreen(context);
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
          if (_selectedIndex == 0) ...[
            Padding(
              padding: ResponsiveDesign.responsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to NutriPlan!',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: ResponsiveDesign.responsiveFontSize(context, 24),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        Text(
                          'Your smart companion for healthy meal planning',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                            fontSize: ResponsiveDesign.responsiveFontSize(context, 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _fetchCounts();
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
          _buildBottomNavItem(Icons.restaurant_menu, 'Meal Plan', 0, badgeCount: _mealPlanCount),
          _buildBottomNavItem(Icons.analytics, 'Analytics', 1),
          _buildBottomNavItem(Icons.favorite, 'Favorites', 2, badgeCount: _favoriteCount),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: isSmallScreen ? 14 : 16,
              backgroundColor: Colors.grey[200],
              child: Icon(Icons.person, color: Colors.grey[700], size: isSmallScreen ? 18 : 20),
            ),
            label: 'Profile',
          ),
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
              top: -5,
              right: -10, // Move badge to top-right
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 252, 65, 51),
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
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

// Rename DashboardPage to AnalyticsPage
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);
    final isMediumScreen = ResponsiveDesign.isMediumScreen(context);
    
    return SingleChildScrollView(
      padding: ResponsiveDesign.responsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analytics Chart Section (moved from MealPlannerScreen)
                  Row(
                    children: [
                      // Line Chart: Calorie Intake
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromRGBO(142, 190, 155, 1.0),
                                Color.fromRGBO(125, 189, 228, 1.0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          height: isSmallScreen ? 160 : 180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calories (7 days)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: ResponsiveDesign.responsiveFontSize(context, 14),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                            return Text(
                                              days[value.toInt() % 7], 
                                              style: TextStyle(
                                                fontSize: ResponsiveDesign.responsiveFontSize(context, 10),
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                          interval: 1,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: 6,
                                    minY: 0,
                                    maxY: 2500,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: [
                                          FlSpot(0, 1800),
                                          FlSpot(1, 2000),
                                          FlSpot(2, 1700),
                                          FlSpot(3, 2200),
                                          FlSpot(4, 1900),
                                          FlSpot(5, 2100),
                                          FlSpot(6, 1850),
                                        ],
                                        isCurved: true,
                                        color: Colors.white,
                                        barWidth: 3,
                                        dotData: FlDotData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveDesign.responsiveSpacing(context)),
                      // Pie Chart: Macronutrient Breakdown
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromRGBO(142, 190, 155, 1.0),
                                Color.fromRGBO(125, 189, 228, 1.0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          height: isSmallScreen ? 160 : 180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Macros Today',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: ResponsiveDesign.responsiveFontSize(context, 14),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                        value: 250,
                                        color: Colors.blueAccent,
                                        title: 'Carbs',
                                        radius: isSmallScreen ? 32 : 36,
                                        titleStyle: TextStyle(
                                          fontSize: ResponsiveDesign.responsiveFontSize(context, 10), 
                                          color: Colors.white,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: 75,
                                        color: Colors.green,
                                        title: 'Protein',
                                        radius: isSmallScreen ? 32 : 36,
                                        titleStyle: TextStyle(
                                          fontSize: ResponsiveDesign.responsiveFontSize(context, 10), 
                                          color: Colors.white,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: 50,
                                        color: Colors.orange,
                                        title: 'Fats',
                                        radius: isSmallScreen ? 32 : 36,
                                        titleStyle: TextStyle(
                                          fontSize: ResponsiveDesign.responsiveFontSize(context, 10), 
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                    sectionsSpace: 2,
                                    centerSpaceRadius: isSmallScreen ? 16 : 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          SizedBox(height: ResponsiveDesign.responsiveSpacing(context) * 2),

          // Features Grid
          Text(
            'Features (NO FUNCTIONALITY YET)',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 8, 8, 8),
              fontSize: ResponsiveDesign.responsiveFontSize(context, 24),
            ),
          ),
          SizedBox(height: ResponsiveDesign.responsiveSpacing(context)),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: ResponsiveDesign.responsiveSpacing(context),
            mainAxisSpacing: ResponsiveDesign.responsiveSpacing(context),
            childAspectRatio: isSmallScreen ? 1.0 : 1.1,
            children: [
              _FeatureCard(
                title: 'Suggestions',
                description: 'Discover new meals',
                icon: Icons.lightbulb,
                color: Colors.amber,
                onTap: () {
                  // TODO: Navigate to suggestions
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meal Suggestions coming soon!')),
                  );
                },
              ),
              _FeatureCard(
                title: 'Meal Tracker',
                description: 'Log your daily intake',
                icon: Icons.track_changes,
                color: Colors.red,
                onTap: () {
                  // TODO: Navigate to meal tracker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meal Tracker coming soon!')),
                  );
                },
              ),
              _FeatureCard(
                title: 'Analytics',
                description: 'Track your progress',
                icon: Icons.analytics,
                color: Colors.teal,
                onTap: () {
                  // TODO: Navigate to analytics
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Analytics coming soon!')),
                  );
                },
              ),
              _FeatureCard(
                title: 'Feedback',
                description: 'Share your thoughts',
                icon: Icons.feedback,
                color: Colors.purple,
                onTap: () {
                  // TODO: Navigate to feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback coming soon!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 