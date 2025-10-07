import 'package:flutter/material.dart';
import 'dart:async';
import '../meal_plan/meal_planner_screen.dart';
import '../profile/profile_screen.dart';
import '../../utils/responsive_design.dart'; 
import '../tracking/meal_tracker_screen.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/bottom_navigation.dart'; 
import '../recipes/recipes_page.dart';
import '../recipes/filtered_recipes_page.dart';
import '../../models/smart_suggestion_models.dart';
import '../../models/meal_history_entry.dart';
import '../../services/smart_meal_suggestion_service.dart';
import '../../services/api_cache_service.dart';
import '../recipes/recipe_info_screen.dart';
import '../../widgets/smart_suggestions_loading_animation.dart';
import '../meal_plan/meal_summary_page.dart';
import '../../models/recipes.dart';

class HomePage extends StatefulWidget {
  final bool forceMealPlanRefresh;
  final int initialTab;
  const HomePage({super.key, this.forceMealPlanRefresh = false, this.initialTab = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}
//main
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String userName = ""; // Start empty, will fetch from Supabase
  late int _selectedIndex;

  bool _didForceRefresh = false;

  int _mealPlanCount = 0;
  bool _loadingCounts = false;
  bool _loadingSuggestions = false;
  List<SmartMealSuggestion> _smartSuggestions = [];
  final PageController _bannerController = PageController(viewportFraction: 0.88);
  double _bannerPage = 0.0;
  Timer? _bannerAutoTimer;
  List<Recipe> _recentMeals = [];


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialTab;
    _fetchCounts();
    _fetchSmartSuggestions();
    _fetchRecentMeals();
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


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchCounts();
      _fetchSmartSuggestions();
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

  Future<void> _fetchSmartSuggestions() async {
    if (!mounted) return;
    setState(() => _loadingSuggestions = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
      if (!mounted) return;
      setState(() {
          _smartSuggestions = [];
          _loadingSuggestions = false;
        });
        return;
      }

      // Get suggestions for the current meal time
      final now = DateTime.now();
      MealCategory currentMealCategory;
      if (now.hour < 11) {
        currentMealCategory = MealCategory.breakfast;
      } else if (now.hour < 15) {
        currentMealCategory = MealCategory.lunch;
      } else if (now.hour < 20) {
        currentMealCategory = MealCategory.dinner;
      } else {
        currentMealCategory = MealCategory.snack;
      }

      // Generate cache key
      final cacheKey = APICacheService.generateSmartSuggestionsKey(
        user.id, 
        currentMealCategory.toString(), 
        now
      );

      // Check cache first
      final cachedSuggestions = APICacheService().get<List<SmartMealSuggestion>>(cacheKey);
      if (cachedSuggestions != null) {
        print('Using cached smart suggestions');
        if (!mounted) return;
        setState(() {
          _smartSuggestions = cachedSuggestions;
          _loadingSuggestions = false;
      });
      _startBannerAutoplay();
        return;
      }

      // Test AI integration first (with caching)
      final aiTestKey = APICacheService.generateAITestKey();
      bool aiWorking = APICacheService().get<bool>(aiTestKey) ?? false;
      
      if (!APICacheService().has(aiTestKey)) {
        aiWorking = await SmartMealSuggestionService.testAIIntegration();
        APICacheService().set(aiTestKey, aiWorking, duration: const Duration(minutes: 10));
        print('AI Integration Status: ${aiWorking ? "Working" : "Failed"}');
      } else {
        print('Using cached AI test result: ${aiWorking ? "Working" : "Failed"}');
      }

      // Fetch fresh suggestions
      final suggestions = await SmartMealSuggestionService.getSmartSuggestions(
        userId: user.id,
        mealCategory: currentMealCategory,
        targetTime: now,
        useAI: aiWorking, // Only use AI if it's working
      );

      // Cache the suggestions
      APICacheService().set(cacheKey, suggestions, duration: const Duration(minutes: 5));

      if (!mounted) return;
      setState(() {
        _smartSuggestions = suggestions;
        _loadingSuggestions = false;
      });
      _startBannerAutoplay();
    } catch (e) {
      print('Error fetching smart suggestions: $e');
      if (!mounted) return;
      setState(() {
        _smartSuggestions = [];
        _loadingSuggestions = false;
      });
      _startBannerAutoplay();
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
              _buildSectionHeader('Smart Meal Suggestions for You', showSeeAll: false),
              const SizedBox(height: 12),
              _buildSmartSuggestions(),
              const SizedBox(height: 20),
              _buildSectionHeader('Meal Categories'),
              const SizedBox(height: 12),
              _buildMealCategories(),
              const SizedBox(height: 20),
              _buildSectionHeader('Health-Oriented Categories'),
              const SizedBox(height: 12),
              _buildHealthCategories(),
              const SizedBox(height: 20),
              _buildRecentActivity(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showSeeAll = true}) {
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
              onPressed: () async {
                await Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => RecipesPage(onChanged: _fetchCounts),
                    transitionsBuilder:   (context, animation, secondaryAnimation, child) {
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
                    physics: const BouncingScrollPhysics(),
                    allowImplicitScrolling: true,
                    clipBehavior: Clip.none,
              itemCount: nutritionTips.length,
                    itemBuilder: (context, index) {
                final tip = nutritionTips[index];
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
                        gradient: LinearGradient(
                          colors: tip['gradientColors'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                              boxShadow: [
                                BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15 * opacity),
                                  blurRadius: 8 + (1 - distance) * 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                                children: [
                            // Icon
                                  SizedBox(
                              height: 44,
                              width: 44,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  tip['icon'],
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Tip text
                            Flexible(
                                    child: Text(
                                tip['tip'],
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Category label
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                                    child: Text(
                                tip['category'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
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
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(nutritionTips.length, (i) {
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

  List<Map<String, dynamic>> _getNutritionTips() {
    return [
      {
        'tip': '🍋 Hydration is key — drink water before meals to aid digestion.',
        'category': 'Hydration',
        'icon': Icons.water_drop,
        'gradientColors': [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
      },
      {
        'tip': '🥗 Fill half your plate with vegetables for better balance.',
        'category': 'Portion Control',
        'icon': Icons.eco,
        'gradientColors': [const Color(0xFF8BC34A), const Color(0xFF9CCC65)],
      },
      {
        'tip': '💤 Better sleep = better metabolism. Rest well, eat well.',
        'category': 'Lifestyle',
        'icon': Icons.bedtime,
        'gradientColors': [const Color(0xFF673AB7), const Color(0xFF7E57C2)],
      },
      {
        'tip': '🥑 Include healthy fats like avocado and nuts for brain health.',
        'category': 'Brain Health',
        'icon': Icons.psychology,
        'gradientColors': [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
      },
      {
        'tip': '🍎 Eat the rainbow — colorful fruits provide diverse nutrients.',
        'category': 'Variety',
        'icon': Icons.local_florist,
        'gradientColors': [const Color(0xFFE91E63), const Color(0xFFF06292)],
      },
      {
        'tip': '🏃‍♀️ Combine protein with carbs post-workout for muscle recovery.',
        'category': 'Fitness',
        'icon': Icons.fitness_center,
        'gradientColors': [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
      },
      {
        'tip': '🧘‍♀️ Mindful eating: chew slowly and savor each bite.',
        'category': 'Mindfulness',
        'icon': Icons.self_improvement,
        'gradientColors': [const Color(0xFF00BCD4), const Color(0xFF4DD0E1)],
      },
      {
        'tip': '🌱 Start your day with fiber-rich foods for sustained energy.',
        'category': 'Energy',
        'icon': Icons.wb_sunny,
        'gradientColors': [const Color(0xFFFFC107), const Color(0xFFFFD54F)],
      },
    ];
  }

  Widget _buildSmartSuggestions() {
    if (_loadingSuggestions) {
      return SmartSuggestionsLoadingAnimation(
        loadingMessage: 'Analyzing eating pattern...',
      );
    }
    
    if (_smartSuggestions.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: const Center(
            child: Text(
              'No suggestions available. Start tracking meals to get personalized recommendations!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _smartSuggestions.take(2).map((suggestion) => 
        _buildSmartSuggestionCard(suggestion)
      ).toList(),
    );
  }

  Widget _buildSmartSuggestionCard(SmartMealSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.of(context).push(
          PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => RecipeInfoScreen(
                recipe: suggestion.recipe,
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Recipe image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: suggestion.recipe.imageUrl.isNotEmpty
                  ? Image.network(
                            suggestion.recipe.imageUrl,
                      fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                          )
                        : const Icon(Icons.ramen_dining, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                // Recipe info
                Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                        suggestion.recipe.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        suggestion.reasoning,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildSuggestionTypeChip(suggestion.type),
                          const SizedBox(width: 8),
                          Text(
                            '₱${suggestion.recipe.cost.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionTypeChip(SuggestionType type) {
    Color chipColor;
    String chipText;
    IconData chipIcon;

    switch (type) {
      case SuggestionType.fillGap:
        chipColor = Colors.blue[100]!;
        chipText = 'Fill Gap';
        chipIcon = Icons.trending_up;
        break;
      case SuggestionType.perfectTiming:
        chipColor = Colors.green[100]!;
        chipText = 'Perfect Timing';
        chipIcon = Icons.access_time;
        break;
      case SuggestionType.userFavorites:
        chipColor = Colors.orange[100]!;
        chipText = 'Your Favorite';
        chipIcon = Icons.favorite;
        break;
      case SuggestionType.trySomethingNew:
        chipColor = Colors.purple[100]!;
        chipText = 'Try New';
        chipIcon = Icons.explore;
        break;
      case SuggestionType.healthBoost:
        chipColor = Colors.red[100]!;
        chipText = 'Health Boost';
        chipIcon = Icons.health_and_safety;
        break;
      case SuggestionType.budgetFriendly:
        chipColor = Colors.yellow[100]!;
        chipText = 'Budget';
        chipIcon = Icons.account_balance_wallet;
        break;
      case SuggestionType.quickPrep:
        chipColor = Colors.teal[100]!;
        chipText = 'Quick';
        chipIcon = Icons.speed;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 10, color: chipColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white),
          const SizedBox(width: 2),
          Text(
            chipText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: chipColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCategories() {
    final categories = [
      // Original categories
      {
        'name': 'Soup',
        'asset': 'assets/widgets/soup-vid.gif',
        'assetType': 'gif',
        'category': 'soup',
      },
      {
        'name': 'Fish & Seafood',
        'asset': 'assets/widgets/fish.png',
        'assetType': 'image',
        'category': 'fish_seafood',
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
        'category': 'egg_silog',
      },
      // New protein-based categories
      {
        'name': 'Poultry',
        'asset': 'assets/widgets/fish.png', // Using fish as placeholder
        'assetType': 'image',
        'category': 'chicken',
      },
      {
        'name': 'Beef',
        'asset': 'assets/widgets/pork.png', // Using pork as placeholder
        'assetType': 'image',
        'category': 'beef',
      },
      {
        'name': 'Plant-Based',
        'asset': 'assets/widgets/soup-vid.gif', // Using soup as placeholder
        'assetType': 'gif',
        'category': 'vegetarian',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
          category['name'] as String,
          category['asset'] as String,
          category['assetType'] as String,
          category['category'] as String,
        );
      },
    );
  }

  Widget _buildHealthCategories() {
    final healthCategories = [
      {
        'name': 'Healthy / Low-Calorie',
        'asset': 'assets/widgets/fish.png', // Using fish as placeholder
        'assetType': 'image',
        'category': 'healthy_low_cal',
        'icon': Icons.favorite,
        'color': Colors.green[400]!,
      },
      {
        'name': 'High-Protein / Gym Meals',
        'asset': 'assets/widgets/pork.png', // Using pork as placeholder
        'assetType': 'image',
        'category': 'high_protein',
        'icon': Icons.fitness_center,
        'color': Colors.purple[400]!,
      },
      {
        'name': 'Low-Carb / Keto Friendly',
        'asset': 'assets/widgets/silog-meals.jpg', // Using silog as placeholder
        'assetType': 'image',
        'category': 'low_carb',
        'icon': Icons.grass,
        'color': Colors.teal[400]!,
      },
      {
        'name': 'Heart-Healthy 🫀',
        'asset': 'assets/widgets/soup-vid.gif', // Using soup as placeholder
        'assetType': 'gif',
        'category': 'heart_healthy',
        'icon': Icons.favorite_border,
        'color': Colors.red[300]!,
      },
      {
        'name': 'Low Sodium',
        'asset': 'assets/widgets/fish.png', // Using fish as placeholder
        'assetType': 'image',
        'category': 'low_sodium',
        'icon': Icons.water_drop,
        'color': Colors.cyan[400]!,
      },
      {
        'name': 'Diabetic-Friendly',
        'asset': 'assets/widgets/pork.png', // Using pork as placeholder
        'assetType': 'image',
        'category': 'diabetic_friendly',
        'icon': Icons.medical_services,
        'color': Colors.blue[300]!,
      },
      {
        'name': 'Hypertension-Friendly',
        'asset': 'assets/widgets/silog-meals.jpg', // Using silog as placeholder
        'assetType': 'image',
        'category': 'heart_healthy', // Same as heart-healthy for now
        'icon': Icons.health_and_safety,
        'color': Colors.orange[300]!,
      },
      {
        'name': 'Weight-Loss Meals',
        'asset': 'assets/widgets/soup-vid.gif', // Using soup as placeholder
        'assetType': 'gif',
        'category': 'weight_loss',
        'icon': Icons.trending_down,
        'color': Colors.pink[300]!,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: healthCategories.length,
      itemBuilder: (context, index) {
        final category = healthCategories[index];
        return _buildHealthCategoryCard(
          category['name'] as String,
          category['asset'] as String,
          category['assetType'] as String,
          category['category'] as String,
          category['icon'] as IconData,
          category['color'] as Color,
        );
      },
    );
  }

  Widget _buildHealthCategoryCard(String name, String asset, String assetType, String category, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FilteredRecipesPage(
              category: category,
              categoryName: name,
              onChanged: _fetchCounts,
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
              // Health-themed gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
              // Centered content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Health icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        icon,
                        size: 28,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category name
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildCategoryCard(String name, String asset, String assetType, String category) {
          return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
                PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FilteredRecipesPage(
              category: category,
              categoryName: name,
              onChanged: _fetchCounts,
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
              // Centered asset (image or gif) with padding for floating effect
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.contain,
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
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
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                ),
                    ),
                  ],
                ),
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
                    Row(
                      children: [
                        // Add Meal Plan button
                        GestureDetector(
                          onTap: _createMealPlanFromHomepage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              '+ Add Plan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // CTA removed per request

  // Fetch recent meals for meal plan creation
  Future<void> _fetchRecentMeals() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch recent recipes from meal history
      final mealHistory = await Supabase.instance.client
          .from('meal_plan_history')
          .select('recipe_id, title, image_url, calories, protein, carbs, fat')
          .eq('user_id', user.id)
          .order('completed_at', ascending: false)
          .limit(10);

      if (!mounted) return;

      setState(() {
        _recentMeals = mealHistory.map((meal) => Recipe(
          id: meal['recipe_id']?.toString() ?? '',
          title: meal['title'] ?? 'Unknown Recipe',
          imageUrl: meal['image_url'] ?? '',
          shortDescription: 'Recent meal from history',
          calories: meal['calories'] ?? 0,
          ingredients: [],
          instructions: [],
          macros: {
            'protein': (meal['protein'] ?? 0).toDouble(),
            'carbs': (meal['carbs'] ?? 0).toDouble(),
            'fat': (meal['fat'] ?? 0).toDouble(),
          },
          allergyWarning: '',
          dietTypes: [],
          cost: 0.0,
        )).toList();
      });
    } catch (e) {
      print('Error fetching recent meals: $e');
    }
  }

  // Create meal plan from homepage
  Future<void> _createMealPlanFromHomepage() async {
    if (_recentMeals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No recent meals found. Please add some meals first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

              // Navigate directly to MealSummaryPage
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MealSummaryPage(
                    meals: _recentMeals,
                    onBuildMealPlan: (mealsWithTime) async {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveDesign.isSmallScreen(context);


  List<Widget> pages = [
    _buildHomeContent(),
    MealPlannerScreen(
      forceRefresh: widget.forceMealPlanRefresh,
      onChanged: _fetchCounts,
    ),
    const SizedBox.shrink(), // Empty widget for the plus button space
    const MealTrackerScreen(),
    const ProfileScreen(),
  ];

  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
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
    backgroundColor: Colors.grey[50],
    body: Column(
      children: [
        Expanded(
            child: pages[_selectedIndex],
        ),
      ],
    ),
    floatingActionButton: null, // Removed - now using elevated plus button in bottom navigation
    bottomNavigationBar: BottomNavigation(
      selectedIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      mealPlanCount: _mealPlanCount,
      isSmallScreen: isSmallScreen,
      onAddMealPressed: () async {
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
    ),
  );
}
}